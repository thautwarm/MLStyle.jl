module MatchExt
import MLStyle: Feature, (⇒), Fun
import MLStyle.Match: pattern_match, PatternDef

using MLStyle.Private
using MLStyle.Err
using MLStyle

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

# """
#  [a, b, c, d..., e, f, g] => ...
# """
PatternDef.Meta(expr::Expr -> expr.head == :vect) do expr, guard, tag, mod
    args = expr.args
    if length(args) == 0
        return :($isempty($tag)) |>
                last ->
                if guard === nothing
                    last
                else
                    :($last && $guard)
                end
    end

    atleast_element_count = 0
    unpack_begin = nothing
    unpack_end = 0
    unpack = []
    foreach(args) do arg
        if isa(arg, Expr) && arg.head === :...
            if unpack_begin === nothing
                unpack_begin = atleast_element_count + 1
             else
                SyntaxError("Vector unpack can only perform sequential unpack at most once.") |> throw
            end
            push!(unpack, arg.args[1])
        else
            atleast_element_count = atleast_element_count + 1
            if unpack_begin !== nothing
                push!(unpack, pattern_match(arg, nothing, :($tag[end-$unpack_end]), mod))
                unpack_end = unpack_end + 1
            else
                push!(unpack, pattern_match(arg, nothing, :($tag[$atleast_element_count]), mod))
            end
        end
    end

    if unpack_begin !== nothing
        arg = unpack[unpack_begin]
        unpack[unpack_begin] = pattern_match(arg, nothing, :($view($tag, $unpack_begin:($length($tag) - $unpack_end))), mod)
        reduce(unpack, init=:($length($tag) >= $atleast_element_count)) do last, each
            :($last && $each)
        end
    else
        reduce(unpack, init=:($length($tag) == $atleast_element_count)) do last, each
            :($last && $each)
        end
    end
end
# """
# Feature.@activate TypeLevel
# @match Int ⇒ Int begin
#     ::(T ⇒ G) => (T, G)
# end # => (Int, Int)
# """
PatternDef.Meta(expr :: Expr -> expr.head == :curly) do expr, guard, tag, mod

    if !Feature.is_activated(:TypeLevel, mod)
        :($tag isa $expr)
    else
        @match expr.args begin
            [head, tail...] =>
            begin
                len = length(tail)

                pat1 = pattern_match(head, nothing, tag, mod)

                patn = map(enumerate(tail)) do (idx, each)
                    pattern_match(each, nothing, :($tag.parameters[$idx]), mod)
                end |> last -> reduce(ast_and, last, init = :($length($tag.parameters) == $len))

                :($pat1 && $patn)
            end
            _ => SyntaxError("$(string(expr))") |> throw
        end
    end
end

# """
# @match 1 {
#     1..10   in x => x
#     11..20  in x => x * 10
# }
# """
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

PatternDef.App(⇒) do args, guard, tag, mod
    from, to = args
    pat1 = pattern_match(from, nothing, :($tag.parameters[1]), mod)
    pat2 = pattern_match(to,   nothing, :($tag.parameters[2]), mod)
    :($tag <: $Fun && $pat1 && $pat2)
end



end
