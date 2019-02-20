"""
A julia serialized object (JLSO) file format for storing checkpoint data.

# Structure

The .jlso files are BSON files containing the dictionaries with a specific schema.
NOTE: The raw dictionary should be loadable by any BSON library even if serialized objects
themselves aren't reconstructable.

Example)
```
Dict(
    "metadata" => Dict(
        "version" => v"1.0",
        "julia" => v"0.6.4",
        "format" => :bson,  # Could also be :serialize
        "image" => "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/myrepository:latest"
        "pkgs" => Dict(
            "AxisArrays" => v"0.2.1",
            ...
        )
    ),
    "objects" => Dict(
        "var1" => [0x35, 0x10, 0x01, 0x04, 0x44],
        "var2" => [...],
    ),
)
```
WARNING: The serialized objects are stored using julia's builtin serialization format which
is not intended for long term storage. As a result, we're storing the serialized object data
in a json file which should also be able to load the docker image and versioninfo to allow
reconstruction.
"""
module JLSO

using BSON
using Serialization
using Memento
using Pkg

export JLSOFile

const LOGGER = getlogger(@__MODULE__)
const VALID_VERSIONS = (v"1.0", v"2.0")

# Cache of the versioninfo and image, so we don't compute these every time.
const _CACHE = Dict(
    :PKGS => Dict{String, VersionNumber}(),
    :IMAGE => "",
)

__init__() = Memento.register(LOGGER)

struct JLSOFile
    version::VersionNumber
    julia::VersionNumber
    format::Symbol
    image::String
    pkgs::Dict{String, VersionNumber}
    objects::Dict{String, Vector{UInt8}}
end

"""
    JLSOFile(data; image="", julia=$VERSION, version=v"1.0, format=:serialize)

Stores the information needed to write a .jlso file.

# Arguments

- `data` - The objects to be stored in the file.

# Keywords

- `image=""` - The docker image URI that was used to generate the file
- `julia=$VERSION` - The julia version used to write the file
- `version=v"1.0"` - The file schema version
- `format=:serialize` - The format to use for serializing individual objects. While `:bson` is
    recommended for longer term object storage, `:serialize` tends to be the faster choice
    for adhoc serialization.
"""
function JLSOFile(
    data::Dict{String, <:Any};
    version=v"1.0",
    julia=VERSION,
    format=:serialize,
    image=_image(),
)
    _versioncheck(version)

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

function Base.write(io::IO, jlso::JLSOFile)
    bson(
        io,
        Dict(
            "metadata" => Dict(
                "version" => jlso.version,
                "julia" => jlso.julia,
                "format" => jlso.format,
                "image" => jlso.image,
                "pkgs" => jlso.pkgs,
            ),
            "objects" => jlso.objects,
        )
    )
end

function Base.read(io::IO, ::Type{JLSOFile})
    d = BSON.load(io)
    return JLSOFile(
        d["metadata"]["version"],
        d["metadata"]["julia"],
        d["metadata"]["format"],
        d["metadata"]["image"],
        d["metadata"]["pkgs"],
        d["objects"],
    )
end

Base.names(jlso::JLSOFile) = collect(keys(jlso.objects))

# TODO: Include a more detail summary method for displaying version information.

"""
    getindex(jlso, name)

Returns the deserialized object with the specified name.
"""
function Base.getindex(jlso::JLSOFile, name::String)
    try
        if jlso.format === :bson
            BSON.load(IOBuffer(jlso.objects[name]))[name]
        elseif jlso.format === :serialize
            deserialize(IOBuffer(jlso.objects[name]))
        else
            error(LOGGER, ArgumentError("Unsupported format $(jlso.format)"))
        end
    catch e
        warn(LOGGER, e)
        return jlso.objects[name]
    end
end

"""
    setindex!(jlso, value, name)

Adds the object to the file and serializes it.
"""
function Base.setindex!(jlso::JLSOFile, value, name::String)
    io = IOBuffer()

    if jlso.format === :bson
        bson(io, Dict(name => value))
    elseif jlso.format === :serialize
        serialize(io, value)
    else
        error(LOGGER, ArgumentError("Unsupported format $(jlso.format)"))
    end

    jlso.objects[name] = take!(io)
end

"""
    save(io, data)
    save(path, data)

Creates a JLSOFile with the specified data and kwargs and writes it back to the io.
"""
save(io::IO, data; kwargs...) = write(io, JLSOFile(data; kwargs...))
save(io::IO, data::Pair...; kwargs...) = save(io, Dict(data...); kwargs...)
save(path::String, args...; kwargs...) = open(io -> save(io, args...; kwargs...), path, "w")

"""
    load(io, objects...) -> Dict{String, Any}
    load(path, objects...) -> Dict{String, Any}

Load the JLSOFile from the io and deserialize the specified objects.
If no object names are specified then all objects in the file are returned.
"""
load(path::String, args...) = open(io -> load(io, args...), path)
function load(io::IO, objects::String...)
    jlso = read(io, JLSOFile)
    objects = isempty(objects) ? names(jlso) : objects
    result = Dict{String, Any}()

    for o in objects
        result[o] = jlso[o]
    end

    return result
end



#######################################
# Functions for lazily evaluating the #
# VERSIONINFO and IMAGE at runtime    #
#######################################
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

function _versioncheck(version::VersionNumber)
    supported = first(VALID_VERSIONS) <= version < last(VALID_VERSIONS)
    supported || error(LOGGER, ArgumentError(
        string(
            "Unsupported version ($version). ",
            "Expected a value between ($VALID_VERSIONS)."
        )
    ))
end

end  # module
