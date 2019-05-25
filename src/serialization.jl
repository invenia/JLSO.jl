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
    julia_serialize = (
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
    gzip = (
        compress = GzipCompressorStream,
        decompress = GzipDecompressorStream,
    ),
    gzip_fastest = (
        compress = io -> GzipCompressorStream(io; level=1),
        decompress = GzipDecompressorStream,
    ),
    gzip_smallest = (
        compress = io -> GzipCompressorStream(io; level=9),
        decompress = GzipDecompressorStream,
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
    formatter(jlso.format).serialize!(compressing_buffer, value)

    # need to close buffer so any compression can write end of body stuffs.
    close(compressing_buffer)
    jlso.objects[name] = buffer.data  # can't use take! as stream is now closed
end
