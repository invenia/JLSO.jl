function _versioncheck(version::VersionNumber, valid_versions)
    supported = version ∈ valid_versions
    supported || error(LOGGER, ArgumentError(
        string(
            "Unsupported version ($version). ",
            "Expected a value between ($valid_versions)."
        )
    ))
end

function _versioncheck(version::String, valid_versions)
    return _versioncheck(VersionNumber(version), valid_versions)
end

# Cache of the versioninfo and image, so we don't compute these every time.
const _CACHE = Dict(
    :MANIFEST => "",
    :PROJECT => "",
    :PKGS => Dict{String, VersionNumber}(),
    :IMAGE => "",
)

function _pkgs()
    if isempty(_CACHE[:PKGS])
        for (pkg, ver) in Pkg.installed()
            # BSON can't handle Void types
            if ver !== nothing
                global _CACHE[:PKGS][pkg] = ver
            end
        end
    end

    return _CACHE[:PKGS]
end

function _env()
    if isempty(_CACHE[:PROJECT]) && isempty(_CACHE[:MANIFEST])
        _CACHE[:PROJECT] = read(Base.active_project(), String)
        _CACHE[:MANIFEST] = read(
            joinpath(dirname(Base.active_project()), "Manifest.toml"),
            String
        )
    end

    return (_CACHE[:PROJECT], _CACHE[:MANIFEST])
end

# Used to convert the old "PkgName" => VersionNumber metadata to a
# Project.toml and Manifest.toml file.
function _env(pkgs::Dict)
    src_env = Base.active_project()

    try
        mktempdir() do tmp
            Pkg.activate(tmp)

            for (key, value) in pkgs
                Pkg.add(Pkg.PackageSpec(; name=key, version=value))
            end

            return _env()
        end
    finally
        Pkg.activate(src_env)
    end
end

function _image()
    if isempty(_CACHE[:IMAGE]) && haskey(ENV, "JLSO_IMAGE")
        return ENV["JLSO_IMAGE"]
    end

    return _CACHE[:IMAGE]
end
