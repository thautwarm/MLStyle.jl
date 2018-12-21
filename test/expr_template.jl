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



@testset "spec" begin
instance = :(function f(a, b, c)
                   a + b + c
             end)
@test @match instance begin
    Expr(:function, Expr(:call, funcname, args...), block) => begin
        dump(block)
        (funcname, collect(args)) == (:f, [:a, :b, :c]) &&
        block.head == :block                            &&
        block.args[1] isa LineNumberNode                &&
        block.args[2] ==  :(a + b + c)
    end
end




@testset "show time" begin
@test @match instance begin
        :(function $funcname($(args...)) $(block...) end) => begin
        dump(block)
        (funcname, collect(args)) == (:f, [:a, :b, :c]) &&
        block[1] isa LineNumberNode                     &&
        block[2] ==  :(a + b + c)
    end
end
end

end

