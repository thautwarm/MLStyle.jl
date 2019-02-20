@testset "test_nothing_match" begin
    @test @match 1 begin
        nothing => false
        _ => true
    end
end
