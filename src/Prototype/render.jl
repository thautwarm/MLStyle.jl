module Render
using MLStyle.Prototype.toolz
using Base: get
export render, @format, format

struct Discard end
discard = Discard()

function render(expr, pair :: Pair{Symbol, Any})
    render(expr, Dict(pair))
end

function render(expr, config :: Dict{Symbol, Any})
    function visit(expr :: Expr)
        hd = expr.head
        tl = filter(x -> x !== discard, map(visit, expr.args))
        Expr(hd, tl...)
    end

    function visit(sym :: Symbol)
        get(config, sym) do
            sym
        end
    end

    function visit(:: LineNumberNode)
        discard
    end

    function visit(a)
        a
    end

    visit(expr)
end

function fmt(args, template)
    function dispatch(arg :: Symbol)
        Expr(:call, :(=>), QuoteNode(arg), arg)
    end

    function dispatch(arg :: Pair)
        Expr(:call, :(=>), QuoteNode(arg[1]), arg[2])
    end

    function dispatch(arg :: Expr)
        @assert arg.head == :(=)
        sym = arg.args[1]
        @assert sym isa Symbol "$sym"
        value = arg.args[2]
        Expr(:call, :(=>), QuoteNode(sym), value)
    end
    function  dispatch(_)
        throw("Unknown argtype")
    end
    constlist = map(dispatch, args.args)
    constlist = Expr(:vect, constlist...)
    config = Expr(:call, Dict{Symbol, Any}, constlist)
    Expr(:call, render, template, config)
end

function fmt(template)
    Expr(:call, render, template, :(Base.@locals))
end

format = fmt

macro format(args, template)
    esc(format(args, template))
end

end
