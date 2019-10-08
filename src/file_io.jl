# This is the code that handles getting the JLSO file itself on to and off of the disk
# However, it does not describe how to serialize or deserialize the individual objects
# that is done lazily and the code for that is in serialization.jl

function Base.write(io::IO, jlso::JLSOFile)
    _versioncheck(jlso.version, WRITEABLE_VERSIONS)
    bson(
        io,
        Dict(
            "metadata" => Dict(
                "version" => jlso.version,
                "julia" => jlso.julia,
                "format" => jlso.format,
                "compression" => jlso.compression,
                "image" => jlso.image,
                "project_toml" => jlso.project_toml,
                "manifest_toml" => jlso.manifest_toml,
            ),
            "objects" => jlso.objects,
        )
    )
end

# `read`, unlike `load` does not deserialize any of the objects within the JLSO file,
# they will be `deserialized` when they are indexed out of the returned JSLOFile object.
function Base.read(io::IO, ::Type{JLSOFile})
    d = BSON.load(io)
    _versioncheck(d["metadata"]["version"], READABLE_VERSIONS)
    upgrade_jlso!(d)
    return JLSOFile(
        string(d["metadata"]["version"]),
        string(d["metadata"]["julia"]),
        d["metadata"]["format"],
        d["metadata"]["compression"],
        d["metadata"]["image"],
        d["metadata"]["project_toml"],
        d["metadata"]["manifest_toml"],
        d["objects"],
    )
end

function upgrade_jlso!(raw_dict::AbstractDict)
    metadata = raw_dict["metadata"]

    # v1 and v2 stored version numbers but v3 stores strings
    version = if isa(metadata["version"], VersionNumber)
        metadata["version"]
    else
        VersionNumber(metadata["version"])
    end

    if version ∈ semver_spec("1")
        if metadata["format"] == :serialize
            metadata["format"] = :julia_serialize
        end
        metadata["compression"] = :none
        metadata["version"] = v"3"
    end

    # If the dict is using the deprecated pkgs then update to the project
    # and manifest toml values.
    if haskey(metadata, "pkgs")
        project, manifest = _env(metadata["pkgs"])
        metadata["project_toml"] = project
        metadata["manifest_toml"] = manifest
        metadata["version"] = v"3"
    end

    return raw_dict
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
