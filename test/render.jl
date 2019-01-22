using MLStyle.Render
module S_test_render
        b = 5
        node = :(function func_name(a)
            a + b
        end)
end
@testset "ast interpolation" begin
    x = 1
    y = 2

    node = @format [b = x + y] quote
        b + 2
    end
    @test eval(node) == 5

    S = S_test_render
    S.eval(render(S.node, Dict{Symbol, Any}(:b => 2, :func_name => :f1)))
    @test S.f1(1) == 3

end
