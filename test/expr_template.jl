using MLStyle


rmlines = @λ begin
    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)
      :: LineNumberNode -> nothing
    a                   -> a
end

macroexpand(@__MODULE__, :(@match 1 begin
        1 => 1
end)) |> rmlines


@testset "call / expr" begin
@test @match Expr(:call, :f, :a) begin
    Expr(:call, tail...) => collect(tail) == [:f, :a]
end
end

@testset "call / ast" begin
ast = :(f(a, b))

@test @match Expr(:call, :f, :a, :b) begin
  :($f($a, $b)) => (a, b) == (:a, :b)
end
end

# https://github.com/JuliaLang/julia/pull/35138
const LN_OFF = VERSION >= v"1.5.0" ? 1 : 0

@testset "Ast Pattern" begin
instance = :(function f(a, b, c)
                   a + b + c
             end)
@test @match instance begin
    Expr(:function, Expr(:call, funcname, args...), block) => begin
        (funcname, collect(args)) == (:f, [:a, :b, :c]) &&
        block.head == :block                            &&
        block.args[1 + LN_OFF] isa LineNumberNode                &&
        block.args[2 + LN_OFF] ==  :(a + b + c)
    end
end




@testset "function" begin
@test @match instance begin
        :(function $funcname($(args...)) $(block...) end) => begin
        (funcname, collect(args)) == (:f, [:a, :b, :c]) &&
        block[1 + LN_OFF] isa LineNumberNode                     &&
        block[2 + LN_OFF] ==  :(a + b + c)
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

@testset "only head" begin
    @test @match Expr(:f) begin
        Expr(a) => a === :f
        _       => false
    end
end

@testset "only pack" begin
    @test @match Expr(:f) begin
        Expr(a...) => a == [:f]
        _          => false
    end
end

@testset "pack all" begin
    @test @match Expr(:f, :a) begin
        Expr(a...) => a == [:f, :a]
        _          => false
    end
end


module ASTSamples

    node_fn1 = :(function f(a, b) a + b end)
    node_fn2 = :(function f(a, b, c...) c end)
    node_let = :(let x = a + b
                2x
            end)
    node_chain = :(subject.method(arg1, arg2))
    node_struct = :(
            struct name <: base
                field1 :: Int
                field2 :: Float32
            end
    )

    node_const = :(
            const a = value
    )
    node_assign = :(a = b + c)

end

@testset "case from Match.jl" begin

extract_name = @λ begin
        e ::Symbol                         -> e
        Expr(:<:, a, _)                    -> extract_name(a)
        Expr(:struct, _, name, _)          -> extract_name(name)
        Expr(:call, f, _...)               -> extract_name(f)
        Expr(:., subject, attr, _...)      -> extract_name(subject)
        Expr(:function, sig, _...)         -> extract_name(sig)
        Expr(:const, assn, _...)           -> extract_name(assn)
        Expr(:(=), fn, body, _...)         -> extract_name(fn)
        Expr(expr_type,  _...)             -> error("Can't extract name from ",
                                                    expr_type, " expression:\n",
                                                    "    $e\n")
end

@test extract_name(ASTSamples.node_fn1) == :f
@test extract_name(ASTSamples.node_fn2) == :f
@test extract_name(ASTSamples.node_chain) == :subject
@test extract_name(ASTSamples.node_struct) == :name
@test extract_name(ASTSamples.node_const) == :a
@test extract_name(ASTSamples.node_assign) == :a
@test_skip extract_name(:(1 + 1))

end

