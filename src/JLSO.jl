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
        "version" => v"2.0",
        "julia" => v"1.0.4",
        "format" => :bson,  # Could also be :julia_serialize
        "compression" => :gzip_fastest, # could also be: :none, :gzip_smallest, or :gzip
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
WARNING: Regardless of serialization `format`, the serialized objects can not be deserialized
into structures with different fields, or if the types have been renamed or removed from the
packages.
Further, the `:julia_serialize` format is not intended for long term storage and is not
portable across julia versions. As a result, we're storing the serialized object data
in a json file which should also be able to load the docker image and versioninfo to allow
reconstruction.
"""
module JLSO

using BSON
using CodecZlib
using Serialization
using Memento
using Pkg: Pkg
using Pkg.Types: semver_spec

export JLSOFile

const READABLE_VERSIONS = semver_spec("1, 2")
const WRITEABLE_VERSIONS = semver_spec("2")

const LOGGER = getlogger(@__MODULE__)
__init__() = Memento.register(LOGGER)

include("JLSOFile.jl")
include("file_io.jl")
include("metadata.jl")
include("serialization.jl")

end  # module
