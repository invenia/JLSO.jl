# This is the code that handles getting the JLSO file itself on to and off of the disk
# However, it does not describe how to serialize or deserialize the individual objects
# that is done lazily and the code for that is in serialization.jl

function Base.write(io::IO, jlso::JLSOFile)
    bson(
        io,
        Dict(
            "metadata" => Dict(
                "version" => jlso.version,
                "julia" => jlso.julia,
                "format" => jlso.format,
                "image" => jlso.image,
                "pkgs" => jlso.pkgs,
            ),
            "objects" => jlso.objects,
        )
    )
end

function Base.read(io::IO, ::Type{JLSOFile})
    d = BSON.load(io)
    return JLSOFile(
        d["metadata"]["version"],
        d["metadata"]["julia"],
        d["metadata"]["format"],
        d["metadata"]["image"],
        d["metadata"]["pkgs"],
        d["objects"],
    )
end

"""
    save(io, data)
    save(path, data)

Creates a JLSOFile with the specified data and kwargs and writes it back to the io.
"""
save(io::IO, data; kwargs...) = write(io, JLSOFile(data; kwargs...))
save(io::IO, data::Pair...; kwargs...) = save(io, Dict(data...); kwargs...)
save(path::String, args...; kwargs...) = open(io -> save(io, args...; kwargs...), path, "w")

"""
    load(io, objects...) -> Dict{String, Any}
    load(path, objects...) -> Dict{String, Any}

Load the JLSOFile from the io and deserialize the specified objects.
If no object names are specified then all objects in the file are returned.
"""
load(path::String, args...) = open(io -> load(io, args...), path)
function load(io::IO, objects::String...)
    jlso = read(io, JLSOFile)
    objects = isempty(objects) ? names(jlso) : objects
    result = Dict{String, Any}()

    for o in objects
        # Note that calling getindex on the jlso triggers the deserialization of the object
        result[o] = jlso[o]
    end

    return result
end
