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
using TimeZones

@testset "JLSO" begin
    # Serialize "Hello World!" on julia 0.5.2 (not supported)
    img = JLSO._image()
    sysinfo = JLSO._versioninfo()
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
        @testset "$k" for (k, v) in datas
            jlso = JLSOFile(v)
            io = IOBuffer()
            bytes = serialize(io, v)
            expected = take!(io)

            @test jlso.objects["data"] == expected
        end
    end

    @testset "reading and writing" begin
        @testset "$k" for (k, v) in datas
            io = IOBuffer()
            orig = JLSOFile(v)
            write(io, orig)

            seekstart(io)

            result = read(io, JLSOFile)
            @test result == orig
        end
    end

    @testset "deserialization" begin
        # Test deserialization works
        @testset "data - $k" for (k, v) in datas
            jlso = JLSOFile(v)
            @test jlso["data"] == v
        end

        @testset "unsupported julia version" begin
            jlso = JLSOFile(v"1.0", img, VERSION, sysinfo, Dict("data" => hw_5))

            # Test failing to deserialize data because of incompatible julia versions
            # will will return the raw bytes
            result = @test_warn(LOGGER, r"MethodError*", jlso["data"])
            @test result == hw_5
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
                    @eval Main using AxisArrays
                end

                fetch(f)

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
                jlso = JLSOFile(v"1.0", img, VERSION, sysinfo, Dict("data" => bytes))

                # Test failing to deserailize data because of missing modules will
                # still return the raw bytes
                result = if VERSION < v"0.7.0"
                    @test_warn(LOGGER, r"UndefVarError*", jlso["data"])
                else
                    @test_warn(LOGGER, r"KeyError*", jlso["data"])
                end

                @test result == bytes
            finally
                rmprocs(pnum)
            end
        end
    end
end
