@deprecate(
    JLSOFile(
        version::VersionNumber,
        julia::VersionNumber,
        format::Symbol,
        compression::Symbol,
        image::String,
        pkgs::Dict{String, VersionNumber},
        objects::Dict{String, Vector{UInt8}},
    ),
    JLSOFile(
        version,
        julia,
        format,
        compression,
        image,
        Pkg.TOML.parse.(_upgrade_env(pkgs))...,
        Dict{Symbol, Vector{UInt8}}(Symbol(k) => v for (k, v) in objects),
    )
)

@deprecate JLSOFile(data; kwargs...) JLSOFile(:data => data; kwargs...)
@deprecate(
    JLSOFile(data::Dict{String, <:Any}; kwargs...),
    JLSOFile(Dict(Symbol(k) => v for (k, v) in data); kwargs...)
)

function upgrade_jlso(raw_dict::AbstractDict)
    result = copy(raw_dict)
    version = version_number(result["metadata"]["version"])

    while version < v"3"
        result = upgrade_jlso(result, Val(Int(version.major)))
        version = version_number(result["metadata"]["version"])
    end

    return result
end

@deprecate getindex(jlso::JLSOFile, name::String) getindex(jlso, Symbol(name))
@deprecate setindex!(jlso::JLSOFile, value, name::String) setindex!(jlso, value, Symbol(name))

# v1 and v2 stored version numbers but v3 stores strings to be bson parser agnostic
version_number(x::VersionNumber) = x
version_number(x::String) = VersionNumber(x)

# Metadata changes to upgrade file from v1 to v2
function upgrade_jlso(raw_dict::AbstractDict, ::Val{1})
    info(LOGGER, "Upgrading JLSO format from v1 to v2")
    metadata = copy(raw_dict["metadata"])
    version = version_number(metadata["version"])
    @assert version ∈ semver_spec("1")

    if metadata["format"] == :serialize
        metadata["format"] = :julia_serialize
    end

    metadata["compression"] = :none
    metadata["version"] = v"2"

    return Dict("metadata" => metadata, "objects" => get(raw_dict, "objects", Dict()))
end

# Metadata changes to upgrade from v2 to v3
function upgrade_jlso(raw_dict::AbstractDict, ::Val{2})
    info(LOGGER, "Upgrading JLSO format from v2 to v3")
    metadata = copy(raw_dict["metadata"])
    version = version_number(metadata["version"])
    @assert version ∈ semver_spec("2")

    # JLSO v3 expects to be loading a compressed manifest
    compression = get(metadata, "compression", :none)
    project, manifest = _upgrade_env(get(metadata, "pkgs", nothing))

    return Dict{String, Dict}(
        "metadata" => Dict{String, Union{String, Vector{UInt8}}}(
            "version" => "3",
            "julia" => string(get(metadata, "julia", VERSION)),
            "format" => string(get(metadata, "format", :julia_serialize)),
            "compression" => string(compression),
            "image" => get(metadata, "image", ""),
            "project" => project,
            "manifest" => read(compress(compression, IOBuffer(manifest))),
        ),
        "objects" => Dict{String, Vector{UInt8}}(
            k => v for (k, v) in get(raw_dict, "objects", Dict())
        ),
    )
end

# Used to convert the old "PkgName" => VersionNumber metadata to a
# Project.toml and Manifest.toml file.
function _upgrade_env(pkgs::Dict)
    src_env = Base.active_project()

    try
        mktempdir() do tmp
            Pkg.activate(tmp)

            # We construct an array of PackageSpecs to avoid ordering problems with
            # adding each package individually
            try
                Pkg.add([
                    Pkg.PackageSpec(; name=key, version=value) for (key, value) in pkgs
                ])
            catch e
                # Warn about failure and fallback to simply trying to install the pacakges
                # without version constraints.
                warn(LOGGER) do
                    "Failed to construct an environment with the provide package version " *
                    "($pkgs): $e.\n Falling back to simply adding the packages."
                end
                Pkg.add([Pkg.PackageSpec(; name=key) for (key, value) in pkgs])
            end

            return _env()
        end
    finally
        Pkg.activate(src_env)
    end
end

_upgrade_env(::Nothing) = ("", "")
