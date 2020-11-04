# JLSO

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/JLSO.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/JLSO.jl/dev)
[![Build Status](https://github.com/invenia/JLSO.jl/workflows/CI/badge.svg)](https://github.com/invenia/JLSO.jl/actions)
[![Codecov](https://codecov.io/gh/invenia/JLSO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/JLSO.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![DOI](https://zenodo.org/badge/170755855.svg)](https://zenodo.org/badge/latestdoi/170755855)


JLSO is a storage container for serialized Julia objects.
Think of it less as a serialization format but as a container,
that employs a serializer, and a compressor, handles all the other concerns including metadata and saving.
Such that the serializer just needs to determine how to turn a julia object into a stream`Vector{UInt8}`,
and the compressor just needs to determine how to turn one stream of `UInt8`s into a smaller one (and the reverse).


At the top-level it is a BSON file,
where it stores metadata about the system it was created on as well as a collection of objects (the actual data).
Depending on configuration, those objects may themselves be stored as BSON sub-documents,
or in the native Julia serialization format (default), under various levels of compression (`gzip` default).
It is fast and efficient to load just single objects out of a larger file that contains many objects.

The metadata includes the Julia version and the versions of all packages installed.
It is always store in plain BSON without julia specific extensions.
This means in the worst case you can install everything again and replicate your system.
(Extreme worst case scenario, using a BSON reader from another programming language).

Note: If the amount of data you have to store is very small, relative to the metadata about your environment, then JLSO is a pretty suboptimal format.


### Basic Example:

```
julia> using JLSO, Dates

julia> JLSO.save("breakfast.jlso", :food => "☕️🥓🍳", :cost => 11.95, :time => Time(9, 0))

julia> loaded = JLSO.load("breakfast.jlso")
Dict{Symbol,Any} with 3 entries:
  :cost => 11.95
  :time => 09:00:00
  :food => "☕️🥓🍳"
```
