@testset "lambda pattern" begin
    @testset "example in docstring" begin
        xs = [(1, 2), (1, 3), (1, 4)]
        @test map((@λ (1, x) -> x), xs) == [2, 3, 4]
        
        @test (2, 3) |> @λ begin
            1 -> 2
            2 -> 7
            (a, b) -> (a + b) == 5
        end
    end
    
    @testset "gen_lambda case `:(\$a -> \$(b...))`" begin
        @test (2, 3) |> @λ (a, b) -> a == 2
    end
end
