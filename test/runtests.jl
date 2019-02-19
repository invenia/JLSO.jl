using Mocking
Mocking.enable(force=true)

using BSON
using Dates
using Distributed
using InteractiveUtils
using Random
using Serialization
using Test
using JLSO
using Memento

@testset "JLSO.jl" begin
    include("JLSO.jl")
end
