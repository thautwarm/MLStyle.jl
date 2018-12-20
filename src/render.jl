module Render
using MLStyle.toolz
using Base: get
export render, @format
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

macro format(args, template)
    constlist = [Expr(:call, :(=>), QuoteNode(arg), arg) for arg in args.args if arg isa Symbol]
    constlist =  Expr(:vect, constlist...)
    config    =  Expr(:call, Dict{Symbol, Any}, constlist)
    esc(Expr(:call, render, template, config))
end

end
