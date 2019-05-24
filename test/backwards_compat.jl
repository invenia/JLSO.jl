@testset "upgrade_jlso" begin
    @testset "no change for current version" begin
        d = Dict("metadata" => Dict("version" => v"2.0"))
        upgrade_jlso!(d)
        @test d == Dict("metadata" => Dict("version" => v"2.0"))
    end

    @testset "upgrade 1.0" begin
        d = Dict("metadata" => Dict("version" => v"1.0", "format"=>:serialize))
        upgrade_jlso!(d)
        @test d == Dict("metadata" => Dict(
            "version" => v"2.0", "format"=>:julia_serialize, "compression" => :none
        ))

        @testset "Don't rename bson format" begin
            d = Dict("metadata" => Dict("version" => v"1.0", "format"=>:bson))
            upgrade_jlso!(d)
            @test d == Dict("metadata" => Dict(
                "version" => v"2.0", "format"=>:bson, "compression" => :none
            ))
        end
    end
end

# The below is how we saves the specimens for compat testing
# JLSO.save("specimens/v1_serialize.jlso", datas; format=:serialize)
# JLSO.save("specimens/v1_bson.jlso", datas; format=:bson)

@testset "v1 compat" begin
    @test JLSO.load("specimens/v1_serialize.jlso") == datas
    @test JLSO.load("specimens/v1_bson.jlso") == datas
end
