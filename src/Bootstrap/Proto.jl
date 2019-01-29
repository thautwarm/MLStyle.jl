module Proto
using MLStyle.Prototype
using DataStructures

export @_match, @_λ, @_data, @linq, Many

eval(Expr(:(=), Symbol("@_match"), Symbol("@match")))
eval(Expr(:(=), Symbol("@_λ"), Symbol("@λ")))
eval(Expr(:(=), Symbol("@_data"), Symbol("@data")))



module Linq
    map(arr, f) = Base.map(f, arr)

    filter(arr, f) = Base.filter(f, arr)

    collect(arr) = Base.collect(arr)

    collect(arr, ::Type{T}) = Base.collect(T, arr)

    flat_map(arr, f) = Base.vcat(Base.map(f, arr)...)

    skip(arr) = Base.view(arr, 2:Base.length(arr))

    skip(arr, n) = Base.view(arr, n:Base.length(arr))

    len(arr) = Base.length(arr)

    drop(arr, n) = Base.view(arr, 1:(Base.length(arr) - n))

    sum(arr, f) = Base.sum(Base.map(f, arr))

    group_by(arr, f) = begin
        result = OrderedDict()
        for elt in arr
            push!(get!(result, f(elt)) do
                    []
                  end,
                  elt)

        end
        result
    end

    group_by(arr) = begin
        result = OrderedDict()
        for elt in arr
            push!(get!(result, elt) do
                    []
                  end,
                  elt)

        end
        result
    end

    any(arr, f) = Base.any(f, arr)
    any(arr) = Base.any(arr)

    all(arr, f) = Base.all(f, arr)
    all(arr) = Base.all(arr)

    enum(arr) = enumerate(arr)

    foldl(arr, f) = Base.foldl(f, arr)
    foldl(arr, f, init) = Base.foldl(f, arr, init=init)
    foldr(arr, f) = Base.foldr(f, arr)
    foldr(arr, f, init) = Base.foldr(f, arr, init=init)
    sort(arr) = Base.sort(arr)
    sort(arr, f) = Base.sort(arr, by=f)

end

function linq(expr)
    @match expr begin
        :($subject.$method($(args...))) =>
            let method = getfield(Linq, method),
                subject = linq(subject)

                quote $method($subject, $(args...)) end
            end
        :($subject.$method) =>
            let method = getfield(Linq, method),
                subject = linq(subject)

                quote $method($subject) end
            end
        _ => expr
    end
end

macro linq(expr)
    esc(linq(expr))
end


end