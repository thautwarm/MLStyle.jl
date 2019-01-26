module VersusHandWritten

using Benchmarkplotting
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match

data = [
    Symbol("basic-ok") => (2, 3, (4, 5, 6), (7, 8, 9)), # valid,
    Symbol("special-ok") => (2, 2.3, (4, 5, 6), (7, 8, 9)), # valid,
    Symbol("empty-fail") => (), # invalid
    Symbol("normal-fail") => (1, 2, 3, 4), # invalid
    Symbol("early-fail") => (2, 3, (4, "", 6), (7, 8, 9)), # invalid,
    Symbol("late-fail") => (2, 3, (4, 5, 6), (7, "", 9)), # invalid,
    Symbol("type-fail") => false, # invalid
]

implementations = [
    :MLStyle => (@λ begin
        (_, _, (4, 5, 6), (_, 8, 9)) -> true
        _ -> false
    end),
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            (_, _, (4, 5, 6), (_, 8, 9)) => true
            _ => false
        end
    end,
    :HandWritten1 => function(tp)
                tp isa Tuple && length(tp) === 4 &&
                tp[3] == (4, 5, 6) &&
                let a = tp[4]
                    a[2] === 8 && a[3] === 9
                end
    end,
    :HandWritten2 =>
            let
                function f(tp :: Tuple{Any, Any, Tuple{Int, Int, Int}, Tuple{Any, Int, Int}})
                    tp[3] == (4, 5, 6) &&
                    let tp4 = tp[4]
                        tp4[2] === 8
                        tp4[3] === 9
                    end
                end
                function f(_)
                    false
                end
    end
]

criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))
df = bcompare(criterion, data, implementations)

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=5px
)
report_meantime = report(:meantime, df, theme)[1]
report_allocs = report(:allocs, df, theme)[1]

draw(SVG("vs-handwritten(tuple)-on-time.svg", 10inch, 4inch), report_meantime);
draw(SVG("vs-handwritten(tuple)-on-allocs.svg", 10inch, 4inch), report_allocs);

end