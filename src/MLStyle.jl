module MLStyle
include("Err.jl")
using .Err

# ================deprecated===============
include("Extension.jl")
include("Qualification.jl")

# =========================================



include("AbstractPatterns/AbstractPattern.jl")
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
using .Pervasives: Do, Many
export Do, Many

include("Sugars.jl")

include("StandardPatterns/LambdaCases.jl")
using .LambdaCases
@reexport LambdaCases

include("StandardPatterns/Active.jl")
using .Active
@reexport Active

# Flags
export @use, use, @used
# Match Implementation
export @match, gen_match
# DataTypes
export @data

# Pervasive Patterns
export Many, Do
# Active Patterns
export @active
# Extensibilities
export def_pattern, def_app_pattern, def_gapp_pattern, mk_pattern, mk_app_pattern, mk_gapp_pattern, def_record, def_active_pattern
# Exceptions
export PatternCompilationError, InternalException, SyntaxError, UnknownExtension
# Syntax Sugars
export @as_record
export @λ, gen_lambda
export @when, @otherwise, gen_when
export MatchCore






# # convenient modules
# export Modules


# include("Err.jl")
# using MLStyle.Err

# include("Extension.jl")
# using MLStyle.Extension

# include("Internal/Toolz.jl")

# include("Render.jl")

# include("MatchCore.jl")
# using MLStyle.MatchCore

# include("Infras.jl")
# using MLStyle.Infras

# include("Pervasives.jl")
# using MLStyle.Pervasives

# include("Qualification.jl")

# include("TypeVarExtraction.jl")

# include("StandardPatterns/TypeVarDecons.jl")
# include("StandardPatterns/Active.jl")
# using MLStyle.Active

# include("Record.jl")
# using MLStyle.Record

# include("DataType.jl")
# using MLStyle.DataType

# include("StandardPatterns/Uncomprehensions.jl")

# include("StandardPatterns/LambdaCases.jl")
# using MLStyle.LambdaCases

# include("StandardPatterns/WhenCases.jl")
# using MLStyle.WhenCases

# include("Modules/Modules.jl")

end # module
