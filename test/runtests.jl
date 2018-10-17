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

    include("testmod.jl")

    x = reshape(collect(1:100), 10, 10)
    y = reshape(collect(101:200), 10, 10)

    @testset "Local saver" begin
        mktempdir() do path
            Checkpoints.config(Checkpoints.saver(path), "TestModule.foo")

            TestModule.foo(x, y)

            mod_path = joinpath(path, "TestModule")
            @test isdir(mod_path)

            foo_path = joinpath(path, "TestModule", "foo")
            bar_path = joinpath(path, "TestModule", "bar")
            @test isdir(foo_path)
            @test !isdir(bar_path)

            x_path = joinpath(path, "TestModule", "foo", "x.jlso")
            y_path = joinpath(path, "TestModule", "foo", "y.jlso")
            @test isfile(x_path)
            @test isfile(y_path)

            @test JLSO.load(x_path)["data"] == x
            @test JLSO.load(y_path)["data"] == y
        end
    end

    @testset "S3 saver" begin
        objects = Dict{String, Vector{UInt8}}()

        s3_put_patch = @patch function s3_put(config::AWSConfig, bucket, prefix, data)
            objects[joinpath(bucket, prefix)] = data
        end

        config = AWSCore.aws_config()
        bucket = "mybucket"
        prefix = joinpath("mybackrun", string(DateTime(2017, 1, 1, 8, 50, 32)))
        Checkpoints.config(
            Checkpoints.saver(config, bucket, prefix),
            "TestModule.foo"
        )

        apply(s3_put_patch) do
            TestModule.foo(x, y)

            io = IOBuffer(objects[joinpath(bucket, prefix, "TestModule/foo/x.jlso")])
            @test JLSO.load(io)["data"] == x

            io = IOBuffer(objects[joinpath(bucket, prefix, "TestModule/foo/y.jlso")])
            @test JLSO.load(io)["data"] == y
        end
    end
end
