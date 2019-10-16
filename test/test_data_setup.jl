# Serialize "Hello World!" on julia 0.5.2 (not supported)
const img = JLSO._image()
const pkgs = JLSO._pkgs()
const project, manifest = Pkg.TOML.parse.(JLSO._env())
const hw_5 = UInt8[
    0x26, 0x15, 0x87, 0x48, 0x65,
    0x6c, 0x6c, 0x6f, 0x20, 0x57,
    0x6f, 0x72, 0x6c, 0x64, 0x21
]

const datas = Dict(
    :String => "Hello World!",
    :Vector => [0.867244, 0.711437, 0.512452, 0.863122, 0.907903],
    :Matrix => [
        0.400348 0.892196 0.848164;
        0.0183529 0.755449 0.397538;
        0.870458 0.0441878 0.170899
    ],
    :DateTime => DateTime(2018, 1, 28),
    :ZonedDateTime => ZonedDateTime(2018, 1, 28, tz"America/Chicago"),
    :DataFrame => DataFrame(
        :a => collect(1:5),
        :b => [0.867244, 0.711437, 0.512452, 0.863122, 0.907903],
        :c => ["a", "b", "c", "d", "e"],
        :d => [true, true, false, false, true],
    ),
    :Distribution => Normal(50.2, 4.3),
)

#==
for format in (:bson, :julia_serialize)
    for compression in (:none, :gzip, :gzip_fastest, :gzip_smallest)
        fn = "specimens/v2_$(format)_$(compression).jlso"
        time = @elapsed JLSO.save(fn, datas; format=format, compression=compression);
        time = @elapsed JLSO.save(fn, datas; format=format, compression=compression);
        @info "" format compression time size=filesize(fn)
    end
end
==#
