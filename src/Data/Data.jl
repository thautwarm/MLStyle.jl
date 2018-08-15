module Data
export List, Fun, Cons, Nil, Optional
include("TypedFn.jl")

using MLStyle.Data.TypedFn
using MLStyle.Err
using MLStyle

include("List.jl")
Optional{T} = Union{Some{T}, Nothing}


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

end
