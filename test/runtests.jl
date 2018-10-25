using Mocking
Mocking.enable(force=true)

using Checkpoints
using Compat.Test
using AWSCore

using AWSCore: AWSConfig
using AWSS3: s3_put

# The method based on keyword arguments is not in Compat, so to avoid
# deprecation warnings on 0.7 we need this little definition.
if VERSION < v"0.7.0-DEV.4524"
    function sprint(f::Function, args...; context=nothing)
        if context !== nothing
            Base.sprint((io, args...) -> f(IOContext(io, context), args...), args...)
        else
            Base.sprint(f, args...)
        end
    end
end


@testset "Checkpoints" begin
    include("JLSO.jl")

    include("testpkg.jl")

    x = reshape(collect(1:100), 10, 10)
    y = reshape(collect(101:200), 10, 10)
    a = collect(1:10)

    @testset "Local handler" begin
        mktempdir() do path
            Checkpoints.config("TestPkg.foo", path)

            TestPkg.foo(x, y)
            TestPkg.bar(a)

            mod_path = joinpath(path, "TestPkg")
            @test isdir(mod_path)

            foo_path = joinpath(path, "TestPkg", "foo.jlso")
            bar_path = joinpath(path, "TestPkg", "bar.jlso")
            @test isfile(foo_path)
            @test !isfile(bar_path)

            data = JLSO.load(foo_path)
            @test data["x"] == x
            @test data["y"] == y
        end
    end

    @testset "S3 handler" begin
        objects = Dict{String, Vector{UInt8}}()

        s3_put_patch = @patch function s3_put(config::AWSConfig, bucket, prefix, data)
            objects[joinpath(bucket, prefix)] = data
        end

        config = AWSCore.aws_config()
        bucket = "mybucket"
        prefix = joinpath("mybackrun")
        Checkpoints.config("TestPkg.bar", bucket, prefix)

        apply(s3_put_patch) do
            TestPkg.bar(a)
            expected_path = joinpath(bucket, prefix, "date=2017-01-01", "TestPkg/bar.jlso")
            io = IOBuffer(objects[expected_path])
            @test JLSO.load(io)["data"] == a
        end
    end

    @testset "Sessions" begin
        @testset "No-op" begin
            mktempdir() do path
                d = Dict(zip(map(x -> randstring(4), 1:10), map(x -> rand(10), 1:10)))

                TestPkg.baz(d)

                mod_path = joinpath(path, "TestPkg")
                baz_path = joinpath(path, "TestPkg", "baz.jlso")
                @test !isfile(baz_path)
            end
        end
        @testset "Single" begin
            mktempdir() do path
                d = Dict(zip(map(x -> randstring(4), 1:10), map(x -> rand(10), 1:10)))
                Checkpoints.config("TestPkg.baz", path)

                TestPkg.baz(d)

                mod_path = joinpath(path, "TestPkg")
                @test isdir(mod_path)

                baz_path = joinpath(path, "TestPkg", "baz.jlso")
                @test isfile(baz_path)

                data = JLSO.load(baz_path)
                for (k, v) in data
                    @test v == d[k]
                end
            end
        end
        @testset "Multi" begin
            mktempdir() do path
                a = Dict(zip(map(x -> randstring(4), 1:10), map(x -> rand(10), 1:10)))
                b = rand(10)
                Checkpoints.config("TestPkg.qux" , path)

                TestPkg.qux(a, b)

                mod_path = joinpath(path, "TestPkg")
                @test isdir(mod_path)

                qux_a_path = joinpath(path, "TestPkg", "qux_a.jlso")
                @test isfile(qux_a_path)

                qux_b_path = joinpath(path, "TestPkg", "qux_b.jlso")
                @test isfile(qux_b_path)

                data = JLSO.load(qux_a_path)
                for (k, v) in data
                    @test v == a[k]
                end

                data = JLSO.load(qux_b_path)
                @test data["data"] == b
            end
        end
    end
end
