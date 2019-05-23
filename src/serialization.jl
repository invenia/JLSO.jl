# This is the code that hands the serialiation and deserialization of each object

"""
    getindex(jlso, name)

Returns the deserialized object with the specified name.
"""
function Base.getindex(jlso::JLSOFile, name::String)
    try
        if jlso.format === :bson
            BSON.load(IOBuffer(jlso.objects[name]))[name]
        elseif jlso.format === :serialize
            deserialize(IOBuffer(jlso.objects[name]))
        else
            error(LOGGER, ArgumentError("Unsupported format $(jlso.format)"))
        end
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
    io = IOBuffer()

    if jlso.format === :bson
        bson(io, Dict(name => value))
    elseif jlso.format === :serialize
        serialize(io, value)
    else
        error(LOGGER, ArgumentError("Unsupported format $(jlso.format)"))
    end

    jlso.objects[name] = take!(io)
end
