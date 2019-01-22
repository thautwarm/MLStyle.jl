@testset "active pattern" begin
    @testset "regular case" begin
        @active LessThan0(x) begin
            if x > 0
                nothing
            else
                x
            end
        end

        @test (@match 15 begin
            LessThan0(_) => :a
            _ => :b
        end) === :b

        @test (@match -15 begin
            LessThan0(a) => a
            _ => 0
        end) == -15
    end
    @testset "parametric case" begin

        @active Re{r :: Regex}(x) begin
             match(r, x)
        end

        @test (@match "123" begin
            Re{r"\d+"}(x) => x.match
            _ => @error ""
        end) == "123"

        @test_skip @match "abc" begin
            Re{r"\d+"}(x) => x
            _ => @error ""
        end
    end
end