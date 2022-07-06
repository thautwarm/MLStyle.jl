module RedyFlavoured

using MLStyle.AbstractPatterns
using MLStyle.Err: PatternCompilationError

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@compiler_options"))
    @eval Base.Experimental.@compiler_options compile=min infer=no optimize=0
end

Config = NamedTuple{(:type, :ln)}
Scope = ChainDict{Symbol, Symbol}
ViewCache = ChainDict{Pair{TypeObject, Any}, Tuple{Symbol, Bool}}
Terminal = Dict{Int, Any}
function update_parent!(view_cache::ViewCache)
    parent = view_cache.init[]
    for (typed_viewer, (sym, _)) in view_cache.cur
        parent[typed_viewer] = (sym, false)
    end
end

struct CompileEnv
    # Dict(user_defined_name => actual_name). mangling for scope safety
    scope::Scope
    # Dict(view => (viewed_cache_symbol => guarantee_of_defined?))
    view_cache::ViewCache
    terminal::Dict{Int, Any}
    hygienic::Bool
    ret::Symbol
    final::Symbol
end

function CompileEnv(terminal::Terminal, hygienic::Bool, ret::Symbol, final::Symbol)
    CompileEnv(Scope(), ViewCache(), terminal, hygienic, ret, final)
end

function (env::CompileEnv)(;
    scope::Union{Nothing, Scope} = nothing,
    view_cache::Union{Nothing, ViewCache} = nothing,
)
    scope === nothing && (scope = env.scope)
    view_cache === nothing && (view_cache = env.view_cache)
    CompileEnv(scope, view_cache, env.terminal, env.hygienic, env.ret, env.final)
end

abstract type Cond end
struct AndCond <: Cond
    left::Cond
    right::Cond
end

struct OrCond <: Cond
    left::Cond
    right::Cond
end

struct TrueCond <: Cond
    stmt::Any
end

TrueCond() = TrueCond(true)

struct CheckCond <: Cond
    expr::Any
end

"""
build to disjunctive forms
"""
function build_readable_expression!(
    exprs::Vector{Any},
    following_stmts::Vector{Any},
    cond::CheckCond,
)
    expr = cond.expr
    if !isempty(following_stmts)
        expr = Expr(:block, following_stmts..., expr)
        empty!(following_stmts)
    end
    push!(exprs, expr)
end

function build_readable_expression!(
    exprs::Vector{Any},
    following_stmts::Vector{Any},
    cond::TrueCond,
)
    cond.stmt isa Union{Bool, Int, Float64, Nothing} && return #= shall contain more literal typs =#
    push!(following_stmts, cond.stmt)
    nothing
end

function build_readable_expression!(
    exprs::Vector{Any},
    following_stmts::Vector{Any},
    cond::AndCond,
)
    build_readable_expression!(exprs, following_stmts, cond.left)
    build_readable_expression!(exprs, following_stmts, cond.right)
end

function build_readable_expression!(
    exprs::Vector{Any},
    following_stmts::Vector{Any},
    cond::OrCond,
)
    exprs′ = []
    following_stmts′ = []
    build_readable_expression!(exprs′, following_stmts′, cond.left)
    left = to_expression(exprs′, following_stmts′)

    empty!(exprs′)
    empty!(following_stmts′)

    build_readable_expression!(exprs′, following_stmts′, cond.right)
    right = to_expression(exprs′, following_stmts′)

    empty!(exprs′)
    empty!(following_stmts′)

    bool_or = Expr(:||, left, right)
    if !isempty(following_stmts)
        bool_or = Expr(:block, following_stmts..., bool_or)
        empty!(following_stmts)
    end

    push!(exprs, bool_or)
end

function to_expression(cond::Cond)
    exprs = []
    following_stmts = []
    build_readable_expression!(exprs, following_stmts, cond)
    to_expression(exprs, following_stmts)
end

function to_expression(exprs::Vector{Any}, following_stmts::Vector)
    bool_and(a, b) = Expr(:&&, a, b)
    if isempty(following_stmts)
        isempty(exprs) && return true
        foldr(bool_and, exprs)
    else
        init = Expr(:block, following_stmts..., true)
        foldr(bool_and, exprs, init = init)
    end
end

allsame(xs::Vector) = any(e -> e == xs[1], xs)

const CACHE_NO_CACHE = 0
const CACHE_MAY_CACHE = 1
const CACHE_CACHED = 2

function static_memo(
    f::Function,
    view_cache::ViewCache,
    op::APP;
    ty::TypeObject,
    depend::Union{Nothing, APP} = nothing,
)
    if op isa NoPre
        nothing
    elseif op isa NoncachablePre
        cached_sym = nothing
        f(cached_sym, CACHE_NO_CACHE)
    else
        cache_key = depend === nothing ? op : (depend => op)
        cache_key = Pair{TypeObject, Any}(ty, cache_key)
        cached = get(view_cache, cache_key) do
            nothing
        end::Union{Tuple{Symbol, Bool}, Nothing}
        if cached === nothing
            cached_sym = gensym("cache")
            computed_guarantee = false
        else
            (cached_sym, computed_guarantee) = cached
        end
        if !computed_guarantee
            f(cached_sym, CACHE_MAY_CACHE)
            view_cache[cache_key] = (cached_sym, true)
            cached_sym
        else
            f(cached_sym, CACHE_CACHED)
        end
    end
end

function init_cache(view_cache::ViewCache)
    block = Expr(:block)
    cache_syms = block.args
    # TODO: OPT
    for_chaindict_dup(view_cache) do _, (view_cache_sym, _)
        push!(cache_syms, :($view_cache_sym = nothing))
    end
    if isempty(cache_syms)
        true
    else
        block
    end
end

@static if !isdefined(Base, :ismutabletype)
    ismutabletype(x::Type) = x.mutable
end

function myimpl()
    function cache(f)
        function apply(env::CompileEnv, target::Target{true})::Cond
            target′ = target.with_repr(gensym(), Val(false))
            AndCond(TrueCond(:($(target′.repr) = $(target.repr))), f(env, target′))
        end
        function apply(env::CompileEnv, target::Target{false})::Cond
            f(env, target)
        end
        apply
    end

    wildcard(::Config) = (::CompileEnv, target::Target) -> TrueCond()

    literal(v, config::Config) = function ap_literal(::CompileEnv, target::Target)::Cond
        ty = typeof(v)
        if v isa Symbol
            v = QuoteNode(v)
        end
        (isprimitivetype(ty) || ty.size == 0 && !ismutabletype(ty)) ?
        CheckCond(:($(target.repr) === $v)) : CheckCond(:($(target.repr) == $v))
    end

    function and(ps::Vector{<:Function}, config::Config)
        @assert !isempty(ps)
        function ap_and_head(env::CompileEnv, target::Target{false})::Cond
            hd = ps[1]::Function
            tl = view(ps, 2:length(ps))
            init = hd(env, target)

            # the first conjuct must be executed, so the computation can get cached:
            # e.g.,
            #   match val with
            #   | View1 && View2 ->
            # and we know `View1` must be cached.
            (computed_guarantee′, env′, ret) = foldl(
                tl,
                init = (true, env, init),
            ) do (computed_guarantee, env, last), p
                # `TrueCond` means the return expression must be evaluated to `true`
                computed_guarantee′ = computed_guarantee && last isa TrueCond
                if !computed_guarantee′ && computed_guarantee
                    view_cache = env.view_cache
                    view_cache′ = child(view_cache)
                    view_cache_change = view_cache′.cur
                    env = env(view_cache = view_cache′)
                end
                computed_guarantee′, env, AndCond(last, p(env, target))
            end

            if !computed_guarantee′
                update_parent!(env′.view_cache)
            end
            ret
        end |> cache
    end

    function or(ps::Vector{<:Function}, config::Config)
        @assert !isempty(ps)
        function ap_or(env::CompileEnv, target::Target{false})::Cond
            or_checks = Cond[]
            scope = env.scope
            view_cache = env.view_cache
            scopes = Dict{Symbol, Symbol}[]
            n_ps = length(ps)
            for p in ps
                scope′ = child(scope)
                env′ = env(; scope = scope′, view_cache = view_cache)
                push!(or_checks, p(env′, target.clone))
                push!(scopes, scope′.cur)
            end

            # check the change of scope discrepancies for all branches
            intersected_new_names = reduce(
                intersect!,
                (keys(scope) for scope in scopes[2:n_ps]),
                init = Set(keys(scopes[1])),
            )

            for key in intersected_new_names
                refresh = gensym(key)
                for i in eachindex(or_checks)
                    check = or_checks[i]
                    old_name = scopes[i][key]
                    or_checks[i] =
                        AndCond(or_checks[i], TrueCond(:($refresh = $old_name)))
                end
                scope[key] = refresh
            end
            foldr(OrCond, or_checks)
        end |> cache
    end

    # C(p1, p2, .., pn)
    # pattern = (target: code, remainder: code) -> code
    function decons(comp::PComp, extract::Function, ps::Vector, config::Config)
        ty = config.type
        ln = config.ln

        function ap_decons(env, target::Target{false})::Cond
            # type check
            chk = if target.type <: ty
                TrueCond()
            else
                target.type_narrow!(ty)
                CheckCond(:($(target.repr) isa $ty))
            end

            scope = env.scope
            # compute pattern viewing if no guarantee of being computed
            view_cache = env.view_cache

            target_sym::Symbol = target.repr
            viewed_sym::Any = target_sym
            static_memo(view_cache, comp.guard1; ty = ty) do cached_sym, cache_flag
                if cache_flag === CACHE_CACHED
                    chk = AndCond(chk, CheckCond(:($cached_sym.value)))
                    return
                end

                if cache_flag === CACHE_NO_CACHE
                    guard_expr = comp.guard1(target_sym)
                    chk = AndCond(chk, CheckCond(guard_expr))
                elseif cache_flag === CACHE_MAY_CACHE
                    guard_expr = comp.guard1(target_sym)
                    do_cache = Expr(
                        :if,
                        :($cached_sym === nothing),
                        :($cached_sym = Some($guard_expr)),
                    )
                    chk = AndCond(
                        chk,
                        AndCond(TrueCond(do_cache), CheckCond(:($cached_sym.value))),
                    )
                else
                    error("impossible: invalid flag")
                end
                nothing
            end

            static_memo(view_cache, comp.view; ty = ty) do cached_sym, cache_flag
                if cache_flag === CACHE_NO_CACHE
                    viewed_sym = gensym()
                    viewed_expr = comp.view(target_sym)
                    chk = AndCond(TrueCond(:($viewed_sym = $viewed_expr)))
                elseif cache_flag === CACHE_CACHED
                    viewed_sym = :($cached_sym.value)
                elseif cache_flag === CACHE_MAY_CACHE
                    viewed_expr = comp.view(target_sym)
                    do_cache = Expr(
                        :if,
                        :($cached_sym === nothing),
                        :($cached_sym = Some($viewed_expr)),
                    )
                    chk = AndCond(chk, TrueCond(do_cache))
                    viewed_sym = :($cached_sym.value)
                else
                    error("impossible: invalid flag")
                end
                nothing
            end

            static_memo(
                view_cache,
                comp.guard2;
                ty = ty,
                depend = comp.view,
            ) do cached_sym, cache_flag
                if cache_flag === CACHE_CACHED
                    chk = AndCond(chk, CheckCond(:($cached_sym.value)))
                    return
                end

                if cache_flag === CACHE_NO_CACHE
                    guard_expr = comp.guard2(viewed_sym)
                    chk = AndCond(chk, CheckCond(guard_expr))
                elseif cache_flag === CACHE_MAY_CACHE
                    guard_expr = comp.guard2(viewed_sym)
                    do_cache = Expr(
                        :if,
                        :($cached_sym === nothing),
                        :($cached_sym = Some($guard_expr)),
                    )
                    chk = AndCond(
                        chk,
                        AndCond(TrueCond(do_cache), CheckCond(:($cached_sym.value))),
                    )
                else
                    error("impossible: invalid flag")
                end
                nothing
            end

            for i in eachindex(ps)
                p = ps[i]::Function
                field_target = Target{true}(
                    extract(viewed_sym, i, scope, ln),
                    Ref{TypeObject}(Any),
                )
                view_cache′ = ViewCache()
                env′ = env(; view_cache = view_cache′)
                elt_chk = p(env′, field_target)
                chk = AndCond(chk, AndCond(TrueCond(init_cache(view_cache′)), elt_chk))
            end
            chk
        end |> cache
    end

    function guard(pred::Function, config::Config)
        function ap_guard(env, target::Target{false})::Cond
            expr = pred(target.repr, env.scope, config.ln)
            expr === true ? TrueCond() : CheckCond(expr)
        end |> cache
    end

    function effect(perf::Function, config::Config)
        function ap_effect(env, target::Target{false})::Cond
            TrueCond(perf(target.repr, env.scope, config.ln))
        end |> cache
    end

    (
        and = and,
        or = or,
        literal = literal,
        wildcard = wildcard,
        decons = decons,
        guard = guard,
        effect = effect,
    )
end

const redy_impl = myimpl()

function compile_spec!(
    env::CompileEnv,
    suite::Vector{Any},
    x::Shaped,
    target::Target{IsComplex},
) where {IsComplex}
    if IsComplex && !(x.case isa Leaf)
        sym = gensym()
        push!(suite, :($sym = $(target.repr)))
        target = target.with_repr(sym, Val(false))
    end
    mkcond = re_tagless(x.pattern, x.ln)(redy_impl)
    ln = x.ln
    push!(suite, ln)
    cond = mkcond(env, target)
    conditional_expr = to_expression(cond)
    true_clause = Expr(:block)
    compile_spec!(env, true_clause.args, x.case, target)
    push!(
        suite,
        conditional_expr === true ? true_clause :
        Expr(:if, conditional_expr, true_clause),
    )
end

function compile_spec!(env::CompileEnv, suite::Vector{Any}, x::Leaf, target::Target)
    body = env.terminal[x.cont]
    ret = env.ret
    if env.hygienic
        bound = Expr(:block)
        let_expr = Expr(:let, bound, body)
        for_chaindict(env.scope) do k, v
            push!(bound.args, Expr(:(=), k, v))
        end
        push!(suite, Expr(:(=), ret, let_expr))
    else
        for_chaindict(env.scope) do k, v
            push!(suite, :($k = $v))
        end
        push!(suite, :($ret = $body))
    end
    push!(suite, CFGJump(env.final))
end

function compile_spec!(
    env::CompileEnv,
    suite::Vector{Any},
    x::SwitchCase,
    target::Target{IsComplex},
) where {IsComplex}
    if IsComplex
        sym = gensym()
        push!(suite, :($sym = $(target.repr)))
        target = target.with_repr(sym, Val(false))
    else
        sym = target.repr
    end

    for (ty, case) in x.cases
        true_clause = Expr(:block)
        # create new `view_cache` as only one case will be executed
        view_cache′ = child(env.view_cache)
        env′ = env(; scope = child(env.scope), view_cache = view_cache′)
        compile_spec!(env′, true_clause.args, case, target.with_type(ty))
        update_parent!(view_cache′)
        push!(suite, Expr(:if, :($sym isa $ty), true_clause))
    end
end

function compile_spec!(
    env::CompileEnv,
    suite::Vector{Any},
    x::EnumCase,
    target::Target{IsComplex},
) where {IsComplex}
    if IsComplex
        sym = gensym()
        push!(suite, :($sym = $(target.repr)))
        target = target.with_repr(sym, Val(false))
    end
    for case in x.cases
        # use old view_cache:
        # cases are tried in order,
        # hence `view_cache` can inherit from the previous case
        env′ = env(; scope = child(env.scope))
        compile_spec!(env′, suite, case, target.clone)
    end
end

function compile_spec(
    env::CompileEnv,
    target::Any,
    case::AbstractCase,
    ln::LineNumberNode,
)
    target = Target{true}(target, Ref{TypeObject}(Any))
    ret = Expr(:block)
    suite = ret.args
    if env.hygienic
        push!(suite, :($(env.ret) = nothing))
    end
    view_cache = env.view_cache

    compile_spec!(env, suite, case, target)
    pushfirst!(suite, init_cache(view_cache))

    msg = "matching non-exhaustive, at $ln"
    push!(suite, Expr(:call, error, msg))
    push!(suite, CFGLabel(env.final))
    push!(suite, env.ret)
    if env.hygienic
        # during match process can have functions that write variables.
        # hence,
        # 1. if the match expression is at global scope, write operations not allowed
        # 2. those write operations might affect outside scope.
        # to address this:
        ret = Expr(:let, Expr(:block), ret)
        # this applies to @match, but not to @switch
        # when using @switch, take care about unexpected write operations and
        # global variable issues.
    end
    CFGSpec(ret)
end

"""compile a series of `Term => Symbol`(match clauses/branches) to a Julia expression
"""
function backend(
    expr_to_match::Any,
    clauses::Vector{Pair{Function, Tuple{LineNumberNode, Int}}},
    terminal::Terminal,
    ln::LineNumberNode;
    hygienic::Bool = true,
)
    spec = spec_gen(clauses)
    env = CompileEnv(terminal, hygienic, gensym(:return), gensym(:final))
    compile_spec(env, expr_to_match, spec, ln)
end
end
