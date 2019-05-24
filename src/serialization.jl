# This is the code that hands the serialiation and deserialization of each object

const formatters = (
    # format = (
    #    deserialize! # IO -> value
    #    serialize! # IO, Value -> nothing
    #)
    bson = (
        deserialize! = first ∘ values ∘ BSON.load,
        serialize! = (io, value) -> bson(io, Dict("object" => value))
    ),
    julia_native = (
        deserialize! = Serialization.deserialize,
        serialize! = Serialization.serialize,
    )
)

function formatter(format)
    return get(formatters, format) do
        error(LOGGER, ArgumentError("Unsupported format $(format)"))
    end
end


const compressors = (
    none = (
        compress = identity,
        decompress = identity
    ),
)

function compressor(compression)
    return get(compressors, compression) do
        error(LOGGER, ArgumentError("Unsupported compression $(compression)"))
    end
end


"""
    getindex(jlso, name)

Returns the deserialized object with the specified name.
"""
function Base.getindex(jlso::JLSOFile, name::String)
    try
        buffer = IOBuffer(jlso.objects[name])
        decompressing_buffer = compressor(jlso.compression).decompress(buffer)
        return formatter(jlso.format).deserialize!(decompressing_buffer)
    catch e
        warn(LOGGER, e)
        return jlso.objects[name]
    end
end

"""
    setindex!(jlso, value, name)

Adds the object to the file and serializes it.
"""
function Base.setindex!(jlso::JLSOFile, value, name::String)
    buffer = IOBuffer()
    compressing_buffer = compressor(jlso.compression).compress(buffer)
    formatter(jlso.format).serialize!(buffer, value)

    jlso.objects[name] = take!(buffer)
end
