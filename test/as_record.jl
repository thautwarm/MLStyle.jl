@testcase "record creation" begin
    @lift struct Record_1
        a
        b
    end

    @lift @as_record Record_1

    @lift struct Record_2{A}
        x::A
        y::Int
    end

    @lift @as_record Record_2

    @lift @as_record struct AsRecordInDeclaration
        a
        b
    end

    @testset "matching" begin
        @test @match Record_1(1, 2) begin
            Record_1(1, 2) => true
            _ => false
        end
    end

    @testset "field extraction" begin
        
        @test @match Record_1(1, 2) begin
            Record_1(a=1) => true
            _ => false  
        end

        @test @match Record_1(1, 2) begin
            Record_1(b=2) => true
            _ => false
        end
    end

    @testset "field punning" begin
        @test @match Record_1(1, 2) begin
            Record_1(;a=1) => true
            _ => false
        end

        @test @match Record_1(1, 2) begin
            Record_1(;b=2) => true
            _ => false
        end

        @test @match Record_1(1, 2) begin
            Record_1(;b) => b == 2
            _ => false
        end        
    end

    @testset "parametric record" begin
        @test @match Record_2(1, 2) begin
            Record_2{A}(_) where A => A == typeof(1)
            _ => false
        end
    end

    @testset "macro in declaration" begin
        @test @match AsRecordInDeclaration(1, 2) begin
            AsRecordInDeclaration(1, 2) => true
            _ => false
        end
    end
end

@testcase "expression problem" begin
    # test whether addition of a new record in an old ADT works as expected
    # see https://en.wikipedia.org/wiki/Expression_problem for details

    # data structure compiled in some module M
    @lift @data A{B} begin
        C1(x::Int, y::Int, z::B)
        C2(x::Real, y::Real, z::B)
        C3(x::Complex, y::Complex, z::B)
    end

    f(x::A) = @match x begin
        C1(;z) => z
        C2(;z) => z
        C3(;z) => z
        _ => false
    end 

    c₁ = C1(0, 0, 1)
    c₂ = C2(0.0, 0.0, 1.0)
    c₃ = C3(0.0 + im, 0.0 + im, 1.0 + im)

    # programmer tests his code, compiles and releases software:

    # commented for performance
    # @testcase "basic match" begin
    #     @test f(c₁) == 1
    #     @test f(c₂) == 1.0
    #     @test f(c₃) == 1.0 + im
    #     @test f(0) == false
    # end

    # programmer goes drink beer, later finds out he forgot to add UInts!

    @lift struct C0{B} <: A{B} 
        x::UInt
        y::UInt
        z::B
    end

    # if programmer forgets this, pattern matching will not work
    @lift @as_record C0

    c₀ = C0(UInt(0x000), UInt(0xFFF), UInt(0x111))
    
    @testset "new records match" begin
        @test f(c₀) == false
        @test f(c₁) == 1
        @test f(c₂) == 1.0
        @test f(c₃) == 1.0 + im
    end

    # Unfortunately the function f is too generic to treat the C0 case,
    # but no problem:

    f(x::C0) = @match x begin
        C0(;z) => z
        _ => false
    end

    @testset "new implementation matches" begin
        @test f(c₀) == 0x111
        @test f(c₁) == 1
        @test f(c₂) == 1.0
        @test f(c₃) == 1.0 + im
    end

    # programmer is happy!

end
