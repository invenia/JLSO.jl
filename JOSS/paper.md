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
 - name: Research Engineer, Invenia Technical Computing
   index: 1
 - name: Research Engineer, Invenia Labs
   index: 2
date: 24 August 2022
bibliography: paper.bib
---

# Summary

As scientific computing software grows increasingly complex, the need to efficiently and reliably store sophisticated program objects has become a growing need. The expanding list of file formats for serializing objects is evidence of this problem. Unfortunately, these file formats typically come with usability versus reliability tradeoffs.

Choosing serialization formats such as CSV, JSON, BSON, and HDF5 are prudent choices for long term storage because they are application and language agnostic. Projects that evolve beyond an initial language or library decision can still load old experimental data.
These formats often support a limited set of types, requiring applications to define and maintain serialization methods for their custom objects.

Using formats such as JLD (Julia Data), Python pickles or MAT files work best for convenient saving of arbitrary objects. Unfortunately, these formats are often highly coupled to the software dependencies (e.g., language version, software packages), which makes restoring the data more challenging as time passes and the software evolves.

JLSO.jl is a library for conveniently storing arbitrary Julia objects while maintaining restoration reliability. The JLSO (Julia Serialized Object) format stores metadata about the save environment alongside the arbitrarily serialized objects. This metadata includes the:

1. Julia release version
2. Object serialization and compression methods used
3. Package environment states, expressed via the Julia Project.toml and Manifest.toml files

Let's use a simple example to demonstrate why this metadata is valuable. The next few lines we'll load a JLSO files and try to load various objects.

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

As you can see, we do not have Distributions installed and we also don't know which version of Distributions.jl we need to successfully deserialize that object. As of version 1.2.0, users can resolve these kinds of concerns by rebuilding the package environment used to save a JLSO file directly from the REPL.

```julia
julia> using Pkg

julia> Pkg.activate(jlso, "./")
 Activating environment at `~/repos/invenia/JLSO.jl/JOSS/Project.toml`

# Now we can process data within this file using the environment used to save it.
julia> using Distributions

julia> jlso[:Distribution]
Normal{Float64}(μ=50.2, σ=4.3)
```

While the metadata in JLSO files caters towards Julia users, the format itself is mostly language agnostic. A variety of internal object serialization formats can be used, and the metadata itself is saved as a BSON documented. The Julia language provides first-class support for package environments via Project.toml and Manifest.toml files, which provided an intuitive platform for building our prototype.

Machine learning and simulation software such as MLJ.jl use JLSO to snapshot model state and datasets. Similarly, JLSO is used extensively at Invenia Technical Computing for snapshotting models and our intermediate datasets.

# Acknowledgements

We are grateful for the 12 other contributors to the JLSO.jl github repository, and the broader Julia Community for their support and feedback.

# Citations
