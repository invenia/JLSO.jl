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
        "project" =>
            \"\"\"
            name = "JLSO"
            uuid = "9da8a3cd-07a3-59c0-a743-3fdc52c30d11"
            license = "MIT"
            authors = ["Invenia Technical Computing Corperation"]
            version = "1.1.1"

            [deps]
            BSON = "fbb218c0-5317-5bc6-957e-2ee96dd4b1f0"
            CodecZlib = "944b1d66-785c-5afd-91f1-9de20f533193"
            Memento = "f28f55f0-a522-5efc-85c2-fe41dfb9b2d9"
            Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
            Serialization = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

            [compat]
            Memento = "0.10, 0.11, 0.12"
            TimeZones = "0.9"
            julia = "0.7, 1.0"

            [extras]
            AxisArrays = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
            DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
            Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
            Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
            TimeZones = "f269a46b-ccf7-5d73-abea-4c690281aa53"

            [targets]
            test = ["AxisArrays", "DataFrames", "Distributions", "Test", "TimeZones"]
            \"\"\",
        "manifest" =>
            \"\"\"
            [[BSON]]
            git-tree-sha1 = "4c4fdd4d9935fdd820f3f2a5a33d179f5aaea71e"
            uuid = "fbb218c0-5317-5bc6-957e-2ee96dd4b1f0"
            version = "0.2.4"

            [[Base64]]
            uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

            [[BinaryProvider]]
            deps = ["Libdl", "Logging", "SHA"]
            git-tree-sha1 = "c7361ce8a2129f20b0e05a89f7070820cfed6648"
            uuid = "b99e7846-7c00-51b0-8f62-c81ae34c0232"
            version = "0.5.6"

            ...
            \"\"\",
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

# We need to import these cause of a deprecation on object index via strings.
import Base: getindex, setindex!

export JLSOFile

const READABLE_VERSIONS = semver_spec("1, 2, 3")
const WRITEABLE_VERSIONS = semver_spec("3")

const LOGGER = getlogger(@__MODULE__)
__init__() = Memento.register(LOGGER)

include("JLSOFile.jl")
include("deprecated.jl")
include("file_io.jl")
include("metadata.jl")
include("serialization.jl")

end  # module
