module MLStyle
include("Err.jl")
using .Err

# ================deprecated===============
include("Extension.jl")
include("Qualification.jl")
include("Render.jl")
# =========================================

include("AbstractPatterns/AbstractPatterns.jl")
include("MatchCore.jl")
include("ExprTools.jl")
include("MatchImpl.jl")
include("Record.jl")
include("DataType.jl")

using .ExprTools

@reexport Err

using .DataType
@reexport DataType

using .MatchImpl
@reexport MatchImpl

using .Record
@reexport Record

include("Pervasives.jl")
using .Pervasives: Do, Many, GuardBy
export Do, Many, GuardBy

include("Sugars.jl")

include("StandardPatterns/LambdaCases.jl")
using .LambdaCases
@reexport LambdaCases

include("StandardPatterns/Active.jl")
using .Active
@reexport Active

include("StandardPatterns/WhenCases.jl")
using .WhenCases
@reexport WhenCases

using .Extension
@reexport Extension

include("Modules/Modules.jl")
export Modules

end # module
