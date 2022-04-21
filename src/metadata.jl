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

# Make sure _CACHE access is thread-safe
const _CACHE_LOCK = ReentrantLock()

function _pkgs()
    lock(_CACHE_LOCK) do
        if isempty(_CACHE[:PKGS])
            for (pkg, ver) in Pkg.installed()
                # BSON can't handle Void types
                if ver !== nothing
                    global _CACHE[:PKGS][pkg] = ver
                end
            end
        end
    end

    return _CACHE[:PKGS]
end

function _env()
    lock(_CACHE_LOCK) do
        if isempty(_CACHE[:PROJECT]) && isempty(_CACHE[:MANIFEST])
            _CACHE[:PROJECT] = read(Base.active_project(), String)
            _CACHE[:MANIFEST] = read(
                joinpath(dirname(Base.active_project()), "Manifest.toml"),
                String
            )
        end
    end

    return (_CACHE[:PROJECT], _CACHE[:MANIFEST])
end

function _image()
    if isempty(_CACHE[:IMAGE]) && haskey(ENV, "JLSO_IMAGE")
        return ENV["JLSO_IMAGE"]
    end

    return _CACHE[:IMAGE]
end

function Pkg.activate(jlso::JLSOFile, path=tempdir(); kwargs...)
    mkpath(path)
    open(io -> Pkg.TOML.print(io, jlso.project), joinpath(path, "Project.toml"), "w")
    open(io -> Pkg.TOML.print(io, jlso.manifest), joinpath(path, "Manifest.toml"), "w")
    Pkg.activate(path; kwargs...)
end

function Pkg.activate(f::Function, jlso::JLSOFile, path=tempdir(); kwargs...)
    curr_env = dirname(Base.active_project())
    try
        Pkg.activate(jlso, path; kwargs...)
        f()
    finally
        Pkg.activate(curr_env)
    end
end
