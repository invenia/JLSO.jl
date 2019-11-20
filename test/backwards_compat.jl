@testset "Upgrading" begin
    @testset "JLSO.upgrade_jlso" begin
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

    # Test upgrading files to avoid repeated upgrading
    @testset "JLSO.upgrade" begin
        src_dir = joinpath(@__DIR__, "specimens")
        @testset "upgrade" begin
            mktempdir() do dest_dir
                @testset "$fn" for fn in readdir(src_dir)
                    src = joinpath(src_dir, fn)
                    dest = joinpath(dest_dir, fn)
                    @suppress_out JLSO.upgrade(src, dest)
                    jlso_data = JLSO.load(dest)
                    @test jlso_data == load_datas
                end
            end
        end
        @testset "batch upgrade" begin
            mktempdir() do dest_dir
                fns = readdir(src_dir)
                src = joinpath.(src_dir, fns)
                dest = joinpath.(dest_dir, fns)

                @suppress_out JLSO.upgrade(src, dest)
                jlso_data = JLSO.load(first(dest))
                @test jlso_data == load_datas
            end
        end
        @testset "upgrade w/ manifest" begin
            src = joinpath(src_dir, "v3_bson_none.jlso")
            orig_jlso = read(src, JLSOFile)

            # Extract the project & manifest to modify
            new_project = deepcopy(orig_jlso.project)
            new_manifest = deepcopy(orig_jlso.manifest)

            # Check the current state is what we expect
            @test new_project["compat"]["Memento"] == "0.10, 0.11, 0.12"
            @test new_manifest["Memento"][1]["version"] == "0.12.1"


            # Update those values
            new_project["compat"]["Memento"] = "0.11, 0.12"
            new_manifest["Memento"][1]["version"] = "0.12.0"

            mktempdir() do dest_dir
                dest = joinpath(dest_dir, "v3_bson_none.jlso")
                @suppress_out JLSO.upgrade(src, dest, new_project, new_manifest)
                new_jlso = read(dest, JLSOFile)

                @test new_project["compat"]["Memento"] == "0.11, 0.12"
                @test new_manifest["Memento"][1]["version"] == "0.12.0"
            end
        end
    end
end
