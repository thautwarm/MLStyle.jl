module Pervasives

if isdefined(Base, :Experimental)
    Base.Experimental.@compiler_options optimize=0 compile=min infer=no
end

using MLStyle
using MLStyle.AbstractPatterns
using MLStyle.AbstractPatterns
struct Many end
struct Do end
struct GuardBy end
export Many, Do, GuardBy

@nospecialize
function MLStyle.pattern_uncall(
    ::typeof(:),
    self::Function,
    tparams::AbstractArray,
    targs::AbstractArray,
    args::AbstractArray,
)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    guard() do target, scope, _
        rng = Expr(:call, :, args...)
        see_captured_vars(:($target in $rng), scope)
    end
end
@specialize

function MLStyle.pattern_uncall(
    ::Type{Dict},
    self::Function,
    tparams::AbstractArray,
    targs::AbstractArray,
    args::AbstractArray,
)

    isempty(tparams) || return begin
        call = Expr(:call, Dict, args...)
        ann = Expr(:curly, Dict, targs...)
        self(Where(call, ann, tparams))
    end

    pairs = Pair[]
    for arg in args
        @switch arg begin
            @case :($a => $b)
            push!(pairs, a => b)
            continue
            @case _
            error(
                "A Dict pattern's sub-pattern should be the form of `(a::Symbol) => b`.",
            )
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

    tchk = isempty(targs) ? P_type_of(Dict) : self(:(::$Dict{$(targs...)}))
    decomp =
        decons(dict_extract, [self(Expr(:call, Some, pair.second)) for pair in pairs])
    and([tchk, decomp])
end

function _allow_assignment!(expr::Expr)
    if expr.head === :kw || expr.head === :(=)
        expr.head = :(=)
        @assert expr.args[1] isa Symbol
    end
end

function MLStyle.pattern_unref(::Type{E}, self::Function, args::AbstractArray) where E
    self(:([$(args...)] :: $AbstractVector{$E}))
end

function MLStyle.pattern_unref(::Type{Do}, self::Function, args::AbstractArray)
    foreach(_allow_assignment!, args)

    effect() do target, scope, ln
        ret = Expr(:block)
        for arg in args
            @switch arg begin
                @case :($sym = $value) && if sym isa Symbol
                end
                sym′ = get(scope, sym) do
                    nothing
                end
                bound = true
                if sym′ === nothing
                    sym′ = sym
                    bound = false
                elseif sym′ !== sym
                    mlstyle_add_deprecation_msg!(
                        "Deprecated use of pattern Do($sym=$value, ...): \n" *
                        "Chaning a variable $sym captured during pattern matching.\n" *
                        "This is dangerous and prevents optimizations, hence got deprecated.\n" *
                        "There might be similar cases that we couldn't detect from your code.\n" *
                        "Plesae avoid it! And remember not to change the variable bound during pattern matching, " *
                        "instead, mutate outer variables.",
                    )
                end
                assignment = Expr(:(=), sym′, see_captured_vars(value, scope))
                push!(ret.args, assignment)
                if !bound
                    scope[sym] = sym′
                end
                continue
                @case _
                push!(ret.args, see_captured_vars(arg, scope))
                continue
            end
        end
        ret
    end
end

@nospecialize
function MLStyle.pattern_uncall(
    ::Type{Do},
    self::Function,
    tparams::AbstractArray,
    targs::AbstractArray,
    args::AbstractArray,
)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    MLStyle.pattern_unref(Do, self, args)
end

function MLStyle.pattern_uncall(
    ::Type{GuardBy},
    self::Function,
    tparams::AbstractArray,
    targs::AbstractArray,
    args::AbstractArray,
)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    @assert length(args) === 1
    guard() do target, _, _
        :($(args[1])($target))
    end
end

function MLStyle.pattern_unref(::Type{Many}, self::Function, args::AbstractArray)
    @assert length(args) === 1
    arg = args[1]
    foreach(_allow_assignment!, args)

    let_pat = Expr(:let, Expr(:block, args...), Expr(:block))
    old = repr(Expr(:call, :Do, args...))
    new = repr(let_pat)
    guard() do target, scope, ln
        token = gensym("loop token")
        iter = gensym("loop iter")
        mk_case(x) = Expr(:macrocall, Symbol("@case"), ln, x)
        switch_body = quote
            $(mk_case(arg))
            continue
            $(mk_case(:_))
            $token = false
            break
        end
        switch_stmt =
            Expr(:macrocall, GlobalRef(MLStyle, Symbol("@switch")), ln, iter, switch_body)
        final = quote
            $token = true
            for $iter in $target
                $switch_stmt
            end
            $token
        end
        see_captured_vars!(final, scope)
    end
end

function MLStyle.pattern_uncall(
    ::Type{Many},
    self::Function,
    tparams::AbstractArray,
    targs::AbstractArray,
    args::AbstractArray,
)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    MLStyle.pattern_unref(Many, self, args)
end

function MLStyle.pattern_unmacrocall(
    r_str::typeof(@eval $(Symbol("@", "r_str"))),
    self::Function,
    args::AbstractArray,
)
    @switch args begin
        @case [ln, m, s::String]
    end

    regex = r_str(ln, m, s)
    guard() do target, _, _
        :($match($regex, $target) !== nothing)
    end
end

@specialize

end
