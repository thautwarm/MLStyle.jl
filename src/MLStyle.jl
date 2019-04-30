module MLStyle

# Flags
export @use, use, @used
# Match Implementation
export @match, gen_match
# DataTypes
export @data

# Pervasive Patterns
export Many, Do
# Active Patterns
export @active
# Extensibilities
export def_pattern, def_app_pattern, def_gapp_pattern, mk_pattern, mk_app_pattern, mk_gapp_pattern, def_record, def_active_pattern
# Exceptions
export PatternUnsolvedException, InternalException, SyntaxError, UnknownExtension, @syntax_err
# Syntax Sugars
export @as_record
export @λ, gen_lambda
export @when, gen_when

# convenient modules
export Modules


include("Err.jl")
using MLStyle.Err

include("Extension.jl")
using MLStyle.Extension

include("Internal/Toolz.jl")

include("Render.jl")

include("MatchCore.jl")
using MLStyle.MatchCore

include("Infras.jl")
using MLStyle.Infras

include("Pervasives.jl")
using MLStyle.Pervasives

include("Qualification.jl")

include("TypeVarExtraction.jl")

include("StandardPatterns.jl")
using MLStyle.StandardPatterns

include("Record.jl")
using MLStyle.Record

include("DataType.jl")
using MLStyle.DataType

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
                :($a -> $(bs...)) && Do(push!(stmts, make_pair_expr(a, bs))) ||
                (a :: LineNumberNode) && Do(push!(stmts , a))
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

        _ => @syntax_err "Syntax error in lambda case definition. Check if your arrow is `->` but not `=>`!"

    end
end

"""
Code generation for `@when`.
You should pass an `Expr(:let, ...)` as the first argument.
"""
function gen_when(let_expr, source :: LineNumberNode, mod :: Module)
    @match let_expr begin
        Expr(:let, Expr(:block, bindings...) ||  a && Do(bindings = [a]), ret) =>
            foldr(bindings, init=ret) do each, last
                @match each begin
                    :($a = $b) =>
                        let cbl =  @format [source, a, last] quote
                                source
                                a => last
                                _ => nothing
                            end
                            gen_match(b, cbl, source, mod)
                        end
                    a => :(let $a; $last end)
                end
            end

        Expr(a, _...) => @syntax_err "Expect a let-binding, but found a `$a` expression."
        _ => @syntax_err "Expect a let-binding."
    end
end

"""
1. Allow destructuring in binding sequences of `let` syntax.

In binding sequences,
- For bindings in form of `a = b` and `f(x) = y`, it's regarded as pattern matching here.
- For others like `@inline f(x) = 1`, it's the same as the original let binding(not pattern matching).

```julia
    @when let (a, 1) = x,
          [b, c, 5] = y
        (a, b, c)
    end
```

2. For a regular assignment, like

```julia
    @when (a, 2) = x begin
        # dosomething
    end
```

It's nothing different from

```julia
    @match x begin
        (a, 2) => # dosomething
        _ => nothing
    end
```
"""
macro when(let_expr)
    gen_when(let_expr, __source__, __module__) |> esc
end

macro when(assignment, ret)
    @match assignment begin
        :($_ = $_) =>
            let let_expr = Expr(:let, Expr(:block, assignment), ret)
                gen_when(let_expr, __source__, __module__) |> esc
            end
        _ => @syntax_err "Not match the form of `@when a = b expr`"
    end
end

"""
Lambda cases.

e.g.

```julia
    xs = [(1, 2), (1, 3), (1, 4)]
    map((@λ (1, x) -> x), xs)
    # => [2, 3, 4]

    (2, 3) |> @λ begin
        1 -> 2
        2 -> 7
        (a, b) -> a + b
    end
    # => 5
```
"""
macro λ(cases)
    gen_lambda(cases, __source__, __module__) |> esc
end

include("Modules/Modules.jl")

end # module
