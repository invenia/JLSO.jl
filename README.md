# JLSO

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/JLSO.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/JLSO.jl/dev)
[![Build Status](https://github.com/invenia/JLSO.jl/workflows/CI/badge.svg)](https://github.com/invenia/JLSO.jl/actions)
[![Codecov](https://codecov.io/gh/invenia/JLSO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/JLSO.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![DOI](https://zenodo.org/badge/170755855.svg)](https://zenodo.org/badge/latestdoi/170755855)

JLSO is a storage container for serialized Julia objects.
Think of it less as a serialization format and more of a container for arbitrarily serialized objects and metadata.
The modular structure of the JLSO container files allows users to balance their specific performance, flexibility and reliability requirements.

A JLSO file contains two primary components:

1. [BSON](https://bsonspec.org/spec.html) formatted metadata about the host operating system and environment
2. An arbitrary collection of serialized objects

While the metadata is specific to the JLSO file format, various serializers and compressors can be employed when saving objects.
The serializer needs to determine how to turn a Julia object into a stream (`Vector{UInt8}`), while the compressor needs to choose how to convert one stream of `UInt8`s into a smaller one or the reverse.
Depending on the configuration metadata, objects may be stored as [BSON sub-documents](https://bsonspec.org/spec.html) or [Julia serialized](https://docs.julialang.org/en/v1/stdlib/Serialization/) types, using various compression methods.
JLSO currently defaults to [Julia serialization](https://docs.julialang.org/en/v1/stdlib/Serialization/) with [`gzip`](https://github.com/JuliaIO/CodecZlib.jl).

Currently, JLSO files store the following metadata:

- JLSO version number
- Julia version number
- Serialization format (e.g., "julia_serialize", "bson")
- Compression method like "gzip"
- A docker image URI
- Project.toml
- Manifest.toml (possibly compressed)

This information makes it possible to reconstruct the original environment necessary to deserialize the objects if the internal serialization format has introduced breaking changes.
Since the metadata is formatted in language-agnostic BSON (no Julia extensions), all you need is a BSON reader.
Due to the size of this metadata, JLSO files are not ideal for storing many small files.

## Example

```jldoctest
julia> using JLSO, Dates

julia> JLSO.save("breakfast.jlso", :food => "☕️🥓🍳", :cost => 11.95, :time => Time(9, 0))

julia> loaded = JLSO.load("breakfast.jlso")
Dict{Symbol,Any} with 3 entries:
  :cost => 11.95
  :food => "☕️🥓🍳"
  :time => 09:00:00
```
