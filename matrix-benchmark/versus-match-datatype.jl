module BenchDataType

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

@data NormalData begin
    Normal1(a :: Int, b :: Int, c :: Any)
    Normal2(a :: Int)
end

@data GenericData{A} begin
    Generic1(a :: A, b :: Int)
    Generic2(A)
end


"""
ok cases:
1.   Normal1(c :: Number)
2.   Normal1(Normal2(1))
3.   Generic1(a = 3, b = 3)
4.   Generic2((1, 2))
5.   GenericData{String}
"""
data = [
    Symbol("ok1") => Normal1(2, 3, 1.0),

    Symbol("fail1") => Normal1(2, 3, ()),
    
    Symbol("ok2") => Normal1(2, 3, Normal2(1)),
    
    Symbol("fail2") => Normal1(2, 3, Normal2(3)),

    Symbol("ok3") => Generic1(3, 3),

    Symbol("fail3") => Generic1(3, -3),

    Symbol("ok4") => Generic2((1, 2)),

    Symbol("fail4") => Generic2(()),

    Symbol("ok5") => Generic2("5"),

    Symbol("fail5") => Generic2(Int)
]

implementations = [
    :MLStyle => (@λ begin
        Normal1(c = ::T where T <: Number) -> 1
        Normal1(c = Normal2(1)) -> 2
        Generic1(a = 3, b = 3) -> 3
        Generic2((1, 2)) -> 4
        ::GenericData{String} -> 5
        _ -> 0 
    end),
    Symbol("Match.jl") => function (x)
        Match.@match x begin
            Normal1(_, _, _ :: Number) => 1
            Normal1(_, _, Normal2(1)) => 2
            Generic1(3, 3) => 3
            Generic2((1, 2)) => 4
            _ :: GenericData{String} => 5
            _ => 0 
        end
    end
]

criterion(x) = (meantime = mean(x.times), allocs = 1 + x.allocs)
df = bcompare(criterion, data, implementations, repeat=1)


@info df

theme = Theme(
    guide_title_position = :left,
    colorkey_swatch_shape = :circle,
    minor_label_font = "Consolas",
    major_label_font = "Consolas",
    point_size=5px
)

report_meantime, df_time = report(:meantime, df, Scale.y_log10, theme)
report_allocs, df_allocs = report(:allocs, df, theme)

open("stats/vs-match(datatype).txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/vs-match(datatype)-on-time.svg", 10inch, 4inch), report_meantime);
draw(SVG("stats/vs-match(datatype)-on-allocs.svg", 10inch, 4inch), report_allocs);

end