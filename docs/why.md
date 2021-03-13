# Why use MLStyle.jl?

## Straightforward

Pattern matching is convenient.

Algebraic data types are convenient.

Extensible pattern matching is convenient.

Generalised Algebraic data types are convenient.

## Performance Gain

When dealing with conditional logics or visiting nested data, the codes compiled via `MLStyle.jl` is usually faster than the handwritten code. You can check the benchmark results in the home page for details.

## Extensibility

You can define your own patterns via the interfaces:

- `pattern_uncall(::Type{P}, self, type_params, type_args, args)`
- `pattern_unref(::Type{P}, self, args)`

Check documentations for details.

## Referential Transparency

**You can use MLStyle only in development time** by expanding the macros.

MLStyle generates enclosed codes which require no runtime support, which means **the generated code can run without MLStyle installed**.

Also, MLStyle is implemented by itself now, via the bootstrap method.

## Intuition of AST Manipulations

MLStyle.jl gives you a chance to validate or extract things from Julia ASTs(`Symbol`, `Expr`, etc.) in an intuitive way, that is, a syntactic way:

Suppose you construct an AST with code `ex = :($f(a, b))`, here you insert `f` into the AST.

You can then just extract what you insert into AST with the same syntax:

```julia
f = some_thing
ex = :($f(a, b))

f == @match ex begin
    :($f(a, b)) => f
end # => true
```

Note, MLStyle.jl is not a superset of MacroToos.jl, though it provides something useful for AST manipulations. Besides, in terms of extracting sub-structures from a given AST, you get an orders of magnitude speed up against using MacroTools.jl.


(TODO)