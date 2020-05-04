module BenchMisc

using Benchmarkplotting
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
import Rematch

import Base.getindex
getindex(asoc_lst :: Vector{Pair{Symbol, T}}, key ::Symbol) where T =
    for (search_key, value) in asoc_lst
        if search_key === key
            return value
        end
    end

"""
3 cases could succeed in validation:

(1, (_, "2", _), ("3", 4, 5))
(_, "1", 2, _, (3, "4", _), _)
(_, 1, _, 2, _, 3, _, 4, _, 5)
((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13))))
"""

abstract type AbstractUserType end
struct UserTy1{A} <: AbstractUserType
    field1 :: Int
    field2 :: String
    field3 :: A
end
@as_record UserTy1
struct UserTy2 <: AbstractUserType end
@as_record UserTy2

data = [
    Symbol("ok1-1") => (1, "2", "aaa"),
    Symbol("ok1-2") => (1, 1.5f0, ""),
    Symbol("fail1-1") => (1, "2", 8),
    Symbol("fail1-2") => (0, 1.5f0, ""),
    
    Symbol("ok2-1") => [2, 5, 4, 3],
    Symbol("ok2-2") => [2, 1.5, 0, 3],
    Symbol("fail2-1") => [3, 5, 4, 3],
    Symbol("fail2-2") => [3, 5, 1.5, 6],
    Symbol("fail2-3") => [3, 0, 1.5, 6],
    
    Symbol("ok3") => UserTy1(2, "a", (7, 9)),
    Symbol("fail3") => UserTy1(2, "", (0, 9)),
    
    Symbol("ok4") => "yes",
    Symbol("fail4") => "no",
    
    Symbol("ok5") => UserTy1(2, "no", UserTy2()),
    Symbol("fail5") => UserTy1(2, "no", (0, 9)),

    Symbol("ok6-1") => (2, 3, 1.0, 5),
    Symbol("ok6-2") => (2, 3, 1.7f2, 5),
    Symbol("fail6-1") => (2, 1, 1.7f2, 5),
    Symbol("fail6-2") => (2, 1, "a", 5),
    
    Symbol("ok7") => [7, (1, UserTy2()), 0, "1", Int, 10],
    Symbol("fail7-1") => [7, (1, UserTy2()), 0, "1", Int, ""],
    Symbol("fail7-2") => [7, (1, UserTy2()), 0, "1", Int, 2],

    Symbol("ok8") => ("hello", ("5", UserTy2()), 10),
    Symbol("fail8-1") => ("hello", (5, UserTy2()), 10),
    Symbol("fail8-2") => ("hello", ("5", UserTy2()), "1")
]

implementations = [
    :MLStyle => (@λ begin
        (1, _, ::String)              -> 1
        ([2, a, b, 3] && if a > b end)  -> 2
        UserTy1(2, ::String, (7, 9))  -> 3
        "yes"                         -> 4
        UserTy1(2, "no", ::AbstractUserType)      -> 5
        (2, 3, ::Real, 5)                         -> 6
        [7, (1, ::AbstractUserType), _..., ::Int] -> 7
        (::String, ("5", ::UserTy2, ), 10) -> 8
        _                                  -> 9
    end),
    :Rematch => function (x)
        Rematch.@match x begin
            (1, _, _::String)              => 1
            ([2, a, b, 3] where a > b)  => 2
            UserTy1(2, _::String, (7, 9))  => 3
            "yes"                         => 4
            UserTy1(2, "no", _::AbstractUserType)      => 5
            (2, 3, _::Real, 5)                         => 6
            [7, (1, _::AbstractUserType), _..., _::Int] => 7
            (_::String, ("5", _::UserTy2, ), 10) => 8
            _                                  => 9
        end
    end,
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            (1, _, _::String)              => 1
            ([2, a, b, 3], if a > b end)  => 2
            UserTy1(2, _::String, (7, 9))  => 3
            "yes"                         => 4
            UserTy1(2, "no", _::AbstractUserType)      => 5
            (2, 3, _::Real, 5)                         => 6
            [7, (1, _::AbstractUserType), _..., _::Int] => 7
            (_::String, ("5", _::UserTy2, ), 10) => 8
            _                                  => 9
        end
    end
]

criterion(x) = (meantime = mean(x.times), allocs = 1 + x.allocs)
df = bcompare(criterion, data, implementations)
@info df
theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=5px
)
report_meantime, df_time = report(df,  Scale.y_log2, theme; benchfield=:meantime, baseline=:MLStyle)
open("stats/vs-hw(misc).txt", "w") do f
    write(f, string(df))
end
draw(SVG("stats/vs-hw(misc)-on-time.svg", 10inch, 4inch), report_meantime);

end