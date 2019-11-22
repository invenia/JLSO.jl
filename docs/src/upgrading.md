# Upgrading

JLSO.jl will automatically upgrade older versions of the file format when you call `JLSO.load` or `read`.

```
julia> jlso = read("test/specimens/v1_bson.jlso", JLSOFile)
[info | JLSO]: Upgrading JLSO format from v1 to v2
[info | JLSO]: Upgrading JLSO format from v2 to v3
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `git@github.com:JuliaRegistries/General.git`
  Updating registry at `~/.julia/registries/Invenia`
  Updating git-repo `git@gitlab.invenia.ca:invenia/PackageRegistry.git`
 Resolving package versions...
  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmphxMa6g/Project.toml`
  [39de3d68] + AxisArrays v0.3.0
  [fbb218c0] + BSON v0.2.3
  [b99e7846] + BinaryProvider v0.5.4
  [34da2185] + Compat v2.1.0
  [a93c6f00] + DataFrames v0.18.2
  [31c24e10] + Distributions v0.20.0
  [8f5d6c58] + EzXML v0.9.1
  [9da8a3cd] + JLSO v1.0.0
  [f28f55f0] + Memento v0.12.1
  [78c3b35d] + Mocking v0.5.7
  [f269a46b] + TimeZones v0.9.1
  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmphxMa6g/Manifest.toml`
  [7d9fca2a] + Arpack v0.3.1
  [39de3d68] + AxisArrays v0.3.0
  [fbb218c0] + BSON v0.2.3
  ...
[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.
JLSOFile([ZonedDateTime, DataFrame, Vector, DateTime, String, Matrix, Distribution]; version="3.0.0", julia="1.1.0", format=:bson, compression=:none, image="")
```

Upgrading to v3 requires generating a new manifest and project fields from the legacy `pkgs` field (as seen above) which can be slow and may require manual intervention to address package name collisions across registries.
`JLSO.upgrade` can be used to mitigate these issues.

To upgrade a single file:

```
julia> JLSO.upgrade("test/specimens/v1_bson.jlso", "v3_bson.jlso")
[info | JLSO]: Upgrading test/specimens/v1_bson.jlso -> v3_bson.jlso
[info | JLSO]: Upgrading JLSO format from v1 to v2
[info | JLSO]: Upgrading JLSO format from v2 to v3
 Resolving package versions...
  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmpTxpaLh/Project.toml`
  [39de3d68] + AxisArrays v0.3.0
  [fbb218c0] + BSON v0.2.3
  [b99e7846] + BinaryProvider v0.5.4
  [34da2185] + Compat v2.1.0
  [a93c6f00] + DataFrames v0.18.2
  [31c24e10] + Distributions v0.20.0
  [8f5d6c58] + EzXML v0.9.1
  [9da8a3cd] + JLSO v1.0.0
  [f28f55f0] + Memento v0.12.1
  [78c3b35d] + Mocking v0.5.7
  [f269a46b] + TimeZones v0.9.1
  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmpTxpaLh/Manifest.toml`
  [7d9fca2a] + Arpack v0.3.1
  [39de3d68] + AxisArrays v0.3.0
  [fbb218c0] + BSON v0.2.3
  ...
[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.
```

To batch upgrade files created with the same environment:

```
julia> filenames = ["v1_bson.jlso", "v1_serialize.jlso"]
2-element Array{String,1}:
 "v1_bson.jlso"
 "v1_serialize.jlso"

julia> JLSO.upgrade(joinpath.("test/specimens", filenames), filenames)
[info | JLSO]: Upgrading JLSO format from v1 to v2
[info | JLSO]: Upgrading JLSO format from v2 to v3
 Resolving package versions...
  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmptUsSQV/Project.toml`
  [39de3d68] + AxisArrays v0.3.0
  [fbb218c0] + BSON v0.2.3
  [b99e7846] + BinaryProvider v0.5.4
  [34da2185] + Compat v2.1.0
  [a93c6f00] + DataFrames v0.18.2
  [31c24e10] + Distributions v0.20.0
  [8f5d6c58] + EzXML v0.9.1
  [9da8a3cd] + JLSO v1.0.0
  [f28f55f0] + Memento v0.12.1
  [78c3b35d] + Mocking v0.5.7
  [f269a46b] + TimeZones v0.9.1
  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmptUsSQV/Manifest.toml`
  [7d9fca2a] + Arpack v0.3.1
  [39de3d68] + AxisArrays v0.3.0
  [fbb218c0] + BSON v0.2.3
  ...
[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.
[info | JLSO]: Upgrading test/specimens/v1_serialize.jlso -> v1_serialize.jlso
[info | JLSO]: Upgrading JLSO format from v1 to v2
[info | JLSO]: Upgrading JLSO format from v2 to v3
 Resolving package versions...
[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.

```

In the above case, the project and manifest is only generated for the first file and reused for all subsequent files.
