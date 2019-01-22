using MLStyle

@testset "exception" begin
    @test_skip @match 1 begin
        Unknown(a, b) => 0
    end

    @test_skip @match 1 begin
        a = b => 0
    end
end

