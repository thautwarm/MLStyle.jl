@testset "adt" begin
    @testset "adt List" begin
        # 1. define List
        @data List{T} begin
            Nil()
            Cons(head :: T, tail :: List{T})
        end
        # 2. define interfaces
        len(xs::List{T}) where T = @match xs begin
            Nil{T}() => 0
            Cons{T}(_, tail) => 1 + len(tail)
        end

        @test len(Nil{Any}()) == 0
        xs = Cons(3,Cons(2, Cons(1, Nil{Int}())))
        @test len(xs) == 3
    end
    @testset "adt Arith" begin
        # 1. define Arith
        @data Arith begin
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
        Number = Num
        @test eval_arith(
            Add(Number(1),
                Minus(Number(2),
                    Divide(Number(20),
                            Mult(Number(2),
                                Number(5)))))) == 1
    end

end

@testset "case" begin
    @data CD begin
        D(a, b)
        C{T} :: (a :: Int, b::T) => CD
    end
    @data A begin
        E()
    end
    @test E <: A
    @test fieldnames(D) == (:a, :b)
    @test_throws MethodError C(3.0, :abc)
end


module ADummy
    using MLStyle.Prototype
end

module BDummy
    using MLStyle.Prototype
end

@testset "share data with several modules" begin
    @data visible in [ADummy] SSS begin
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
end