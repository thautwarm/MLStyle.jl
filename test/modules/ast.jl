using MLStyle.Modules.AST

@testset "tools for ast manipulations" begin

@test 1 == @matchast :(1 + 2) quote
    $a + 2 => a
end

@test (:f, [:a, :b, :c]) == @matchast :(f(a, b, c)) quote
    $func() => throw("not expected")
    $func($(args...)) => (func, args)

end


input = :(1 + 2)
@test  (@capture ($a + 2) input)[:a] == 1

end