module BenchTuple
using Benchmarkplotting
using BenchmarkTools
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
import Rematch
using ..ArbitrarySampler

import Base.getindex
getindex(asoc_lst::Vector{Pair{Symbol,T}}, key::Symbol) where {T} =
    for (search_key, value) in asoc_lst
        if search_key === key
            return value
        end
    end

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
    :spec1 => (@spec (1, (_, "2", _), ("3", 4, 5))),
    :spec2 => (@spec (_, "1", 2, _, (3, "4", _), _)),
    :spec3 => (@spec (_, 1, _, 2, _, 3, _, 4, _, 5)),
    :spec4  => (@spec ((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13))))),
    :spec5  => (@spec (::String, ::Symbol, ::Real, ([1, _], UserTy(:a, :b)))),
    :_      => @spec(_)
]

implementations = [
    :MLStyle => (@λ begin
        (1, (_, "2", _), ("3", 4, 5))   -> 1
        (_, "1", 2, _, (3, "4", _), _)  -> 2
        (_, 1, _, 2, _, 3, _, 4, _, 5)  -> 3
        ((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13)))) -> 4
        _ -> 5
    end),
    :Rematch => function (x)
        Rematch.@match x begin
            (1, (_, "2", _), ("3", 4, 5))   => 1
            (_, "1", 2, _, (3, "4", _), _)  => 2
            (_, 1, _, 2, _, 3, _, 4, _, 5)  => 3
            ((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13)))) => 4
            _ => 5
        end
    end,
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            (1, (_, "2", _), ("3", 4, 5))   => 1
            (_, "1", 2, _, (3, "4", _), _)  => 2
            (_, 1, _, 2, _, 3, _, 4, _, 5)  => 3
            ((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13)))) => 4
            _ => 5
        end
    end,
    :HandWritten => function(tp)
        !(tp isa Tuple)  ? 5 :
        let n = length(tp)
            if n === 3 && tp[1] === 1
                tp_ = tp[2]
                if !(tp isa Tuple) || tp_[2] != "2"
                    return 5
                end
                tp[3] == ("3", 4, 5) ? 1 : 5
            elseif n === 6 && tp[2] == "1" && tp[3] === 2
                tp = tp[5]
                !(tp isa Tuple) ? 5 :
                tp[1] === 3 && tp[2] == "4" ? 2 : 5
            elseif n ===  10 &&
                   tp[2] === 1 &&
                   tp[4] === 2 &&
                   tp[6] === 3 &&
                   tp[8] === 4 &&
                   tp[10] === 5
                3
            elseif n === 2 && tp[1] isa Tuple && tp[2] isa Tuple
                @inline eqtp(a, slice, v) =
                    all(slice) do i
                        a[i] === v[i]
                    end
                (a, b) = tp
                if eqtp(a, 1:3, (1, 2, 3)) &&
                   eqtp(b, 1:3, (4, 5, 6)) &&
                    let a = b[5]
                        eqtp(a, 1:3, (7, 8, 9)) &&
                        a[5] === (11, 12, 13)
                    end
                    4
                end
            else
                5
            end
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
    report(df, Scale.y_log2, theme, Guide.title("Tuples"); benchfield = :time_mean, baseline = :MLStyle)

open("stats/bench-tuple.txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/bench-tuple.svg", 10inch, 4inch), report_meantime)

end
