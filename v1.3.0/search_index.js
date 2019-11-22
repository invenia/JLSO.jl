var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#JLSO-1",
    "page": "Home",
    "title": "JLSO",
    "category": "section",
    "text": "(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Build Status) (Image: Codecov) (Image: Code Style: Blue)JLSO is a storage container for serialized Julia objects. Think of it less as a serialization format but as a container, that employs a serializer, and a compressor, handles all the other concerns including metadata and saving. Such that the serializer just needs to determine how to turn a julia object into a streamVector{UInt8}, and the compressor just needs to determine how to turn one stream of UInt8s into a smaller one (and the reverse).At the top-level it is a BSON file, where it stores metadata about the system it was created on as well as a collection of objects (the actual data). Depending on configuration, those objects may themselves be stored as BSON sub-documents, or in the native Julia serialization format (default), under various levels of compression (gzip default). It is fast and efficient to load just single objects out of a larger file that contains many objects.The metadata includes the Julia version and the versions of all packages installed. It is always store in plain BSON without julia specific extensions. This means in the worst case you can install everything again and replicate your system. (Extreme worst case scenario, using a BSON reader from another programming language).Note: If the amount of data you have to store is very small, relative to the metadata about your environment, then JLSO is a pretty suboptimal format."
},

{
    "location": "#Basic-Example:-1",
    "page": "Home",
    "title": "Basic Example:",
    "category": "section",
    "text": "julia> using JLSO, Dates\n\njulia> JLSO.save(\"breakfast.jlso\", \"food\" => \"☕️🥓🍳\", \"cost\" => 11.95, \"time\" => Time(9, 0))\n\njulia> loaded = JLSO.load(\"breakfast.jlso\")\nDict{String,Any} with 3 entries:\n  \"cost\" => 11.95\n  \"time\" => 09:00:00\n  \"food\" => \"☕️🥓🍳\""
},

{
    "location": "metadata/#",
    "page": "Metadata",
    "title": "Metadata",
    "category": "page",
    "text": ""
},

{
    "location": "metadata/#Metadata-1",
    "page": "Metadata",
    "title": "Metadata",
    "category": "section",
    "text": "Manually reading JLSO files can be helpful when addressing issues deserializing objects or to simply to help with reproducibility.julia> jlso = read(\"breakfast.jlso\", JLSOFile)\nJLSOFile([cost, food, time]; version=\"3.0.0\", julia=\"1.0.3\", format=:julia_serialize, compression=:gzip, image=\"\")Now we can manually access the serialized objects:julia> jlso.objects\nDict{Symbol,Array{UInt8,1}} with 3 entries:\n  :cost => UInt8[0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13  …  0x0e, 0x00, 0x8b, 0xea, 0xfc, 0xc1, 0x11, 0x00, 0x00, 0x00]\n  :food => UInt8[0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13  …  0x66, 0x00, 0x10, 0x8c, 0x21, 0xf6, 0x18, 0x00, 0x00, 0x00]\n  :time => UInt8[0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13  …  0x0c, 0x00, 0xa7, 0xc5, 0x38, 0x8c, 0x5b, 0x00, 0x00, 0x00]Or deserialize individual objects:julia> jlso[:food]\n\"☕️🥓🍳\"Maybe you need to figure out what the environment state was when you wrote the file?julia> jlso.project\nDict{String,Any} with 9 entries:\n  \"deps\"    => Dict{String,Any}(\"CodecZlib\"=>\"944b1d66-785c-5afd-91f1-9de20f533193\",\"Pkg\"=>\"44cfe95a-1eb2-52ea-b672-e2afdf69b78f\",\"Serialization\"=>\"9e88b42a-f829-5b0c-bbe9-9e923198166b\",\"BSON\"=>\"fbb218c0-5317…\n  \"name\"    => \"JLSO\"\n  ...\n\njulia> jlso.manifest\nDict{String,Any} with 39 entries:\n  \"Mocking\"            => Dict{String,Any}[Dict(\"git-tree-sha1\"=>\"bd2623f8b728af988d2afec53d611acb621f3bc4\",\"uuid\"=>\"78c3b35d-d492-501b-9361-3d52fe80e533\",\"version\"=>\"0.7.0\")]\n  \"Pkg\"                => Dict{String,Any}[Dict(\"deps\"=>[\"Dates\", \"LibGit2\", \"Markdown\", \"Printf\", \"REPL\", \"Random\", \"SHA\", \"UUIDs\"],\n  ...\nThese project and manifest fields are just the dictionary representations of the Project.toml and Manifest.toml files found in a Julia Pkg environment. In the future, we may add some tooling to make it easier to view and compare these dictionaries, but it\'s currently unclear if that should live here or in Pkg.jl."
},

{
    "location": "upgrading/#",
    "page": "Upgrading",
    "title": "Upgrading",
    "category": "page",
    "text": ""
},

{
    "location": "upgrading/#Upgrading-1",
    "page": "Upgrading",
    "title": "Upgrading",
    "category": "section",
    "text": "JLSO.jl will automatically upgrade older versions of the file format when you call JLSO.load or read.julia> jlso = read(\"test/specimens/v1_bson.jlso\", JLSOFile)\n[info | JLSO]: Upgrading JLSO format from v1 to v2\n[info | JLSO]: Upgrading JLSO format from v2 to v3\n  Updating registry at `~/.julia/registries/General`\n  Updating git-repo `git@github.com:JuliaRegistries/General.git`\n  Updating registry at `~/.julia/registries/Invenia`\n  Updating git-repo `git@gitlab.invenia.ca:invenia/PackageRegistry.git`\n Resolving package versions...\n  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmphxMa6g/Project.toml`\n  [39de3d68] + AxisArrays v0.3.0\n  [fbb218c0] + BSON v0.2.3\n  [b99e7846] + BinaryProvider v0.5.4\n  [34da2185] + Compat v2.1.0\n  [a93c6f00] + DataFrames v0.18.2\n  [31c24e10] + Distributions v0.20.0\n  [8f5d6c58] + EzXML v0.9.1\n  [9da8a3cd] + JLSO v1.0.0\n  [f28f55f0] + Memento v0.12.1\n  [78c3b35d] + Mocking v0.5.7\n  [f269a46b] + TimeZones v0.9.1\n  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmphxMa6g/Manifest.toml`\n  [7d9fca2a] + Arpack v0.3.1\n  [39de3d68] + AxisArrays v0.3.0\n  [fbb218c0] + BSON v0.2.3\n  ...\n[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.\nJLSOFile([ZonedDateTime, DataFrame, Vector, DateTime, String, Matrix, Distribution]; version=\"3.0.0\", julia=\"1.1.0\", format=:bson, compression=:none, image=\"\")Upgrading to v3 requires generating a new manifest and project fields from the legacy pkgs field (as seen above) which can be slow and may require manual intervention to address package name collisions across registries. JLSO.upgrade can be used to mitigate these issues.To upgrade a single file:julia> JLSO.upgrade(\"test/specimens/v1_bson.jlso\", \"v3_bson.jlso\")\n[info | JLSO]: Upgrading test/specimens/v1_bson.jlso -> v3_bson.jlso\n[info | JLSO]: Upgrading JLSO format from v1 to v2\n[info | JLSO]: Upgrading JLSO format from v2 to v3\n Resolving package versions...\n  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmpTxpaLh/Project.toml`\n  [39de3d68] + AxisArrays v0.3.0\n  [fbb218c0] + BSON v0.2.3\n  [b99e7846] + BinaryProvider v0.5.4\n  [34da2185] + Compat v2.1.0\n  [a93c6f00] + DataFrames v0.18.2\n  [31c24e10] + Distributions v0.20.0\n  [8f5d6c58] + EzXML v0.9.1\n  [9da8a3cd] + JLSO v1.0.0\n  [f28f55f0] + Memento v0.12.1\n  [78c3b35d] + Mocking v0.5.7\n  [f269a46b] + TimeZones v0.9.1\n  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmpTxpaLh/Manifest.toml`\n  [7d9fca2a] + Arpack v0.3.1\n  [39de3d68] + AxisArrays v0.3.0\n  [fbb218c0] + BSON v0.2.3\n  ...\n[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.To batch upgrade files created with the same environment:julia> filenames = [\"v1_bson.jlso\", \"v1_serialize.jlso\"]\n2-element Array{String,1}:\n \"v1_bson.jlso\"\n \"v1_serialize.jlso\"\n\njulia> JLSO.upgrade(joinpath.(\"test/specimens\", filenames), filenames)\n[info | JLSO]: Upgrading JLSO format from v1 to v2\n[info | JLSO]: Upgrading JLSO format from v2 to v3\n Resolving package versions...\n  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmptUsSQV/Project.toml`\n  [39de3d68] + AxisArrays v0.3.0\n  [fbb218c0] + BSON v0.2.3\n  [b99e7846] + BinaryProvider v0.5.4\n  [34da2185] + Compat v2.1.0\n  [a93c6f00] + DataFrames v0.18.2\n  [31c24e10] + Distributions v0.20.0\n  [8f5d6c58] + EzXML v0.9.1\n  [9da8a3cd] + JLSO v1.0.0\n  [f28f55f0] + Memento v0.12.1\n  [78c3b35d] + Mocking v0.5.7\n  [f269a46b] + TimeZones v0.9.1\n  Updating `/private/var/folders/h_/vkjv56410m7f75g9ffp46mf80000gp/T/tmptUsSQV/Manifest.toml`\n  [7d9fca2a] + Arpack v0.3.1\n  [39de3d68] + AxisArrays v0.3.0\n  [fbb218c0] + BSON v0.2.3\n  ...\n[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.\n[info | JLSO]: Upgrading test/specimens/v1_serialize.jlso -> v1_serialize.jlso\n[info | JLSO]: Upgrading JLSO format from v1 to v2\n[info | JLSO]: Upgrading JLSO format from v2 to v3\n Resolving package versions...\n[ Info: activating new environment at ~/repos/JLSO.jl/Project.toml.\nIn the above case, the project and manifest is only generated for the first file and reused for all subsequent files."
},

{
    "location": "api/#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api/#JLSO.JLSO",
    "page": "API",
    "title": "JLSO.JLSO",
    "category": "module",
    "text": "A julia serialized object (JLSO) file format for storing checkpoint data.\n\nStructure\n\nThe .jlso files are BSON files containing the dictionaries with a specific schema. NOTE: The raw dictionary should be loadable by any BSON library even if serialized objects themselves aren\'t reconstructable.\n\nExample)\n\nDict(\n    \"metadata\" => Dict(\n        \"version\" => v\"2.0\",\n        \"julia\" => v\"1.0.4\",\n        \"format\" => :bson,  # Could also be :julia_serialize\n        \"compression\" => :gzip_fastest, # could also be: :none, :gzip_smallest, or :gzip\n        \"image\" => \"xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/myrepository:latest\"\n        \"project\" => Dict{String, Any}(...),\n        \"manifest\" => Dict{String, Any}(...),\n    ),\n    \"objects\" => Dict(\n        \"var1\" => [0x35, 0x10, 0x01, 0x04, 0x44],\n        \"var2\" => [...],\n    ),\n)\n\nWARNING: Regardless of serialization format, the serialized objects can not be deserialized into structures with different fields, or if the types have been renamed or removed from the packages. Further, the :julia_serialize format is not intended for long term storage and is not portable across julia versions. As a result, we\'re storing the serialized object data in a json file which should also be able to load the docker image and versioninfo to allow reconstruction.\n\n\n\n\n\n"
},

{
    "location": "api/#JLSO.JLSOFile-Tuple{Dict{Symbol,#s30} where #s30}",
    "page": "API",
    "title": "JLSO.JLSOFile",
    "category": "method",
    "text": "JLSOFile(data; format=:julia_serialize, compression=:gzip, kwargs...)\n\nStores the information needed to write a .jlso file.\n\nArguments\n\ndata - The objects to be stored in the file.\n\nKeywords\n\nimage=\"\" - The docker image URI that was used to generate the file\njulia=1.0.5 - The julia version used to write the file\nversion=v\"2.0\" - The file schema version\nformat=:julia_serialize - The format to use for serializing individual objects. While :bson is   recommended for longer term object storage, :julia_serialize tends to be the faster choice   for adhoc serialization.\ncompression=:gzip, what form of compression to apply to the objects.   Use :none, to not compress. :gzipfastest for the fastest gzip compression,   :gzipsmallest for the most compact (but slowest), or :gzip for a generally good compromize.   Due to the time taken for disk IO, :none is not normally as fast as using some compression.\n\n\n\n\n\n"
},

{
    "location": "api/#Base.getindex-Tuple{JLSOFile,Symbol}",
    "page": "API",
    "title": "Base.getindex",
    "category": "method",
    "text": "getindex(jlso, name)\n\nReturns the deserialized object with the specified name.\n\n\n\n\n\n"
},

{
    "location": "api/#Base.setindex!-Tuple{JLSOFile,Any,Symbol}",
    "page": "API",
    "title": "Base.setindex!",
    "category": "method",
    "text": "setindex!(jlso, value, name)\n\nAdds the object to the file and serializes it.\n\n\n\n\n\n"
},

{
    "location": "api/#JLSO.load-Tuple{String,Vararg{Any,N} where N}",
    "page": "API",
    "title": "JLSO.load",
    "category": "method",
    "text": "load(io, objects...) -> Dict{String, Any}\nload(path, objects...) -> Dict{String, Any}\n\nLoad the JLSOFile from the io and deserialize the specified objects. If no object names are specified then all objects in the file are returned.\n\nWarning: This method will return Dict{Symbol, Any} in the next major release.\n\n\n\n\n\n"
},

{
    "location": "api/#JLSO.save-Tuple{IO,Any}",
    "page": "API",
    "title": "JLSO.save",
    "category": "method",
    "text": "save(io, data)\nsave(path, data)\n\nCreates a JLSOFile with the specified data and kwargs and writes it back to the io.\n\n\n\n\n\n"
},

{
    "location": "api/#JLSO.complete_compression-Tuple{Any}",
    "page": "API",
    "title": "JLSO.complete_compression",
    "category": "method",
    "text": "complete_compression(compressing_buffer)\n\nWrites any end of compression sequence to the compressing buffer; but does not close the underlying stream. The compressing_buffer itself should not be used after this operation\n\n\n\n\n\n"
},

{
    "location": "api/#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [JLSO]\nPublic = true\nPrivate = true\nPages = [\"JLSO.jl\", \"JLSOFile.jl\", \"metadata.jl\", \"file_io.jl\", \"serialization.jl\"]"
},

]}
