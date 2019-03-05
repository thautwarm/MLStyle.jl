MLStyle.Modules.AST
==================================

@matchast
---------------------

- Description: Similar to `@match`, but focus on AST matching. No need to quote patterns with `quote ... end` or `:(...)`.
- Usage: `@matchast ast_to_match (begin cases... end)`
- Examples:

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

@capture
-------------------

- Description: Similar to `MacroTools.@capture`, but provided with a more regex-flavored matching.
- Usage: `@capture template input_ast`,  note that `template` is purely static and cannot be a variable from current context.
- Examples:
```julia
func_node = :(f(a, b, c))
let_node = :(let a = b; a + b end)
@info :function @capture $fn($(args...)) func_node
@info :let @capture let $a = $b; $(stmts...) end let_node
```
outputs
```julia
┌ Info: function
│   #= REPL[9]:1 =# @capture ($(Expr(:$, :fn)))($(Expr(:$, :(args...)))) func_node =
│    Dict{Symbol,Any} with 2 entries:
│      :args => Any[:a, :b, :c]
└      :fn   => :f

┌ Info: let
│   #= REPL[10]:1 =# @capture let $(Expr(:$, :a)) = $(Expr(:$, :b))
        #= REPL[10]:1 =#
        $(Expr(:$, :(stmts...)))
    end let_node =
│    Dict{Symbol,Any} with 3 entries:
│      :a     => :a
│      :b     => :b
└      :stmts => Any[:(#= REPL[8]:1 =#), :(a + b)]
```