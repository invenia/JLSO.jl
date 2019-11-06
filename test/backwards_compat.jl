@testset "upgrade_jlso" begin
    @testset "no change for current version" begin
        d = Dict("metadata" => Dict("version" => v"3.0"))
        new_d = @suppress_out upgrade_jlso(d)
        @test new_d == Dict("metadata" => Dict("version" => v"3.0"))
    end

    @testset "upgrade 1.0" begin
        d = Dict("metadata" => Dict("version" => v"1.0", "format"=>:serialize))
        new_d = @suppress_out upgrade_jlso(d)
        @test new_d["metadata"]["version"] == "3"
        @test new_d["metadata"]["format"] == "julia_serialize"
        @test new_d["metadata"]["compression"] == "none"
        @test isempty(new_d["metadata"]["project"])
        @test isempty(new_d["metadata"]["manifest"])
        @test isempty(new_d["objects"])

        @testset "Don't rename bson format" begin
            d = Dict("metadata" => Dict("version" => v"1.0", "format"=>:bson))
            new_d = @suppress_out upgrade_jlso(d)
            @test new_d["metadata"]["version"] == "3"
            @test new_d["metadata"]["format"] == "bson"
            @test new_d["metadata"]["compression"] == "none"
            @test isempty(new_d["metadata"]["project"])
            @test isempty(new_d["metadata"]["manifest"])
            @test isempty(new_d["objects"])
        end
    end
end

# The below is how we saves the specimens for compat testing
# JLSO.save("specimens/v1_serialize.jlso", datas; format=:serialize)
# JLSO.save("specimens/v1_bson.jlso", datas; format=:bson)

@testset "Can still load old files" begin
    dir = joinpath(@__DIR__, "specimens")
    @testset "$fn" for fn in readdir(dir)
        jlso_data = @suppress_out JLSO.load(joinpath(dir, fn))
        @test jlso_data == datas
    end
end
