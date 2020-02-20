# This is the code that hands the serialiation and deserialization of each object

struct Formatter{S} end
deserialize(format::Symbol, io) = deserialize(Formatter{format}(), io)
serialize(format::Symbol, io, value) = serialize(Formatter{format}(), io, value)

deserialize(::Formatter{:bson}, io) = first(values(BSON.load(io)))
serialize(::Formatter{:bson}, io, value) = bson(io, Dict("object" => value))

deserialize(::Formatter{:julia_serialize}, io) = Serialization.deserialize(io)
serialize(::Formatter{:julia_serialize}, io, value) = Serialization.serialize(io, value)

struct Compressor{S} end
compress(compression::Symbol, io) = compress(Compressor{compression}(), io)
decompress(compression::Symbol, io) = decompress(Compressor{compression}(), io)

compress(::Compressor{:none}, io) = io
decompress(::Compressor{:none}, io) = io

compress(::Compressor{:gzip}, io) = GzipCompressorStream(io)
decompress(::Compressor{:gzip}, io) = GzipDecompressorStream(io)

compress(::Compressor{:gzip_fastest}, io) = GzipCompressorStream(io; level=1)
decompress(::Compressor{:gzip_fastest}, io) = GzipDecompressorStream(io)

compress(::Compressor{:gzip_smallest}, io) = GzipCompressorStream(io; level=9)
decompress(::Compressor{:gzip_smallest}, io) = GzipDecompressorStream(io)

"""
    complete_compression(compressing_buffer)
Writes any end of compression sequence to the compressing buffer;
but does not close the underlying stream.
The compressing_buffer itself should not be used after this operation
"""
complete_compression(::Any) = nothing
function complete_compression(compressing_buffer::CodecZlib.TranscodingStream)
    # need to close `compressing_buffer` so any compression can write end of body stuffs.
    # But can't use normal `close` without closing `buffer` as well
    # see https://github.com/bicycle1885/TranscodingStreams.jl/issues/85
    CodecZlib.TranscodingStreams.changemode!(compressing_buffer, :close)
end


"""
    getindex(jlso, name)

Returns the deserialized object with the specified name.
"""
function getindex(jlso::JLSOFile, name::Symbol)
    try
        buffer = IOBuffer(jlso.objects[name])
        decompressing_buffer = decompress(jlso.compression, buffer)
        return deserialize(jlso.format, decompressing_buffer)
    catch e
        warn(LOGGER, e)
        return jlso.objects[name]
    end
end

"""
    setindex!(jlso, value, name)

Adds the object to the file and serializes it.
"""
function setindex!(jlso::JLSOFile, value, name::Symbol)
    buffer = IOBuffer()
    compressing_buffer = compress(jlso.compression, buffer)
    serialize(jlso.format, compressing_buffer, value)
    complete_compression(compressing_buffer)
    result = take!(buffer)

    lock(jlso.lock)
    jlso.objects[name] = result
    unlock(jlso.lock)
end
