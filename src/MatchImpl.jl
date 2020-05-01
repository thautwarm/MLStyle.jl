using MLStyle.MatchCore
using AbstractPattern
using AbstractPattern.BasicPatterns
OptionalLn = Union{LineNumberNode, Nothing}

ex2tf(eval::Function, a) =
    isprimitivetype(typeof(a)) ? literal(a) : error("invalid literal $a")
ex2tf(eval::Function, l::LineNumberNode) = wildcard
ex2tf(eval::Function, q::QuoteNode) = literal(q)
ex2tf(eval::Function, s::String) = literal(s)
ex2tf(eval::Function, n::Symbol) =
    n === :_ ?  wildcard : P_capture(n)

Base.@pure function qt2ex(ex::Any)
    if ex isa Expr
        Meta.isexpr(ex, :$) && return ex.args[1]
        Expr(:call, Expr, QuoteNode(ex.head), Expr(:vect, (qt2ex(e) for e in ex.args)...))
    elseif ex isa Symbol
        QuoteNode(ex)
    else
        ex
    end
end

function bind_locally(f::Function)
    function ap(target::Any, env::ChainDict{Symbol, Symbol}, ln::OptionalLn)
        bind = Expr(:block)
        for_chaindict(env) do k, v
            push!(bind.args, :($k = $v))
        end
        inner = f(target, env, ln) 
        isempty(bind.args) ?
            inner :
            Expr(:let, bind, inner)
    end
end

function ex2tf(eval::Function, ex::Expr)
    !(x) = ex2tf(eval, x)
    @sswitch ex begin
    @case Expr(:||, args)
        return or([!e for e in args])
    @case Expr(:&&, args)
        return and([!e for e in args])
    @case Expr(:if, cond, Expr(:block, _))
        return bind_locally() do _, _, _
            cond
        end |> guard
    @case Expr(:&, [expr])
        return bind_locally() do target, _, _
            :($target == $expr)
        end |> guard
    @case Expr(:(::), [p, ty])
        t = eval(ty)::TypeObject
        and([P_type_of(ty), !p])
    
        
    elseif hd === :(::)
        if n_args === 2
            p, ty = args
            ty = eval(ty)::TypeObject
            and(P_type_of(ty), !p)
        else
            @assert n_args === 1
            p = args[1]
            ty = eval(ty)::TypeObject
            P_type_of(ty)
        end
    elseif hd === :vect
        ellipsis_index = findfirst(args) do arg
            Meta.isexpr(arg, :...)
        end
        isnothing(ellipsis_index) ?
            P_vector([!e for e in args]) :
            P_vector3(
                [!e for e in args[1:ellipsis_index-1]],
                !(args[ellipsis_index].args[1]),
                [!e for e in args[ellipsis_index+1:end]],
            )
    elseif hd === :tuple
        P_tuple([!e for e in args])
    elseif hd === :call
        let f = args[1],
            args′ = view(args, 2:length(args))
            n_args′ = n_args - 1
            t = eval(f)
            all_field_ns = fieldnames(t)
            partial_ns = Symbol[]
            patterns = Function[]
            if n_args′ >= 1 && Meta.isexpr(args′[1], :parameters)
                kwargs = args′[1].args
                args′ = view(args′, 2:length(args′))
            else
                kwargs = []
            end
            if length(all_field_ns) === length(args′)
                append!(patterns, [!e for e in args′])
                append!(partial_ns, all_field_ns)
            elseif length(all_field_ns) !== 0
                error("count of positional fields should be 0 or the same as the fields($all_field_ns)")
            end
            for e in kwargs
                if e isa Symbol
                    e in all_field_ns || error("unknown field name $e for $t when field punnning.")
                    push!(partial_ns, e)
                    push!(patterns, P_capture(e))
                elseif Meta.isexpr(e, :kw)
                    key, value = e.args
                    key in all_field_ns || error("unknown field name $key for $t when field punnning.")
                    @assert key isa Symbol
                    push!(partial_ns, key)
                    push!(patterns, and(P_capture(key), !value))
                end
            end
            P_partial_struct_decons(t, partial_ns, patterns)
        end
    elseif hd === :quote
        !qt2ex(args[1])
    else
        error("not implemented expr=>pattern rule for '($hd)' Expr.")
    end
end

const case_sym = Symbol("@case")
"""a minimal implementation of sswitch
"""
macro sswitch(val, ex)
    @assert Meta.isexpr(ex, :block)
    clauses = Pair{Function, Symbol}[]
    body = Expr(:block)
    alphabeta = 'a':'z'
    base = gensym()
    k = 0
    for i in eachindex(ex.args)
        stmt = ex.args[i]
        if Meta.isexpr(stmt, :macrocall) &&
           stmt.args[1] === case_sym &&
           length(stmt.args) == 3

            pattern = basic_ex2tf(__module__.eval, stmt.args[3])
            br :: Symbol = Symbol(alphabeta[i % 26], i <= 26 ? "" : string(i), base)
            push!(clauses,  pattern => br)
            push!(body.args, :(@label $br))
        else
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