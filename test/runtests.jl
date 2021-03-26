using BSON
using Dates
using Distributed
using Documenter
using FilePathsBase: SystemPath
using InteractiveUtils
using Memento
using Pkg
using Random
using Serialization
using Suppressor
using Test

using JLSO
using JLSO: JLSOFile, LOGGER, upgrade_jlso

# To test different types from common external packages
using DataFrames
using Distributions
using TimeZones

include("test_data_setup.jl")
@testset "JLSO" begin
    include("backwards_compat.jl")
    include("JLSOFile.jl")
    include("file_io.jl")

    # The doctests fail on x86, so only run them on 64-bit hardware & Julia 1.5
    Sys.WORD_SIZE == 64 && v"1.5" <= VERSION < v"1.6" && doctest(JLSO)
end
