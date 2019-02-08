using MLStyle
using DataFrames

include("MQuery.ConstantNames.jl")
include("MQuery.DynamicInfer.jl")
include("MQuery.Interfaces.jl")
include("MQuery.MacroProcessor.jl")
include("MQuery.Impl.jl")


using Base.Enums
@enum TypeChecking Dynamic Static
df = DataFrame(
        Symbol("Type checking") => [
            Dynamic, Static, Static, Dynamic, Static, Dynamic, Dynamic, Static
        ],
        :name => [
            "Julia", "C#", "F#", "Ruby", "Java", "JavaScript", "Python", "Haskell"
        ],
        :year => [
            2012, 2000, 2005, 1995, 1995, 1995, 1990, 1990
        ]
)

df |>
@where !startswith(_.name, "Java"),
@groupby _."Type checking" => TC,
@having TC === Dynamic,
@select join(_.name, " and ") => result