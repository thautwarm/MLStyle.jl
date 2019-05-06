module LambdaCases
using MLStyle
using MLStyle.Render

export gen_lambda, @λ

"""
Code generation for `@λ`.
The first argument must be something like
- `a -> b`
- `begin a -> b; (c -> d)... end`
"""
function gen_lambda(cases, source :: LineNumberNode, mod :: Module)
    TARGET = gensym("λ")
    function make_pair_expr(case, stmts)
        let block = Expr(:block, stmts...)
            :($case => $block)
        end
    end
    @match cases begin
        :($a => $b) && Do(bs = [b]) ||
        :($a -> $(bs...)) =>
                let pair = make_pair_expr(a, bs),
                    cbl = Expr(:block, source, pair),
                    match_expr = gen_match(TARGET, cbl, source, mod)

                    @format [TARGET, source, match_expr] quote
                        source
                        function (TARGET)
                            match_expr
                        end
                    end
                end

        Do(stmts=[]) &&
        quote
            $(Many(
                (a :: LineNumberNode) && Do(push!(stmts , a)) ||
                (:($a => $b) && Do(bs=[b]) || :($a -> $(bs...))) &&
                Do(push!(stmts, make_pair_expr(a, bs)))
            )...)
        end =>
            let cbl = Expr(:block, source, stmts...),
                match_expr = gen_match(TARGET, cbl, source, mod)

                @format [source, match_expr, TARGET] quote
                    source
                    function (TARGET)
                        match_expr
                    end
                end
            end

        _ => @syntax_err "Syntax error in lambda case definition!"

    end
end

"""
Lambda cases.

e.g.

```julia
    xs = [(1, 2), (1, 3), (1, 4)]
    map((@λ (1, x) => x), xs)
    # => [2, 3, 4]

    (2, 3) |> @λ begin
        1 => 2
        2 => 7
        (a, b) => a + b
    end
    # => 5
```
"""
macro λ(cases)
    gen_lambda(cases, __source__, __module__) |> esc
end

end