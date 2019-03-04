Pattern Scoping Qualifier
==================================

To avoid scoping pollution, we introduce a mechanism to allow customizing a pattern's visibility.

This is supported in the definitions of ADTs/GADTs and active patterns.

Public
------------------------------

Unless specified otherwise, all patterns are defined with a `public` qualifier.

```julia
@data A begin
    ...
end
@active B(x) begin
    ...
end
```
Above snippet is equivalent to
```julia
@data public A begin
    ...
end
@active public B(x) begin
    ...
end
```

`public` means that the pattern is visible once it's imported into current scope.

Internal
--------------------------------------

`internal` means that a pattern is only visible in the module it's defined in. In this situation, even if you export the pattern to other modules, it just won't work.

```julia
module A
using MLStyle
export Data, Data1
@data internal Data begin
    Data1(Int)
end

@match Data1(2) begin
    Data1(x) => @info x
end

module A2
    using ..A
    using MLStyle
    @match Data1(2) begin
        Data1(x) => @info x
    end
end
end
```

outputs:

```
[ Info: 2
ERROR: LoadError: MLStyle.Err.PatternUnsolvedException("invalid usage or unknown application case Main.A.Data1(Any[:x]).")
```

When it comes to active patterns, the behaviour is the same.

Visible-In
----------------------

Sometimes users need to have a more fine-grained control over the patterns' visibility, thus we have provided such a way to allow patterns to be visible in several modules specified by one's own.

```julia
@active visible in (@__MODULE__) IsEven(x) begin
    x % 2 === 4
end
```

Above `IsEven` is only visible in current module.


```julia
@active visible in [MyPack.A, MyPack.B] IsEven(x) begin
    x % 2 === 4
end
```

Above `IsEven` is only visible in modules `MyPack.A` and `MyPack.B`.