using MLStyle.Modules.AST

@testset "matchast" begin

@test 1 == @matchast :(1 + 2) quote
    $a + 2 => a
end

end