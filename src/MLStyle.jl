module MLStyle

export @case, @data, @def, @match, Pattern, Case, Failed, failed, PatternDef, pattern_match, app_pattern_match, (..), enum_next

include("utils.jl")

include("Err.jl")
using MLStyle.Err

include("Match.jl")
using MLStyle.Match

include("ADT.jl")
using MLStyle.ADT

include("MatchExt.jl")
using MLStyle.MatchExt

include("Data/Data.jl")
using MLStyle.Data

end # module
