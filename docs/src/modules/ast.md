MLStyle.Modules.AST
==================================

- `@matchast`: Similar to `@match`, but focus on AST matching. No need to quote patterns with `quote ... end` or `:(...)`.

```julia
@matchast :(1 + 1) quote
    $a + 1 => a + 2
end
```
is equivalent to

```julia
@match :(1 + 1) begin
    :($a + 1) => a + 2
end
```