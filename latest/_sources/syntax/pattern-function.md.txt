Pattern Functions
=========================

`Pattern function` is a convenient way to define a function with multiple entries.

```julia-console
julia> f = @λ begin
           # patterns here
           x                  => 1
           ((x, (1, 2)) &&
               if x > 3 end)  => 5
           (x, y)             => 2
           ::String           => "is string"
           _                  => "is any"
       end
##λ#365 (generic function with 1 method)

julia> f(1) # => 1
1

julia> f((4, (1, 2))) # => 5
1

julia> f((1, (1, 2))) # => 2
1

julia> f("") # => "is string"
1
```

Also, sometimes you might want to pass a single lambda which just matches the
argument in one means:

```julia
map((@λ [a, b, c...] -> c), [[1, 2, 3, 4], [1, 2]])
# Or: map((@λ [a, b, c...] => c), [[1, 2, 3, 4], [1, 2]])
2-element Array{SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true},1}:
 [3, 4]
 []
```

Functionally, a `pattern function` is no more than using a `@match` inside an anonymous function.

```julia
function (x)
    @match x begin
        pat1 => body1
        pat2 => body2
    end
end
```

Both `->` and `=>` works for pattern functions.