module Render
using Base: get
export render, @format, format

struct Discard end
const discard = Discard()

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

function format(args, template)
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
    
    wrap = @static VERSION < v"1.1.0" ? (x -> x) : (x -> Expr(:call, merge, :(Base.@locals), x)) 
    Expr(:call, render, template, wrap(config))
end

function format(template)
    Expr(:call, render, template, :(Base.@locals))
end

macro format(args, template)
    esc(format(args, template))
end

macro format(template)
    esc(format(template))
end

end
