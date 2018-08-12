module ADT
using MLStyle.Err
export @case

function _check_components(arg)
    if !(isa(arg, Expr) && arg.head == :(::) ||
         isa(arg, Symbol)                    ||
         isa(arg, LineNumberNode))
        SyntaxError("`$arg`")
    end
end


macro case(cons)
    ty = nothing

    if !(cons.head in (:call, :macrocall, :<:))
        SyntaxError("Invalid Syntax `$(repr(cons))`") |> throw
    end

    if cons.head == :<:
        cons, ty = cons.args

    end

    let cons =
        if cons.head == :macrocall

                macroexpand(
                    Base.@__MODULE__,
                    cons,
                    recursive=False) |> esc
        else
            cons
        end

    let args = cons.args

    foreach(_check_components, args)

    let head = args[1], tail = args[2:end]
        if ty === nothing
            quote
                struct ($head)
                    $(tail...)
                end
            end |> esc
        else
            quote
                struct ($head) <: ($ty)
                    $(tail...)
                end
            end |> esc
        end

    end
    end
    end
end
end
