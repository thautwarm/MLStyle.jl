module BenchMisc
using BenchmarkTools
using Benchmarkplotting
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
import Rematch
using ..ArbitrarySampler

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

mod′(n) = x -> mod(x, n)

any_user1 = @spec UserTy1(::Int, ::String, _)
any_user  = @spec UserTy2() || $any_user1
specs = [
    :s1 => @spec((1 || 2, _, ::String || ::Symbol)),
    :s2 => @spec([2 || 0, ::Integer, ::Integer, 3 || 0]),
    :s3 => @spec(UserTy1(::Int isa mod′(4), ::String, (7||8 , 8||9))),
    :s4 => @spec("yes" || "no" || "not sure" || _),
    :s5 => @spec(UserTy1(::Int isa mod′(5), "no" || "yes", $any_user)),
    :s6 => @spec([7 || _, (1 || _, $any_user), (_{2})..., ::Int || _]),
    :s7 => @spec((_::String, ("1" || "2" || "5", UserTy2(), ), ::Int isa (x -> 9 + mod(x, 5)))),
    :s8 => @spec((_, 10, _, 20, _)),
    :_  => @spec(_)
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

records = NamedTuple{(:time_mean, :implementation, :case)}[]
for (spec_id, spec) in specs
    # group_key = string(spec_id)
    # suite[group_key] = BenchmarkGroup()
    for (impl_id, impl_fn) in implementations
        bench′ =
            @benchmark $impl_fn(sample) setup = (sample = $generate($spec)) samples = 2000
        time′ = mean(bench′.times)
        @info :bench (spec_id, impl_id, time′)
        push!(records, (time_mean = time′, implementation = impl_id, case = spec_id))
    end
end

df = DataFrame(records)
@info df

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size = 5px,
)
report_meantime, df_time =
    report(df, Scale.y_log2, theme, Guide.title("Misc"); benchfield = :time_mean, baseline = :MLStyle)

open("stats/bench-misc.txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/bench-misc.svg", 10inch, 4inch), report_meantime)

end