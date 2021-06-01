module MLStyle
include("DeprecationUtils.jl")
include("Err.jl")
using .Err

# ================deprecated===============
include("Extension.Deprecated.jl")
include("Qualification.jl")
include("Render.Deprecated.jl")
# =========================================

include("AbstractPatterns/AbstractPatterns.jl")
include("MatchCore.jl")
include("ExprTools.jl")
include("MatchImpl.jl")
using .ExprTools
using .MatchImpl
@reexport MatchImpl

include("Pervasives.jl")
using .Pervasives: Do, Many, GuardBy
export Do, Many, GuardBy

include("Record.jl")
include("DataType.jl")

@reexport Err

using .DataType
@reexport DataType

using .Record
@reexport Record

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
