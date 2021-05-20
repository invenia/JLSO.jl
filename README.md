# JLSO

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/JLSO.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/JLSO.jl/dev)
[![Build Status](https://github.com/invenia/JLSO.jl/workflows/CI/badge.svg)](https://github.com/invenia/JLSO.jl/actions)
[![Codecov](https://codecov.io/gh/invenia/JLSO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/JLSO.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![DOI](https://zenodo.org/badge/170755855.svg)](https://zenodo.org/badge/latestdoi/170755855)


JLSO is a storage container for serialized Julia objects.  JLSO
is less of a serialization format and moreso a container which employs
a serializer, a compressor, and handles all other concerns
involving metadata and saving.  JLSOs serializer simply needs to
determine how to turn a Julia object into a stream
`Vector{UInt8}`, and the compressor simply needs to determine how
to turn one stream of `UInt8`s into a smaller one or the reverse.

In JLSO it's fast and efficient to load single objects out of a
larger file containing many objects.  Objects represent data. At
the top-level is a BSON file which stores metadata about the host
operating system environment as well as an arbitrary collection
of objects.  Depending on configuration metadata objects may be
stored as BSON sub-documents, or using native Julia serialization
format under various levels of compression. Serialization in
Julia currently defaults to `gzip`.

JLSO metadata stored in BSON without any Julia specific
extensions includes: the Julia version and the versions of all
packages installed.  Unfortunately this means one might
accidentally install everything again and replicate their
system. Even harder problems will arise when using a BSON reader
in another programming language.

Note that if the amount of data you have to store is small relative
to the metadata about your environment then JLSO is a suboptimal
format.

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
