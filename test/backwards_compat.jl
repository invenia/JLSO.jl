@testset "upgrade_jlso" begin
    @testset "no change for current version" begin
        d = Dict("metadata" => Dict("version" => v"2.0"))
        @suppress_out upgrade_jlso!(d)
        @test d == Dict("metadata" => Dict("version" => v"2.0"))
    end

    @testset "upgrade 1.0" begin
        d = Dict("metadata" => Dict("version" => v"1.0", "format"=>:serialize))
        @suppress_out upgrade_jlso!(d)
        @test d == Dict("metadata" => Dict(
            "version" => v"3.0", "format"=>:julia_serialize, "compression" => :none
        ))

        @testset "Don't rename bson format" begin
            d = Dict("metadata" => Dict("version" => v"1.0", "format"=>:bson))
            @suppress_out upgrade_jlso!(d)
            @test d == Dict("metadata" => Dict(
                "version" => v"3.0", "format"=>:bson, "compression" => :none
            ))
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
