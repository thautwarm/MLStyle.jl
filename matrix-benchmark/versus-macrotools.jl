module VersusMacroTools

using Benchmarkplotting
using MLStyle
using Statistics
using Gadfly
using MacroTools: @capture

data = [
    :simple1 => quote
        struct Foo
            x :: Int
            y
        end
    end,

    :simple2 => quote
        struct Foo
            x :: Int
            y :: Array{Int}
        end
    end,

    Symbol("N(fields) = 5") => quote
        struct Foo
            x1 :: Int
            x2 :: Int
            x3 :: Int
            x4 :: Float32
            x5 :: Int
        end
    end,
    Symbol("N(fields) = 10") => quote
        struct Foo
            x1 :: Int
            x2 :: Int
            x3 :: Int
            x4 :: Float32
            x5 :: Int
            x6 :: Int
            x7 :: Int
            x8 :: Int
            x9 :: Int
            x10 :: Int
        end
    end
]

implementations = [
    :MacroTools => function(ex)
        @capture(ex, struct T_ fields__ end)
        (T, fields)
    end,
    :MLStyle => function (ex)
        @match ex begin
            Do(fields = []) &&
            quote
            $(::LineNumberNode)
            struct $typename
                $(
                Many(
                    ::LineNumberNode                 ||
                    :($name :: $typ) &&
                        Do(push!(fields, (name, typ)))||
                    (a :: Symbol)    &&
                        Do(push!(fields, (a, Any)))
                )...
                )
            end
            end => (typename, fields)
        end
    end
]

criterion(x) = (meantime = mean(x.times), allocs = float(x.allocs))
df = Benchmarkplotting.bcompare(criterion, data, implementations)

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=6px
)
report_meantime = report(:meantime, df, Scale.y_log10, theme)[1]
report_allocs = report(:allocs, df, theme)[1]

draw(SVG("vs-macrotools-on-time.svg", 8inch, 3inch), report_meantime)
draw(SVG("vs-macrotools-on-allocs.svg", 8inch, 3inch), report_allocs)
end