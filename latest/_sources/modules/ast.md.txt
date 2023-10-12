MLStyle.Modules.AST
==================================

@matchast
---------------------

- Description: Similar to `@match`, but the focus is on AST matching. There is no need to quote patterns with `quote ... end` or `:(...)`.
- Usage: `@matchast ast_to_match (begin cases... end)`
- Examples:

```julia
julia> @matchast :(1 + 1) quote
           $a + 1 => a + 2
       end
3
```
is equivalent to

```julia-console
julia> @match :(1 + 1) begin
           :($a + 1) => a + 2
       end
3
```


`Capture`
------------------------

`Capture` is a pattern, which could peek the scope(a `Dict{Symbol, T}`) at some point during the pattern matching. The scope only consists of the variables that MLStyle can aware of. Outer local variables and global variables cannot appear in the returned dictionary.

```julia-console
julia> @switch (1, 2, 3) begin
           @case (Capture(s1), Capture(s2), Capture(s3))
               println(s1)
               println(s2)
               println(s3)
       end       
Dict{Any,Any}()
Dict{Symbol,Dict{Any,Any}}(:s1 => Dict())
Dict{Symbol,Dict}(:s1 => Dict{Any,Any}(),:s2 => Dict{Symbol,Dict{Any,Any}}(:s1 => Dict()))
```

@capture
-------------------

- Description: Similar to `MacroTools.@capture`, but provides a more regex-flavored matching.

- Usage: `@capture template input_ast`,  note that `template` is purely static and cannot be a variable from current context.

- Examples:

```julia
func_node = :(f(a, b, c))
let_node = :(let a = b; a + b end)
@info :function @capture $fn($(args...)) func_node
@info :let @capture let $a = $b; $(stmts...) end let_node
```
outputs
```julia-console
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
