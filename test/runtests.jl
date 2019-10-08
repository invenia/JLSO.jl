using BSON
using Dates
using Distributed
using InteractiveUtils
using Memento
using Random
using Serialization
using Suppressor
using Test

using JLSO
using JLSO: JLSOFile, LOGGER, upgrade_jlso!

# To test different types from common external packages
using DataFrames
using Distributions
using TimeZones

include("test_data_setup.jl")
@testset "JLSO" begin
    include("backwards_compat.jl")
    include("JLSOFile.jl")
    include("file_io.jl")
end
