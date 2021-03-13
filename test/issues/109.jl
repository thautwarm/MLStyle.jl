@testcase "#109: matching macrocall" begin
    @test 20 == @match raw"123" begin
        r"\Gaaa$" => 10
        raw"123" => 20
    end

    @lift @as_record struct Name
        n
    end

    @lift macro some_macro()
        n = esc(:Name)
        :(Name($n))
    end

    f(Name) = @match Name begin
        @some_macro() => Name
    end

    @test f(Name(1)) == 1
end
