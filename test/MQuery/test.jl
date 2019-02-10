include("MQuery.jl")
@testset "MQuery" begin
using Base.Enums

@enum TypeChecking Dynamic Static
df = Dict(
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

res = df |>
@where !startswith(_.name, "Java"),
@groupby _."Type checking" => TC, endswith(_.name, "#") => is_sharp,
@having TC === Dynamic || is_sharp,
@select join(_.name, " and ") => result, _.TC => TC

@info res
@test res[:result][map(==(Dynamic), res[:TC]) ] == ["Julia and Ruby and Python"]
@test res[:result][map(==(Static), res[:TC])  ] == ["C# and F#"]

res = df |>
@select _.(!startswith("Type"))
@test Set(keys(res)) == Set([:name, :year])

end