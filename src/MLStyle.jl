module MLStyle

# export Feature , @case, @data, @def, @match, Fun, (⇒), Pattern, Case, Failed, failed, PatternDef, pattern_match, app_pattern_match, (..), enum_next
export @match, Many, PushTo, Push, Seq, Do, @data, @use, use, @used
export defPattern, defAppPattern, defGAppPattern, mkPattern, mkAppPattern, mkGAppPattern

include("Extension.jl")
using MLStyle.Extension

include("Err.jl")

include("toolz.jl")

include("render.jl")

include("MatchCore.jl")
using MLStyle.MatchCore

include("Infras.jl")
using MLStyle.Infras

include("Pervasives.jl")
using MLStyle.Pervasives

include("DataType.jl")
using MLStyle.DataType

end # module
