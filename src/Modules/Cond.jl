module Cond
using MLStyle

export @cond

function cond(cases, source, mod::Module)
    @match cases begin
        quote
        $(cases...)
        end =>
        let default = Expr(:call, throw, "None of the branches have satisfied conditions, at $(string(source)).")
            foldr(cases, init = default) do case, last
                last_lnode = source
                @match case begin
                    ::LineNumberNode => begin
                        last_lnode = case
                        Expr(:block, case, last)
                    end
                    :(_ => $b) => b
                    :($a => $b) => Expr(:if, a, b, last)
                    _ => throw("Invalid syntax for conditional branches at $last_lnode.")
                end
            end
        end
        _ => begin
            msg = "Malformed ast template, the second arg should be a block with a series of pairs(`a => b`), at $(string(source))."
            throw(SyntaxError(msg))
        end
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