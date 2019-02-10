Static-Capturing
================================

We know that `MacroTools.jl` has brought about a useful macro
`@capture` to capture specific structures from a given AST.

As the motivation of some contributors, `@capture` of `MacroTools.jl` has 3 following shortages.

- Use underscore to denote the structures to be captured, like
`struct typename_ field__ end`, which makes you have to manually number the captured variables and not that readable or consistent.

- Cause Side-Effect. The captured variables are entered in current scope.

- Lack functionalities like conditional capturing.

We can implement several new `@capture` via MLStyle.jl to get better in all aspects.



RAII-Style
=====================

This implementation prevents scope leaking.

```julia

function capture(template, ex, action)
    let template = Expr(:quote, template)
        quote
            @match $ex begin 
                $template => $action
                _         => nothing
            end
        end 
    end
end

macro capture(template, ex, action)
    capture(template, ex, action) |> esc
end

node = :(f(1))

@capture f($(x :: T where T <: Number)) node begin
    @info x + 1
end

# info: 2

node2 = :(f(x))

@capture f($(x :: T where T <: Number)) node2 begin
    @info x + 1
end

# do nothing
```


Regex-Style
==================

This implementation collects captured variables into a dictionary, just like groups in regex but more powerful.

For we have to analyse which variables to be caught, this implementation could be a bit verbose(100 lines about scoping analysis) and might not work with your own patterns(application patterns/recognizers and active-patterns are okay).


Check [MLStyle-Playground](https://github.com/thautwarm/MLStyle-Playground/blob/master/StaticallyCapturing.jl) for implementation codes.

```julia
@info @capture f($x) :(f(1))
# Dict(:x=>1)

destruct_fn = @capture function $(fname :: Symbol)(a, $(args...)) $(body...) end

@info destruct_fn(:(
    function f(a, x, y, z)
        x + y + z
    end
))

# Dict{Symbol,Any}(
#     :args => Any[:x, :y, :z],
#     :body=> Any[:(#= StaticallyCapturing.jl:93 =#), :(x + y + z)],
#    :fname=>:f
# )
```



