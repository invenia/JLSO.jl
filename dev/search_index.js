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
    "text": "(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Build Status) (Image: Codecov) (Image: Code Style: Blue)JLSO is a storage container for serialized Julia objects.   Think of it less as a serialization format but as a container, that employs a serializer, and a compressor, handles all the other concerns including metadata and saving. Such that the serializer just needs to determine how to turn a julia object into a streamVector{UInt8}, and the compressor just needs to determine how to turn one stream of UInt8s into a smaller one (and the reverse).At the top-level it is a BSON file, where it stores metadata about the system it was created on as well as a collection of objects (the actual data). Depending on configuration, those objects may themselves be stored as BSON sub-documents, or in the native Julia serialization format (default), under various levels of compression (gzip default). It is fast and efficient to load just single objects out of a larger file that contains many objects.The metadata includes the Julia version and the versions of all packages installed. It is always store in plain BSON without julia specific extensions. This means in the worst case you can install everything again and replicate your system. (Extreme worst case scenario, using a BSON reader from another programming language).Note: If the amount of data you have to store is very small, relative to the metadata about your environment, then JLSO is a pretty suboptimal format."
},

{
    "location": "#Basic-Example:-1",
    "page": "Home",
    "title": "Basic Example:",
    "category": "section",
    "text": "julia> using JLSO, Dates\n\njulia> JLSO.save(\"breakfast.jlso\", \"food\" => \"☕️🥓🍳\", \"cost\" => 11.95, \"time\" => Time(9, 0))\n\njulia> loaded = JLSO.load(\"breakfast.jlso\")\nDict{String,Any} with 3 entries:\n  \"cost\" => 11.95\n  \"time\" => 09:00:00\n  \"food\" => \"☕️🥓🍳\""
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
    "text": "load(io, objects...) -> Dict{Symbol, Any}\nload(path, objects...) -> Dict{Symbol, Any}\n\nLoad the JLSOFile from the io and deserialize the specified objects. If no object names are specified then all objects in the file are returned.\n\n\n\n\n\n"
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
