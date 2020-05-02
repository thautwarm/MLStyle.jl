module MatchImpl
export is_enum, pattern_compile, @switch, @match
using MLStyle.MatchCore
using MLStyle.ExprTools

using AbstractPattern
using AbstractPattern.BasicPatterns
OptionalLn = Union{LineNumberNode, Nothing}

is_enum(_) = false
function pattern_compile end

Base.@pure function qt2ex(ex::Any)
    if ex isa Expr
        Meta.isexpr(ex, :$) && return ex.args[1]
        Expr(:call, Expr, QuoteNode(ex.head), (qt2ex(e) for e in ex.args)...)
    elseif ex isa Symbol
        QuoteNode(ex)
    else
        ex
    end
end

function const_type(t::Any, Ary::Val{N}) where N
    get_const_type(::Vararg{Any, N})::Any = t
    get_const_type
end

function guess_type_from_expr(eval::Function, ex::Any, tps :: Set{Symbol})
    @sswitch ex begin
        @case :($t{$(targs...)})
            # TODO: check if it is a type
            return eval(t)
        @case t::Type
            return t
        @case ::Symbol
            return ex in tps ? Any : #= TODO: check if it's a type =# eval(ex)
        @case _
            error("unrecognised type expression $ex")
    end
end

ex2tf(m::Module, a) = isprimitivetype(typeof(a)) ? literal(a) : error("invalid literal $a")
ex2tf(m::Module, l::LineNumberNode) = wildcard
ex2tf(m::Module, q::QuoteNode) = literal(q.value)
ex2tf(m::Module, s::String) = literal(s)
ex2tf(m::Module, n::Symbol) =
    if n === :_
        wildcard
    else
        if isdefined(m, n)
            p = getfield(m, n)
            rec(x) = ex2tf(m, x)
            is_enum(p) && return pattern_compile(p, rec, [], [], [])
        end
        P_capture(n)    
    end

function ex2tf(m::Module, ex::Expr)
    eval = m.eval
    rec(x) = ex2tf(m, x)

    @sswitch ex begin
    @case Expr(:||, args)
        return or(map(recur, args))
    @case Expr(:&&, args)
        return and(map(recur, args))
    @case Expr(:if, [cond, Expr(:block, _)])
        return guard() do _, scope, _
            see_captured_vars(cond, scope)
        end
    @case Expr(:&, [expr])
        return guard() do target, scope, _
            see_captured_vars(:($target == $expr), scope)
        end
    @case Expr(:vect, elts)
        tag, split = ellipsis_split(elts)
        return tag isa Val{:vec} ?

            P_vector([rec(e) for e in split]) :
            let (init, mid, tail) = split
                P_vector3(
                    [rec(e) for e in init],
                    rec(mid),
                    [rec(e) for e in tail]
                )
            end
    @case Expr(:tuple, elts)
        return P_tuple([rec(e) for e in args])
    
    @case Expr(:quote, [quoted])
        return rec(qt2ex(quoted))
    
    @case Expr(:where, [
                Expr(:call, [:($t{$(targs...)}), args...])   ||
                Expr(:call, [t, args...]) && let targs = [] end,
                tps...
            ])
        t = eval(t)
        return pattern_compile(t, rec, tps, targs, args)
    
    @case Expr(:call, [:($t{$(targs...)}), args...])   ||
          Expr(:call, [t, args...]) && let targs = [] end
        t = eval(t)
        return pattern_compile(t, rec, [], targs, args)

    @case :($val :: $t where {$(tps...)}) ||
          :(:: $t where {$(tps...)}) && let val = :_ end ||
          :($val :: $t)              && let tps = [] end ||
          :(:: $t)                   && let val = :_, tps = [] end
        
       
        tp_set = get_type_parameters(tps)::Set{Symbol}
        p_ty = guess_type_from_expr(m.eval, t, tp_set) |> P_type_of
        tp_vec = collect(tp_set)
        sort!(tp_vec)
        p_guard = guard() do target, scope, _
            isempty(tp_vec) &&
                return see_captured_vars(
                    :($target isa $t),
                    scope
                )
            targns = Symbol[]
            fn = gensym("extract type params")
            testn = gensym("test type params")
            ret = Expr(:block)
            suite = ret.args
            for tp in tp_vec
                targn = gensym(tp)
                push!(targns, targn)
            end
            push!(
                suite,
                :(function $fn(::$t) where {$(tps...)}
                    $(Expr(:tuple, tp_vec...))
                end),
                :(function $fn(_)
                    nothing
                end),
                :($testn = $fn($target)),
                Expr(:if,
                    :($testn !== nothing),
                    Expr(
                        :block,
                        Expr(:(=), Expr(:tuple, targns...), testn),
                        true
                    ),
                    false
                )
            )
            for i in eachindex(tp_vec)
                scope[tp_vec[i]] = targns[i]
            end
            ret
        end
        
        return and([p_ty, p_guard, rec(val)])
    @case a
        error("unknown pattern syntax $(repr(a))")
    end
end

const case_sym = Symbol("@case")

macro switch(val, ex)
    @assert Meta.isexpr(ex, :block)
    clauses = Union{LineNumberNode, Pair{<:Function, Symbol}}[]
    body = Expr(:block)
    alphabeta = 'a':'z'
    base = gensym()
    k = 0
    for i in eachindex(ex.args)
        stmt = ex.args[i]
        if Meta.isexpr(stmt, :macrocall) &&
           stmt.args[1] === case_sym &&
           length(stmt.args) == 3
            
            k += 1
            pattern = ex2tf(__module__, stmt.args[3])
            br :: Symbol = Symbol(alphabeta[k % 26], k <= 26 ? "" : string(i), base)
            push!(clauses,  pattern => br)
            push!(body.args, :(@label $br))
        else
            if stmt isa LineNumberNode
                push!(clauses, stmt)
            end
            push!(body.args, stmt)
        end
    end
    
    match_logic = backend(val, clauses, __source__)
    esc(Expr(
        :block,
        match_logic,
        body
    ))
end

Base.@pure function expr2tuple(expr)
    :($expr.head, $expr.args)
end

function pattern_compile(
    ::Type{Expr},
    self::Function,
    type_params::AbstractArray,
    type_args::AbstractArray,
    args::AbstractArray
)
    isempty(type_params) || error("A Expr pattern requires no type params.")
    isempty(type_args)   || error("A Expr pattern requires no type arguments.")
    
    tcons(_...)::Type{Expr} = Expr
    comp = PComp(
        "Expr",
        tcons,
    )
    
    p_tag = self(args[1])
    p_vec = self(Expr(:vect, view(args, 2:length(args))...))
    p_tuple = P_tuple([p_tag, p_vec])
    and([P_type_of(Expr), P_slow_view(expr2tuple, p_tuple)])
end


function pattern_compile(
    ::Type{Core.SimpleVector},
    self::Function,
    type_params::AbstractArray,
    type_args::AbstractArray,
    args::AbstractArray
)
    isempty(type_params) || error("A Expr pattern requires no type params.")
    isempty(type_args)   || error("A Expr pattern requires no type arguments.")
    
    tag, split = ellipsis_split(args)
    return tag isa Val{:vec} ?
        P_svec([self(e) for e in split]) :
        let (init, mid, tail) = split
            P_svec3(
                [self(e) for e in init],
                self(mid),
                [self(e) for e in tail]
            )
        end
end

macro match(val, tbl)
    @assert Meta.isexpr(tbl, :block)
    clauses = Union{LineNumberNode, Pair{<:Function, Symbol}}[]
    body = Expr(:block)
    alphabeta = 'a':'z'
    base = gensym()
    k = 0
    final_label = Symbol(".", base)
    final_res = gensym("final")
    
    for i in eachindex(tbl.args)
        ex = tbl.args[i]
        @switch ex begin
            @case :($a => $b)
                k += 1
                pattern = ex2tf(__module__, a)
                br :: Symbol = Symbol(alphabeta[k % 26], k <= 26 ? "" : string(i), base)
                push!(clauses,  pattern => br)
                push!(body.args, :(@label $br))
                push!(body.args, :($final_res = $b))
                push!(body.args, :(@goto $final_label))
                continue
            @case ln::LineNumberNode
                push!(clauses, ln)
                push!(body.args, ln)
                continue
        end
    end
    
    match_logic = backend(val, clauses, __source__)
    push!(body.args, :(@label $final_label))
    push!(body.args, final_res)
    
    esc(
        Expr(
            :let,
            Expr(:block),
            Expr(
                :block,
                match_logic,
                body
            )
        )
    )

end
end