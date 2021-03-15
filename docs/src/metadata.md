# Metadata

```@setup metadata-example
using JLSO, Dates
JLSO.save("breakfast.jlso", :food => "☕️🥓🍳", :cost => 11.95, :time => Time(9, 0))
```

Manually reading JLSO files can be helpful when addressing issues deserializing objects or to simply to help with reproducibility.

```@example metadata-example
using JLSO;

jlso = read("breakfast.jlso", JLSOFile)
```

Now we can manually access the serialized objects:
```@example metadata-example
jlso.objects
```

Or deserialize individual objects:
```@example metadata-example
jlso[:food]
```

Maybe you need to figure out what packages you had installed in the save environment?
```@example metadata-example
jlso.project
```

In extreme cases, you may need to inspect the full environment stack.
For example, having a struct changed in a dependency.
```@example metadata-example
jlso.manifest
```

These `project` and `manifest` fields are just the dictionary representations of the Project.toml and Manifest.toml files found in a Julia Pkg environment.
As such, we can also use `Pkg.activate` to construct and environment matching that used to write the file.
```@example metadata-example
dir = joinpath(dirname(dirname(pathof(JLSO))), "test", "specimens")
jlso = read(joinpath(dir, "v4_bson_none.jlso"), JLSOFile)
jlso[:DataFrame]
```

Unfortunately, we can't load some object in the current environment, so we might try to load the offending package only to find out it isn't part of our current environment.
```@example metadata-example
try using DataFrames catch e @warn e end
```

Okay, so we don't have DataFrames loaded and it isn't part of our current environment.
Rather than adding every possible package needed to deserialize the objects in the file, we can use the `Pkg.activate` do-block syntax to:

1. Initial the extact environment needed to deserialize our objects
2. Load our desired dependencies
3. Migrate our data to a more appropriate long term format

```@repl metadata-example
using JLSO, Pkg

# Now we can run our conversion logic in an isolated environment
mktempdir(pwd()) do d
    cd(d) do
        repopath = dirname(dirname(pathof(JLSO)))
        jlso = read(joinpath(repopath, "test", "specimens", "v4_bson_none.jlso"), JLSOFile)

        # Modify our Manifest to just use the latest release of JLSO
        delete!(jlso.manifest, "JLSO")

        Pkg.activate(jlso, d) do
            @eval Main begin
                using Pkg; Pkg.resolve(); Pkg.instantiate(; verbose=true)
                using DataFrames, JLSO
                describe($(jlso)[:DataFrame])
            end
        end
    end
end
```


NOTE:
- Comparing `project` and `manifest` dictionaries isn't ideal, but it's currently unclear if that should live here or in Pkg.jl.
- The `Pkg.activate` workflow could probably be replaced with a macro
