module MatchCore
import MLStyle.toolz: bind
using MLStyle.toolz.List
using MLStyle.toolz
using MLStyle.Err
using MLStyle.Render

# a token to denote matching failure
export Failed, failed
struct Failed end
failed = Failed()

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


checkDo(f, check_fn, err_fn) = expr ->
     if !check_fn(expr)
         err_fn(expr)
     else
         f(expr)
     end


# TODO: for friendly error report
recogErr(expr) :: String = "syntax error"

checkSyntax(f, predicate) = begin
    check_fn = expr -> predicate(expr)
    err_fn   = expr -> bind(err! ∘ recogErr $ expr) do _
        return! $ nothing
    end
    checkDo(f, check_fn, err_fn)
end

const init_state = config(LineNumberNode(1), nil())


# implementation of qualified pattern matching

export qualifier, internal, invasive, shareWith, shareThrough

struct qualifier
    test :: Function
end

internal = qualifier((my_mod, umod) -> my_mod === umod)
invasive = qualifier((my_mod, umod) -> true)
shareWith(ms::Set{Module}) = qualifier((_, umod) -> umod in ms)
shareThrough(symbol, value) = qualifier((_, umod) -> isdefined(umod, symbol) && getfield(umod, symbol) === true)

export qualifierTest
function qualifierTest(qualifiers :: Set{qualifier}, use_mod, def_mod)
    any(qualifiers) do q
        q.test(def_mod, use_mod)
    end
end

struct pattern_descriptor
    # for appPatterns: (object :: Object, tl :: Vector{AST}) -> bool
    # for general    : (case:AST) -> bool
    predicate  :: Function

    # for app: (to_match: Symbol, caseObj: Any, args::Vector{AST}, mod::Module) -> Expr
    # general: (to_match: Symbol, case:AST, mod :: Module) -> Expr which's evaluated to bool
    rewrite    :: Function

    qualifiers :: Set{qualifier}
end

pattern_descriptor(;predicate, rewrite, qualifiers) =
    pattern_descriptor(predicate, rewrite, qualifiers)

# A bug occurred when key is of Module type.
# Tentatively we use associate list(vector?).

pattern_manager = Vector{Tuple{Module, pattern_descriptor}}()

export registerPattern, pattern_descriptor

function registerPattern(pdesc :: pattern_descriptor, defmod :: Module)
    push!(pattern_manager, (defmod, pdesc))
end

# a simple example to define pattern `1`:
# tp = pattern_descriptor(
#       x -> x === 1,
#       (s, c, m) -> quote $s == 1 end,
#       Set([invasive])
#      )
# registerPattern(tp, MatchCore)

function getPattern(case, use_mod :: Module)
    for (def_mod, desc) in pattern_manager
        # @info a
        # @info b
        # @info def_mod
        # @info desc

        if qualifierTest(desc.qualifiers, use_mod, def_mod) && desc.predicate(case)
           return desc.rewrite
        end
    end
    return nothing
end

# the form:
# @match begin
#     ...
# end
isHeadEq(s :: Symbol) = (e::Expr) -> e.head == s

function collectCases(expr :: Expr) :: State
    expr |>
    checkSyntax(isHeadEq(:block))       do block
    bind(forM(collectCase, block.args)) do cases
    return! $ filter(a -> a !== nothing, cases)
    end
    end
end

function collectCase(expr :: LineNumberNode) :: State
    bind(putBy ∘ set_loc $ expr) do _
    return! $ nothing
    end
end

function collectCase(expr :: Expr) :: State
    expr |>
    checkSyntax(isHeadEq(:call))            do expr
    expr.args |>
    checkSyntax(args ->
                length(args) == 3 &&
                args[1]      == :(=>))      do (_, case, body)
    bind(getBy $ loc)                       do loc
    return! $ (loc, case, body)
    end
    end
    end
end

# macro match

# allocate names for anonymous temporary variables.

internal_counter = Dict{Module, Int}()

function removeModulePatterns(mod :: Module)
    delete!(internal_counter, mod)
end

function getNameOfModule(m::Module) :: String
    string(m)
end

export mangle
function mangle(mod::Module)
    get!(internal_counter, mod) do
       0
    end |> id -> begin
    internal_counter[mod] = id + 1
    mod_name = getNameOfModule(mod)
    Symbol("$mod_name $id")
    end

end


function matchImpl(target, cbl, mod)
    # cbl: case body list
    # cbl = (fst ∘ (flip $ runState $ init_state) ∘ collectCases) $ cbl
    bind(collectCases(cbl))                          do cbl
    # cbl :: [(LineNumberNodem, Expr, Expr)]
    tag_sym = mangle(mod)
    mkMatchBody(target, tag_sym, cbl, mod)
    end
end


throwFrom(errs) = begin
    # TODO: pretty print
    s = string(errs)
    throw(SyntaxError("$s"))
end

export @match
macro match(target, cbl)
   (a, s) = runState $ matchImpl(target, cbl, __module__) $ init_state
   if isempty(s.errs)
       esc $ a
   else
       throwFrom(s.errs)
   end
end



function mkMatchBody(target, tag_sym, cbl, mod)
    bind(getBy $ loc) do loc # start 1
    final =
        @format [loc] quote
            loc
            throw(($InternalException)("Non-exhaustive pattern found!"))
        end
    result = mangle(mod)
    cbl = collect(cbl)
    main_logic =
       foldr(cbl, init=final) do (loc, case, body), last # start 2
           expr   = mkPattern(tag_sym, case, mod)
           @format [
               result,
               expr,
               body,
               loc,
               failed,
               last
           ] quote
              let result = # start 3
                  let
                     loc
                     if expr
                        body
                     else
                        failed
                     end
                  end
              if result  === failed
                   last
              else
                   result
              end
              end # end 3
           end
       end  # end 2
    return! $
    quote
       let $tag_sym = $target
           $main_logic
       end
    end
    end # end 1
end


export mkPattern
function mkPattern(tag_sym :: Symbol, case :: Any, mod :: Module)
    rewrite = getPattern(case, mod)
    if rewrite !== nothing
        return rewrite(tag_sym, case, mod)
    end
    case = string(case)
    throw $ PatternUnsolvedException("invalid usage or unknown case $case")
end




end # module end
