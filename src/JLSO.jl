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
        "format" => v"1.0",
        "image" => "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/myrepository:latest"
        "julia" => v"0.6.4",
        "sysinfo" => "Julia Version 0.6.4 ...",
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

using AWSCore
using AWSS3
using BSON
using Compat
using Memento
using Mocking

using Compat.Serialization

const LOGGER = getlogger(@__MODULE__)
const VALID_VERSIONS = (v"1.0", v"2.0")

# Cache of the versioninfo and image, so we don't compute these every time.
const _CACHE = Dict{Symbol, String}(
    :VERSIONINFO => "",
    :IMAGE => "",
)

__init__() = Memento.register(LOGGER)

struct JLSOFile
    format::VersionNumber
    image::String
    julia::VersionNumber
    sysinfo::String
    objects::Dict{String, Vector{UInt8}}
end

function JLSOFile(
    data::Dict{String, <:Any};
    image=_image(),
    julia=VERSION,
    sysinfo=_versioninfo(),
    format=v"1.0"
)
    _versioncheck(format)

    objects = map(data) do t
        varname, vardata = t
        io = IOBuffer()
        serialize(io, vardata)
        return varname => take!(io)
    end |> Dict

    return JLSOFile(format, image, julia, sysinfo, objects)
end

JLSOFile(data) = JLSOFile(Dict("data" => data))
JLSOFile(data::Pair...) = JLSOFile(Dict(data...))

function Base.:(==)(a::JLSOFile, b::JLSOFile)
    return (
        a.format == b.format &&
        a.julia == b.julia &&
        a.image == b.image &&
        a.sysinfo == b.sysinfo &&
        a.objects == b.objects
    )
end

function Base.write(io::IO, jlso::JLSOFile)
    bson(
        io,
        Dict(
            "metadata" => Dict(
                "format" => jlso.format,
                "image" => jlso.image,
                "julia" => jlso.julia,
                "sysinfo" => jlso.sysinfo,
            ),
            "objects" => jlso.objects,
        )
    )
end

function Base.read(io::IO, ::Type{JLSOFile})
    d = BSON.load(io)
    return JLSOFile(
        d["metadata"]["format"],
        d["metadata"]["image"],
        d["metadata"]["julia"],
        d["metadata"]["sysinfo"],
        d["objects"],
    )
end

function Base.getindex(jlso::JLSOFile, name::String)
    try
        return deserialize(IOBuffer(jlso.objects[name]))
    catch e
        warn(LOGGER, e)
        return jlso.objects[name]
    end
end

# save(io::IO, data) = write(io, JLSOFile(data))
# load(io::IO, data) = read(io, JLSOFile(data))

#######################################
# Functions for lazily evaluating the #
# VERSIONINFO and IMAGE at runtime    #
#######################################
function _versioninfo()
    if isempty(_CACHE[:VERSIONINFO])
        global _CACHE[:VERSIONINFO] = sprint(versioninfo, true)
    end

    return _CACHE[:VERSIONINFO]
end

function _image()
    if isempty(_CACHE[:IMAGE]) && haskey(ENV, "AWS_BATCH_JOB_ID")
        job_id = ENV["AWS_BATCH_JOB_ID"]
        response = @mock describe_jobs(Dict("jobs" => [job_id]))

        if length(response["jobs"]) > 0
            global _CACHE[:IMAGE] = first(response["jobs"])["container"]["image"]
        else
            warn(LOGGER, "No jobs found with id: $job_id.")
        end
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

end
