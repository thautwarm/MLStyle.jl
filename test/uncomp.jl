using MLStyle

@testset "uncomp map" begin
    @test [2, 3, 5] == @match [(1, 2), (2, 3), (3, 5)] begin
        [(_, snd) for snd in seq] => seq
        _ => nothing
    end
end

@testset "uncomp filter" begin
    @test [3, 5] == @match [(1, 2), (2, 3), (3, 5)] begin
        [(_, snd) for snd in seq if snd > 2] => seq
        _ => nothing
    end
end