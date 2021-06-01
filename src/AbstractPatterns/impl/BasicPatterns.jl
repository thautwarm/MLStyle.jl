module BasicPatterns
using MLStyle.AbstractPatterns
using MLStyle.AbstractPatterns.RedyFlavoured

export P_bind,
    P_tuple, P_type_of, P_vector, P_capture, P_vector3, P_slow_view, P_fast_view
export P_svec, P_svec3
export SimpleCachablePre, see_captured_vars, see_captured_vars!

const EQ = 0b001
const GT = 0b100
const LT = 0b010

@nospecialize
OptionalLn = Union{LineNumberNode, Nothing}

function see_captured_vars(inner::Any, in_scope::ChainDict{Symbol, Symbol})
    bind = Expr(:block)
    for_chaindict(in_scope) do k, v
        push!(bind.args, :($k = $v))
    end
    isempty(bind.args) ? inner : Expr(:let, bind, inner)
end

function see_captured_vars!(inner::Any, in_scope::ChainDict{Symbol, Symbol})
    bind = Expr(:block)
    for_chaindict(in_scope) do k, v
        if k !== v
            assign = :($k = $v)
            push!(bind.args, assign)
        end
    end
    isempty(bind.args) ? inner : Expr(:let, bind, inner)
end

struct SimpleCachablePre <: APP
    f::Function
end
(f::SimpleCachablePre)(target) = f.f(target)

function sequence_index(viewed, i::Integer, ::Any, ::Any)
    :($viewed[$i])
end

function self_index(viewed, i::Integer, ::Any, ::Any)
    @assert i === 1
    viewed
end

function length_eq_check(seq, n::Int)
    if n === 0
        :(isempty($seq))
    else
        :(length($seq) === $n)
    end
end

function mk_type_object(i::Int, ::Type{T}) where {T}
    if isabstracttype(T)
        TypeVar(Symbol(:var, i), T)
    else
        T
    end
end

"""match by type
"""
function P_type_of(t, prepr::AbstractString = "isa $t")
    recog_type() = t
    comp = PComp(prepr, recog_type)
    decons(comp, [])
end

"""bind a symbol
"""
function P_bind(n::Symbol, expr::Any; see_capture = false)
    function bind_effect!(target, scope::ChainDict{Symbol, Symbol}, ln::OptionalLn)
        expr′ = see_capture ? see_captured_vars(expr, scope) : expr
        n′ = scope[n] = gensym(n)
        :($n′ = $expr′)
    end
    effect(bind_effect!)
end

"""bind a symbol
"""
function P_capture(n::Symbol)
    function capture_effect!(target, scope::ChainDict{Symbol, Symbol}, ln::OptionalLn)
        if target isa Symbol
            scope[n] = target
            return nothing
        end
        n′ = scope[n] = gensym(n)
        :($(n′) = $target)
    end
    effect(capture_effect!)
end

"""deconstruct a tuple
"""
function P_tuple(fields::AbstractArray, prepr::AbstractString = "Tuple")
    function type_of_tuple(xs...)
        ts = [mk_type_object(i, xs[i]) for i in eachindex(xs)]
        foldl(ts, init = Tuple{ts...}) do last, t
            t isa TypeVar ? UnionAll(t, last) : last
        end
    end
    comp = PComp(prepr, type_of_tuple)

    decons(comp, sequence_index, fields)
end

function type_of_vector(types...)
    AbstractArray
end
"""deconstruct a vector
"""
function P_vector(fields::AbstractArray, prepr::AbstractString = "1DVector")
    n_fields = length(fields)

    function pred(target)
        length_eq_check(target, n_fields)
    end
    comp = PComp(prepr, type_of_vector; guard1 = NoncachablePre(pred))
    decons(comp, sequence_index, fields)
end

"""deconstruct a vector
"""
function P_svec(fields::AbstractArray, prepr::AbstractString = "svec")
    function type_of_svec(_...)
        Core.SimpleVector
    end
    n_fields = length(fields)
    function pred(target)
        :(ndims($target) === 1 && length($target) === $n_fields)
    end
    comp = PComp(prepr, type_of_svec; guard1 = NoncachablePre(pred))
    decons(comp, sequence_index, fields)
end

"""deconstruct a vector in this way: [a, b, c, pack..., d, e]
"""
function P_vector3(
    init::AbstractArray,
    pack::Function,
    tail::AbstractArray,
    prepr::AbstractString = "1DVector Pack",
)
    n1 = length(init)
    n2 = length(tail)
    min_len = length(init) + length(tail)
    function extract(arr, i::Int, ::Any, ::Any)
        ex = if i <= n1
            :($arr[$i])
        elseif i === n1 + 1
            n2 === 0 ? :($SubArray($arr, ($(n1 + 1):length($arr),))) :
            :($SubArray($arr, ($(n1 + 1):length($arr)-$n2,)))
        else
            incr = i - n1 - 1
            j = n2 - incr
            ex = j == 0 ? :($arr[end]) : :($arr[end-$j])
            :($ex)
        end
    end
    function pred(target)
        :(ndims($target) === 1 && length($target) >= $min_len)
    end
    comp = PComp(prepr, type_of_vector; guard1 = NoncachablePre(pred))
    decons(comp, extract, [init; pack; tail])
end

"""deconstruct a vector in this way: [a, b, c, pack..., d, e]
"""
function P_svec3(
    init::AbstractArray,
    pack::Function,
    tail::AbstractArray,
    prepr::AbstractString = "svec Pack",
)
    n1 = length(init)
    n2 = length(tail)
    min_len = length(init) + length(tail)
    function type_of_svec(types...)
        Core.SimpleVector
    end
    function extract(arr, i::Int, ::Any, ::Any)
        if i <= n1
            :($arr[$i])
        elseif i === n1 + 1
            n2 === 0 ? :($arr[$(n1 + 1):end]) : :($arr[$(n1 + 1):end-$n2])
        else
            incr = i - n1 - 1
            j = n2 - incr
            j == 0 ? :($arr[end]) : :($arr[end-$j])
        end
    end
    function pred(target)
        :(length($target) >= $min_len)
    end
    comp = PComp(prepr, type_of_svec; guard1 = NoncachablePre(pred))
    decons(comp, extract, [init; pack; tail])
end

"""untyped view pattern
"""
function P_slow_view(trans, p::Function, prepr::AbstractString = "ViewBy($trans)")
    function type_of_slow_view(args...)
        Any
    end

    comp = PComp(prepr, type_of_slow_view; view = SimpleCachablePre(trans))
    decons(comp, self_index, [p])
end

"""typed view pattern
"""
function P_fast_view(
    tcons,
    trans,
    p::Function,
    prepr::AbstractString = "ViewBy($trans, typecons=$tcons)",
)
    comp = PComp(prepr, tcons; view = SimpleCachablePre(trans))
    decons(comp, self_index, [p])
end

@specialize
end
