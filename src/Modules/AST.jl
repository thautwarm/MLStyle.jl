module AST
using MLStyle
using MLStyle.Render
using MLStyle.Err
include("AST.Compat.jl")
export @matchast, @capture

function matchast(target, actions, source, mod::Module)
    stmts = @match actions begin
       Expr(:quote, quote $(stmts...) end) => stmts

       _ => begin
            msg = "Malformed ast template, the second arg should be a block with a series of pairs(`a => b`), at $(string(source))."
            throw(SyntaxError(msg))
        end
    end
    last_lnode = source
    map(stmts) do stmt
        @match stmt begin
            ::LineNumberNode => (last_lnode = stmt)
            :($a => $b) => :($(Expr(:quote, a)) => $b)
            _ => throw(SyntaxError("Malformed ast template, should be formed as `a => b`, at $(string(last_lnode))."))
        end
    end |> actions ->
    gen_match(target, Expr(:block, actions...), source, mod)
end

"""
An eye candy of `@match` for AST matching.

e.g.,

```julia
    @matchast :(1 + 1) quote
        \$a + 1 => a
    end # 1

    @matchast :(f(a, b)) quote
        \$(Expr(:call, :f, :a, :b)) =>
         dosomething
    end
```
"""
macro matchast(template, actions)
    matchast(template, actions, __source__, __module__) |> esc
end

"""
@capture template
@capture template expr

Template matching for expressions.

```julia
julia> @capture f(\$x)  :(f(2))
Dict{Symbol,Int64} with 1 entry:
  :x => 2
```

If the template doesn't match input AST, return `nothing`.
"""
:(@capture)

macro capture(template)
    capture(template, __source__, __module__) |> esc
end

macro capture(template, ex)
    Expr(:call, capture(template, __source__, __module__), ex) |> esc
end

function capture(template, source, mod::Module)
    out_expr = @static VERSION < v"1.1.0" ?
        begin
            syms = Set(Symbol[])
            capturing_analysis(template, syms, true)
            Expr(:call, Dict, (Expr(:call, =>, QuoteNode(each), each) for each in syms)...)
        end :
        :($Base.@locals)

    arg_sym = gensym()
    let template = Expr(:quote, template),
        actions = Expr(:block, :($template => $out_expr), :(_ => nothing)),
        match_gen = gen_match(arg_sym, actions, source, mod)
        @format [arg_sym, match_gen] quote
            function (arg_sym)
                match_gen
            end
        end
    end
end

end
