module Match

export @match, Pattern, Case, Failed, failed, register_meta_pattern, pattern_matching

using MLStyle.Err

struct Failed end

failed = Failed()

global meta_dispatchers = Vector{Tuple{Function, Function}}()

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
        @warn "Pattern optimaztion notImplemented yet."
        _warned = true
    end

    cases
end



pattern_matching(num :: Number, guard, tag, mod :: Module) =
    if guard == nothing
        :($tag === $num)
    else
        :($tag === $num && $guard)
    end

pattern_matching(sym :: Symbol, guard, tag, mod :: Module) =
    
        if sym === :_ 
            if nothing === guard 
                quote true end 
            else 
                guard 
            end 
        else 
            let ret = 
                quote
                        $sym = $tag
                        true
                end
                if guard === nothing 
                    ret 
                else 
                    :(ret && guard)
                end
            end 
        end 

function pattern_matching(expr :: Expr, guard, tag, mod :: Module)

    for (dispatcher_test, dispatch) in meta_dispatchers
        if dispatcher_test(expr)
            return dispatch(expr, guard, tag, mod)
        end
    end
    PatternUnsolvedException(expr) |> throw

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

    mangling(target) do tag_sym
        final =
            quote
                throw(($InternalException)("Non-exhaustive pattern found!"))
            end

        mangled = Symbol("case", ".", "test")

        for dispatched in make_dispatch(tag_sym, pattern_def.args[end:-1:1], __module__)
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

function register_meta_pattern(dispatch :: Function, dispatcher_test :: Function)
    global meta_dispatchers
    push!(meta_dispatchers, (dispatcher_test, dispatch));
end

# """
# like ^ in Erlang/Elixir
# """
register_meta_pattern((expr :: Expr) -> expr.head == :&) do expr, guard, tag, mod
    value = expr.args[1]
    if guard === nothing
        :($tag === $value)
    else
        :($tag === $value && $guard)
    end
end

# """
# ADT destruction
#
# @assert 2 == @match S(1, 2) {
#     S(1, b) => b
#     _       => @error
# }
#
# """
register_meta_pattern((expr :: Expr) -> expr.head == :call) do expr, guard, tag, mod

    destructor = @eval mod $(expr.args[1])

    fields = fieldnames(destructor)

    args = expr.args[2:end]

    if length(args) != length(fields)
        DataTypeUsageError("Got patterns `$(repr(args))`, expected: `$fields`") |> throw
    end


    ret =
        map(zip(fields, args)) do (field, arg)
            pattern_matching(arg, nothing, :($tag.$field), mod)
        end |> last -> reduce((a, b) -> Expr(:&&, a, b), last, init=:(isa($tag, $destructor)))

    if guard !== nothing
        ret = :($ret && $guard)
    end

    ret
end

end # module
