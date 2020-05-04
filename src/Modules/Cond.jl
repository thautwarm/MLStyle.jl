module Cond
using MLStyle

export @cond

function cond(cases, source, mod::Module)
    @switch cases begin
    @case Expr(:block, cases...)
        default = Expr(:call, throw, "None of the branches have satisfied conditions, at $(string(source)).")
        last_lnode = source
        folded = foldr(cases, init=default) do case, last
            @switch case begin
                @case ::LineNumberNode
                    last_lnode = case
                    return last
                @case  :(_ => $b)
                    return b
                @case :($a => $b)
                    return Expr(:if, a, b, Expr(:block, last_lnode, last))
                @case _
                    throw("Invalid syntax for conditional branches at $last_lnode.")
            end
        end
        return Expr(:block, source, folded)
    @case _
        msg = "Malformed ast template, the second arg should be a block with a series of pairs(`a => b`), at $(string(source))."
        throw(SyntaxError(msg))
    end
end

"""
```julia
@cond begin
    x > 1 => true
    _ => false
end
```
"""
macro cond(cases)
    cond(cases, __source__, __module__) |> esc
end

end