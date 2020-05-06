module BenchDataType

using BenchmarkTools
using Statistics
using Gadfly
using MLStyle
using DataFrames
import Match
import Rematch
using ..ArbitrarySampler
using ..Utils

@data NormalData begin
    Normal1(a :: Int, b :: Int, c :: Any)
    Normal2(a :: Int)
end

@data GenericData{A} begin
    Generic1(a :: A, b :: Int)
    Generic2(A)
end

mod′(n) = x -> mod(x, n)

specs = [
    :s1 => @spec(Normal1(::Int, ::Int, ::Real || ::Complex || _)),
    :s2 => @spec(Normal1(::Int, ::Int, Normal2(1 || ::Int))),
    :s3 => @spec(Generic1(3 || _, 4 || ::Int)),
    :s4 => @spec(Generic2((1 || _, 2 || _))),
    :s5 => @spec(Generic1(::String || _, 0)  || Generic2(::String || _)),
    :s6 => @spec(Generic1(_, ::Int) || Generic2(_) || Normal2(::Int) || Normal1(::Int, ::Int, _)),
    :_ => @spec(_)
]

implementations = [
    :MLStyle => (@λ begin
        Normal1(c = ::Number) -> 1
        Normal1(c = Normal2(1)) -> 2
        Generic1(a = 3, b = 3) -> 3
        Generic2((1, 2)) -> 4
        ::GenericData{String} -> 5
        _ -> 0
    end),
    :Rematch => function (x)
        Rematch.@match x begin
            Normal1(_, _, _ :: Number) => 1
            Normal1(_, _, Normal2(1)) => 2
            Generic1(3, 3) => 3
            Generic2((1, 2)) => 4
            _:: GenericData{String} => 5
            _ => 0
        end
    end,
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

report_meantime, df_time = report(
    df, Guide.title("Data Types");
    benchfield = :time_mean
)


open("stats/bench-datatype.txt", "w") do f
    write(f, string(df))
end

draw(SVG("stats/bench-datatype.svg", 14inch, 6inch), report_meantime)
end