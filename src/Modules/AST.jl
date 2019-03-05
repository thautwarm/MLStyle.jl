module AST
using MLStyle
using MLStyle.Render

export @matchast, @capture

function matchast(target, actions)
    (@match actions begin
       Expr(:quote,
            quote
                $(stmts...)
            end
       ) => stmts
    end) |> stmts ->
    map(stmts) do stmt
        @match stmt begin
            ::LineNumberNode => stmt
            :($a => $b) => :($(Expr(:quote, a)) => $b)
        end
    end |> actions ->
    quote
        $MLStyle.@match $target begin
            $(actions...)
        end
    end
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
    matchast(template, actions) |> esc
end


function capturing_analysis(expr, out, is_literal)

    @match expr begin
        ::QuoteNode =>
             capturing_analysis(expr.value, out, true)

        if is_literal end && Expr(:$, args...) =>

            foreach(x -> capturing_analysis(x, out, false), args)

        if is_literal end && Expr(_, args...) =>

            foreach(x -> capturing_analysis(x, out, true), args)


        if is_literal end && _ => nothing


        # not literal
        ::Symbol => (push!(out, expr); nothing)

        Expr(:quote, args...) =>
            foreach(x -> capturing_analysis(x, out, true), args)

        :(Do($(args...))) =>
            foreach(args) do arg
                @match arg begin
                    Expr(:kw, key :: Symbol, value) =>
                        begin
                            push!(out, key)
                        end
                    _ => nothing
                end
            end
        :($a || $b) =>
        let out1 = Set(Symbol[]),
            out2 = Set(Symbol[])

            capturing_analysis(a, out1, false)
            capturing_analysis(b, out2, false)

            union!(out, intersect(out1, out2))
            nothing
        end
        # type pattern
        Expr(:(::), a, _) => capturing_analysis(a, out, false)
        # dict pattern
        :(Dict($(args...))) =>
            foreach(args) do arg
                @match arg begin
                    :($_ => $v) => capturing_analysis(v, out, false)
                    _ => nothing
                end
            end
        # app pattern
        :($_($(args...))) => foreach(x -> capturing_analysis(x, out, false), args)
        # other expr
        Expr(_, args...) => foreach(x -> capturing_analysis(x, out, false), args)
        # ref pattern
        Expr(:&, _)              ||
        # predicate
        Expr(:function, _...)    ||
        Expr(:if, _...)          ||
        x => nothing
    end
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
    capture(template) |> esc
end

macro capture(template, ex)
    Expr(:call, capture(template, __source__), ex) |> esc
end

function capture(template, source = LineNumberNode(@__LINE__))
    out_expr = @static VERSION < v"1.1.0" ?
        begin
            syms = Set(Symbol[])
            capturing_analysis(template, syms, true)
            Expr(:call, Dict, (Expr(:call, =>, QuoteNode(each), each) for each in syms)...)
        end :
        :($Base.@locals)

    arg_sym = gensym()
    let template = Expr(:quote, template)
        @format [arg_sym, template, out_expr, source] quote
            function (arg_sym)
                $MLStyle.@match source arg_sym begin
                    template => out_expr
                    _ => nothing
                end
            end
        end
    end
end

end
