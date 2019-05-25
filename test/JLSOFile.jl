@testset "JLSOFile" begin

    withenv("JLSO_IMAGE" => "busybox") do
        jlso = JLSOFile("the image env variable is set")
        @test jlso.image == "busybox"
    end

    # Reset the cached image for future tests
    JLSO._CACHE[:IMAGE] = ""

    @testset "$fmt - $k" for fmt in (:bson, :julia_serialize), (k, v) in datas
        jlso = JLSOFile(k => v; format=fmt, compression=:none)
        io = IOBuffer()
        bytes = fmt === :bson ? bson(io, Dict("object" => v)) : serialize(io, v)
        close(io)
        expected = io.data

        @test jlso.objects[k] == expected
    end
end

@testset "unknown format" begin
    @test_throws(
        LOGGER,
        ArgumentError,
        JLSOFile("String" => "Hello World!", format=:unknown)
    )
end

@testset "show" begin
    jlso = JLSOFile(datas["String"])
    expected = string(
        "JLSOFile([data]; version=v\"2.0.0\", julia=v\"$VERSION\", ",
        "format=:julia_serialize, image=\"\")"
    )
    @test sprint(show, jlso) == sprint(print, jlso)
end
