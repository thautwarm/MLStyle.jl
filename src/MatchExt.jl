module MatchExt
import MLStyle.Match: pattern_matching, register_meta_pattern


pattern_matching(num :: Number, guard, tag, mod :: Module) =
    if guard === nothing
        :($tag === $num)
    else
        :($tag === $num && $guard)
    end

pattern_matching(str :: String, guard, tag, mod :: Module) =

    if guard === nothing
        :($tag === $str)
    else
        :($tag === $str && guard)
    end


pattern_matching(sym :: Symbol, guard, tag, mod :: Module) =

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
register_meta_pattern((expr :: Expr) -> expr.head == :&) do expr, guard, tag, mod
    value = expr.args[1]
    if guard === nothing
        :($tag === $value)
    else
        :($tag === $value && $guard)
    end
end

# """
# ADT destruction
#
# @assert 2 == @match S(1, 2) {
#     S(1, b) => b
#     _       => @error
# }
#
# """
register_meta_pattern((expr :: Expr) -> expr.head == :call && Base.isidentifier(expr.head)) do expr, guard, tag, mod

    destructor = @eval mod $(expr.args[1])

    fields = fieldnames(destructor)

    args = expr.args[2:end]

    if length(args) != length(fields)
        DataTypeUsageError("Got patterns `$(repr(args))`, expected: `$fields`") |> throw
    end

    ret =
        map(zip(fields, args)) do (field, arg)
            pattern_matching(arg, nothing, :($tag.$field), mod)
        end |> last -> reduce((a, b) -> Expr(:&&, a, b), last, init=:(isa($tag, $destructor)))

    if guard !== nothing
        ret = :($ret && $guard)
    end

    ret
end


# """
# @match expr {
#     :: Ty => # do something if isa(expr, Ty)
#     x :: Ty => # do something if isa(expr, Ty) and perform capturing.
# }
# """
register_meta_pattern((expr :: Expr -> expr.head == :(::))) do expr, guard, tag, mod
    args = expr.args
    len = length(args)
    check_ty =
        if len === 1
            :(isa($tag, $args[1]))
        else
            @assert len == 2
            pat, ty = args
            guard = pattern_matching(pat, guard, tag, mod)
            :(isa($tag, $ty))
        end
    if guard == nothing
        :(check_ty && guard)
    else
        check_ty
    end
end


register_meta_pattern((expr :: Expr -> expr.head in (:braces, :bracescat))) do expr, guard, tag, mod
    args = expr.args
    
    # TODO: Not Implemented
end

end
