using MLStyle
import MLStyle.AbstractPatterns

abstract type Enum154 end

struct Enum154_1_Cons <: Enum154 end

struct Enum154_2_Cons <: Enum154
    x::Vector{Int}
end
MLStyle.@as_record Enum154_2_Cons

MLStyle.is_enum(::Enum154) = true
MLStyle.enum_matcher(enum::Enum154, expr) = :($enum === $expr)

const Enum154_1 = Enum154_1_Cons()

function Base.:(==)(a::Enum154, b::Enum154)
    @match (a, b) begin
        (Enum154_1, Enum154_1) => true
        (Enum154_2_Cons(xs), Enum154_2_Cons(ys)) => xs == ys
        _ => false
    end
end

# traditional behaviour

@enum JuliaEnum_154 begin
    JuliaEnum_154_a
    JuliaEnum_154_b
    JuliaEnum_154_c
end

MLStyle.is_enum(::JuliaEnum_154) = true

MLStyle.pattern_uncall(a::JuliaEnum_154, ::Vararg) = MLStyle.AbstractPatterns.literal(a)

function eq_154(a, b)
    @match (a, b) begin
        (JuliaEnum_154_a, JuliaEnum_154_a) => true
        (JuliaEnum_154_b, JuliaEnum_154_b) => true
        (JuliaEnum_154_c, JuliaEnum_154_c) => true
        _ => false
    end
end

@testset "issue 154" begin
    @testset "tag matching support" begin
        @test Enum154_1 == Enum154_1
        @test Enum154_2_Cons([1, 2, 3]) == Enum154_2_Cons([1, 2, 3])
        @test Enum154_2_Cons([1, 2, 3]) != Enum154_2_Cons([1, 2, 4])
        @test Enum154_1 != Enum154_2_Cons([1, 2, 3])
    end

    @testset "traditional" begin
        @test eq_154(JuliaEnum_154_a, JuliaEnum_154_a)
        @test eq_154(JuliaEnum_154_b, JuliaEnum_154_b)
        @test eq_154(JuliaEnum_154_c, JuliaEnum_154_c)
        @test !eq_154(JuliaEnum_154_a, JuliaEnum_154_b)
        @test !eq_154(JuliaEnum_154_b, JuliaEnum_154_c)
        @test !eq_154(JuliaEnum_154_c, JuliaEnum_154_a)
    end
end
