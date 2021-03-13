@test 20 == @match raw"123" begin
    r"\Gaaa$" => 10
    raw"123" => 20
end
