@testcase "subtyping" begin
    @lift abstract type A{a} end
    @lift abstract type B{a} <: A{a} end

    @testset "adt subtying" begin
        @lift @data C{A} <: B{A} begin
            C1(A, Int)
        end

        @test C1(1, 2) isa C{Int}
    end
end

@testcase "adt list" begin
    # 1. define the List data type
    @lift @data List{T} begin
        Nil()
        Cons(head :: T, tail :: List{T})
    end
    # 2. define interfaces
    len(xs::List{T}) where T = @match xs begin
        Nil{T}() => 0
        Cons{T}(_, tail) => 1 + len(tail)
    end
    @testset "adt List" begin
        @test len(Nil{Any}()) == 0
        xs = Cons(3,Cons(2, Cons(1, Nil{Int}())))
        @test len(xs) == 3
    end
end

@testcase "adt arith" begin
    # 1. define Arith
    @lift @data Arith begin
        Num(v :: Int)
        Minus(fst :: Arith, snd :: Arith)
        Add(fst :: Arith, snd :: Arith)
        Mult(fst :: Arith, snd :: Arith)
        Divide(fst :: Arith, snd :: Arith)
    end
    # 2. define interfaces
    function eval_arith(arith :: Arith)
        @match arith begin
            Num(v)       => v
            Add(fst, snd) => eval_arith(fst) + eval_arith(snd)
            Minus(fst, snd) => eval_arith(fst) - eval_arith(snd)
            Mult(fst, snd)   => eval_arith(fst) * eval_arith(snd)
            Divide(fst, snd) => eval_arith(fst) / eval_arith(snd)
        end
    end

    @testset "adt Arith" begin
        Number = Num
        @test eval_arith(
            Add(Number(1),
                Minus(Number(2),
                    Divide(Number(20),
                            Mult(Number(2),
                                Number(5)))))) == 1
    end
end


@testcase "share data with several modules" begin
    @lift @data CD begin
        D(a, b)
        C{T} :: (a :: Int, b::T) => CD
    end
    @lift @data A begin
        E()
    end

    @testset "case" begin
        @test E <: A
        @test fieldnames(D) == (:a, :b)
        @test_throws MethodError C(3.0, :abc)
    end

    @lift module ADummy
        using MLStyle
    end

    @lift module BDummy
        using MLStyle
    end

    @lift @data visible in [ADummy] SSS begin
        SSS_1(Int)
    end

    ADummy.eval(:(SSS_1 = $SSS_1; SSS = $SSS))

    @test ADummy.eval(quote
        @match SSS_1(2) begin
            SSS_1(_) => :ok
        end
    end) == :ok

    BDummy.eval(:(SSS_1 = $SSS_1; SSS = $SSS))

    @test_skip BDummy.eval(quote
        @match SSS_1(2) begin
            SSS_1(_) => :ok
        end
    end)

    @testset "enum: #85" begin
        @lift @data Es{T} begin
            E1 :: Es{Int}
            E2 :: Es{Char}
        end
        
        @lift @data Es′ begin
            E3
            E4
        end
        e1 = E1
        e2 = E2
        e3 = E3
        e4 = E4
        
        @test @match 1 begin
            E1 => false
            E2 => false
            E3 => false
            E4 => false
            _ => true
        end

        @test @match E1 begin
            E1 => true
            _ => false
        end
        
        @test @match E2 begin
            E2 => true
            _ => false
        end

        @test @match E3 begin
            E3 => true
            _ => false
        end

        @test @match E4 begin
            E4 => true
            _ => false
        end

        @test @match E1 begin
            E2 => false 
            _ => true
        end

        @test @match E3 begin
            E4 => false 
            _ => true
        end
    end
end
