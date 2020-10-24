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

    # We declare the dict types to be more explicit about the output format.
    metadata = Dict{String, Union{String, Vector{UInt8}}}(
        "version" => string(jlso.version),
        "julia" => string(jlso.julia),
        "format" => string(jlso.format),
        "compression" => string(jlso.compression),
        "image" => jlso.image,
        "project" => project_toml,
        "manifest" => manifest_toml,
    )

    if jlso.version < v"4"
        BSON.bson(
            io,
            Dict{String, Dict}(
                "metadata" => metadata,
                "objects" => Dict{String, Vector{UInt8}}(
                    string(k) => v for (k, v) in jlso.objects
                ),
            )
        )
    else
        # Order is implied by the position in the names and lengths arrays
        # NOTE: We intentionally use a hypthen in the object names and nbytes to make it
        # harder to accidentally accessing them outside of the BSON context
        BSON.bson(
            io,
            Dict{String, Union{Dict, Vector}}(
                "metadata" => metadata,
                "object-names" => string.(keys(jlso.objects)),
                "object-nbytes" => [Int64(length(v)) for v in values(jlso.objects)]
            )
        )

        # Now write our raw data bytes to the end of the IO
        write(io, vcat(values(jlso.objects)...))
    end
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
        _extract_objects(io, d),
        ReentrantLock()
    )
end

"""
    save(io, data)
    save(path, data)

Creates a JLSOFile with the specified data and kwargs and writes it back to the io.
"""
save(io::IO, data; kwargs...) = write(io, JLSOFile(data; kwargs...))
save(io::IO, data::Pair...; kwargs...) = save(io, Dict(data...); kwargs...)
function save(path::Union{AbstractPath, AbstractString}, args...; kwargs...)
    return open(io -> save(io, args...; kwargs...), path, "w")
end

"""
    load(io, objects...) -> Dict{Symbol, Any}
    load(path, objects...) -> Dict{Symbol, Any}

Load the JLSOFile from the io and deserialize the specified objects.
If no object names are specified then all objects in the file are returned.
"""
load(path::Union{AbstractPath, AbstractString}, args...) = open(io -> load(io, args...), path)
function load(io::IO, objects::Symbol...)
    jlso = read(io, JLSOFile)
    objects = isempty(objects) ? names(jlso) : objects
    result = Dict{Symbol, Any}()

    @sync for o in objects
        @spawn begin
            # Note that calling getindex on the jlso triggers the deserialization of the object
            deserialized = jlso[o]
            lock(jlso.lock) do
                result[o] = deserialized
            end
        end
    end

    return result
end

# FileIO Interface
fileio_save(f, args...; kwargs...) = save(f.filename, args...; kwargs...)
fileio_load(f, args...) = load(f.filename, args...)

# Objects were initialially saved inline with the BSON document prior to v4
# To support larger objects/files we started writing objects to the end of file and only save
# names and sizes to the objects dict in the bson doc.
# Since our ideal structure is one dict with object bytes we don't upgrade, but rather
# extract both formats.
function _extract_objects(io::IO, d)
    if VersionNumber(d["metadata"]["version"]) < v"4"
        return Dict{Symbol, Vector{UInt8}}(Symbol(k) => v for (k, v) in d["objects"])
    else
        objects = Dict{Symbol, Vector{UInt8}}()

        for (k, nb) in zip(d["object-names"], d["object-nbytes"])
            bytes = read(io, nb)
            if length(bytes) < nb
                throw(ArgumentError("Failed to read all $nb bytes for object $k"))
            end
            objects[Symbol(k)] = bytes
        end

        return objects
    end
end
