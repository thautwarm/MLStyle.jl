module Pervasives
using MLStyle.MatchCore
using MLStyle.Infras
using MLStyle.Extension
using MLStyle.Err
using MLStyle.toolz: ($)

import MLStyle.Infras: mk_gapp_pattern

@use GADT

function mk_pat_by(f)
    (tag, case, mod) -> body ->
     @format [f, tag, case, body] quote
        f(tag, case) ? body : failed
     end
end

const strict_eq_types = @static VERSION < v"1.1.0" ? Union{Int, Nothing} : Union{Int, String, Nothing}

def_pattern(Pervasives,
        predicate = x -> x isa strict_eq_types,
        rewrite = mk_pat_by(===)
)

def_pattern(Pervasives,
        predicate = x -> x isa Union{Number, AbstractString, AbstractChar, AbstractFloat, QuoteNode},
        rewrite   = (tag, case, mod) ->
        let f = isimmutable(case) ? mk_pat_by(===) : mk_pat_by(==)
            f(tag, case, mod)
        end
)

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head == :(||),
        rewrite = (tag, case, mod) ->
            let pats = [mk_pattern(tag, arg, mod) for arg in case.args]
                reduce(patternOr, pats)
            end
)

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head == :(&&),
        rewrite = (tag, case, mod) ->
            let pats = [mk_pattern(tag, arg, mod) for arg in case.args]
                reduce(∘, pats)
            end
)

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head == :(&),
        rewrite = (tag, case, mod) -> begin
                @assert length(case.args) == 1 "invalid ref pattern."
                var = case.args[1]
                body -> @format [tag, var, body] quote
                   tag == var ? body : failed
                end
        end
)

def_pattern(Pervasives,
        predicate = x -> x isa Symbol && x == :(_),
        rewrite = (_, _, _) -> identity
)

def_pattern(Pervasives,
        predicate = x -> x isa Symbol && x == :nothing,
        rewrite = mk_pat_by(===)
)

islower(s)::Bool = !isempty(s) && islowercase(s[1])
isupper(s)::Bool = !isempty(s) && isuppercase(s[1])

def_pattern(Pervasives,
        predicate = x -> x isa Symbol && islower ∘ string $ x,
        rewrite = (tag, case, mod) -> body ->
        @format [case, tag, body] quote
            let case = tag
                body
            end
        end
)

# Not decided yet about capitalized symbol's semantics, for generic enum is impossible in Julia.
def_pattern(Pervasives,
        predicate = x -> x isa Symbol && isupper ∘ string $ x,
        rewrite = (tag, case, mod) ->
        if used(:Enum, mod)
            mk_app_pattern(tag, case, [], mod)
        elseif used(:UppercaseCapturing, mod)
            body ->
            @format [case, tag, body] quote
                let case = tag
                    body
                end
            end
        else
            @syntax_err "You should use extension `Enum` or `UppercaseCapturing` to specify the behaviour of $(string(case))."
        end
)

def_pattern(Pervasives,
    predicate = x -> x isa Expr && x.head === :curly,
    rewrite = (tag, case, mod) -> mk_gapp_pattern(tag, [], case, [], mod)
)

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head == :if,
        rewrite   = (_, case, mod) ->
        # TODO: perform syntax validation here.
        let cond = case.args[1]
            body -> @format [cond, body] quote
                cond ? body : failed
            end
        end
)

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head == :function,
        rewrite  = (tag, case, mod) ->
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

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head === :tuple,
        rewrite  = (tag, case, mod) ->
        let pat_elts = case.args,
            n = length(pat_elts),
            TARGET = mangle(mod),
            IDENTS = [mangle(mod) for _ in 1:n]
            map(1:n) do i
                IDENT = IDENTS[i]
                elt = pat_elts[i]
                function (body)
                    Expr(:block, Expr(:(=), IDENT, :($TARGET[$i])), body)
                end ∘ mk_pattern(IDENT, elt, mod)
            end |> match_elts ->
            let match_elts =  reduce(∘, match_elts, init=identity)
                (@typed_as NTuple{n, Any}) ∘ match_elts
            end
        end
)


def_pattern(Pervasives,
    predicate = x -> x isa Expr && x.head == :vect,
    rewrite   = (tag, case, mod) -> begin
        elts = case.args
        ordered_seq_match(tag, elts, mod)
    end
)

struct QuotePattern
        value
end

function mk_expr_template(expr :: Expr)
    if expr.head == :($)
        return expr.args[1]
    end
    rec = mk_expr_template
    Expr(:call, :Expr, rec(expr.head), filter(x -> x !== _discard, map(rec, expr.args))...)
end

struct Discard end
const _discard = Discard()

function mk_expr_template(expr :: Symbol)
        QuoteNode(expr)
end

function mk_expr_template(expr :: QuoteNode)
        QuotePattern(expr.value)
end

function mk_expr_template(expr :: LineNumberNode)
    _discard
end

function mk_expr_template(expr)
        expr
end


def_pattern(Pervasives,
       predicate = x -> x isa Expr && x.head == :quote,
       rewrite  = (tag, case, mod) -> begin
        expr = case.args[1]
        expr = mk_expr_template(expr)
        mk_pattern(tag, expr, mod)
       end
)


def_pattern(Pervasives,
       predicate = x -> x isa QuotePattern,
       rewrite  = (tag, case, mod) -> begin
        expr = case.value
        expr = mk_expr_template(expr)
        TARGET = mangle(mod)
        VALUE = mangle(mod)
        access_value(body) =
            @format [body, TARGET, VALUE] quote
                let VALUE = TARGET.value
                    body
                end
            end
        (@typed_as QuoteNode) ∘  access_value ∘ mk_pattern(VALUE ,expr, mod)
       end
)


def_app_pattern(Pervasives,
    predicate = (hd_obj, args) -> hd_obj === (:),
    rewrite = (tag, hd_obj, args, mod) -> begin
        pat = Expr(:call, hd_obj, args...)
        body -> @format [pat, tag, body] quote
            tag in pat ? body : failed
        end
    end
)

def_app_pattern(Pervasives,
    predicate = (hd_obj, args) -> hd_obj === Expr && !isempty(args),
    rewrite = (tag, hd_obj, args, mod) ->
    let TARGET     = mangle(mod)
        length(args) === 1 ?
        let arg = args[1]
            (arg isa Expr && arg.head === :...) ?
            let _          = (@assert length(arg.args) === 1),
                lst        = mangle(mod),
                arg        = arg.args[1],
                perf_match = mk_pattern(lst, arg, mod)
                exprargs_to_arr(body) =
                    @format [body, lst, TARGET] quote
                        lst = [TARGET.head, TARGET.args...]
                        body
                    end
                (@typed_as Expr) ∘ exprargs_to_arr ∘ perf_match
            end :
            let HEAD = mangle(mod),
                perf_match = mk_pattern(HEAD, arg, mod)
                bind_head(body) =
                    @format [body, HEAD, TARGET] quote
                        !isempty(TARGET.args) ? failed :
                        let HEAD = TARGET.head
                            body
                        end
                    end
                (@typed_as Expr) ∘ bind_head ∘ perf_match
            end
        end :
        let HEAD       = mangle(mod),
            ARGS       = mangle(mod)

            head_pat = args[1]
            args_pat = args[2:end]

            assign_attrs(body) =
                @format [body, HEAD, ARGS, TARGET] quote
                    let (HEAD, ARGS) = (TARGET.head, TARGET.args)
                        body
                    end
                end

            (@typed_as Expr) ∘ assign_attrs ∘ mk_pattern(HEAD, head_pat, mod) ∘ ordered_seq_match(ARGS, args_pat, mod)
        end
    end
)

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head == :(::),
        rewrite = (tag, case, mod) ->
                let args   = (case.args..., ),
                    TARGET = mangle(mod)
                    function f(args :: NTuple{2, Any})
                        pat, t = args
                        (@typed_as t) ∘ mk_pattern(TARGET, pat, mod)
                    end

                    function f(args :: NTuple{1, Any})
                        t = args[1]
                        @typed_as t
                    end
                    f(args)
                end,
        qualifiers = Set([internal])
)

def_app_pattern(Pervasives,
        predicate = (hd_obj, args) -> hd_obj === Dict,
        rewrite = (tag, hd_obj, args, mod) ->
        let TARGET = mangle(mod)

            foldr(args, init=identity) do kv, last
                if !(isa(kv, Expr) && kv.head === :call && (@eval mod $(kv.args[1])) === Pair)
                    throw $
                    SyntaxError("Dictionary destruct must take patterns like Dict(<expr> => <pattern>, ...)")
                end
                let (k, v)    = kv.args[2:end],
                    IDENT     = mangle(mod),
                    match_elt = mk_pattern(IDENT, v, mod)
                    function (body)
                        @format [IDENT, TARGET, get, k, body] quote
                            IDENT = get(TARGET, k) do
                                failed
                            end
                            IDENT === failed ? failed : body
                        end
                    end ∘ match_elt ∘ last
                end
            end |> match_kvs ->
            (@typed_as Dict) ∘ match_kvs
        end
)

# arbitray ordered sequential patterns match
function ordered_seq_match(tag, elts, mod)

        TARGET = mangle(mod)
        NAME = mangle(mod)
        T = mangle(mod)
        function check_generic_array(body)
            @format [AbstractArray, NAME, TARGET, body, T, tag] quote

                @inline __L__ function NAME(TARGET :: AbstractArray{T, 1}) where {T}
                    body
                end

                @inline __L__ function NAME(_)
                    failed
                end

                NAME(tag)

            end
        end
        length(elts) == 0 ?
        (
            check_generic_array ∘
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
                    if elt === :_
                        push!(unpack, identity)
                    else
                        perf_match = mk_pattern(IDENT, elt, mod)
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
            end
            if unpack_begin !== nothing
                IDENT = mangle(mod)
                check_len = body -> @format [body, TARGET, atleast_element_count, length] quote
                    length(TARGET) >= atleast_element_count ? body : failed
                end
                elt = unpack[unpack_begin]
                if elt === :_
                    unpack[unpack_begin] = identity
                else
                    unpack[unpack_begin] = function (body)
                        @format [body, IDENT, TARGET, unpack_begin, unpack_end, length] quote
                            IDENT = view(TARGET, unpack_begin: (length(TARGET) - unpack_end))
                            body
                        end
                    end ∘ mk_pattern(IDENT, elt, mod)
                end
            else
                check_len = body -> @format [body, TARGET, length, atleast_element_count] quote
                    length(TARGET) === atleast_element_count ? body : failed
                end
            end
            check_generic_array ∘ check_len ∘ foldr(∘, unpack)

        end
end


struct _ManyToken end
struct _DoToken end

export Many, Do
Many   = _ManyToken()
Do     = _DoToken()


function allow_assignment(expr :: Expr)
        head = expr.head == :kw ? :(=) : expr.head
        Expr(head, expr.args...)
end

function allow_assignment(expr)
        expr
end

def_app_pattern(Pervasives,
        predicate = (hd_obj, args) -> hd_obj === Do,
        rewrite = (_, _, args, _) ->
        let action = Expr(:block, map(allow_assignment, args)...)
                body -> @format [body, action] quote
                        (@inline __L__ function ()
                                action
                                body
                        end)()
                end
        end
)


def_app_pattern(Pervasives,
    predicate = (hd_obj, args) -> hd_obj === Many,
    rewrite   = (tag, hd_obj, args, mod) ->
    let inner = args[1],
        ITER_VAR = mangle(mod),
        TEST_VAR = mangle(mod),
        iter_check = mk_pattern(ITER_VAR, inner, mod)(nothing)

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

def_pattern(Pervasives,
        predicate = x -> x isa Expr && x.head === :where,
        rewrite = (tag, case, mod) ->
        begin
            if !used(:GADT, mod)
                @syntax_err "GADT extension hasn't been enabled. Try `@use GADT` and run your codes again."
            end
            # Not sure about if there's any other references of `where`,
            # but GADT is particularly important,
            # Tentatively, we use `where` for GADT support only.
            @match case begin
                :($hd($(tl...)) where {$(forall...)}) => mk_gapp_pattern(tag, forall, hd, tl, mod)
                _ =>
                    @syntax_err "Unknown usage of `where` in pattern region. Currently `where` is used for only GADT syntax."
            end
        end
)

function mk_gapp_pattern(tag, forall, hd, tl, use_mod)
        @match hd begin
            ::Symbol && if isempty(forall) end => mk_app_pattern(tag, hd, tl, use_mod)
            :($(ctor :: Symbol){$(spec_vars...)}) || ctor :: Symbol && Do(spec_vars = [])=>
                begin
                    if isdefined(use_mod, ctor)
                        ctor = use_mod.eval(ctor)
                        for (def_mod, desc) in Infras.GAPP_DESTRUCTORS
                            if qualifier_test(desc.qualifiers, use_mod, def_mod) && desc.predicate(spec_vars, ctor, tl)
                                return desc.rewrite(tag, forall, spec_vars, ctor, tl, use_mod)
                            end
                        end
                    end
                    info = string(hd) * string(tl)
                    throw $ PatternUnsolvedException("invalid usage or unknown application case $info.")
                end
        end
end



end