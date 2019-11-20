# This is the code that handles getting the JLSO file itself on to and off of the disk
# However, it does not describe how to serialize or deserialize the individual objects
# that is done lazily and the code for that is in serialization.jl

function Base.write(io::IO, jlso::JLSOFile)
    _versioncheck(jlso.version, WRITEABLE_VERSIONS)

    # Setup an IOBuffer for serializing the manifest
    project_toml = sprint(Pkg.TOML.print, jlso.project)
    # @show jlso.manifest
    manifest_toml = read(
        compress(jlso.compression, IOBuffer(sprint(Pkg.TOML.print, jlso.manifest)))
    )

    bson(
        io,
        # We declare the dict types to be more explicit about the output format.
        Dict{String, Dict}(
            "metadata" => Dict{String, Union{String, Vector{UInt8}}}(
                "version" => string(jlso.version),
                "julia" => string(jlso.julia),
                "format" => string(jlso.format),
                "compression" => string(jlso.compression),
                "image" => jlso.image,
                "project" => project_toml,
                "manifest" => manifest_toml,
            ),
            "objects" => Dict{String, Vector{UInt8}}(
                string(k) => v for (k, v) in jlso.objects
            ),
        )
    )
end

# `read`, unlike `load` does not deserialize any of the objects within the JLSO file,
# they will be `deserialized` when they are indexed out of the returned JSLOFile object.
function Base.read(io::IO, ::Type{JLSOFile})
    parsed = BSON.load(io)
    _versioncheck(parsed["metadata"]["version"], READABLE_VERSIONS)
    d = upgrade_jlso(parsed)
    compression = Symbol(d["metadata"]["compression"])

    # Try decompressing the manifest, otherwise just return a dict with the raw data
    manifest = try
        Pkg.TOML.parse(
            read(
                decompress(compression, IOBuffer(d["metadata"]["manifest"])),
                String
            )
        )
    catch e
        warn(LOGGER, e)
        Dict("raw" => d["metadata"]["manifest"])
    end

    return JLSOFile(
        VersionNumber(d["metadata"]["version"]),
        VersionNumber(d["metadata"]["julia"]),
        Symbol(d["metadata"]["format"]),
        compression,
        d["metadata"]["image"],
        Pkg.TOML.parse(d["metadata"]["project"]),
        manifest,
        Dict{Symbol, Vector{UInt8}}(Symbol(k) => v for (k, v) in d["objects"]),
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

Warning: This method will return `Dict{Symbol, Any}` in the next major release.
"""
load(path::String, args...) = open(io -> load(io, args...), path)
function load(io::IO, objects::String...)
    jlso = read(io, JLSOFile)
    objects = isempty(objects) ? names(jlso) : objects
    result = Dict{String, Any}()

    for o in objects
        # Note that calling getindex on the jlso triggers the deserialization of the object
        result[String(o)] = jlso[o]
    end

    return result
end
