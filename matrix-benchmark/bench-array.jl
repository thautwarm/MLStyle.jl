module BenchArray
using BenchmarkTools
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
import Rematch
using ..ArbitrarySampler
using ..Utils

mod′(n) = x -> mod(x, n)
len_in(rng) = x -> length(x) in rng
is_in(rng) = x -> x in rng

integer20 = @spec ::Integer isa mod′(20)

struct UserTy{T}
    a::T
    b::Symbol
end
@as_record UserTy

specs = [
    :s1 => (@spec [1, _, _, $integer20{2,5}..., 10, 7, ::String, [1, 2, 3]]),
    :s2 => (@spec [10, 20, [27, ::UInt8], ::String, ::Symbol, _{2,10}...]),
    :s3 => (@spec [
        (1, 2, ::String),
        (::Int, ::Int isa (x -> x % 4 + 8)),
        12,
        9,
        9,
        _{2,10}...,
        3,
    ]),
    :s4 => (@spec [_, _, _, _, 8, _, ::Integer, UserTy(::String, :bb)]),
    :s5 => (@spec [$integer20, _, UserTy(1, :a), _, UserTy(2, :b)]),
    :s6 => (@spec [_, 125, _]),
    :s7 => (@spec [2, (), (), _{2,3}..., 1, 2, 3, 10]),
    :_ => @spec(_),
]

implementations = [
    :MLStyle => function (x)
        @match x begin
            [1, _, _, xs..., 10, 7, ::String, &[1, 2, 3]] && if sum(xs) < 37
            end => 1
            [10, 20, [27, ::UInt8], ::String, ::Symbol, _...] => 2
            [(1, 2, ::String), (::Int, ::Int && 7:11), 12, 9, 9, _..., 3] => 3
            [_, _, _, _, 8, _, ::Integer, UserTy(::String, :bb)] => 4
            [_, _, UserTy(1, :a), UserTy(2, :b)] => 5
            _ => 6
        end
    end,
    :Rematch => function (x)
        Rematch.@match x begin
            [1, _, _, x..., 10, 7, _::String, [1, 2, 3]] where {sum(x)<37} => 1
            [10, 20, [27, _::UInt8], _::String, _::Symbol, _...] => 2
            [(1, 2, _::String), (_::Int, v::Int), 12, 9, 9, _..., 3] where {v in 7:11} => 3
            [_, _, _, _, 8, _, _::Integer, UserTy(_::String, :bb)] => 4
            [_, _, UserTy(1, :a), UserTy(2, :b)] => 5
            _ => 6
        end
    end,
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            [1, _, _, x..., 10, 7, _::String, [1, 2, 3]], if sum(x) < 37
            end => 1
            [10, 20, [27, _::UInt8], _::String, _::Symbol, _...] => 2
            [(1, 2, _::String), (_::Int, v::Int), 12, 9, 9, _..., 3], if v in 7:11
            end => 3
            [_, _, _, _, 8, _, _::Integer, UserTy(_::String, :bb)] => 4
            [_, _, UserTy(1, :a), UserTy(2, :b)] => 5
            _ => 6
        end
    end,
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

report_meantime, df_time = report(
    df, Guide.title("Arrays");
    benchfield = :time_mean
)

open("stats/bench-array.txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/bench-array.svg", 14inch, 6inch), report_meantime)

end
