using Checkpoints
using Compat.Test

# The method based on keyword arguments is not in Compat, so to avoid
# deprecation warnings on 0.7 we need this little definition.
if VERSION < v"0.7.0-DEV.4524"
    function sprint(f::Function, args...; context=nothing)
        if context !== nothing
            Base.sprint((io, args...) -> f(IOContext(io, context), args...), args...)
        else
            Base.sprint(f, args...)
        end
    end
end

@testset "Checkpoints" begin
    include("JLSO.jl")
end
