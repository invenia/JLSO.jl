# Metadata

Manually reading JLSO files can be helpful when addressing issues deserializing objects or to simply to help with reproducibility.

```@repl metadata-example
using JLSO
jlso = read("breakfast.jlso", JLSOFile)
```

Now we can manually access the serialized objects:
```@repl metadata-example
jlso.objects
```

Or deserialize individual objects:
```@repl metadata-example
jlso[:food]
```

Maybe you need to figure out what the environment state was when you wrote the file?
```@repl metadata-example
jlso.project
jlso.manifest
```

These `project` and `manifest` fields are just the dictionary representations of the Project.toml and Manifest.toml files found in a Julia Pkg environment.
As such, we can also use `Pkg.activate` to construct and environment matching that used to write the file.
```
julia> using JLSO, Pkg

julia> dir = joinpath(dirname(dirname(pathof(JLSO))), "test", "specimens")
"/Users/rory/repos/invenia/JLSO.jl/test/specimens"

julia> jlso = read(joinpath(dir, "v4_bson_none.jlso"), JLSOFile)
JLSOFile([ZonedDateTime, DataFrame, Vector, DateTime, String, Matrix, Distribution]; version="4.0.0", julia="1.0.5", format=:bson, compression=:none, image="")

julia> # Can't load some object in the current environment
       jlso[:DataFrame]
[warn | JLSO]: UndefVarError: DataFrames not defined
1355-element Array{UInt8,1}:
 0x4b
 0x05
 0x00
 0x00
 0x02
 0x74
 0x61
 0x67
 0x00
 0x07
 0x00
 0x00
 0x00
 0x73
 0x74
 0x72
 0x75
 0x63
 0x74
 0x00
 0x03
 0x74
 0x79
 0x70
 0x65
 0x00
 0x00
 0x01
 0x00
 0x00
 0x02
 0x74
 0x61
 0x67
 0x00
 0x09
 0x00
 0x00
 0x00
 0x64
 0x61
 0x74
 0x61
    ⋮
 0x33
 0x00
 0x21
 0x00
 0x00
 0x00
 0x02
 0x74
 0x61
 0x67
 0x00
 0x07
 0x00
 0x00
 0x00
 0x73
 0x79
 0x6d
 0x62
 0x6f
 0x6c
 0x00
 0x02
 0x6e
 0x61
 0x6d
 0x65
 0x00
 0x02
 0x00
 0x00
 0x00
 0x64
 0x00
 0x00
 0x00
 0x00
 0x00
 0x00
 0x00
 0x00
 0x00
 0x00

julia> using DataFrames
ERROR: ArgumentError: Package DataFrames not found in current path:
- Run `import Pkg; Pkg.add("DataFrames")` to install the DataFrames package.

Stacktrace:
 [1] require(::Module, ::Symbol) at ./loading.jl:893

julia> # Specify a non-temp directory as the second argument if you want to reuse this environment across sessions.
       Pkg.activate(jlso)
 Activating environment at `/var/folders/vz/zx_0gsp9291dhv049t_nx37r0000gn/T/Project.toml`

julia> # Load our object and perhaps inspect some properties about it
       # Could also choose export it to a more transparent format
       using DataFrames

julia> describe(jlso[:DataFrame])
4×8 DataFrame
│ Row │ variable │ mean     │ min      │ median   │ max      │ nunique │ nmissing │ eltype   │
│     │ Symbol   │ Union…   │ Any      │ Union…   │ Any      │ Union…  │ Union…   │ DataType │
├─────┼──────────┼──────────┼──────────┼──────────┼──────────┼─────────┼──────────┼──────────┤
│ 1   │ a        │ 3.0      │ 1        │ 3.0      │ 5        │         │          │ Int64    │
│ 2   │ b        │ 0.772432 │ 0.512452 │ 0.863122 │ 0.907903 │         │          │ Float64  │
│ 3   │ c        │          │ a        │          │ e        │ 5       │ 0        │ Any      │
│ 4   │ d        │ 0.6      │ 0        │ 1.0      │ 1        │         │          │ Bool     │
```

In the future, we may add some tooling to make it easier to view and compare these dictionaries, but it's currently unclear if that should live here or in Pkg.jl.
