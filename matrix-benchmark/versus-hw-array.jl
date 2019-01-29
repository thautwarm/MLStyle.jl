module BenchArray

using Benchmarkplotting
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match

import Base.getindex
getindex(asoc_lst :: Vector{Pair{Symbol, T}}, key ::Symbol) where T =
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
    Symbol("ok_case1") => [42, 42, 3, 3, 5, 10],
    Symbol("ok_case2") => [1, 2, 3, 42, 42, 42],
    Symbol("ok_case3") => [42, 42, 1, 42, 2, 3, 11],
    Symbol("early_fail") => [42, 42, 3, 3, 3, 10],
    Symbol("late_fail1") => [42, 42, 3, 3, 5, 42],
    Symbol("late_fail2") => [1, 2, 42],
    Symbol("late_fail3") => [42, 42, 1, 42, 2, 3, -42]
]

implementations = [
    :MLStyle => (@λ begin
        [_, _, (frag && if sum(frag) > 10 end)..., 10] -> 1
        [1, 2, 3, _...]  -> 2
        [_, _, 1, _, 2, 3, z && if z > 10 end]  -> 3
        _ -> 4
    end),
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            [_, _, frag..., 10], if sum(frag) > 10 end => 1
            [1, 2, 3, _...]  => 2
            [_, _, 1, _, 2, 3, z], if z > 10 end => 3
            _ => 4
        end
    end,
    :HandWritten => function(vec)
        !(vec isa Vector)  ? 4 :
        let n = length(vec)
            if n > 1 && vec[end] === 10 && sum(vec[3:end-1]) > 10
                1
            elseif n > 3 && vec[1] === 1 && vec[2] === 2 && vec[3] === 3
                2
            elseif n === 7 && vec[3] === 1 && vec[5] === 2 && vec[6] === 3 &&
                    vec[end] > 10
                3
            else
                4
            end
        end
    end
]

criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))

@info macroexpand(BenchArray, :(@λ begin
        [_, _, (frag && if sum(frag) > 10 end)..., 10] -> 1
        [1, 2, 3, _...]  -> 2
        [_, _, 1, _, 2, 3, z && if z > 10 end]  -> 3
        _ -> 4
    end))

df = bcompare(criterion, data, implementations, repeat=1)


@info df

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=5px
)
report_meantime = report(:meantime, df, theme)[1]

draw(SVG("vs-handwritten(array)-on-time.svg", 12inch, 4inch), report_meantime);

end