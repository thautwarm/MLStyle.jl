module MatchExt
import MLStyle.Match: pattern_match, PatternDef

pattern_match(num :: Number, guard, tag, mod :: Module) =
    if guard === nothing
        :($tag === $num)
    else
        :($tag === $num && $guard)
    end

pattern_match(str :: AbstractString, guard, tag, mod :: Module) =

    if guard === nothing
        :($tag === $str)
    else
        :($tag === $str && guard)
    end

pattern_match(sym :: Symbol, guard, tag, mod :: Module) =

        if sym === :_
            if nothing === guard
                quote true end
            else
                guard
            end
        else
            let ret =
                quote
                    $sym = $tag
                    true
                end
                if guard === nothing
                    ret
                else
                    :(ret && guard)
                end
            end
        end

# """
# like ^ in Erlang/Elixir
# """
PatternDef.Meta((expr :: Expr) -> expr.head == :&) do expr, guard, tag, mod
    value = expr.args[1]
    if guard === nothing
        :($tag === $value)
    else
        :($tag === $value && $guard)
    end
end

# """
# @match expr {
#     :: Ty => # do something if isa(expr, Ty)
#     x :: Ty => # do something if isa(expr, Ty) and perform capturing.
# }
# """

PatternDef.Meta((expr :: Expr -> expr.head == :(::))) do expr, guard, tag, mod
    args = expr.args
    len = length(args)
    check_ty =
        if len === 1
            :(isa($tag, $args[1]))
        else
            @assert len == 2
            pat, ty = args
            guard = pattern_match(pat, guard, tag, mod)
            :(isa($tag, $ty))
        end
    if guard == nothing
        :(check_ty && guard)
    else
        check_ty
    end
end

end
