@testset "type destructing" begin
    @data internal S{A, B} begin
        S_1{A, B} :: (a :: A, b :: B) => S{A, B}
    end

    s = S_1(1, "2")
    @test @match s begin
        ::S{A, B} where {A, B} => A == Int && B == String
    end

    @testset "curried destructing" begin
        s = S_1(S_1(1, 2), "2")
        @match s begin
            ::S{A} where A => A <: S{Int, Int}
            _ => false
        end
    end
end
