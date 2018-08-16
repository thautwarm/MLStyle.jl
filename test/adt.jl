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
            Mult(fst :: Arith, snd :: Arith)
            Divide(fst :: Arith, snd :: Arith)
        end
        # 2. define interfaces
    end
end