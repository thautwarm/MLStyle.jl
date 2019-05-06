using PrettyPrint

PrettyPrint.pprint_impl(io, sym :: Symbol, indent, newline) = print(io, repr(sym))

PrettyPrint.pprint_impl(io, expr :: Expr, indent, newline) = begin
    print(io, "Expr(\n")

    print(io, repeat(" ", indent + 2))
    print(io, repr(expr.head))
    print(io, ",\n")

    for each in expr.args
        print(io, repeat(" ", indent + 2))
        pprint(io, each, indent + 2, false)
        print(io, ",\n")
    end

    print(io, repeat(" ", indent))
    print(io, ")")
end


PrettyPrint.pprint_impl(io, expr :: GlobalRef, indent, newline) = begin
    print(io, "GlobalRef(\n")

    for each in [expr.mod, expr.name]
        print(io, repeat(" ", indent + 2))
        pprint(io, each, indent + 2, false)
        print(io, ",\n")
    end

    print(io, repeat(" ", indent))
    print(io, ")")
end

PrettyPrint.pprint_impl(io, lnode :: LineNumberNode, indent, newline) = begin
    print(io, "LineNumberNode(\n")

    for each in [lnode.line, lnode.file]
        print(io, repeat(" ", indent + 2))
        pprint(io, each, indent + 2, false)
        print(io, ",\n")
    end

    print(io, repeat(" ", indent))
    print(io, ")")
end

PrettyPrint.pprint_impl(io, qnode :: QuoteNode, indent, newline) = begin
    print(io, "QuoteNode(\n")

    print(io, repeat(" ", indent + 2))
    pprint(io, qnode.value, indent + 2, false)
    print(io, ",\n")

    print(io, repeat(" ", indent))
    print(io, ")")
end

PrettyPrint.pprint_impl(io, mod :: Union{Module, Type}, indent, newline) = begin
    print(io, mod)
end
