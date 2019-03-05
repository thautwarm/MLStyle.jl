using MLStyle.Modules.Cond

usign(x) = @cond begin
    x < 0 => -1
    x == 0 => 0
    x > 0 => 1
end

@testset "cond" begin
    @test usign(-1) == -1
    @test usign(-100) == -1

    @test usign(1) == 1
    @test usign(100) == 1

    @test usign(0) == 0

    @test :ohhh == @cond begin
        false => :emmm
        _ => :ohhh
    end
end