module ArbitrarySampler
export get_sample, @spec, generate
using MLStyle
import InteractiveUtils: subtypes
# for typed test generator

struct Iterator{T}
    f :: Function
end

function next_item!(iter::Iterator{T}):: Union{Nothing, Some{T}} where T
    e  = iter.f() :: Union{Nothing, Some{<:T}}
    e === nothing && return nothing
    e.value isa T && return e
    Some{T}(e.value)
end

function take_all!(iter::Iterator{T})::Vector{T} where T
    xs = T[]
    while (a = next_item!(iter); a !== nothing)
        push!(xs, a.value)
    end
    return xs
end

function take_n!(iter::Iterator{T}, n :: Int)::Vector{T} where T
    xs = T[]
    while (a = next_item!(iter); a !== nothing && length(xs) < n)
        push!(xs, a.value)
    end
    return xs
end

abstract type SeqElt{T}  end
abstract type Spec{T} end

→(A, B) = Function

@data SeqElt{T} begin
    One(Spec{T})
    Ellipsis(Spec{Vector{T}})
end

@data Spec{T} begin
    S_of{T}           :: (() → T)           => Spec{T}
    S_modif{T}        :: ((T → T), Spec{T}) => Spec{T}
    S_rep_of{T}       :: Spec{T}            => Spec{Iterator{T}}
    S_app{F}          :: (f, args)          => Spec{F}
    S_tp{Tp <: Tuple} :: tup                => Spec{Tp} where
      { Tp = Tuple{map(get_spec_type, tup)...} }

    S_guard{T}  :: (filter::(T → Bool), spec::Spec{T}) => Spec{T}
    S_map{A, B} :: (f::(A → B), spec::Spec{A})         => Spec{B}
    S_or{A, B}  :: (Spec{A}, Spec{B})                  => Spec{Union{A, B}}

    S_vec_of{T} :: (xs::Vector{SeqElt})                => Spec{Vector{T}} where
      { T =  isempty(xs) ? Any : reduce(typejoin, map(get_elt_type, xs)) }
end

S_tp(hd, args...) = S_tp((hd, args...))
get_spec_type(::Spec{T}) where T = T
get_elt_type(::SeqElt{T}) where T = T

function int_mod(n::Int, spec::Spec{Int})
    function modify(orig::Int)::Int
        orig % n
    end
    S_modif(modify, spec)
end

@nospecialize
function _take_method_arg_type(t)
    while t isa UnionAll
        t = t.body
    end
    t = t.parameters[2].parameters[1]
    while t isa TypeVar
        t = t.ub
    end
    return t
end
@specialize

get_subtypes(t) = get_subtypes(Val(Base.get_world_counter()), t)
@generated function get_subtypes(::Val{WorldAge}, ::Type{T}) where {WorldAge, T}
    subtypes(T)
end

get_registered_types() = get_registered_types(Val(Base.get_world_counter()))
@generated function get_registered_types(::Val{WorldAge}) where WorldAge
    meths = methods(get_sample)
    Any[_take_method_arg_type(m.sig) for m in meths.ms]
end

get_registered_datatypes() = get_registered_datatypes(Val(Base.get_world_counter()))
@generated function get_registered_datatypes(::Val{WorldAge}) where WorldAge
    regs = get_registered_types(Val(WorldAge))
    DataType[t for t in regs if t isa DataType]
end

function _get_all_concrete!(sup, cts::Set)
    if isabstracttype(sup)
        if Core.Compiler.unwrap_unionall(sup).name.module === Core
            push!(cts, sup)
        end
        for sub in get_subtypes(sup)
            _get_all_concrete!(sub, cts)
        end
    else
        if Core.Compiler.unwrap_unionall(sup).name.module === Core
            push!(cts, sup)
        end
    end
end
const Cores = Set{Any}([BigFloat, BigInt])
_get_all_concrete!(Real, Cores)

rand′(x) = rand(x)
rand′(::Type{BigInt}) = BigInt(rand(Int))
rand′(::Type{<:Irrational}) = pi
rand′(::Type{<:Irrational}) = pi
rand′(::Type{Complex}) =
    let T = rand([Int, Float64])    
        rand(Complex{T})
    end
rand′(::Type{Rational}) =
    let T = rand([Integer])
        get_sample(T) // (abs(get_sample(T)) + 1)
    end

function _get_sample_generic(x)
    regs = get_registered_types()
    if isabstracttype(x)
        possible = [t for t in get_subtypes(x) if t in Cores || t in regs]
        isempty(possible) && return nothing
        return get_sample(rand(possible))
    else
        (x in Cores || x in regs) && return rand′(x)
        return nothing
    end
end

get_sample(::Type{Complex}) = rand′(Complex)
function get_sample(::Type{T}) where T <: Real
    ret = _get_sample_generic(T)
    ret === nothing && error("cannot find random generator for $T.")
    return ret
end
get_sample(::Type{String}) =
    String([rand('0':'z')  for i in 1:get_sample(Int) % 100])
get_sample(::Type{Symbol}) =
    Symbol(String([rand('0':'z')  for i in 1:get_sample(Int) % 7]))

function get_sample(::Type{DataType})
    dts = get_registered_datatypes()
    dts[rand(1:length(dts))]
end

function get_sample(::Type{Any})
    get_sample(rand(get_registered_types()))
end

function generate(spec::Spec{T})::T where T
    @switch spec begin
        @case S_of(gen)
            return gen()

        @case S_or(a, b)
            return rand(Bool) === true ?
                generate(a) :
                generate(b)

        @case S_modif(modif, spec)
            return modif(generate(spec))

        @case S_rep_of{A}(unit) where A
            # infinite generator
            return Iterator{A}() do
                return Some(generate(unit))
            end
        
        @case S_app(f, args)
            return f(generate(args)...)

        @case S_tp(tup)
            tp = Any[]
            for e in tup
                push!(tp, generate(e))
            end
            return Tuple(tp)
        
        @case S_guard(filt, spec)
            a = nothing
            while (a = generate(spec); !filt(a))
            end
            return a

        @case S_map(f, spec)
            a = generate(spec)
            return f(a)

        @case S_vec_of{G}(elts) where G
            ret = G[]
            for each in elts
                @switch each begin
                    @case One(spec)
                        push!(ret, generate(spec))
                        continue
                    @case Ellipsis(spec)
                        append!(ret, generate(spec))
                end
            end
            return ret
    end
end

const any_spec = S_of{Any}() do
    get_sample(Any)
end

const sym_spec = S_of{Symbol}() do
    get_sample(Symbol)
end

function gen_spec(s, __module__::Module)
    S_of{typeof(s)}() do
        s
    end
end

function gen_spec(s::QuoteNode, __module__::Module)
    s.value isa Symbol && return let s=s.value
            S_of{Symbol}() do
                s
            end
    end
        
    gen_spec(s.value)
end

function gen_spec(s::Symbol, __module__::Module)
    if s === :_
        return any_spec
    end
    error("Only '_' is a supported Symbol for spec syntax so far.")
end


function qt2ex(ex::Any)
    if ex isa Expr
        Meta.isexpr(ex, :$) && return ex.args[1]
        ret = Expr(:call)
        push!(ret.args, Expr, QuoteNode(ex.head))
        for each in ex.args
            if each isa LineNumberNode
                continue
            end
            push!(ret.args, qt2ex(each))
        end
        ret
    elseif ex isa Symbol
        QuoteNode(ex)
    else
        ex
    end
end

function gen_spec(ex::Expr, __module__::Module)
    rec(ex) = gen_spec(ex, __module__)
    @switch ex begin
        @case Expr(:quote, a)
            return rec(qt2ex(a))
        @case Expr(:(::), val, ty)
            T = __module__.eval(ty)
            val = T(val)
            return S_of{T}() do
                val
            end
        @case Expr(:(::), ty)
            T = __module__.eval(ty)
            return S_of{T}() do
                get_sample(T)
            end
        @case Expr(:$, a)
            spec = __module__.eval(a)
            spec isa Spec || error("invalid spec")
            return spec
        @case Expr(:||, a, b)
            return S_or(rec(a), rec(b))
        @case Expr(:tuple, args...)
            return S_tp(Tuple(rec(arg) for arg in args))
        @case Expr(:vect, args...)
            specs = SeqElt[]
            for arg in args
                @switch arg begin
                    @case :($a...)
                        push!(specs, Ellipsis(rec(a)))
                        continue
                    @case _
                        push!(specs, One(rec(arg)))
                end
            end
            return S_vec_of(specs)
        @case Expr(:comparison, args...)
            isodd(length(args)) || error("invalid spec: $ex")
            args[2] === :isa || error("invalid spec: $ex, require 'a isa b isa c'")
            return foldl(3:2:length(args), init=rec(args[1])) do last, i
                    arg = args[i]
                    args[i-1] === :isa || error("invalid spec: $ex, require 'a isa b isa c'")
                    @match arg begin
                        :($f.?) => S_guard(__module__.eval(f), last)
                        _ => S_modif(__module__.eval(arg), last)
                    end
            end
        @case :($a isa $f)
            return @match f begin
                :($f.?) => S_guard(__module__.eval(f), rec(a))
                _ => S_modif(__module__.eval(f), rec(a))
            end

        @case :($a.?($f))
            return S_guard(__module__.eval(f), rec(a))
        
        @case :($a{$min_v, $max_v}) || :($a{$min_v}) && let max_v = min_v end
            min_v = __module__.eval(min_v)::Int
            max_v = __module__.eval(max_v)::Int
            spec = rec(a)
            T = get_spec_type(spec)
            rep_spec = S_rep_of(spec)
            if min_v === max_v
                return  S_map{Iterator{T}, Vector{T}}(rep_spec) do iter
                    take_n!(iter, min_v)
                end
            else
                return  S_map{Iterator{T}, Vector{T}}(rep_spec) do iter
                    take_n!(iter, rand(min_v:max_v))
                end
            end
        @case Expr(:call, f, args...)
            f = __module__.eval(f)
            return S_app{f}(f, rec(Expr(:vect, args...)))
        @case _
            error("not supported syntax: $ex")
    end
end

macro spec(ex)
    gen_spec(ex, __module__)
end

# mod′(n) = x -> x % n
# len_lt(n) = x -> length(x) < n && length(x) !== 0
# not_num(x) = !(x isa Number)
# struct S{T}
#     a :: T
#     v :: Int
# end

# spec0 = @spec (::Int) isa iseven.?
# spec1 = @spec [_, (2||3, _, 0)]
# spec2 = @spec S(::Symbol, ::Int isa mod′(12))
# spec3 = @spec 1 || ::DataType
# spec4 = @spec [1, (2, ::String isa len_lt(6).?), 3]
# spec5 = @spec (_, S(::Bool, 2), ::Int isa mod′(3))

# for (id, spec) in [0=>spec0, 1=>spec1, 2=>spec2, 3=>spec3, 4=>spec4, 5=>spec5]
#     for nth in 1:2
#         sample = generate(spec)
#         println("spec$id, ($nth)th sample: $sample")
#     end
# end
end