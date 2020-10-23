@testset "reading and writing" begin
    @testset "$fmt - $k" for fmt in (:bson, :julia_serialize), (k, v) in datas
        io = IOBuffer()
        orig = JLSOFile(:data => v; format=fmt)
        write(io, orig)

        seekstart(io)

        result = read(io, JLSOFile)
        @test result.version == orig.version
        @test result.julia == orig.julia
        @test result.image == orig.image
        @test result.manifest == orig.manifest
        @test result.format == orig.format
        @test result.compression == orig.compression
        @test result.objects == orig.objects
        @test result == orig
    end
end

@testset "deserialization" begin
    # Test deserialization works
    @testset "$fmt - $k" for fmt in (:bson, :julia_serialize), (k, v) in datas
        jlso = JLSOFile(:data => v; format=fmt)
        @test jlso[:data] == v
    end

    @testset "unsupported julia version $jlso_version" for jlso_version in (v"1.0", v"2.0")
        jlso = @suppress_out begin
            JLSOFile(
                jlso_version,
                VERSION,
                :julia_serialize,
                :none,
                img,
                project,
                manifest,
                Dict(:data => hw_5),
                ReentrantLock()
            )
        end

        # Test failing to deserialize data because of incompatible julia versions
        # will return the raw bytes
        result = if VERSION < v"1.2"
            @test_warn(LOGGER, r"MethodError*", jlso[:data])
        else
            @test_warn(LOGGER, r"TypeError*", jlso[:data])
        end

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
                @eval Main using Serialization
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

                jlso = JLSOFile(
                    v"3.0",
                    VERSION,
                    :julia_serialize,
                    :none,
                    img,
                    project,
                    manifest,
                    Dict(:data => bytes),
                    ReentrantLock()
                )

                # Test failing to deserailize data because of missing modules will
                # still return the raw bytes
                result = @test_warn(LOGGER, r"KeyError*", jlso[:data])
                @test result == bytes
            end

            @testset "bson" begin
                f = @spawnat pnum begin
                    io = IOBuffer()
                    bson(
                        io,
                        Dict(
                            :data => AxisArray(
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

                jlso = JLSOFile(
                    v"3.0",
                    VERSION,
                    :bson,
                    :none,
                    img,
                    project,
                    manifest,
                    Dict(:data => bytes),
                    ReentrantLock()
                )

                # Test failing to deserailize data because of missing modules will
                # still return the raw bytes
                result = @test_warn(LOGGER, r"UndefVarError*", jlso[:data])

                @test result == bytes
            end
        finally
            rmprocs(pnum)
        end
    end
end

@testset "saving and loading" begin
    function test_save_and_load(dirpath)
        @testset "$fmt - $k" for fmt in (:bson, :julia_serialize), (k, v) in datas
            filepath = joinpath(dirpath, "$fmt-$k.jlso")
            JLSO.save(filepath, k => v; format=fmt)
            result = JLSO.load(filepath)
            single_item = JLSO.load(filepath, k)
            @test result[k] == single_item[k] == v
        end
    end
    @testset "String-type paths" begin
        mktempdir(test_save_and_load)
    end
    @testset "Path-type paths" begin
        mktempdir(test_save_and_load, SystemPath)
    end
    @testset "keys are not Symbols" begin
        @test_throws(
            getlogger(JLSO),
            MethodError,
            JLSO.save("breakfast.jlso", "food" => "☕️🥓🍳", "time" => Time(9, 0)),
        )
    end
    @testset "Size Limits" begin
        mktempdir() do d
            @testset "Large Objects" begin
                obj = zeros(UInt8, typemax(Int32) + 1)
                @test_throws(
                    InexactError,
                    JLSO.save(
                        joinpath(d, "large-object.jlso"),
                        :X => obj;
                        compression=:none,
                    ),
                )
            end
            @testset "Large Docs" begin
                # Even if an individual object isn't too big we expect an error if the total
                # doc is too big
                sz = ceil(Int, typemax(Int32) / 2)
                @test_throws(
                    InexactError,
                    JLSO.save(
                        joinpath(d, "large-doc.jlso"),
                        :A => zeros(UInt8, sz),
                        :B => zeros(UInt8, sz);
                        compression=:none,
                    ),
                )
            end
        end
    end
    @testset "README example" begin
        mktempdir() do path
            JLSO.save(
                joinpath(path, "breakfast.jlso"),
                :food => "☕️🥓🍳",
                :cost => 11.95,
                :time => Time(9, 0),
            )
            loaded = JLSO.load("$path/breakfast.jlso")
            @test loaded == Dict{Symbol,Any}(
                :cost => 11.95,
                :time => Time(9, 0),
                :food => "☕️🥓🍳",
            )
        end
    end
end
