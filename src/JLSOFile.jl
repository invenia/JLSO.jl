struct JLSOFile
    version::VersionNumber
    julia::VersionNumber
    format::Symbol
    compression::Symbol
    image::String
    project::Dict{String, Any}
    manifest::Dict{String, Any}
    objects::Dict{Symbol, Vector{UInt8}}
    lock::ReentrantLock
end

"""
    JLSOFile(data; format=:julia_serialize, compression=:gzip, kwargs...)

Stores the information needed to write a .jlso file.

# Arguments

- `data` - The objects to be stored in the file.

# Keywords

- `image=""` - The docker image URI that was used to generate the file
- `julia=$VERSION` - The julia version used to write the file
- `version=v"2.0"` - The file schema version
- `format=:julia_serialize` - The format to use for serializing individual objects. While `:bson` is
    recommended for longer term object storage, `:julia_serialize` tends to be the faster choice
    for adhoc serialization.
- `compression=:gzip`, what form of compression to apply to the objects.
    Use :none, to not compress. :gzip_fastest for the fastest gzip compression,
    :gzip_smallest for the most compact (but slowest), or :gzip for a generally good compromize.
    Due to the time taken for disk IO, :none is not normally as fast as using some compression.
"""
function JLSOFile(
    data::Dict{Symbol, <:Any};
    version=v"3",
    julia=VERSION,
    format=:julia_serialize,
    compression=:gzip,
    image=_image(),
)
    if format === :serialize
        # Deprecation warning
        @warn "The `:serialize` format has been renamed to `:julia_serialize`."
        format = :julia_serialize
    end

    _versioncheck(version, WRITEABLE_VERSIONS)
    project_toml, manifest_toml = _env()
    jlso = JLSOFile(
        version,
        julia,
        format,
        compression,
        image,
        Pkg.TOML.parse(project_toml),
        Pkg.TOML.parse(manifest_toml),
        Dict{Symbol, Vector{UInt8}}(),
        ReentrantLock()
    )

    @sync for (key, val) in data
        @spawn jlso[key] = val
    end

    return jlso
end

function JLSOFile(;
    version=v"3",
    julia=VERSION,
    format=:julia_serialize,
    compression=:gzip,
    image=_image(),
    kwargs...
)
    return JLSOFile(
        Dict(kwargs);
        version=version,
        julia=julia,
        format=format,
        compression=compression,
        image=image,
    )
end


JLSOFile(data::Pair{Symbol}...; kwargs...) = JLSOFile(Dict(data); kwargs...)

function Base.show(io::IO, jlso::JLSOFile)
    variables = join(names(jlso), ", ")
    kwargs = join(
        [
            "version=\"$(jlso.version)\"",
            "julia=\"$(jlso.julia)\"",
            "format=:$(jlso.format)",
            "compression=:$(jlso.compression)",
            "image=\"$(jlso.image)\"",
        ],
        ", "
    )

    print(io, "JLSOFile([$variables]; $kwargs)")
end

function Base.:(==)(a::JLSOFile, b::JLSOFile)
    return (
        a.version == b.version &&
        a.julia == b.julia &&
        a.image == b.image &&
        a.manifest == b.manifest &&
        a.format == b.format &&
        a.compression == b.compression &&
        a.objects == b.objects
    )
end

Base.names(jlso::JLSOFile) = collect(keys(jlso.objects))
