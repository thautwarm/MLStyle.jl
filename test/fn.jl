@testset "fn" begin
    @testset "fn cons" begin
        f = (Int ⇒ Int)(x -> x + 1)
        @test f(1) === 2
    end
    @testset "fn des" begin

        f = (Int ⇒ Int)(x -> x + 1)
        g = (Int ⇒ String)(x -> "$x")
        test_des(inp) = @match inp begin
            ::(Int ⇒ Int) => true
            _              => false
        end
        @test test_des(f)
        @test !test_des(g)
    end
end
