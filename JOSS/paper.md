---
title: 'JLSO: Storing reproducible serialized objects in Julia'
tags:
  - julialang
  - data storage
  - reproducibility
authors:
  - name: Rory Finnegan
    orcid: 0000-0002-4603-077X
    affiliation: 1
  - name: Lyndon White
    orcid: 0000-0003-1386-1646
    affiliation: 2
affiliations:
 - name: Invenia Technical Computing
   index: 1
 - name: Invenia Labs
   index: 2
date: 24 August 2022
bibliography: paper.bib
---

# Summary

The complexity of scientific computing software has increased our need for efficient and reliable object storage methods.
The expanding list of file formats for serializing objects is evidence of this problem.
Best practices encourage us to explicitly serialize and parse our objects into standardized and reliable file formats (e.g., CSV, BSON, HDF5).
Unfortunately, this process is tedious and often error-prone, particularly for rapidly changing codebases and types.
For short term storage, non-standard and language-dependent formats (e.g., Julia serializer, Python pickles) provide a convenient way to save state, without requiring custom application logic.
These non-standard formats depend on the software stack's exact state during serialization, causing files to become stale and preventing restoration.
JLSO uses information about the save environment to ensure that these objects can be recovered regardless of the serialization format.

# Specification

The JLSO (Julia Serialized Object) format uses a language-independent BSON format to save environment metadata with serialized objects.
Metadata such as the Julia version and manifest provide a mechanism for debugging deserialization errors and allows for automatic reconstruction of the save state environment.
By default, JLSO uses the builtin Julia serialization stdlib for individual objects, but the extended BSON.jl format is also supported.

```
{
    "metadata" : {
        "julia" : "1.0.3",
        "format" : "julia_serialize",
        "project" : "name = \"JLSO\"\n...",
        "manifest" : [0x5b, 0x5b, 0x50 ... 0x30, 0x22, 0x0a],
        "image" : "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/myrepository:latest",
        "compression" : "none",
        "version" : "3.0.0",
    },
    "objects" : {
        "var1" : [0x37, 0x4a, 0x4c ... 0x12, 0x00, 0xdf],
        "var2" : [0x37, 0x4a, 0x4c ... 0xe0, 0xc5, 0x3f],
        ...
    ),
)
```

# Usage

The Julia language provides first-class support for package environments via Project.toml and Manifest.toml files, which provided an intuitive platform for building our prototype.
Let us use a simple example to demonstrate why this metadata is valuable.
Here we will load a JLSO file and try to reconstruct various objects.

```julia
julia> using Pkg, JLSO

julia> jlso = read("../test/specimens/v3_julia_serialize_none.jlso", JLSOFile)
JLSOFile([ZonedDateTime, DataFrame, Vector, DateTime, String, Matrix, Distribution]; version="3.0.0", julia="1.0.3", format=:julia_serialize, compression=:none, image="")

# Examples of different julia objects that can be serialized
julia> names(jlso)
7-element Array{Symbol,1}:
 :ZonedDateTime
 :DataFrame
 :Vector
 :DateTime
 :String
 :Matrix
 :Distribution

julia> jlso[:Matrix]
3×3 Array{Float64,2}:
 0.400348   0.892196   0.848164
 0.0183529  0.755449   0.397538
 0.870458   0.0441878  0.170899

julia> jlso[:String]
"Hello World!"

julia> jlso[:DateTime]
2018-01-28T00:00:00

julia> jlso[:Distribution];
[warn | JLSO]: KeyError: key Distributions [31c24e10-a181-5473-b8eb-7969acd0382f] not found

julia> using Distributions
ERROR: ArgumentError: Package Distributions not found in current path:
- Run `import Pkg; Pkg.add("Distributions")` to install the Distributions package.

Stacktrace:
 [1] require(::Module, ::Symbol) at ./loading.jl:893
```

We do not have Distributions.jl installed, and we also do not know which version of Distributions.jl we need to deserialize that object successfully.
Users can resolve these kinds of concerns by rebuilding the JLSO save environment directly from the REPL.

```julia
julia> using Pkg

julia> Pkg.activate(jlso, "./")
 Activating environment at `~/repos/invenia/JLSO.jl/JOSS/Project.toml`

# Now we can process data within this file using the environment used to save it.
julia> using Distributions

julia> jlso[:Distribution]
Normal{Float64}(μ=50.2, σ=4.3)
```

# Conclusion

JLSO.jl is a library for conveniently storing arbitrary Julia objects while maintaining restoration reliability.
While the concept of pairing save state metadata with serialized objects is not inherently specific to Julia, our implementation of JLSO.jl is.
Our package is currently being used to snapshot model state and datasets in software at Invenia and in registered packages like MLJ.jl.

# Acknowledgements

We are grateful for the 12 other contributors to the JLSO.jl GitHub repository, and the broader Julia Community for their support and feedback.

# References
