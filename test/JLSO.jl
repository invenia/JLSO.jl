using BSON
using Compat
using Compat.Test
using Compat.Dates
using Compat.Distributed
using Compat.InteractiveUtils
using Compat.Serialization
using Checkpoints
using Checkpoints.JLSO: JLSOFile, LOGGER
using Memento
using Memento.Test

# To test different types from common external packages
using DataFrames
using Distributions
using Nullables  # Needed for loading BSON encoded ZonedDateTimes on 1.0
using TimeZones

@testset "JLSO" begin
    # Serialize "Hello World!" on julia 0.5.2 (not supported)
    img = JLSO._image()
    pkgs = JLSO._pkgs()
    hw_5 = UInt8[0x26, 0x15, 0x87, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21]

    datas = Dict(
        "String" => "Hello World!",
        "Vector" => [0.867244, 0.711437, 0.512452, 0.863122, 0.907903],
        "Matrix" => [0.400348 0.892196 0.848164; 0.0183529 0.755449 0.397538; 0.870458 0.0441878 0.170899],
        "DateTime" => DateTime(2018, 1, 28),
        "ZonedDateTime" => ZonedDateTime(2018, 1, 28, tz"America/Chicago"),
        "DataFrame" => DataFrame(
            :a => collect(1:5),
            :b => [0.867244, 0.711437, 0.512452, 0.863122, 0.907903],
            :c => ["a", "b", "c", "d", "e"],
            :d => [true, true, false, false, true],
        ),
        "Distribution" => Normal(50.2, 4.3),
    )

    @testset "JLSOFile" begin
        @testset "$fmt - $k" for fmt in (:bson, :serialize), (k, v) in datas
            jlso = JLSOFile(k => v; format=fmt)
            io = IOBuffer()
            bytes = fmt === :bson ? bson(io, Dict(k => v)) : serialize(io, v)
            expected = take!(io)

            @test jlso.objects[k] == expected
        end
    end

    @testset "show" begin
        jlso = JLSOFile(datas["String"])
        expected = string(
            "JLSOFile([data]; version=v\"1.0.0\", julia=v\"$VERSION\", ",
            "format=:serialize, image=\"\")"
        )
        @test sprint(show, jlso; context=:compact => true) == expected
        @test sprint(show, jlso) == sprint(print, jlso)
    end

    @testset "reading and writing" begin
        @testset "$fmt - $k" for fmt in (:bson, :serialize), (k, v) in datas
            io = IOBuffer()
            orig = JLSOFile(v; format=fmt)
            write(io, orig)

            seekstart(io)

            result = read(io, JLSOFile)
            @test result == orig
        end
    end

    @testset "deserialization" begin
        # Test deserialization works
        @testset "$fmt - $k" for fmt in (:bson, :serialize), (k, v) in datas
            jlso = JLSOFile(v; format=fmt)
            @test jlso["data"] == v
        end

        @testset "unsupported julia version" begin
            jlso = JLSOFile(v"1.0", VERSION, :serialize, img, pkgs, Dict("data" => hw_5))

            # Test failing to deserialize data because of incompatible julia versions
            # will will return the raw bytes
            result = @test_warn(LOGGER, r"MethodError*", jlso["data"])
            @test result == hw_5

            # TODO: Test that BSON works across julia versions using external files?
        end

        @testset "missing module" begin
            # We need to load and use AxisArrays on another process to cause the
            # deserialization error
            pnum = first(addprocs(1))

            try
                # We need to do this separately because there appears to be a race
                # condition on AxisArrays being loaded.
                f = @spawnat pnum begin
                    @eval Main using Compat
                    @eval Main using Compat.Serialization
                    @eval Main using BSON
                    @eval Main using AxisArrays
                end

                fetch(f)

                @testset "serialize" begin
                    f = @spawnat pnum begin
                        io = IOBuffer()
                        serialize(
                            io,
                            AxisArray(
                                rand(20, 10),
                                Axis{:time}(14010:10:14200),
                                Axis{:id}(1:10)
                            )
                        )
                        return io
                    end

                    io = fetch(f)
                    bytes = take!(io)

                    jlso = JLSOFile(v"1.0", VERSION, :serialize, img, pkgs, Dict("data" => bytes))

                    # Test failing to deserailize data because of missing modules will
                    # still return the raw bytes
                    result = if VERSION < v"0.7.0"
                        @test_warn(LOGGER, r"UndefVarError*", jlso["data"])
                    else
                        @test_warn(LOGGER, r"KeyError*", jlso["data"])
                    end

                    @test result == bytes
                end

                @testset "bson" begin
                    f = @spawnat pnum begin
                        io = IOBuffer()
                        bson(
                            io,
                            Dict(
                                "data" => AxisArray(
                                    rand(20, 10),
                                    Axis{:time}(14010:10:14200),
                                    Axis{:id}(1:10)
                                )
                            )
                        )
                        return io
                    end

                    io = fetch(f)
                    bytes = take!(io)

                    jlso = JLSOFile(v"1.0", VERSION, :bson, img, pkgs, Dict("data" => bytes))

                    # Test failing to deserailize data because of missing modules will
                    # still return the raw bytes
                    result = @test_warn(LOGGER, r"UndefVarError*", jlso["data"])

                    @test result == bytes
                end
            finally
                rmprocs(pnum)
            end
        end
    end

    @testset "saving and loading" begin
        mktempdir() do path
            @testset "$fmt - $k" for fmt in (:bson, :serialize), (k, v) in datas
                JLSO.save("$path/$fmt-$k.jlso", k => v; format=fmt)
                result = JLSO.load("$path/$fmt-$k.jlso")
                @test result[k] == v
            end
        end
    end
end
