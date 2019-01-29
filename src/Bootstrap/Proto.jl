module Proto
using MLStyle.Prototype

export @_match, @_λ, @_data, @linq, Many

eval(Expr(:(=), Symbol("@_match"), Symbol("@match")))
eval(Expr(:(=), Symbol("@_λ"), Symbol("@λ")))
eval(Expr(:(=), Symbol("@_data"), Symbol("@data")))


macro linq(expr)
    @match expr begin
        :($subject.$method($(args...))) =>
                quote $method($(args...), $subject) end
        _ => @error "invalid"
    end
end


end