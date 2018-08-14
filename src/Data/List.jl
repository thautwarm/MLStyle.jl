module List
export List!, Cons, Nil
using MLStyle
using MLStyle.Data
import Base: ^, map, foreach, iterate, isempty

@data List!{T} begin
    Nil{T}
    Cons{T}(head :: T, tail :: List!{T})
end

# not to overload convert,

Base.convert(::Type{List!{G}}, it :: Nil{T}) where {G, T <: G} = Nil{G}()

Base.convert(::Type{List!{G}}, it :: Cons{T}) where {G, T <: G} =
    Cons{G}(
        convert(G, it.head),
        convert(List!{G}, it.tail))

Cons(head :: T, tail :: List!{G}) where {G, T} =
    Cons{typejoin(T, G)}(head, tail)

function (^)(head :: T, tail :: List!{G}) where {G, T}
    Cons{typejoin(T, G)}(head, tail)
end

Nil() = Nil{Any}()

Base.iterate(lst :: List!{T}) where T =
    iterate(lst, lst)

function Base.iterate(::List!{T}, lst :: List!{T})::Union{Nothing, Tuple{T, List!{T}}} where T
    @match lst begin
        Nil{T}()      => nothing
        Cons{T}(a, b) => (a, b)
    end
end

function Base.map(fn :: Fun{T, R}, lst :: List!{T}) :: List!{R} where {T, R}
    ret = Nil{R}()
    for each in lst
       ret = Cons{R}(fn(each), ret)
    end
    ret
end


function Base.map(fn :: Function, lst :: List!{T}) :: List! where T

    ret = Nil()
    for each in lst
        ret = Cons(fn(each), ret)
    end
    ret

end

function Base.foreach(fn :: Fun{T, R}, lst :: List!{T}) :: Nothing where {T, R}
    for each in lst
        fn(each)
    end
end

function Base.foreach(fn :: Function, lst :: List!{T}) :: Nothing  where T
    for each in lst
        fn(each)
    end
end


function _flatten_cons_marker(ast :: Expr, res :: Vector)
    if ast.head === :call && ast.args[1] === :^
        push!(res, ast.args[2])
        _flatten_cons_marker(ast.args[3], res)
    else
        push!(res, ast)
    end
end

function _flatten_cons_marker(ast :: Symbol, res :: Vector)
    push!(res, ast)
end

function _flatten_cons_marker(ast)
    if isa(ast, Expr)
        res = []
        _flatten_cons_marker(ast, res)
    else
        [ast]
    end
end

PatternDef.App(^) do args, guard, tag, mod

    check_ty = :($isa($tag, $Cons))

    l, r = args

    rs = _flatten_cons_marker(r)

    let l = pattern_match(l, nothing, :($tag.head), mod),
        r = map(rs) do r
                pattern_match(r, nothing, :($tag.tail), mod)
            end |>
            function (last)
                reduce((a, b) -> Expr(:&&, a, b), last)
            end
        :($check_ty && $l && $r)
    end |>

    function (last)
        if guard === nothing
            last
        else
            :($last && $guard)
        end
    end

end


# TODO:
# Base.reduce, Base.flatmap, Base.all, Base.any, Base.isempty, Base.copy
# head, tail, find, take, zip...

function isempty(lst :: Cons{T}) where T
    false
end

function isempty(lst :: Nil{T}) where T
    true
end

end
