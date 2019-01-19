module MLStyle

# export Feature , @case, @data, @def, @match, Fun, (⇒), Pattern, Case, Failed, failed, PatternDef, pattern_match, app_pattern_match, (..), enum_next
export @match, Many, PushTo, Push, Seq, Do, @data

include("Err.jl")

include("toolz.jl")

include("render.jl")

include("MatchCore.jl")

include("Pervasive.jl")
using MLStyle.MatchCore
using MLStyle.Pervasive

# include("DataType.jl")
# using MLStyle.DataType
# include("utils.jl")
# include("Feature.jl")

# using MLStyle.Err

# include("Match.jl")
# using MLStyle.Match

# include("ADT.jl")
# using MLStyle.ADT

# include("Infras.jl")

# include("MatchExt.jl")
# using MLStyle.MatchExt

# include("Data/Data.jl")
# using MLStyle.Data

end # module
