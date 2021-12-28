module MatchImpl
export is_enum,
    pattern_uncall, pattern_unref, pattern_unmacrocall, @switch, @tryswitch, @match, Where, gen_match, gen_switch
export Q
import MLStyle
using MLStyle: mlstyle_report_deprecation_msg!
using MLStyle.Err
using MLStyle.MatchCore
using MLStyle.ExprTools

using MLStyle.AbstractPatterns
using MLStyle.AbstractPatterns.BasicPatterns
OptionalLn = Union{LineNumberNode, Nothing}

is_enum(_)::Bool = false
function pattern_uncall end
function pattern_unref end
function pattern_unmacrocall(macro_func, self::Function, args::AbstractArray)
    @sswitch args begin
    @case [ln, m::Module, args...]
    return self(macroexpand(m, Expr(:macrocall, macro_func, ln, args...)))
    end
end

struct Where
    value::Any
    type::Any
    type_parameters::AbstractArray{T, 1} where {T}
end

struct QuotePattern
    value::Any
end

Base.@pure function qt2ex(ex::Any)
    if ex isa Expr
        Meta.isexpr(ex, :$) && return ex.args[1]
        Expr(
            :call,
            Expr,
            QuoteNode(ex.head),
            (qt2ex(e) for e in ex.args if !(e isa LineNumberNode))...,
        )
    elseif ex isa QuoteNode
        QuotePattern(qt2ex(ex.value))
    elseif ex isa Symbol
        QuoteNode(ex)
    else
        ex
    end
end

function guess_type_from_expr(m::Module, ex::Any, tps::Set{Symbol})
    @sswitch ex begin
        @case :($t{$(targs...)})
        t′ = guess_type_from_expr(m, t, tps)[2]
        t′ isa Type || error("$t should be a type!")
        t = t′
        rt_type_check = true
        if t === Union
            # Issue 87
            targs = map(targs) do targ
                t′ = guess_type_from_expr(m, targ, tps)[2]
                t′ isa Type ? t′ : Any
            end
            t = Union{targs...}
        end
        return true, t
        @case t::Type
        return false, t
        @case ::Symbol
        ex in tps ||
            isdefined(m, ex) &&
            #= TODO: check if it's a type =#
                return (false, getfield(m, ex))
        return true, Any
        @case _
        # TODO: for better performance we should guess types smartly.
        return true, Any
    end
end

ex2tf(m::Module, @nospecialize(a)) = literal(a)
ex2tf(m::Module, l::LineNumberNode) = wildcard
ex2tf(m::Module, q::QuoteNode) = literal(q.value)
ex2tf(m::Module, s::String) = literal(s)
ex2tf(m::Module, n::Symbol) =
    if n === :_
        wildcard
    elseif n === :nothing
        literal(nothing)
    else
        if isdefined(m, n)
            p = getfield(m, n)
            rec(x) = ex2tf(m, x)
            is_enum(p) && return pattern_uncall(p, rec, [], [], [])
        end
        P_capture(n)
    end

_quote_extract(expr::Any, ::Int, ::Any, ::Any) = :($expr.value)

function ex2tf(m::Module, s::QuotePattern)
    p0 = P_type_of(QuoteNode)
    p1 = decons(_quote_extract, [ex2tf(m, s.value)])
    and([p0, p1])
end

function ex2tf(m::Module, w::Where)
    rec(x) = ex2tf(m, x)
    @sswitch w begin
        @case Where(; value = val, type = t, type_parameters = tps)

        tp_set = get_type_parameters(tps)::Set{Symbol}
        should_guess, ty_guess = guess_type_from_expr(m, t, tp_set)
        p_ty = P_type_of(ty_guess)
        tp_vec = collect(tp_set)
        sort!(tp_vec)
        @nospecialize
        p_guard = guard() do target, scope, _
            if isempty(tp_vec)
                return if should_guess
                    see_captured_vars(:($target isa $t), scope)
                else
                    true
                end
            end

            tp_ret = Expr(:tuple, tp_vec...)

            targns = Symbol[]
            fn = gensym("extract type params")
            testn = gensym("test type params")
            ty_accurate = gensym("accurate type param")
            ret = Expr(:block)
            suite = ret.args
            for tp in tp_vec
                targn = gensym(tp)
                push!(targns, targn)
            end
            push!(
                suite,
                :(
                    $fn(::Type{$ty_accurate}) where {$(tps...), $ty_accurate <: $t} =
                        $tp_ret
                ),
                :($fn(_) = nothing),
                :($testn = $fn(typeof($target))),
                Expr(
                    :if,
                    :($testn !== nothing),
                    Expr(:block, Expr(:(=), Expr(:tuple, targns...), testn), true),
                    false,
                ),
            )
            for i in eachindex(tp_vec)
                scope[tp_vec[i]] = targns[i]
            end
            ret
        end
        @specialize
        return and([p_ty, p_guard, rec(val)])
    end
end

function ex2tf(m::Module, ex::Expr)
    eval = m.eval
    rec(x) = ex2tf(m, x)

    @sswitch ex begin
        @case Expr(:||, args)
        return or(map(rec, args))
        @case Expr(:&&, args)
        return and(map(rec, args))
        @case Expr(:if, [cond, Expr(:block, _)])
        return guard() do _, scope, _
            see_captured_vars(cond, scope)
        end
        @case Expr(:let, args)
        bind = args[1]
        @assert bind isa Expr
        return if bind.head === :(=)
            @assert bind.args[1] isa Symbol
            P_bind(bind.args[1], bind.args[2], see_capture = true)
        else
            @assert bind.head === :block
            binds = Function[
                P_bind(arg.args[1], arg.args[2], see_capture = true) for arg in bind.args
            ]
            push!(binds, wildcard)
            and(binds)
        end
        @case Expr(:&, [expr])
        return guard() do target, scope, _
            see_captured_vars(:($target == $expr), scope)
        end
        @case Expr(:vect, elts)
        tag, split = ellipsis_split(elts)
        return tag isa Val{:vec} ? P_vector([rec(e) for e in split]) :
               let (init, mid, tail) = split
            P_vector3([rec(e) for e in init], rec(mid), [rec(e) for e in tail])
        end
        @case Expr(:tuple, elts)
        return P_tuple([rec(e) for e in elts])

        @case Expr(:quote, [quoted])
        return rec(qt2ex(quoted))

        @case Expr(:ref, [t, args...])
        t = eval(t)
        return pattern_unref(t, rec, args)

        @case Expr(
            :where,
            [
                Expr(:call, [:($t{$(targs...)}), args...]) ||
                Expr(:call, [t, args...]) && let targs = []
                end,
                tps...,
            ],
        ) && if t !== Where
        end
        t = eval(t)
        return pattern_uncall(t, rec, tps, targs, args)

        @case (
            Expr(:call, [:($t{$(targs...)}), args...]) ||
            Expr(:call, [t, args...]) && let targs = []
            end
        ) && if t !== Where
        end
        t = eval(t)
        return pattern_uncall(t, rec, [], targs, args)

        @case Expr(:curly, [t, targs...])
        t = eval(t)
        return pattern_uncall(t, rec, [], targs, [])

        @case :($val::$t where {$(tps...)}) ||
              :(::$t where {$(tps...)}) && let val = :_
              end ||
              :($val::$t) && let tps = []
              end ||
              :(::$t) && let val = :_, tps = []
              end

        return ex2tf(m, Where(val, t, tps))

        @case :($ty[$pat for $reconstruct in $seq if $cond]) ||
              :($ty[$pat for $reconstruct in $seq]) && let cond = true
              end ||
              :[$pat for $reconstruct in $seq if $cond] && let ty = Any
              end ||
              :[$pat for $reconstruct in $seq] && let cond = true, ty = Any
              end && if seq isa Symbol
              end

        return uncomprehension(rec, ty, pat, reconstruct, seq, cond)

        @case Expr(:macrocall, [macro_expr, ln::LineNumberNode, args...])
        macro_func = m.eval(macro_expr)
        return pattern_unmacrocall(macro_func, rec, Any[ln, m, args...])

        @case a
        error("unknown pattern syntax $(repr(a))")
    end
end

function uncomprehension(
    self::Function,
    ty::Any,
    pat::Any,
    reconstruct::Any,
    seq::Any,
    cond::Any,
)
    eltype = guess_type_from_expr(self.m, ty, Set{Symbol}())[2]
    p0 = P_type_of(AbstractArray{T, 1} where {T <: eltype})
    function extract(
        target::Any,
        ::Int,
        scope::ChainDict{Symbol, Symbol},
        ln::LineNumberNode,
    )
        token = gensym("uncompreh token")
        iter = gensym("uncompreh iter")
        vec = gensym("uncompreh seq")
        infer_flag = gensym("uncompreh flag")
        fn = gensym("uncompreh func")
        reconstruct_tmp = gensym("reconstruct")
        mk_case(x) = Expr(:macrocall, Symbol("@case"), ln, x)
        switch_body = quote
            $(mk_case(pat))
            $reconstruct_tmp = $reconstruct
            if $infer_flag isa $Val{true}
                return $reconstruct_tmp
            else
                if $cond
                    push!($vec.value, $reconstruct_tmp)
                end
                return true
            end
            $(mk_case(:_))
            if $infer_flag isa $Val{true}
                error("impossible")
            else
                return false
            end
        end
        switch_stmt =
            Expr(:macrocall, GlobalRef(MLStyle, Symbol("@switch")), ln, iter, switch_body)
        final = quote
            $Base.@inline $fn($iter, $infer_flag::$Val) = $switch_stmt
            $vec =
                $Base._return_type($fn, $Tuple{$Base.eltype($target), $Val{true}})[]
            $vec = $Some($vec)
            for $iter in $target
                $token = $fn($iter, $Val(false))
                $token && continue
                $vec = nothing
                break
            end
            $vec
        end
        see_captured_vars(final, scope)
    end
    p1 = decons(extract, [self(Expr(:call, Some, seq))])
    return and([p0, p1])
end

const case_sym = Symbol("@case")
@nospecialize
"""
    @switch <item> begin
        @case <pattern>
            <action>
    end

In the real use of pattern matching provided by `MLStyle`, things can sometimes becomes painful. To end this, we have [`@when`](@ref), and now even [`@switch`](@ref).

Following code is quite stupid in many aspects:

```julia
var = 1
@match x begin
    (var_, _) => begin
        var = var_
        # do stuffs
    end
end
```

Firstly, capturing in [`@match`](@ref) just shadows outer variables, but sometimes you just want to change them.

Secondly, [`@match`](@ref) is an expression, and the right side of `=>` can be only an expression, and writing a begin end there can bring bad code format.

To address these issues, we present the `@switch` macro:

```julia
julia> var = 1
1

julia> x = (33, 44)
(33, 44)

julia> @switch x begin
       @case (var, _)
           println(var)
       end
33

julia> var
33

julia> @switch 1 begin
       @case (var, _)
           println(var)
       end
ERROR: matching non-exhaustive, at #= REPL[25]:1 =#
```
"""
macro switch(val, ex)
    res = gen_switch(val, ex, __source__, __module__)
    res = init_cfg(res)
    esc(res)
end
"""
    @tryswitch <item> begin
        @case <pattern>
            <action>
    end

Very similar to [`@switch`](@ref), except that a failure to match does nothing instead of throwing a "match non-exhaustive" error.

It is equivalent to

```julia
@switch <item> begin
    @case <pattern>
        <action>
    @case _
        nothing
    end
```
"""
macro tryswitch(val, ex)
    @assert Meta.isexpr(ex, :block)
    insert_case = length(ex.args) >= 2 || begin
        case, line = ex.args[end-2:end]
        Meta.isexpr(case, [:macrocall], 3)  &&
            case.args[1] == Symbol("@case") &&
            case.args[3] == :_
    end
    insert_case && push!(ex.args, Expr(:macrocall, Symbol("@case"), __source__, :_), :nothing)
    :($(esc(:(@switch $val $ex))))
end
@specialize
function gen_switch(val, ex, __source__::LineNumberNode, __module__::Module)
    @assert Meta.isexpr(ex, :block)
    branches = Pair{Function, Tuple{LineNumberNode, Int}}[]
    k = 0
    ln = __source__
    terminal = Dict{Int, Any}()
    body = nothing
    for i in eachindex(ex.args)
        stmt = ex.args[i]
        if Meta.isexpr(stmt, :macrocall) &&
           stmt.args[1] === case_sym &&
           length(stmt.args) == 3
            k += 1
            pattern = try
                ex2tf(__module__, stmt.args[3])
            catch e
                throw(PatternCompilationError(ln, e))
            end

            mlstyle_report_deprecation_msg!(ln)

            push!(branches, (pattern => (ln, k)))
            body = terminal[k] = Expr(:block)
        else
            is_ln = stmt isa LineNumberNode
            if k !== 0 && !is_ln
                push!(body.args, ln)
                push!(body.args, stmt)
            end
            is_ln && (ln = stmt)
        end
    end

    backend(val, branches, terminal, __source__; hygienic = false)
end

@nospecialize
Base.@pure function expr2tuple(expr)
    :($expr.head, $expr.args)
end

Base.@pure function packexpr(expr)
    :([$expr.head, $expr.args...])
end
@specialize

function pattern_uncall(
    ::Type{Expr},
    self::Function,
    type_params::AbstractArray,
    type_args::AbstractArray,
    args::AbstractArray,
)
    isempty(type_params) || error("An Expr pattern requires no type params.")
    isempty(type_args) || error("An Expr pattern requires no type arguments.")
    @sswitch args begin
        @case [Expr(:..., [_]), _...]
        return and([P_type_of(Expr), P_slow_view(packexpr, self(Expr(:vect, args...)))])
        @case _
    end

    tcons(_...)::Type{Expr} = Expr
    comp = PComp("Expr", tcons)

    p_tag = self(args[1])
    p_vec = self(Expr(:vect, view(args, 2:length(args))...))
    p_tuple = P_tuple([p_tag, p_vec])
    and([P_type_of(Expr), P_slow_view(expr2tuple, p_tuple)])
end

function pattern_uncall(
    ::Type{Core.SimpleVector},
    self::Function,
    type_params::AbstractArray,
    type_args::AbstractArray,
    args::AbstractArray,
)
    isempty(type_params) || error("A svec pattern requires no type params.")
    isempty(type_args) || error("A svec pattern requires no type arguments.")

    tag, split = ellipsis_split(args)
    return tag isa Val{:vec} ? P_svec([self(e) for e in split]) :
           let (init, mid, tail) = split
        P_svec3([self(e) for e in init], self(mid), [self(e) for e in tail])
    end
end

function pattern_uncall(
    ::Type{QuoteNode},
    self::Function,
    type_params::AbstractArray,
    type_args::AbstractArray,
    args::AbstractArray,
)
    isempty(type_params) || error("A QuoteNode pattern requires no type params.")
    isempty(type_args) || error("A QuoteNode pattern requires no type arguments.")
    length(args) == 1 || error("A QuoteNode pattern accepts only 1 argument.")
    self(QuotePattern(args[1]))
end

@nospecialize
function _some_guard1(expr::Any)
    :($expr !== nothing)
end
function _some_tcons(t)
    Some{T} where {T <: t}
end
@specialize

const _some_comp = PComp("Some", _some_tcons; guard1 = NoncachablePre(_some_guard1))

function pattern_uncall(
    ::Type{Some},
    self::Function,
    tparams::AbstractArray,
    targs::AbstractArray,
    args::AbstractArray,
)
    isempty(tparams) || error("A (:) pattern requires no type params.")
    isempty(targs) || error("A (:) pattern requires no type arguments.")
    @assert length(args) === 1
    function some_extract(expr::Any, i::Int, ::Any, ::Any)
        @assert i === 1
        :($expr.value)
    end
    decons(_some_comp, some_extract, [self(args[1])])
end

@nospecialize
"""
    @match <item> begin
        <pattern> => <result>
        <pattern> => <result>
        _ => <other>
    end

Define a pattern matching expression. You can find available patterns in the
[Patterns](https://thautwarm.github.io/MLStyle.jl/latest/syntax/pattern.html#patterns)
section of documentation.

# Example

```julia
julia> @match 10 begin
    1  => "wrong!"
    2  => "wrong!"
    10 => "right!"
end
"right!"

julia> @match 1 begin
    ::Float64  => nothing
    b :: Int => b
    _        => nothing
end
1
```
"""
macro match(val, tbl)
    res = gen_match(val, tbl, __source__, __module__)
    res = init_cfg(res)
    esc(res)
end
@specialize

function gen_match(val, tbl, __source__::LineNumberNode, __module__::Module)
    Meta.isexpr(tbl, :block) || (tbl = Expr(:block, tbl))
    branches = Pair{Function, Tuple{LineNumberNode, Int}}[]
    k = 0
    ln = __source__
    terminal = Dict{Int, Any}()
    for i in eachindex(tbl.args)
        stmt = tbl.args[i]
        @switch stmt begin
            @case :($case => $body)
            k += 1
            pattern = try
                ex2tf(__module__, case)
            catch e
                throw(PatternCompilationError(ln, e))
                rethrow()
            end

            mlstyle_report_deprecation_msg!(ln)

            push!(branches, (pattern => (ln, k)))
            terminal[k] = body
            @case ln::LineNumberNode
            @case _
            error("invalid match clause $stmt")
        end
    end

    backend(val, branches, terminal, __source__; hygienic = true)
end

end
