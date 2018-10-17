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

    @testset "Local saver" begin
        mktempdir() do path
            Checkpoints.config(Checkpoints.saver(path), "TestPkg.foo")

            TestPkg.foo(x, y)

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

    @testset "S3 saver" begin
        objects = Dict{String, Vector{UInt8}}()

        s3_put_patch = @patch function s3_put(config::AWSConfig, bucket, prefix, data)
            objects[joinpath(bucket, prefix)] = data
        end

        config = AWSCore.aws_config()
        bucket = "mybucket"
        prefix = joinpath("mybackrun", string(DateTime(2017, 1, 1, 8, 50, 32)))
        Checkpoints.config(Checkpoints.saver(config, bucket, prefix), "TestPkg.bar")

        apply(s3_put_patch) do
            TestPkg.bar(a)

            io = IOBuffer(objects[joinpath(bucket, prefix, "TestPkg/bar.jlso")])
            @test JLSO.load(io)["data"] == a
        end
    end
end
