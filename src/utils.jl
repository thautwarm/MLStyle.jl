module Private
export get_most_union_all
function get_most_union_all(expr, mod :: Module)

    if isa(expr, Expr) && expr.head == :curly
        get_most_union_all(expr.args[1], mod)
    else
        @eval mod $expr
    end
    
end

end
