module AST
using MLStyle

export @matchast
function matchast(target, actions)
    (@match actions begin
       Expr(:quote,
            quote
                $(stmts...)
            end
       ) => stmts
    end) |> stmts ->
    map(stmts) do stmt
        @match stmt begin
            ::LineNumberNode => stmt
            :($a => $b) => :($(Expr(:quote, a)) => $b)
        end
    end |> actions ->
    quote
        $MLStyle.@match $target begin
            $(actions...)
        end
    end
end

"""
An eye candy of `@match` for AST matching.

e.g.,

```julia
    @matchast :(1 + 1) quote
        \$a + 1 => a
    end # 1

    @matchast :(f(a, b)) quote
        \$(Expr(:call, :f, :a, :b)) =>
         dosomething
    end
```
"""
macro matchast(template, actions)
    matchast(template, actions) |> esc
end
end
