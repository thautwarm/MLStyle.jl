module MLStyle

export @match, Many, Do, @data, @use, use, @used
export def_pattern_def_app_pattern_def_gapp_pattern_mk_pattern_mk_app_pattern_mk_gapp_pattern
export PatternUnsolvedException, InternalException, SyntaxError, UnknownExtension, @syntax_err
export @active

include("Err.jl")
using MLStyle.Err

include("Extension.jl")
using MLStyle.Extension

include("toolz.jl")

include("Render.jl")

include("MatchCore.jl")
using MLStyle.MatchCore

include("Infras.jl")
using MLStyle.Infras

include("Pervasives.jl")
using MLStyle.Pervasives


include("StandardPatterns.jl")
using MLStyle.StandardPatterns

include("DataType.jl")
using MLStyle.DataType

export @λ
"""
Lambda cases.
e.g.
map((@λ (1, x) -> x), xs)

(2, 3) |> @λ begin
    1 -> 2
    2 -> 7
    (a, b) -> a + b
end

# 5
"""
macro λ(cases)
    TARGET = mangle(__module__)
    @match cases begin
        :($a -> $(b...)) =>
                esc(quote
                    function ($TARGET, )
                        @match $TARGET begin
                            $a => begin $(b...) end
                        end
                    end
                end)

        Do(stmts=[]) &&
        :(begin $(Many(:($a -> $(b...)) && Do(push!(stmts, :($a => begin $(b...) end))) ||
                       (a :: LineNumberNode) && Do(push!(stmts , a))
                       )...)
          end) =>
            esc(quote
                function ($TARGET, )
                    @match $TARGET begin
                        $(stmts...)
                    end
                end
            end)
        _ => @syntax_err "Syntax error in lambda case definition. Check if your arrow is `->` but not `=>`!"
    end
end

export @when
function when(let_expr)
    @match let_expr begin
       Expr(:let, Expr(:block, bindings...) ||  a && Do(bindings = [a]), ret) =>
            foldr(bindings, init=ret) do each, last
                @match each begin
                    :($a = $b) => 
                        :(
                            $MLStyle.@match $b begin 
                                $a =>  $last
                                _  =>  nothing
                            end
                        )
                    a => :(let $a; $last end)
                end
            end
       Expr(a, _...) => @syntax_err "Expect a let-binding, but found a `$a` expression."
       _ => @syntax_err "Expect a let-binding."
    end
end

"""

1. Allow destructuring in binding sequences of let syntax.
    
In binding sequences, 
- For the bindings with the form `a = b`, you can use destructuring here.
- For others like `@inline f(x) = 1`, it's the same as the original let binding.  

@when let (a, 1) = x,
          [b, c, 5] = y
        (a, b, c)
end

2. For a regular assignment, like
```
@when (a, 2) = x begin
    # dosomething
end
```
It's nothing different with
```
@match x begin
    (a, 2) => # dosomething
    _ => nothing
end
```
"""
macro when(let_expr)
    when(let_expr) |> esc
end

macro when(assignment, ret)
    @match assignment begin
        :($_ = $_) =>
            when(Expr(:let, Expr(:block, assignment), ret)) |> esc
        _ => @syntax_err "Not match the form of `@when a = b expr`"
    end
end

macro stagedexpr(exp)
    __module__.eval(exp)
end

end # module
