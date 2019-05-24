struct JLSOFile
    version::VersionNumber
    julia::VersionNumber
    format::Symbol
    image::String
    pkgs::Dict{String, VersionNumber}
    objects::Dict{String, Vector{UInt8}}
end

"""
    JLSOFile(data; image="", julia=$VERSION, version=v"2.0, format=:julia_native)

Stores the information needed to write a .jlso file.

# Arguments

- `data` - The objects to be stored in the file.

# Keywords

- `image=""` - The docker image URI that was used to generate the file
- `julia=$VERSION` - The julia version used to write the file
- `version=v"2.0"` - The file schema version
- `format=:julia_native` - The format to use for serializing individual objects. While `:bson` is
    recommended for longer term object storage, `:julia_native` tends to be the faster choice
    for adhoc serialization.
"""
function JLSOFile(
    data::Dict{String, <:Any};
    version=v"2.0.0",
    julia=VERSION,
    format=:julia_native,
    image=_image(),
)
    if format == :serialize
        @warn "the format keyword `:serialize` has been renamed to `:julia_native`."
        format = :julia_native
    end

    _versioncheck(version, WRITEABLE_VERSIONS)
    objects = Dict{String, Vector{UInt8}}()
    jlso = JLSOFile(version, julia, format, image, _pkgs(), objects)

    for (key, val) in data
        jlso[key] = val
    end

    return jlso
end

JLSOFile(data; kwargs...) = JLSOFile(Dict("data" => data); kwargs...)
JLSOFile(data::Pair...; kwargs...) = JLSOFile(Dict(data...); kwargs...)

function Base.show(io::IO, jlso::JLSOFile)
    variables = join(names(jlso), ", ")
    kwargs = join(
        [
            "version=v\"$(jlso.version)\"",
            "julia=v\"$(jlso.julia)\"",
            "format=:$(jlso.format)",
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
        a.pkgs == b.pkgs &&
        a.format == b.format &&
        a.objects == b.objects
    )
end

Base.names(jlso::JLSOFile) = collect(keys(jlso.objects))

# TODO: Include a more detail summary method for displaying version information.
