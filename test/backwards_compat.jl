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

        @testset "Invalid VersionNumber" begin
            d = Dict(
                "metadata" => Dict(
                    "version" => v"1.0", "format" => :bson,
                    # We don't intend to go back an make a 0.3.14 release at any point.
                    "pkgs" => merge(pkgs, Dict("JLSO" => v"0.3.14")),
                )
            )

            new_d = @suppress_out upgrade_jlso(d)
            @test !isempty(new_d["metadata"]["project"])
            @test !isempty(new_d["metadata"]["manifest"])

            # Test that the project.toml has the JLSO dep, but not a specific version
            # (fallback when package versions don't exist in the registry)
            _project = Pkg.TOML.parse(new_d["metadata"]["project"])
            @test haskey(_project, "deps")
            @test haskey(_project["deps"], "JLSO")
            @test haskey(_project, "compat")
            # Check that the compat section doesn't have our package version
            @test !haskey(_project["compat"], "JLSO")
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
        @test jlso_data == load_datas
    end
end
