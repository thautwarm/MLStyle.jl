module List
export List!, Cons, Nil
using MLStyle
using MLStyle.Data
import Base: ^, map, foreach, iterate, isempty, getindex

@data List!{T} begin
    Nil{T}
    Cons{T}(head :: T, tail :: List!{T})
end

# NO SFINAE in Julia...

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


function List!(args :: Vararg{T, N}) where {T, N}
    ret = Nil{T}()
    for i = 0:N-1
        ret = Cons{T}(args[end - i], ret)
    end
    ret
end

function (::Type{List!{T1}})(args :: Vararg{T2, N}) where {T1, T2, N}
    T =
        if T1 === Any && T2 !== Any
            T2
        else
            T1
        end

    ret = Nil{T}()

    for i = 0:N-1
        ret = Cons{T}(args[end - i], ret)
    end
    ret
end

List!(args...) =
    begin
        ret = Nil{Any}()
        for i = 0:length(args)-1
            ret = Cons{Any}(args[end - i], ret)
        end
        ret
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

function _match(args, guard, tag, mod)
    l, r = args

    let l    = pattern_match(l, nothing, :($tag.head), mod),
        tail = :($tag.tail),
        r    = if isa(r, Expr) && r.head == :call && r.args[1] === :^
                   _match(r.args[2:end], nothing, tail, mod)
               else
                   pattern_match(r, nothing, tail, mod)
               end

        :($l && $r)

    end |>
    function (last)
        if guard === nothing
            last
        else
            :($last && $guard)
        end
    end
end

PatternDef.App(^) do args, guard, tag, mod
    check_ty = :($isa($tag, $Cons))
    _match(args, nothing, tag, mod) |>
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

function head(lst :: Cons{T}) :: T where T
    lst.head
end

function head(lst :: Nil{T}) where T
    ArgumentError("Cannot get head from zero sized list.") |> throw
end

function try_head(lst :: Cons{T}) where T
    Some{T}(lst.head)
end

function try_head(lst :: Nil{T}) where T
    nothing
end

function tail(lst :: Cons{T}) where T
    lst.tail
end

function tail(lst :: Nil{T}) where T
    ArgumentError("Cannot get tail from zero sized list.") |> throw
end

function try_tail(lst :: Cons{T}) where T
    Some{T}(lst.tail)
end

function try_tail(lst :: Nil{T}) where T
    nothing
end

end
