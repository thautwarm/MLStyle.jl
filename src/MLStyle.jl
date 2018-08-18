module MLStyle

export Feature , @case, @data, @def, @match, Fun, (⇒), Pattern, Case, Failed, failed, PatternDef, pattern_match, app_pattern_match, (..), enum_next

include("utils.jl")
include("Feature.jl")

include("Err.jl")
using MLStyle.Err

include("Match.jl")
using MLStyle.Match

include("ADT.jl")
using MLStyle.ADT

include("Infras.jl")

include("MatchExt.jl")
using MLStyle.MatchExt

include("Data/Data.jl")
using MLStyle.Data

end # module
