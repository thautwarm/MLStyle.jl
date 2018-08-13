module Match

export @match, Pattern, Case, Failed, failed, register_meta_pattern, pattern_matching

using MLStyle.Err

struct Failed end

failed = Failed()

global meta_dispatchers = Vector{Tuple{Function, Function}}()
global app_dispatchers = Dict{Any, Function}()

global _count = 0


function mangling(apply, repr_ast)
    global _count = _count + 1
    let symbol = Symbol(repr(repr_ast)[2:end], ".", _count)
        ret = apply(symbol)
        global _count = _count - 1
        ret
    end
end

struct Pattern
    shape
    guard
end

struct Case
    patterns :: Vector{Pattern}
    body
end

@inline function collect_guard(arg)
    if isa(arg, Expr) && arg.head == :curly
    let args = arg.args
        Pattern(args[1],
                Expr(:block,
                     reduce( (a, b) -> Expr(:&&, a, b), args[2:end])
                     ))
    end
    else
        Pattern(arg, nothing)
    end
end

function collect_fallthrough(c :: Channel, arg)

    if isa(arg, Expr) && arg.head == :call && arg.args[1] == :|

        let nested = arg.args[2:end-1], last = collect_guard(arg.args[end])

            if isempty(nested)
                put!(c, last)
            else
                foreach(nested) do n
                    collect_fallthrough(c, n)
                end
                put!(c, last)
            end

        end

    else
        put!(c, collect_guard(arg))
    end
end

function collect_fallthrough(arg)
    Channel(c -> collect_fallthrough(c, arg))
end

_warned = false
function merge_cases(cases :: Vector{Case})

    global _warned
    if !_warned
        @warn "Pattern optimization not implemented yet."
        _warned = true
    end

    cases
end


pattern_matching_maker(tag :: Symbol, case :: Case, mod :: Module) =
    if isempty(case.patterns)
        InternalException("Internal Error 0") |> throw
    else let body = case.body,
             cond = map(case.patterns) do pattern
                    pattern_matching(pattern.shape, pattern.guard, tag, mod)
                   end |>
                   last -> reduce((a, b) -> Expr(:||, a, b), last)
        quote
            if $cond
                $(case.body)
            else
                $failed
            end
        end
        end
    end

function make_dispatch(tag, cases, mod :: Module)
    let cases =
        map(cases) do case
                if !(case.head == :call && case.args[1] == :(=>))
                    SyntaxError("A case should be something like <pattern> => <body>") |> throw
                end

                let args = case.args, pattern = args[2], body = args[3]
                    Case(append!([], collect_fallthrough(pattern)), body)
                end
        end
    let cases = merge_cases(cases)
        map(it -> pattern_matching_maker(tag, it, mod), cases)
    end
    end
end


macro match(target, pattern_def)

    if !isa(pattern_def, Expr) || !(pattern_def.head in (:braces, :bracescat, :block))
        SyntaxError("Invalid leading marker of match body.") |> throw
    end

    mangling(target) do tag_sym
        final =
            quote
                throw(($InternalException)("Non-exhaustive pattern found!"))
            end

        mangled = Symbol("case", ".", "test")
        
        args = 
            if pattern_def.head === :block 
                filter(it -> !isa(it, LineNumberNode), pattern_def.args)
            else 
                pattern_def.args 
            end 
        for dispatched in make_dispatch(tag_sym, args[end:-1:1], __module__)
            final =
                quote
                    let $mangled =
                        let
                            $dispatched
                        end
                    if $mangled === $failed
                        $final
                    else
                        $mangled
                    end
                    end
                end
        end

        quote
              let $tag_sym = $target
                $final
              end
        end |> esc
        end
end

function meta_pattern_match(expr :: Expr, guard, tag, mod :: Module)

    for (dispatcher_test, dispatch) in meta_dispatchers
        if dispatcher_test(expr)
            return dispatch(expr, guard, tag, mod)
        end
    end
    PatternUnsolvedException(expr) |> throw

end

function app_pattern_match(destructor, args, guard, tag, mod :: Module)
    global app_dispatchers
    fn = get(app_dispatchers, destructor, nothing)
    if fn === nothing 
        PatternUnsolvedException(:($destructor($(args...)))) |> throw 
    else 
        fn(args, guard, tag, mod)
    end 
end 

function register_meta_pattern(dispatch :: Function, dispatcher_test :: Function)
    global meta_dispatchers
    push!(meta_dispatchers, (dispatcher_test, dispatch));
end

function register_app_pattern(dispatch :: Function, destructor :: Any)
    global app_dispatchers
    push!(app_dispatchers, (destructor => dispatch))
end 

function register_app_pattern(args, tag, mod)
    matches = 
        map(args) do kv 
            if !(isa(kv, Expr) && kv.head === :call && kv.args[1] == :=>)
                SyntaxError("Dictionary destruct must take patterns like Dict(<expr> => <pattern>)") |> throw 
            end
            let (k, v) = kv.args[2:end]
                pattern_matching(v, nothing, :($tag[$k]), mod)
            end
        end

    check_ty = :($isa($tag, $Dict))

    check_keys =  
           map(it -> it[2], kv.args) |> 
           keys -> :($map(it -> it in $tag.keys, [$(keys...)]) |> all)


end

end # module

