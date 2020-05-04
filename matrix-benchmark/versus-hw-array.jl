module BenchArray

using Benchmarkplotting
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
import Rematch

import Base.getindex
getindex(asoc_lst::Vector{Pair{Symbol,T}}, key::Symbol) where {T} =
    for (search_key, value) in asoc_lst
        if search_key === key
            return value
        end
    end

"""
3 cases could succeed in validation:

[_, _, frag..., 10], sum(frag) > 10
[1, 2, 3, _...]
[_, _, 1, _, 2, 3, z], z > 10

"""


data = [
    Symbol("ok_case1") => [42, 42, 3, 3, 3, 10, 1, -2, 5, 10],
    Symbol("ok_case2") => [1, 2, 3, 42, 42, 42, 22, 22, 22, 22, 22],
    Symbol("ok_case3") => [42, 42, 1, 42, 2, 3, 11],
    Symbol("early_fail") => [42, 42, -3, -3, -8, 18, -21, 1, 10],
    Symbol("late_fail1") => [42, 42, 3, 3, 5, 42],
    Symbol("late_fail2") => [1, 2, 42],
    Symbol("late_fail3") => [42, 42, 1, 42, 2, 3, -42],
]


implementations = [
    :MLStyle => (@λ begin
        [_, _, (frag && if sum(frag) > 10
        end)..., 10] -> 1
        [1, 2, 3, _...] -> 2
        [_, _, 1, _, 2, 3, z && if z > 10
        end] -> 3
        _ -> 4
    end),
    :Rematch => function (x)
        Rematch.@match x begin
            [_, _, frag..., 10] where {sum(frag)>10} => 1
            [1, 2, 3, _...] => 2
            [_, _, 1, _, 2, 3, z] where {z>10} => 3
            _ => 4
        end
    end,
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            [_, _, frag..., 10], if sum(frag) > 10
            end => 1
            [1, 2, 3, _...] => 2
            [_, _, 1, _, 2, 3, z], if z > 10
            end => 3
            _ => 4
        end
    end,
    :HandWritten => function (vec)
        !(vec isa Vector) ? 4 :
                let n = length(vec)
            if n > 3 && vec[end] === 10 && sum(vec[3:end-1]) > 10
                1
            elseif n > 3 && vec[1] === 1 && vec[2] === 2 && vec[3] === 3
                2
            elseif n === 7 && vec[3] === 1 && vec[5] === 2 && vec[6] === 3 && vec[end] > 10
                3
            else
                4
            end
        end
    end,
    :MLStyleGEN => function (x)
        var"A263" = x
        if var"A263" isa AbstractArray{T,1} where {T}
            #= REPL[3]:2 =#
            if length(var"A263") >= 3 && (
                begin
                    var"A264" = view(var"A263", 3:length(var"A263")-1)
                    let frag = var"A264"
                        sum(frag) > 10
                    end
                end && var"A263"[end] == 10
            )
                begin end
                @goto var"Aa1#266"
            end
            #= REPL[3]:3 =#
            if length(var"A263") >= 3 &&
               var"A263"[1] == 1 &&
               var"A263"[2] == 2 &&
               var"A263"[3] == 3
                @goto var"Ab2#267"
            end
            #= REPL[3]:4 =#
            if length(var"A263") === 7 && (
                var"A263"[3] == 1 &&
                var"A263"[5] == 2 &&
                var"A263"[6] == 3 &&
                begin
                    var"A265" = var"A263"[7]
                    let z = var"A265"
                        z > 10
                    end
                end
            )
                begin end
                @goto var"Ac3#268"
            end
        end
        #= REPL[3]:5 =#
        begin
            @goto var"Ad4#269"
        end
        error("matching non-exhaustive, at #= REPL[3]:1 =#")

        begin
            #= REPL[3]:2 =#
            @label var"Aa1#266"
            var"Afinal#262" = let frag = var"A264"
                1
            end
            @goto var"AFINAL#270"
            #= REPL[3]:3 =#
            @label var"Ab2#267"
            var"Afinal#262" = let
                2
            end
            @goto var"AFINAL#270"
            #= REPL[3]:4 =#
            @label var"Ac3#268"
            var"Afinal#262" = let z = var"A265"
                3
            end
            @goto var"AFINAL#270"
            #= REPL[3]:5 =#
            @label var"Ad4#269"
            var"Afinal#262" = let
                4
            end
            @goto var"AFINAL#270"
            @label var"AFINAL#270"
            var"Afinal#262"
        end

    end,
]

criterion(x) = (meantime = mean(x.times), allocs = 1 + x.allocs)
df = bcompare(criterion, data, implementations, repeat = 1)


@info df

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size = 5px,
)
report_meantime, df_time =
    report(df, Scale.y_log2, theme; benchfield = :meantime, baseline = :MLStyle)

open("stats/vs-hw(array).txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/vs-hw(array)-on-time.svg", 10inch, 4inch), report_meantime)

end
