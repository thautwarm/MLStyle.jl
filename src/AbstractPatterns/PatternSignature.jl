struct PatternCompilationError <: Exception
    line::Union{LineNumberNode,Nothing}
    msg::AbstractString
end


PatternImpl = NamedTuple{
    (:and, :or, :literal, :wildcard, :decons, :guard, :effect),
}


PatternImpls{N} = NTuple{N, PatternImpl}

@nospecialize
and(args :: Any...) = and(collect(args))
and(ps::Vector) = function apply(impls::PatternImpls{N}) where N
    xs = [p(impls) for p in ps]
    me = Vector{Any}(undef, N)
    for i in 1:N
        @inbounds me[i] = impls[i].and(xs)
    end
    me
end

or(args :: Any...) = or(collect(args))
or(ps::Vector) = function apply(impls::PatternImpls{N}) where N
    xs = [p(impls) for p in ps]
    me = Vector{Any}(undef, N)
    for i in 1:N
        me[i] = impls[i].or(xs)
    end
    me
end

literal(val) = function apply(impls::PatternImpls{N}) where N
    me = Vector{Any}(undef, length(impls))
    for i in 1:N
        me[i] = impls[i].literal(val)
    end
    me
end

function wildcard(impls::PatternImpls{N}) where N
    me = Vector{Any}(undef, length(impls))
    for i in 1:N
        me[i] = impls[i].wildcard
    end
    me
end

guard(pred) = function apply(impls::PatternImpls{N}) where N
    me = Vector{Any}(undef, N)
    for i in 1:N
        me[i] = impls[i].guard(pred)
    end
    me
end

"""
abstract pure process
"""
abstract type APP end

struct NoncachablePre <: APP
    callable :: Any
end
(f::NoncachablePre)(target::Any) = f.callable(target)
struct NoPre <: APP end

"""composite pattern
"""
struct PComp
    repr :: AbstractString
    tcons :: Function
    guard1 :: APP
    view :: APP
    guard2 :: APP
end

invalid_extract(_, _) = error("impossible")

function PComp(
    repr :: AbstractString,
    tcons::Function;
    guard1::APP=NoPre(),
    view::APP=NoPre(),
    guard2::APP=NoPre()
)
    PComp(repr, tcons, guard1, view, guard2)
end

decons(comp::PComp, ps; extract=invalid_extract) = decons(comp, extract, ps)

decons(comp::PComp, extract::Function, ps) = function apply(impls::PatternImpls{N}) where N
    xs = [p(impls) for p in ps]
    me = Vector{Any}(undef, N)
    for i in 1:N
        me[i] = impls[i].decons(comp, extract, xs)
    end
    me
end

effect(ctx_perf) = function apply(impls::PatternImpls{N}) where N
    me = Vector{Any}(undef, N)
    for i in 1:N
        me[i] = impls[i].effect(ctx_perf)
    end
    me
end

@specialize

const self = (
    and = and,
    or = or,
    literal = literal,
    wildcard = wildcard,
    decons = decons,
    guard = guard,
    effect = effect
)
