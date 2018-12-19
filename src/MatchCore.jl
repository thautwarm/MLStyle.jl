module MatchCore
using MLStyle.toolz
using MLStyle.Err
using DataStructures: list, head, tail, cons, nil, reverse, LinkedList
struct err_spec
    location :: LineNumberNode
    msg      :: String
end

struct config
    loc       :: LineNumberNode
    errs      :: LinkedList{err_spec}
end

# lens
loc(conf      :: config)               = conf.loc
errs(conf     :: config)               = conf.errs
set_loc(loc   :: LineNumberNode)       = (conf) -> config(loc, conf.errs)
set_errs(errs :: LinkedList{err_spec}) = (conf) -> config(conf.loc, errs)

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

const init_state = config(LineNumberNode(1), nil(err_spec))


# implementation of qualified pattern matching

struct qualifier
    test :: Function
end

internal = qualifier((my_mod, umod) -> my_mod === umod)
invasive = qualifier((my_mod, umod) -> true)
shareWith(ms::Set{Module}) = qualifier(umod -> umod in ms)

function qualifierTest(qualifiers :: Set{qualifier}, use_mod, def_mod)
    any(qualifiers) do q
        q.test(def_mod, use_mod)
    end
end

struct pattern_descriptor
    # (case:AST) -> bool
    predicate  :: Function

    # (to_match: Symbol, case:AST, mod :: Module) -> Expr which's evaluated to bool
    rewrite    :: Function

    qualifiers :: Set{qualifier}
end

pattern_manager = Dict{Module, Vector{pattern_descriptor}}()

function get_pattern(case :: Expr, use_mod :: Module, def_mod :: Module)
   get!(pattern_manager, def_mod) do
      []
   end |> pattern_desc_lst ->
   for desc in pattern_desc_lst
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
    return! $ filter(a -> !isnothing(a), cases)
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

function mangle(mod::Module)
    get(internal_counter, mod) do
       0
    end |> id ->
    mod_name = getNameOfModule(mod)
    "$mod_name $id"

end


function matchImpl(target, cbl, mod)
    # cb: case body list
    # cb :: Expr
    cbl |>
    checkSyntax(a -> a isa Expr && a.head == :block) do target
    # cbl = (fst ∘ (flip $ runState $ init_state) ∘ collectCases) $ cbl
    bind(collectCases(cb))                           do cbl
    # cbl :: [(LineNumberNodem, Expr, Expr)]
    tag_sym = mangle(mod)
    mkMatchBody(target, tag_sym, cbl, mod)
    end
    end
end


throwFrom(errs) = begin
    # TODO: pretty print
    s = string(errs)
    SyntaxError("$s")
end

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
    final = quote
              $loc
              throw(($InternalException)("Non-exhaustive pattern found!"))
            end
    result = mangle(mod)
    cbl = collect(cbl)
    main_logic =
       foldr(cbl, init=final) do (loc, case, body), last # start 2
           expr = mkPattern(tag_sym, case, mod)
           quote
              let $result = # start 3
                  let
                     $loc
                     $expr
                  end
              if $result  === $failed
                    $last
              else
                   $result
              end
              end # end 3
           end
       end # end 2
    quote
       let $tag_sym = $tag
           $main_logic
       end
    end
    end # end 1
end


function mkPattern(tag_sym :: Symbol, case, mod :: Module)
   for (def_mod, _) in collect(pattern_manager)
       rewrite = get_pattern(case, mod, def_mod)
       if rewrite !== nothing
           return rewrite(tag_sym, case, mod)
       end
   end
   case = string(case)
   throw $ PatternUnsolvedException("invalid usage or unknown case $case")
end


end # module end
