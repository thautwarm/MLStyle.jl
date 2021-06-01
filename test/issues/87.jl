@testcase "issue 87" begin
    @test 1 == @match 1 begin
        ::Union{Int, String} => 1
        ::Int => 2
    end
end