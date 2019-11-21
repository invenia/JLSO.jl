# Metadata

Manually reading JLSO files can be helpful when addressing issues deserializing objects or to simply to help with reproducibility.

```
julia> jlso = read("breakfast.jlso", JLSOFile)
JLSOFile([cost, food, time]; version="3.0.0", julia="1.0.3", format=:julia_serialize, compression=:gzip, image="")
```

Now we can manually access the serialized objects:
```
julia> jlso.objects
Dict{Symbol,Array{UInt8,1}} with 3 entries:
  :cost => UInt8[0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13  …  0x0e, 0x00, 0x8b, 0xea, 0xfc, 0xc1, 0x11, 0x00, 0x00, 0x00]
  :food => UInt8[0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13  …  0x66, 0x00, 0x10, 0x8c, 0x21, 0xf6, 0x18, 0x00, 0x00, 0x00]
  :time => UInt8[0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13  …  0x0c, 0x00, 0xa7, 0xc5, 0x38, 0x8c, 0x5b, 0x00, 0x00, 0x00]
```

Or deserialize individual objects:
```
julia> jlso[:food]
"☕️🥓🍳"
```

Maybe you need to figure out what the environment state was when you wrote the file?
```
julia> jlso.project
Dict{String,Any} with 9 entries:
  "deps"    => Dict{String,Any}("CodecZlib"=>"944b1d66-785c-5afd-91f1-9de20f533193","Pkg"=>"44cfe95a-1eb2-52ea-b672-e2afdf69b78f","Serialization"=>"9e88b42a-f829-5b0c-bbe9-9e923198166b","BSON"=>"fbb218c0-5317…
  "name"    => "JLSO"
  ...

julia> jlso.manifest
Dict{String,Any} with 39 entries:
  "Mocking"            => Dict{String,Any}[Dict("git-tree-sha1"=>"bd2623f8b728af988d2afec53d611acb621f3bc4","uuid"=>"78c3b35d-d492-501b-9361-3d52fe80e533","version"=>"0.7.0")]
  "Pkg"                => Dict{String,Any}[Dict("deps"=>["Dates", "LibGit2", "Markdown", "Printf", "REPL", "Random", "SHA", "UUIDs"],
  ...

```

These `project` and `manifest` fields are just the dictionary representations of the Project.toml and Manifest.toml files found in a Julia Pkg environment.
In the future, we may add some tooling to make it easier to view and compare these dictionaries, but it's currently unclear if that should live here or in Pkg.jl.
