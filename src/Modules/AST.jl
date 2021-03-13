module AST
using MLStyle
using MLStyle.AbstractPatterns
using MLStyle.Err
export @matchast, @capture, Capture

@nospecialize
struct Capture end

function MLStyle.pattern_uncall(
    ::Type{Capture},
    self::Function,
    type_params::AbstractArray,
    type_args::AbstractArray,
    args::AbstractArray,
)
    isempty(type_params) || error("A Capture requires no type params.")
    isempty(type_args) || error("A Capture pattern requires no type arguments.")
    length(args) === 1 || error("A Capture pattern accepts one argument.")
    function extract(::Any, ::Int, scope::ChainDict{Symbol, Symbol}, ::Any)
        ret = Expr(:call, Dict)
        for_chaindict(scope) do k, v
            k = QuoteNode(k)
            push!(ret.args, :($k => $v))
        end
        ret
    end
    decons(extract, [self(args[1])])
end

function matchast(target, actions, source::LineNumberNode, mod::Module)
    @switch actions begin
        @case Expr(:quote, Expr(:block, stmts...))
        last_lnode = source
        cbl = Expr(:block)
        for stmt in stmts
            @switch stmt begin
                @case ::LineNumberNode
                last_lnode = stmt
                continue
                @case :($a => $b)
                push!(cbl.args, last_lnode, :($(Expr(:quote, a)) => $b))
                continue
                @case _
                throw(
                    SyntaxError(
                        "Malformed ast template, should be formed as `a => b`, at $(string(last_lnode)).",
                    ),
                )
            end
        end
        return gen_match(target, cbl, source, mod)
        @case _
        msg = "Malformed ast template, the second arg should be a block with a series of pairs(`a => b`), at $(string(source))."
        throw(SyntaxError(msg))
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
    res = matchast(template, actions, __source__, __module__)
    res = init_cfg(res)
    return esc(res)
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
    farg = gensym("expression")
    fbody = gen_capture(template, farg, __source__, __module__) |> init_cfg
    fhead = Expr(:call, farg, farg)
    esc(Expr(:function, fhead, fbody))
end

macro capture(template, ex)
    res = gen_capture(template, ex, __source__, __module__)
    res = init_cfg(res)
    return esc(res)
end

function gen_capture(template::Any, ex::Any, source::LineNumberNode, mod::Module)
    template = Expr(:quote, template)
    sym = :__SCOPE_CAPTURE__
    p_capture_scope = Expr(:call, Capture, sym)
    p_whole = Expr(:&&, template, p_capture_scope)
    tbl = Expr(:block, :($p_whole => $sym))

    gen_match(ex, tbl, source, mod)
end
@specialize
end
