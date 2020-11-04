# Upgrading

JLSO.jl will automatically upgrade older versions of the file format when you call `JLSO.load` or `read`.

```@repl upgrade-example
using JLSO
dir = joinpath(dirname(dirname(pathof(JLSO))), "test", "specimens")
jlso = read(joinpath(dir, v1_bson.jlso"), JLSOFile)
```

Upgrading to v3 requires generating a new manifest and project fields from the legacy `pkgs` field (as seen above) which
can be slow and may require manual intervention to address package name collisions across registries.
`JLSO.upgrade` can be used to mitigate these issues.

To upgrade a single file:

```@repl upgrade-example
JLSO.upgrade(joinpath(dir, "v1_bson.jlso"), "v3_bson.jlso")
```

To batch upgrade files created with the same environment:

```@repl upgrade-example
filenames = ["v1_bson.jlso", "v1_serialize.jlso"]
JLSO.upgrade(joinpath.(dir, filenames), filenames)
```

In the above case, the project and manifest is only generated for the first file and reused for all subsequent files.
