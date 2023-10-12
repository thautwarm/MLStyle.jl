Static Capturing
================================

We know that `MacroTools.jl` has brought about a useful macro
`@capture` to capture specific structures from a given AST.

As the motivation of some contributors, `@capture` of `MacroTools.jl` has the following 3 short comings.

- An underscore is used to denote the structures which are to be captured, like `struct typename_ field__ end`, which makes you have to manually number the captured variables. This is not very readable or consistent.

- Causes Side-Effects. The captured variables are entered in current scope.

- Lacks functionalities like conditional capturing.

We can implement several new `@capture` via MLStyle.jl to get better results in all of these aspects.

`Capture` Pattern from `MLStyle.Modules.AST`:
----------------------------------------------------------

MLStyle now can collaborate with scope information very well. You can get the captured variables by pattern matching in one point of your program.

```julia
using MLStyle.Modules.AST
println(Capture) # => Capture
@match :(a + b + c) begin
    :($a + $b + $c) && Capture(scope) => scope
end
# Dict{Symbol,Symbol} with 3 entries:
#  :a => :a
#  :b => :b
#  :c => :c
```

RAII-Style
---------------------------------

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
