module Cond
using MLStyle

export @cond

function cond(cases)
    @match cases begin
        quote
        $(cases...)
        end =>
        let default = Expr(:call, throw, "None of the branches have satisfied conditions.")
            foldr(cases, init = default) do case, last
                last_lnode = LineNumberNode(@__LINE__)
                @match case begin
                    ::LineNumberNode => begin
                        last_lnode = case
                        Expr(:block, case, last)
                    end
                    :(_ => $b) => b
                    :($a => $b) => Expr(:if, a, b, last)
                    _ => throw("Invalid syntax at $last_lnode.")
                end
            end
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
    cond(cases) |> esc
end

end