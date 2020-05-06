module BenchStructureFields

using Benchmarkplotting
using BenchmarkTools
using Statistics
using Gadfly
using MLStyle
using DataFrames
using MacroTools: @capture
using ..ArbitrarySampler

lineno = @spec LineNumberNode(::Int isa (x -> mod(x, 100) + 1))
field = @spec :($(::Symbol)::$(::Symbol)) || ::Symbol

specs = [
    Symbol("N(fields)=2") => @spec(quote
        $$lineno
        struct $(::Symbol)
            $([$lineno{0, 2}..., $field{2}...]...)
        end
    end),
    Symbol("N(fields)=5") => @spec(quote
        $$lineno
        struct $(::Symbol)
            $([$lineno{0,2}..., $field{5}...]...)
        end
    end),
    Symbol("N(fields)=10") => @spec(quote
        $$lineno
        struct $(::Symbol)
            $([$lineno{0,2}..., $field{10}...]...)
        end
    end),
    Symbol("N(fields)=50") => @spec(quote
        $$lineno
        struct $(::Symbol)
            $([$lineno{0,2}..., $field{50}...]...)
        end
    end),
]

struct StructField end
@active StructField(x) begin
    @match x begin
        :($a::$b) => Some((a, b))
        a::Symbol => Some((a, Any))
        _ => nothing
    end
end

using MLStyle.AbstractPattern: effect
struct PushTo end
function MLStyle.pattern_uncall(::Type{PushTo}, self, _, _, args)
    length(args) === 1 || error("PushTo accepts 1 arg.")
    container = args[1]
    effect() do target, _, _
        :(push!($container, $target))
    end
end

implementations = [
    :MLStyle => function (ex)
        fields = Tuple[]
        @match ex begin
            quote
                $(::LineNumberNode)
                struct $typename
                    $(Many[::LineNumberNode||StructField(PushTo(fields))]...)
                end
            end => (typename, fields)
        end
    end,
    :MacroTools => function (ex)
        @capture(ex, struct T_
            fields__::Any
        end)
        (T, fields)
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
report_meantime, df_time =
    report(df, Scale.y_log2, theme, Guide.title("Extracting ASTs"); benchfield = :time_mean, baseline = :MLStyle)

open("stats/bench-structfields.txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/bench-structfields.svg", 10inch, 4inch), report_meantime)

end
