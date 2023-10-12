The Switch Statements
===============================

Not all real-world code is most conveniently expressed using `@match`. To help with some common pain-points, we have included `@when`, and **`@switch`**.

The following example demonstrates a common pattern that is unnecessarily verbose:

```julia
var = 1
@match x begin
    (var_, _) => begin
            var = var_
            # do stuffs
    end
```

Firstly, capturing in `@match` just shadows outer variables, but sometimes you just want to change them.

Secondly, `@match` is an expression, and the right side of `=>` can only be an expression. Therefore writing `begin` or `end` statements can bring about an undesirable code format.

To address these issues, we present the `@switch` macro:

```julia-console
julia> var = 1
1

julia> x = (33, 44)
(33, 44)

julia> @switch x begin
       @case (var, _)
           println(var)
       end
33

julia> var
33

julia> @switch 1 begin
       @case (var, _)
           println(var)
       end
ERROR: matching non-exhaustive, at #= REPL[25]:1 =#
```
