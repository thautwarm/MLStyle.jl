module VersusMatch
using BenchmarkTools
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
using ..ArbitrarySampler
using ..Utils

sym = @spec ::Symbol
scall = @spec :($$sym($$sym, $$sym{0,5}...)) || :($$sym())
atom = @spec $sym || $scall
xcall = @spec :($$atom($$atom, $$atom{0,5}...)) || :($$atom()) || $atom
specs = [
    :s1 => @spec(:(function $$xcall($$xcall, $$xcall)
        $$xcall + $ $xcall
    end)),
    :s2 => @spec(:(function $$xcall($$xcall, $($xcall{0,5}...))
        $$xcall
    end)),
    :s3 => @spec(Expr(:call, Expr(:., $xcall, QuoteNode($sym)), $xcall{0,3}...)),
    :s4 => @spec(:(struct $$sym <: $$xcall
        $$sym::$ $sym
        $$sym::$ $xcall
    end)),
    :s5 => @spec(:(const $$sym = $$scall)),
    :s6 => @spec(:($$xcall = $$scall + $ $sym)),
]

implementations = [
    Symbol(:MLStyle, " Expr-pattern") => let
        function extract_name(e)
            MLStyle.@match e begin
                ::Symbol => e
                Expr(:<:, a, _) => extract_name(a)
                Expr(:struct, _, name, _) => extract_name(name)
                Expr(:call, f, _...) => extract_name(f)
                Expr(:., subject, attr, _...) => extract_name(subject)
                Expr(:function, sig, _...) => extract_name(sig)
                Expr(:const, assn, _...) => extract_name(assn)
                Expr(:(=), fn, body, _...) => extract_name(fn)
                Expr(expr_type, _...) => error(
                    "Can't extract name from ",
                    expr_type,
                    " expression:\n",
                    "    $e\n",
                )
            end
        end
        extract_name
    end,
    Symbol(:MLStyle, " AST-pattern") => let
        function extract_name_homoiconic(e)
            MLStyle.@match e begin
                ::Symbol => e
                :($a <: $_) => extract_name_homoiconic(a)
                :(struct $name <: $_
                    $(_...)
                end) => name
                :($f($(_...))) => extract_name_homoiconic(f)
                :($subject.$_) => extract_name_homoiconic(subject)
                :(function $name($(_...))
                    $(_...)
                end) => extract_name_homoiconic(name)
                :(const $assn = $_) => extract_name_homoiconic(assn)
                :($fn = $_) => extract_name_homoiconic(fn)
                Expr(expr_type, _...) => error(
                    "Can't extract name from ",
                    expr_type,
                    " expression:\n",
                    "    $e\n",
                )
            end
        end
        extract_name_homoiconic
    end,
    Symbol("Match.jl") => let
        extract_name(e::Symbol) = e
        function extract_name(e::Expr)
            Match.@match e begin
                Expr(:<:, [a, b]) => extract_name(a)
                Expr(:struct, [_, name, _]) => extract_name(name)
                Expr(:call, [f, _...]) => extract_name(f)
                Expr(:., [subject, attr, _...]) => extract_name(subject)
                Expr(:function, [sig, _...]) => extract_name(sig)
                Expr(:const, [assn, _...]) => extract_name(assn)
                Expr(:(=), [fn, body, _...]) => extract_name(fn)
                Expr(expr_type, _...) => error(
                    "Can't extract name from ",
                    expr_type,
                    " expression:\n",
                    "    $e\n",
                )
            end
        end
        extract_name
    end,
]

records = NamedTuple{(:time_mean, :implementation, :case)}[]
for (spec_id, spec) in specs
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

report_meantime, df_time =
    report(df, Guide.title("Example from Match.jl Documentation"); benchfield = :time_mean)

open("stats/bench-versus-match.txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/bench-versus-match.svg", 14inch, 6inch), report_meantime)

end
