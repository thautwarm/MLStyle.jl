module Private

export get_most_union_all, ast_and, ast_or

function get_most_union_all(expr, mod :: Module)
    if isa(expr, Expr) && expr.head == :curly
        get_most_union_all(expr.args[1], mod)
    else
        @eval mod $expr
    end
end

ast_and(a, b) =  Expr(:&&, a, b)
ast_or(a, b) = Expr(:||, a, b)


isCapitalized(s :: AbstractString) :: Bool = !isempty(s) && isuppercase(s[1])


end


