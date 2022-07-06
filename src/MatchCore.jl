module MatchCore

using MLStyle
using MLStyle.Err

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@compiler_options"))
    @eval Base.Experimental.@compiler_options compile=min infer=no optimize=0
end

export @sswitch, ellipsis_split, backend, P_partial_struct_decons
using MLStyle.AbstractPatterns
using MLStyle.AbstractPatterns.BasicPatterns

"""
[a, b..., c] -> :vec3 => [a], b, [c]
[a, b, c]    -> :vec => [a, b, c]
"""
function ellipsis_split(args::AbstractArray{T, 1}) where {T}
    ellipsis_index = findfirst(args) do arg
        Meta.isexpr(arg, :...)
    end
    if ellipsis_index === nothing
        Val(:vec) => args
    else
        Val(:vec3) => (
            args[1:ellipsis_index-1],
            args[ellipsis_index].args[1],
            args[ellipsis_index+1:end],
        )
    end
end

@nospecialize
function qt2ex(ex::Any)
    if ex isa Expr
        Meta.isexpr(ex, :$) && return ex.args[1]
        Expr(
            :call,
            Expr,
            QuoteNode(ex.head),
            Expr(:vect, (qt2ex(e) for e in ex.args if !(e isa LineNumberNode))...),
        )
    elseif ex isa Symbol
        QuoteNode(ex)
    else
        ex
    end
end

const backend = RedyFlavoured.backend

function P_partial_struct_decons(t, partial_fields, ps, prepr::AbstractString = "$t")
    function tcons(_...)
        t
    end
    comp = PComp(prepr, tcons;)
    function extract(sub, i::Int, ::Any, ::Any)
        :($sub.$(partial_fields[i]))
    end
    decons(comp, extract, ps)
end

basic_ex2tf(eval::Function, a) =
    isprimitivetype(typeof(a)) ? literal(a) : error("invalid literal $a")
basic_ex2tf(eval::Function, l::LineNumberNode) = wildcard
basic_ex2tf(eval::Function, q::QuoteNode) = literal(q.value)
basic_ex2tf(eval::Function, s::String) = literal(s)
basic_ex2tf(eval::Function, n::Symbol) = n === :_ ? wildcard : P_capture(n)

function basic_ex2tf(eval::Function, ex::Expr)
    !(x) = basic_ex2tf(eval, x)
    hd = ex.head
    args = ex.args
    n_args = length(args)
    if hd === :||
        @assert n_args === 2
        l, r = args
        or(!l, !r)
    elseif hd === :&&
        @assert n_args === 2
        l, r = args
        and(!l, !r)

    elseif hd === :if
        @assert n_args === 2
        let cond = args[1]
            guard() do _, scope, _
                see_captured_vars(cond, scope)
            end
        end
    elseif hd === :&
        @assert n_args === 1
        val = args[1]
        guard() do target, scope, _
            see_captured_vars(:($target == $val), scope)
        end
    elseif hd === :let
        bind = args[1]
        @assert bind isa Expr
        if bind.head === :(=)
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
    elseif hd === :(::)
        if n_args === 2
            p, ty = args
            ty = eval(ty)::TypeObject
            and(P_type_of(ty), !p)
        else
            @assert n_args === 1
            ty = args[1]
            ty = eval(ty)::TypeObject
            P_type_of(ty)
        end
    elseif hd === :vect
        tag, split = ellipsis_split(args)
        return tag isa Val{:vec} ? P_vector([!e for e in split]) :
               let (init, mid, tail) = split
            P_vector3([!e for e in init], !mid, [!e for e in tail])
        end
    elseif hd === :tuple
        P_tuple([!e for e in args])
    elseif hd === :call
        let f = args[1], args′ = view(args, 2:length(args))
            n_args′ = n_args - 1
            t = eval(f)
            if t === Core.svec
                tag, split = ellipsis_split(args′)
                return tag isa Val{:vec} ? P_svec([!e for e in split]) :
                       let (init, mid, tail) = split
                    P_svec3([!e for e in init], !mid, [!e for e in tail])
                end
            end
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
            elseif length(partial_ns) !== 0
                error(
                    "count of positional fields should be 0 or the same as the fields($all_field_ns)",
                )
            end
            for e in kwargs
                if e isa Symbol
                    e in all_field_ns ||
                        error("unknown field name $e for $t when field punnning.")
                    push!(partial_ns, e)
                    push!(patterns, P_capture(e))
                elseif Meta.isexpr(e, :kw)
                    key, value = e.args
                    key in all_field_ns ||
                        error("unknown field name $key for $t when field punnning.")
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
this is incomplete and only for bootstrapping, do not use it.
"""
macro sswitch(val, ex)
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
                basic_ex2tf(__module__.eval, stmt.args[3])
            catch e
                throw(PatternCompilationError(ln, e))
            end
            push!(branches, (pattern => (ln, k)))
            body = terminal[k] = Expr(:block)
        else
            stmt isa LineNumberNode && (ln = stmt)
            k === 0 || push!(body.args, stmt)
        end
    end

    block = backend(val, branches, terminal, __source__; hygienic = false)
    esc(init_cfg(block))
end
@specialize

end # module end
