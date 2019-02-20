Pattern function
=========================

`Pattern function` is a convenient way to define a function with multiple entries.

```julia
f = @λ begin
    # patterns here
    x                  -> 1
    (x, (1, 2)) &&
        if x > 3 end   -> 5
    (x, y)             -> 2
    ::String           -> "is string"
    _                  -> "is any"
end
f(1) # => 1
f((4, (1, 2))) # => 5
f((1, (1, 2))) # => 2
f("") # => "is string"
```

Also, sometimes you might want to pass a single lambda which just matches the
argument in one means:

```julia
map((@λ [a, b, c...] -> c), [[1, 2, 3, 4], [1, 2]])
# => 2-element Array{SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true},1}:
#    [3, 4]
#    []
```

Functionally, A `pattern function` is no more than using a `@match` inside some anonymous function.

```julia

function (x)
    @match x begin
        pat1 => body1
        pat2 => body2
    end
end

```