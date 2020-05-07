
<a id='The-Switch-Statement-1'></a>

# The Switch Statement


In the real use of pattern matching provided by MLStyle, things can sometimes becomes painful. To end this, we have `@when`, and now even **`@switch`**.


Following code is quite stupid in many aspects:


```julia
var = 1
@match x begin
    (var_, _) => begin
            var = var_
            # do stuffs
    end
```


Firstly, capturing in `@match` just shadows outer variables, but sometimes you just want to change them.


Secondly, `@match` is an expression, and the right side of `=>` can be only an expression, and writing a `begin end` there can bring bad code format.


To address these issues, we present the `@switch` macro:


```julia
var = 1
x = (33, 44)
@switch x begin
@case (var, _)
    println(var)
end
# print: 33
var # => 33

@switch 1 begin
@case (var, _)
    println(var)
end
# ERROR: matching non-exhaustive, at #= REPL[n]:1 =#
```

