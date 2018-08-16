@testset "adt" begin
    @testset "adt List" begin
        # 1. define List
        @data List{T} begin
            Nil{T}
            Cons{T}(head :: T, tail :: List{T})
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
            Number(v :: Int)
            Minus(fst :: Arith, snd :: Arith)
            Add(fst :: Arith, snd :: Arith)
            Mult(fst :: Arith, snd :: Arith)
            Divide(fst :: Arith, snd :: Arith)
        end
        # 2. define interfaces
        function eval_arith(arith :: Arith) 
            @match arith begin
                Number(v)       => v
                Add(fst, snd) => eval_arith(fst) + eval_arith(snd)
                Minus(fst, snd) => eval_arith(fst) - eval_arith(snd)
                Mult(fst, snd)   => eval_arith(fst) * eval_arith(snd)
                Divide(fst, snd) => eval_arith(fst) / eval_arith(snd)
            end
        end

        @test eval_arith(
            Add(Number(1),
                Minus(Number(2),
                    Divide(Number(20),
                            Mult(Number(2),
                                Number(5)))))) == 1
    end

end

# for type definition not allowed in the local scope, define it at top level.
abstract type A end

@testset "@case" begin
    @case C{T}(a :: Int, b::T)
    @case D(a, b)


    @case E <: A

    @test E <: A
    @test fieldnames(D) == (:a, :b)
    @test_throws MethodError C(3.0, :abc)

end