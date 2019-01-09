using MLStyle.MatchCore

# @testset "base" begin
# @test @match Expr(:call, :f, :a) begin
#     Expr(:call, tail...) => collect(tail) == [:f, :a]
# end
# end

# @testset "expr template" begin
# ast = :(f(a, b))

# @test @match Expr(:call, :f, :a, :b) begin
#   esc($f($a, $b)) => (a, b) == (:a, :b)
# end
# end



@testset "Ast Pattern" begin
instance = :(function f(a, b, c)
                   a + b + c
             end)
@test @match instance begin
    Expr(:function, Expr(:call, funcname, args...), block) => begin
        (funcname, collect(args)) == (:f, [:a, :b, :c]) &&
        block.head == :block                            &&
        block.args[1] isa LineNumberNode                &&
        block.args[2] ==  :(a + b + c)
    end
end




@testset "function" begin
@test @match instance begin
        :(function $funcname($(args...)) $(block...) end) => begin
        (funcname, collect(args)) == (:f, [:a, :b, :c]) &&
        block[1] isa LineNumberNode                     &&
        block[2] ==  :(a + b + c)
    end
end
end



let_expr = :(let a = 10 + 20, b = 20
              20a
             end)

@testset "let binding" begin
@test @match let_expr begin
        :(let $bind_name = $fn($left, $right), $(other_bindings...)
               $(block...)
          end) => begin
        bind_name == :a   &&
        fn        == :(+) &&
        left      == 10   &&
        right     == 20   &&
        block[1]  isa LineNumberNode &&
        block[2]  == :(20a)
    end
end
end

end

