function _versioncheck(version::VersionNumber, valid_versions)
    supported = version ∈ valid_versions
    supported || error(LOGGER, ArgumentError(
        string(
            "Unsupported version ($version). ",
            "Expected a value between ($SAVVALID_VERSIONS)."
        )
    ))
end


# Cache of the versioninfo and image, so we don't compute these every time.
const _CACHE = Dict(
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

function _image()
    if isempty(_CACHE[:IMAGE]) && haskey(ENV, "JLSO_IMAGE")
        return ENV["JLSO_IMAGE"]
    end

    return _CACHE[:IMAGE]
end
