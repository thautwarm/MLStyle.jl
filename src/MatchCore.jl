module MatchCore
import MLStyle.toolz: bind
using MLStyle.toolz.List
using MLStyle.toolz
using MLStyle.Err
using MLStyle.Render

# a token to denote matching failure
export Failed, failed
struct Failed end
const failed = Failed()

struct err_spec
    location :: LineNumberNode
    msg      :: String
end

struct config
    loc       :: LineNumberNode
    errs      :: linkedlist
end

# lens of config.
# Variables named in snake_case are marked as internal use
loc(conf      :: config)               = conf.loc
errs(conf     :: config)               = conf.errs
set_loc(loc   :: LineNumberNode)       = (conf) -> config(loc, conf.errs)
set_errs(errs :: linkedlist)           = (conf) -> config(conf.loc, errs)

# some useful utils:
err!(msg :: String) =
    bind(getBy $ loc)  do loc
    bind(getBy $ errs) do errs
    lens = set_errs $ cons(err_spec(loc, msg), errs)
    putBy(lens)
    end
    end


check_do(f, check_fn, err_fn) = expr ->
     if !check_fn(expr)
         err_fn(expr)
     else
         f(expr)
     end


# TODO: for friendly error report
recog_err(expr) :: String = "syntax error"

check_syntax(f, predicate) = begin
    check_fn = expr -> predicate(expr)
    err_fn   = expr -> bind(err! ∘ recog_err $ expr) do _
        return! $ nothing
    end
    check_do(f, check_fn, err_fn)
end

const init_state = config(LineNumberNode(1), nil())


# implementation of qualified pattern matching


export Qualifier
Qualifier = Function


export internal, invasive, share_with, share_through

internal = (my_mod, umod) -> my_mod === umod
invasive = (my_mod, umod) -> true
share_with(ms::Set{Module}) = (_, umod) -> umod in ms
share_through(symbol, value) = (_, umod) -> isdefined(umod, symbol) && getfield(umod, symbol) === true

export qualifier_test
function qualifier_test(qualifiers :: Set{Qualifier}, use_mod, def_mod)
    any(qualifiers) do q
        q(def_mod, use_mod)
    end
end

export PDesc
struct PDesc
    # for gapp patterns: (spec_vars :: Vector{Any}, gapobject :: Object, tl :: Vector{AST}) -> bool
    # for app patterns: (appobject :: Object, tl :: Vector{AST}) -> bool
    # for general    : (case:AST) -> bool

    predicate  :: Function

    # for gapp:
    #    (to_match : Symbol,
    #     forall :: Vector{Any},
    #     spec_vars :: Vector{Any},
    #     appobject :: Object,
    #     args :: Vector{AST},
    #     mod :: Module) -> (AST -> AST)
    # for app: (to_match  : Symbol, appobject: Object, args::Vector{AST}, mod::Module) -> (AST -> AST)
    # general: (to_match  : Symbol, case:AST, mod :: Module) -> (AST -> AST)
    rewrite    :: Function

    qualifiers :: Set{Qualifier}
end

PDesc(;predicate, rewrite, qualifiers) =
    PDesc(predicate, rewrite, qualifiers)

# A bug occurred when key is of Module type.
# Tentatively we use associate list(vector?).

const PATTERNS = Vector{Tuple{Module, PDesc}}()

export register_pattern

function register_pattern(pdesc :: PDesc, defmod :: Module)
    push!(PATTERNS, (defmod, pdesc))
end

# a simple example to define pattern `1`:
# tp = pattern_descriptor(
#       x -> x === 1,
#       (s, c, m) -> quote $s == 1 end,
#       Set([invasive])
#      )
# registerPattern(tp, MatchCore)

function get_pattern(case, use_mod :: Module)
    for (def_mod, desc) in PATTERNS
        if qualifier_test(desc.qualifiers, use_mod, def_mod) && desc.predicate(case)
           return desc.rewrite
        end
    end
end


is_head_eq(s :: Symbol) = (e::Expr) -> e.head == s

function collect_cases(expr :: Expr) :: State
    expr |>
    check_syntax(is_head_eq(:block))       do block
    bind(forM(collect_case, block.args))   do cases
    return! $ filter(a -> a !== nothing, cases)
    end
    end
end

function collect_case(expr :: LineNumberNode) :: State
    bind(putBy ∘ set_loc $ expr) do _
    return! $ nothing
    end
end

function collect_case(expr :: Expr) :: State
    expr |>
    check_syntax(is_head_eq(:call))            do expr
    expr.args |>
    check_syntax(args ->
                length(args) == 3 &&
                args[1]      == :(=>))      do (_, case, body)
    bind(getBy $ loc)                       do loc
    return! $ (loc, case, body)
    end
    end
    end
end

const INTERNAL_COUNTER = Dict{Module, Int}()

function remove_module_patterns(mod :: Module)
    delete!(INTERNAL_COUNTER, mod)
end

function get_name_of_module(m::Module) :: String
    string(m)
end


# allocate names for anonymous temporary variables.
export mangle
function mangle(mod::Module)
    get!(INTERNAL_COUNTER, mod) do
       0
    end |> id -> begin
    INTERNAL_COUNTER[mod] = id + 1
    mod_name = get_name_of_module(mod)
    Symbol("$mod_name $id")
    end

end


function match_impl(target, cbl, mod)
    # cbl: case body list
    # cbl = (fst ∘ (flip $ runState $ init_state) ∘ collectCases) $ cbl
    bind(collect_cases(cbl))                          do cbl
    # cbl :: [(LineNumberNodem, Expr, Expr)]
    tag_sym = mangle(mod)
    mk_match_body(target, tag_sym, cbl, mod)
    end
end


throw_from(errs) = begin
    # TODO: pretty print
    s = string(errs)
    throw(SyntaxError("$s"))
end

# the form:
# @match begin
#     ...
# end

export @match, gen_match

function gen_match(target, cbl, mod)
    (a, s) = runState $ match_impl(target, cbl, mod) $ init_state
    if isempty(s.errs)
        a
    else
        throw_from(s.errs)
    end
end

macro match(target, cbl)
    gen_match(target, cbl, __module__) |> esc
end

function mk_match_body(target, tag_sym, cbl, mod)
    bind(getBy $ loc) do loc # start 1
    final =
        @format [loc, throw, InternalException] quote
            loc
            throw(InternalException("Non-exhaustive pattern found!"))
        end
    result = mangle(mod)
    cbl = collect(cbl)
    main_logic =
       foldr(cbl, init=final) do (loc, case, body), last # start 2
           expr = mk_pattern(tag_sym, case, mod)(body)
           @format [
               result,
               expr,
               loc,
               failed,
               last
           ] quote
              loc
              result = expr
              result === failed ? last : result
           end
       end  # end 2
    return! $ @format [tag_sym, target, main_logic] quote
       let tag_sym = target
           main_logic
       end
    end
    end # end 1
end

export mk_pattern
function mk_pattern(tag_sym :: Symbol, case :: Any, mod :: Module)
    rewrite = get_pattern(case, mod)
    if rewrite !== nothing
        return rewrite(tag_sym, case, mod)
    end
    case = string(case)
    throw $ PatternUnsolvedException("invalid usage or unknown case $case")
end

end # module end
