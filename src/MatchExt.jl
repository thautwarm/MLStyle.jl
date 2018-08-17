module MatchExt
import MLStyle: Feature
import MLStyle.Match: pattern_match, PatternDef
export (..), enum_next
function enum_next(x :: Number)
    x + 1
end

function (..)(predicate, start :: T, _end :: T) where T
    while start < _end
        if predicate(start)
            return true
        end
        start = enum_next(start)
    end
    false
end

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
        :($tag === $str && $guard)
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
                    :($ret && $guard)
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
# tuple pattern
# """
PatternDef.Meta(expr :: Expr -> expr.head == :tuple) do expr, guard, tag, mod
    args = expr.args
    len = length(args)

    if len !== 0
        check_len = :($length($tag) === $len)
        matching = map(zip(1:len, args)) do (idx, arg)
            pattern_match(arg, nothing, :($tag[$idx]), mod)
        end |>
        function (last)
            reduce((a, b) -> Expr(:&&, a, b), last)
        end |>
        function(last)
            :($check_len && $last)
        end
    else
        :($isempty($tag))
    end |>
    function (last)
        if guard !== nothing
            :($last && $guard)
        else
            last
        end
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

    annotation_processing(arg) =
        if Feature.is_activated(:TypeLevel, mod)
            pattern_match(arg, nothing, :($typeof($tag)), mod)
        else
            :($isa($tag, $(arg)))
        end

    check_ty =
        if len === 1
            annotation_processing(args[1])
        else
            @assert len === 2
            pat, ty = args
            let guard = pattern_match(pat, nothing, tag, mod)
                annotation_processing(ty) |>
                function (last)
                    if guard === nothing
                        last
                    else
                        :($last && $guard)
                    end
                end
            end
        end
    if guard === nothing
        check_ty
    else
        :($check_ty && $guard)
    end
end

PatternDef.App(..) do args, guard, tag, mod

    start, _end = args
    quote
        let value = $tag
        ($..)($start, $_end) do it
            it === value
        end
        end
    end

end

end
