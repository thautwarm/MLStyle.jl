module ADT

using MLStyle.Err
using MLStyle.Private
import MLStyle.Match: PatternDef, pattern_match

export @case, @data

function _check_components(arg)
    if !(isa(arg, Expr) && arg.head == :(::) ||
         isa(arg, Symbol)                    ||
         isa(arg, LineNumberNode))
        SyntaxError("`$arg`")
    end
end


macro case(cons)

    ty = nothing

    if isa(cons, Expr)
        if cons.head == :<:
            cons, ty = cons.args
        end
    end

    let cons =
        if isa(cons, Expr) && cons.head == :macrocall
                macroexpand(
                    __module__,
                    cons,
                    recursive=False) |> esc
        else
            cons
        end

    let args =
        if isa(cons, Expr) && cons.head == :call
            cons.args
        else
            [cons]
        end

    foreach(_check_components, args)

    let head = args[1], tail = args[2:end]

        # make struct
        if ty === nothing
            quote
                struct ($head)
                    $(tail...)
                end
            end

        else
            quote
                struct ($head) <: ($ty)
                    $(tail...)
                end
            end
        end |>
        function (ast)
            @eval __module__ $(ast)
        end

        most_union_all = get_most_union_all(head, __module__)

        # get fieldnames
        fields = fieldnames(most_union_all)

        PatternDef.App(most_union_all)  do  args, guard, tag, mod
            if length(args) != length(fields)
                DataTypeUsageError("Got patterns `$(repr(args))`, expected: `$fields`") |> throw
            end

            map(zip(fields, args)) do (field, arg)
                pattern_match(arg, nothing, :($tag.$field), mod)
            end |>
            function (last)
                reduce((a, b) -> Expr(:&&, a, b), last, init=:($tag isa $most_union_all))
            end |>
            function (last)
                if guard === nothing
                    last
                else
                    :($last && $guard)
                end
            end
        end
        nothing

    end
    end
    end
end

macro data(abs_ty, cases)

    if !isa(cases, Expr) || !(cases.head in (:block, :bracescat, :braces))
        SyntaxError("$(repr(cases)).") |> throw
    end

    @eval __module__ abstract type $abs_ty end

    map(cases.args) do case
        if isa(case, LineNumberNode)
            case
        else
            :(@case $case <: $abs_ty)
        end
    end |>
    function (last)
        quote
            $(last...)
        end |> esc
    end

end

end
