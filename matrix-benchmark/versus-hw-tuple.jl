module BenchTuple

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

(1, (_, "2", _), ("3", 4, 5))
(_, "1", 2, _, (3, "4", _), _)
(_, 1, _, 2, _, 3, _, 4, _, 5)
((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13))))
"""


data = [
    Symbol("ok_case1") => (1, (42, "2", 42), ("3", 4, 5)),
    Symbol("ok_case2") => (42, "1", 2, 42, (3, "4", 42), 42),
    Symbol("ok_case3") => (42, 1, 42, 2, 42, 3, 42, 4, 42, 5),
    Symbol("ok_case4") => ((1, 2, 3, 42), (4, 5, 6, 42, (7, 8, 9, 42, (11, 12, 13)))),
    Symbol("fail1") => (1, (42, 42, 42), ("3", 4, 5)),
    Symbol("fail2") => (42, "1", 2, 42, (3, 42, 42), 42),
    Symbol("fail3") => (42, 1, 42, 2, 42, 3, 42, 4, 42, 42)
]

implementations = [
    :MLStyle => (@λ begin
        (1, (_, "2", _), ("3", 4, 5))   -> 1
        (_, "1", 2, _, (3, "4", _), _)  -> 2
        (_, 1, _, 2, _, 3, _, 4, _, 5)  -> 3
        ((1, 2, 3, _), (4, 5, 6, _, (7, 8, 9, _, (11, 12, 13)))) -> 4
        _ -> 5
    end),
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
                eqtp(a, slice, v) =
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


criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))
df = bcompare(criterion, data, implementations)
@info df
theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=5px
)
report_meantime = report(:meantime, df, theme)[1]

draw(SVG("vs-handwritten(tuple)-on-time.svg", 12inch, 4inch), report_meantime);

end