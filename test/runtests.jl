using Test
using MLStyle

include("match.jl")
include("pattern.jl")
include("adt.jl")
include("fn.jl")
include("typelevel.jl")

# WARNING: typelevel.jl must be at the end of the test for once `type level` feature
#          is activated in a module, it won't be able to disable in this module.

# TODO:
# include("data.jl")
