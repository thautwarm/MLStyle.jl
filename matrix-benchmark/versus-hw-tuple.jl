module VersusHandWritten

using Benchmarkplotting
using Statistics
using Gadfly
using MLStyle
using DataFrames

data = [
    Symbol("basic-valid") => (2, 3, (4, 5, 6), (7, 8, 9)), # valid,
    Symbol("special-valid") => (2, 2.3, (4, 5, 6), (7, 8, 9)), # valid,
    Symbol("empty-tuple") => (), # invalid
    Symbol("normal-invalid") => (1, 2, 3, 4), # invalid
    Symbol("early-invalid") => (2, 3, (4, "", 6), (7, 8, 9)), # invalid,
    Symbol("late-invalid") => (2, 3, (4, 5, 6), (7, "", 9)), # invalid,
    Symbol("not-tuple, `false`") => false, # invalid
]

implementations = [
    :MLStyle => (@λ begin
        (_, _, (4, 5, 6), (_, 8, 9)) => true
        _ => false
    end),
    :HandWritten1 => function(tp)
                tp isa Tuple && length(tp) === 4 &&
                tp[3] == (4, 5, 6) && let a = tp[4]
                    a[2] === 8 &&& a[3] === 9
                end
    end,
    :HandWritten2 =>
            let
                function f(tp :: Tuple{Any, Any, Tuple{Int, Int, Int}, Tuple{Any, Int, Int}})
                    tp[2] == (4, 5, 6) &&
                    let tp3 = tp[3]
                        tp3[2] === 8
                        tp3[3] === 9
                    end
                end
                function f(_)
                    false
                end
    end
],
df = bcompare(criterion, data, implementations)
criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=5px
)
report_meantime = report(:meantime, df, Scale.y_log10, theme)[1]
report_allocs = report(:allocs, df, theme)[1]

draw(SVG("vs-handwritten(tuple)-on-time.svg", 7inch, 3inch), report_meantime);
draw(SVG("vs-handwritten(tuple)-on-allocs.svg", 7inch, 3inch), report_allocs);

end