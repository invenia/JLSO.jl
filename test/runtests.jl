using Mocking
Mocking.enable(force=true)

using BSON
using Compat
using Compat.Dates
using Compat.Distributed
using Compat.InteractiveUtils
using Compat.Random
using Compat.Serialization
using Compat.Test
using JLSO
using Memento
using Memento.Test

@testset "JLSO.jl" begin
    include("JLSO.jl")
end
