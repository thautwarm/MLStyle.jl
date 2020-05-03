module Pervasives
using MLStyle
using MLStyle.AbstractPattern
using MLStyle.AbstractPattern
const strict_eq_types = Union{Int, Nothing}

function MLStyle.pattern_compile(::typeof(:), self::Function, tparams::AbstractArray, targs::AbstractArray, args::AbstractArray)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    guard() do target, scope, _
        Expr(:call, :, args...)
    end
end

function MLStyle.pattern_compile(::Type{Dict}, self::Function, tparams::AbstractArray, targs::AbstractArray, args::AbstractArray)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    isempty(tparams) || return begin
        call = Expr(:call, t, args...)
        ann = Expr(:curly, t, targs...)
        self(Where(call, ann, tparams))
    end
    pairs = Pair[]
    for arg in args
        @switch arg begin
            @case :($a => $b)
                push!(pairs, a => b)
                continue
            @case _
                error("A Dict pattern's sub-pattern should be the form of `(a::Symbol) => b`.")
        end
    end
    function dict_extract(expr::Any, i::Int, scope::ChainDict{Symbol, Symbol}, ::Any)
        # cannot avoid performance overhead due to
        # https://discourse.julialang.org/t/distinguish-dictionary-lookup-from-nothing-and-not-found/38654
        k, v = pairs[i]
        if k isa Union{Expr, Symbol}
            # how to reduce the generate code size?
            # most of the cases, see_captured_vars is unnecessary.
            k = see_captured_vars(k, scope)
        end
        :(haskey($expr, $k) ? Some($expr[$k]) : nothing)
    end

    tchk = isempty(targs) ? P_type_of(Dict) : self(:(:: $Dict{$(targs...)}))
    decomp = decons(dict_extract, [self(Expr(:call, Some, pair.second)) for pair in pairs])
    and([tchk, decomp])
end

struct Many end
struct Do end

export Many, Do

# QuoteNode, Do, Many

end