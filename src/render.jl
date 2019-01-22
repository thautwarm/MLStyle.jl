module Render
using MLStyle.toolz
using Base: get
export render, @format, format
function render(expr::Expr, config :: Dict{Symbol, Any}, nested=true)
    hd_f = return!
    function tl_f(expr :: Any)
        if expr isa LineNumberNode
            return! $ nothing
        elseif expr isa Symbol
            yieldAst $
            get(config, expr) do
                expr
            end
        elseif expr isa Expr
           if nested
               expr = render(expr, config, nested)
           end
           yieldAst $ expr
        else
           yieldAst $ expr
        end
    end
    runAstMapper $ mapAst(hd_f, tl_f, expr)
end

function render(sym::Symbol, config :: Dict{Symbol, Any}, nested=true)
    get(config, sym) do
        sym
    end
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
        @assert arg isa Symbol
        value = arg.args[2]
        Expr(:call, :(=>), QuoteNode(sym), value)
    end
    constlist = map(dispatch, args.args)
    constlist = Expr(:vect, constlist...)
    config = Expr(:call, Dict{Symbol, Any}, constlist)
    Expr(:call, render, template, config)
end

macro format(args, template)
    esc(format(args, template))
end

end
