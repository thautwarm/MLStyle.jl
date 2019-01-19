module Pervasive
using MLStyle.MatchCore
using MLStyle.Err
using MLStyle.toolz: ($), ast_and, ast_or, isCase, yieldAst, mapAst, runAstMapper
using MLStyle.Render: render, format
export Many, Do, Seq

export defPattern
function defPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerPattern(desc, mod)
end

export defAppPattern
function defAppPattern(mod; predicate, rewrite, qualifiers=nothing)
    qualifiers = qualifiers === nothing ? Set([invasive]) : qualifiers
    desc = pattern_descriptor(predicate, rewrite, qualifiers)
    registerAppPattern(desc, mod)
end

L = LineNumberNode(1)

macro format(args, template)
    args = Expr(:vect, :L, :failed, args.args...)
    esc(format(args, template))
end

macro typed_pattern(t)
    esc $ quote
        __T__ = $t
        function (body)
            @format [body, tag, TARGET, NAME, __T__] quote

                @inline L function NAME(TARGET :: __T__)
                    body
                end

                @inline L function NAME(TARGET)
                    failed
                end

                NAME(tag)
            end
        end
    end
end


def_pervasive(settings) = defPattern(Pervasive, predicate=settings[:predicate], rewrite=settings[:rewrite], qualifiers=nothing)
def_pervasive_app(settings) = defAppPattern(Pervasive, predicate=settings[:predicate], rewrite=settings[:rewrite], qualifiers=nothing)

# ============ Pattern operations ==================

function mkPatBy(f)
    (tag, case, mod) -> body ->
     @format [f, tag, case, body] quote
        f(tag, case) ? body : failed
     end
end

patternAnd = (p1, p2) -> p1 ∘ p2
patternOr  = (p1, p2) -> body ->
    let p1 = p1(body), p2 = p2(body)
        @format [p1, p2] quote
            p1 === failed ? p2 : p1
        end
    end

# ==================================================

# For app patterns
destructors = Vector{Tuple{Module, pattern_descriptor}}()

function mkAppPattern(tag, hd, tl, use_mod)
    hd = use_mod.eval(hd)
    for (def_mod, desc) in destructors
        if qualifierTest(desc.qualifiers, use_mod, def_mod) && desc.predicate(hd, tl)
            return desc.rewrite(tag, hd, tl, use_mod)
        end
    end
    info = string(hd) * string(tl)
    throw $ PatternUnsolvedException("invalid usage or unknown application case $info.")
end


export registerAppPattern
function registerAppPattern(pdesc :: pattern_descriptor, def_mod::Module)
    push!(destructors, (def_mod, pdesc))
end



# TODO: figure out the list of the mutabilities of `Number`'s subtypes and
#       use `===` instead of `==` for immutable types.

def_pervasive $ Dict(
        :predicate => x -> x isa Int,
        :rewrite => mkPatBy(===)
)

def_pervasive $ Dict(
        :predicate => x -> x isa Union{Number, AbstractString, QuoteNode},
        :rewrite   => mkPatBy(==)
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(||),
        :rewrite => (tag, case, mod) ->
            let pats = [mkPattern(tag, arg, mod) for arg in case.args]
                reduce(patternOr, pats)
            end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(&&),
        :rewrite => (tag, case, mod) ->
            let pats = [mkPattern(tag, arg, mod) for arg in case.args]
                reduce(patternAnd, pats)
            end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(::),
        :rewrite => (tag, case, mod) ->
                let args = (case.args..., ),
                    TARGET = mangle(mod),
                    NAME   = mangle(mod)

                    function f(args :: NTuple{2, Any})
                        pat, t = args
                        mkbody = mkPattern(TARGET, pat, mod)
                        (@typed_pattern t)∘ mkbody
                    end

                    function f(args :: NTuple{1, Any})
                        t = args[1]
                        @typed_pattern t
                    end

                    f(args)
                end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :(&),
        :rewrite => (tag, case, mod) -> begin
                @assert length(case.args) == 1 "invalid ref pattern."
                var = case.args[1]
                body -> @format [tag, var, body] quote
                   tag == var ? body : failed
                end
              end
)

# snake case for internal use.
is_captured(s)::Bool = !isempty(s) && islowercase(s[1])

def_pervasive $ Dict(
        :predicate => x -> x isa Symbol && x == :(_),
        :rewrite => (_, _, _) -> identity
)

def_pervasive $ Dict(
        :predicate => x -> x isa Symbol && is_captured ∘ string $ x,
        :rewrite => (tag, case, mod) -> body ->
        @format [case, tag, body] quote
            (@inline L function (case)
                body
            end)(tag)
        end
)

function mk_expr_template(expr :: Expr)
    if expr.head == :($)
        return expr.args[1]
    end
    rec = mk_expr_template
    Expr(:call, :Expr, rec(expr.head), filter(x -> x !== nothing, map(rec, expr.args))...)
end

function mk_expr_template(expr :: Symbol)
    QuoteNode(expr)
end

function mk_expr_template(expr :: LineNumberNode)
    nothing
end

function mk_expr_template(expr)
    expr
end


# Not decided of capitalized symbol's use case, for generic enum is impossible in Julia.
def_pervasive $ Dict(
        :predicate => isCase,
        :rewrite => (tag, case, mod) ->
        body -> @format [case, tag] quote
            # TODO: enum
            body
        end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :if,
        :rewrite   => (_, case, mod) ->
        # TODO: perform syntax validation here.
        let cond = case.args[1]
            body -> @format [cond, body] quote
                cond ? body : failed
            end
        end
)

def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head == :function,
        :rewrite   => (tag, case, mod) ->
        let n = length(case.args)
            if n === 1
                fn = case.args[1]
            else
                fn = case
            end
            body -> @format [body, fn, tag] quote
                fn(tag) ? body : failed
            end
        end
)


def_pervasive $ Dict(
        :predicate => x -> x isa Expr && x.head === :tuple,
        :rewrite   => (tag, case, mod) ->

        let pat_elts = case.args,
            n = length(pat_elts),
            TARGET = mangle(mod),
            NAME   = mangle(mod),
            IDENTS = [mangle(mod) for _ in 1:n]

            assign_elts = body ->
                let arr = [:($IDENT = $TARGET[$i])
                            for (i, IDENT)
                            in enumerate(IDENTS)]
                    Expr(:block, arr..., body)
                end

            match_elts = foldr(collect(enumerate(pat_elts)), init = identity) do (i, elt), last
                IDENT = IDENTS[i]
                mkPattern(IDENT, elt, mod) ∘ last
            end
            (@typed_pattern NTuple{n, Any}) ∘ assign_elts ∘ match_elts

        end
)

def_pervasive $ Dict(
    :predicate => x -> x isa Expr && x.head == :vect,
    :rewrite   => (tag, case, mod) -> begin
        elts = case.args
        orderedSeqMatch(tag, elts, mod)
    end
)

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === (:),
    :rewrite => (tag, hd_obj, args, mod) -> begin
        pat = Expr(:call, hd_obj, args...)
        body -> @format [pat, tag, body] quote
            tag in pat ? body : failed
        end
    end
)

# All AppPatterns are mastered by following general pattern:
def_pervasive $ Dict(
    :predicate => x -> x isa Expr && x.head == :call,
    :rewrite   => (tag, case, mod) ->
    let hd = case.args[1], tl = case.args[2:end]
    # @info :ExprCall
    # dump(case)
    mkAppPattern(tag, hd, tl, mod)
    end
)

# Expr template !!!
def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Expr && !isempty(args),
    :rewrite => (tag, hd_obj, args, mod) ->
        let lst        = mangle(mod),
            perf_match = orderedSeqMatch(lst, args, mod),
            NAME       = mangle(mod),
            TARGET     = mangle(mod),
            exprargs_to_arr(body) =
                @format [body, lst, TARGET] quote
                    lst = [TARGET.head, TARGET.args...]
                    body
                end

            (@typed_pattern Expr) ∘ exprargs_to_arr ∘ perf_match
        end
)

struct _ManyToken end
struct _DoToken end

Many   = _ManyToken()
Do     = _DoToken()


def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Many,
    :rewrite => (tag, hd_obj, args, mod) ->
    let inner = args[1],
        ITER_VAR = mangle(mod),
        TEST_VAR = mangle(mod),
        iter_check = mkPattern(ITER_VAR, inner, mod)(nothing)

        @assert length(args) === 1 "syntax form should be `Many(pat)`."
        body -> @format [ITER_VAR, TEST_VAR, tag, iter_check, body] quote
            TEST_VAR = true
            for ITER_VAR in tag
                if iter_check !== nothing
                    TEST_VAR = false
                    break
                end
            end
            TEST_VAR ? body : failed
        end
    end
)


function allow_assignment(expr :: Expr)
    head = expr.head == :kw ? :(=) : expr.head
    Expr(head, expr.args...)
end

function allow_assignment(expr)
    expr
end

def_pervasive_app $ Dict(
    :predicate => (hd_obj, args) -> hd_obj === Do,
    :rewrite => (_, _, args, _) ->
    let action = Expr(:block, map(allow_assignment, args)...)
        body -> @format [body, action] quote
            (@inline L function ()
                action
                body
            end)()
        end
    end
)


def_pervasive $ Dict(
       :predicate => x -> x isa Expr && x.head == :quote,
       :rewrite   => (tag, case, mod) -> begin
        expr = case.args[1]
        expr = mk_expr_template(expr)
        # @info :QuoteTemplate
        # dump(expr)
        mkPattern(tag, expr, mod)
       end
)

def_pervasive_app $ Dict(
        :predicate => (hd_obj, args) -> hd_obj === Dict,
        :rewrite => (tag, hd_obj, args, mod) ->
        let TARGET = mangle(mod),
            NAME   = mangle(mod)

            foldr(args, init=identity) do kv, last
                if !(isa(kv, Expr) && kv.head === :call && (@eval mod $(kv.args[1])) === Pair)
                    throw $
                    SyntaxError("Dictionary destruct must take patterns like Dict(<expr> => <pattern>, ...)")
                end
                let (k, v)    = kv.args[2:end],
                    IDENT     = mangle(mod),
                    match_elt = mkPattern(IDENT, v, mod)
                    function (body)
                        @format [IDENT, get, TARGET, k, body] quote
                            IDENT = get(TARGET, k) do
                                nothing
                            end
                            IDENT === nothing ? failed : body
                        end
                    end ∘ match_elt ∘ last
                end
            end |> match_kvs ->
            (@typed_pattern Dict) ∘ match_kvs
        end
)

# arbitray ordered sequential patterns match
function orderedSeqMatch(tag, elts, mod)
    TARGET = mangle(mod)
    NAME   = mangle(mod)

    length(elts) == 0 ?
    (
        (@typed_pattern AbstractArray) ∘
        function (body)
            @format [isempty, body, tag] quote
                isempty(tag) ? body : failed
            end
        end
    )              :

    begin
        atleast_element_count = 0
        unpack_begin          = nothing
        unpack_end            = 0
        unpack                = []
        foreach(elts) do elt

            if elt isa Expr && elt.head === :...
                if unpack_begin === nothing
                    unpack_begin = atleast_element_count + 1
                else
                    throw $
                    SyntaxError("Sequential unpacking can only be performed once at most.")
                end
                push!(unpack, elt.args[1])
            else
                atleast_element_count = atleast_element_count + 1

                IDENT = mangle(mod)
                perf_match = mkPattern(IDENT, elt, mod)
                index = unpack_begin === nothing ?
                    begin
                        :($TARGET[$atleast_element_count])
                    end                       :
                    begin
                        let exp = :($TARGET[end - $unpack_end])
                            unpack_end = unpack_end + 1
                            exp
                        end
                    end

                push!(
                    unpack,
                    let IDENT = IDENT, index = index
                        function (body)
                            @format [IDENT, body, index] quote
                                IDENT = index
                                body
                            end
                        end ∘ perf_match
                    end
                )
            end
        end

        if unpack_begin !== nothing
            IDENT = mangle(mod)
            check_len = body -> @format [body, TARGET, atleast_element_count, length] quote
                length(TARGET) >= atleast_element_count ? body : failed
            end
            elt = unpack[unpack_begin]
            unpack[unpack_begin] = function (body)
                @format [body, IDENT, TARGET, unpack_begin, unpack_end, length] quote
                    IDENT = view(TARGET, unpack_begin: (length(TARGET) - unpack_end))
                    body
                end
            end ∘ mkPattern(IDENT, elt, mod)

        else
            check_len = body -> @format [body, TARGET, length, atleast_element_count] quote
                length(TARGET) == atleast_element_count ? body : failed
            end
        end

        (@typed_pattern AbstractArray) ∘ check_len ∘ foldr(patternAnd, unpack)
    end
end

end
