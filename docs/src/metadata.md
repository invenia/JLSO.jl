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
In the future, we may add some tooling to make it easier to view and compare these dictionaries, but it's currently unclear if that should live here or in Pkg.jl.
