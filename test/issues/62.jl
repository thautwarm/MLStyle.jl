@testcase "issue 62 and 98" begin
    function test_substring_match(x::AbstractString)
        @match x begin
            "1" => 1
            _   => 0
        end
    end
    @test test_substring_match("1") == 1
    @test test_substring_match("11") == 0

    @test test_substring_match(SubString("11", 2)) == 1
    @test test_substring_match(SubString("11", 1)) == 0
end