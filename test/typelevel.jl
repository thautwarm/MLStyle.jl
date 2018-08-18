
@testset "type level" begin
    @case S{A, B}(a :: A, b :: B)
    s = S(1, "2")
    @test @match s begin
        ::S{Int, String} => true
    end

    @testset "type level for func pattern" begin
        f = (Int ⇒ Int)(x -> x)
        Feature.@activate TypeLevel
        function()
                 @match f begin
                ::(T ⇒ G)  => T == G
                _          => false
                end
        end |> it -> @test it()

    end

    @testset "type level for type parameter destruction" begin
        @case S{A, B}(a :: A, b :: B)
        s = S(1, "2")
        function ()
            @match s begin
                ::Kind{A, B} => Kind === S && A === Int && B === String
            end
        end |> it -> @test it()
    end

end
