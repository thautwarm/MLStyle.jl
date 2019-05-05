"""
for expanding macros
"""
module MLBootstrap
    using MLStyle
    using MLStyle.Render
    using MLStyle.Modules.AST
end
include("CodeDumper.jl")
using MLStyle
export bootstrap_gen_pipeline

struct Discard end
const discard = Discard()

function conditional_macro_expand(enable_macros)
    inner = @λ begin
        (Expr(:macrocall, name && if name in enable_macros end, args...) && e) -> inner(macroexpand(MLBootstrap, e))
        e :: Expr           -> Expr(e.head, map(inner, e.args)...)
        a                   -> a
    end
end


function bootstrap(expr, macros_to_expand::Vector{Any} = convert(Vector{Any}, [:match, :matchast]))
    (modname, toplevels) = @match expr begin
        :(module $modname; $(toplevels...) end) => (modname, toplevels)
    end

    macros_to_expand = [Symbol("@", each) for each in macros_to_expand]
    io = IOBuffer()
    println(io, "# This file is automatically generated by MLStyle Boostrap Tools.")
    println(io, "module $(modname)")
    println(io, "using MLStyle")
    expr_to_str = conditional_macro_expand(macros_to_expand)
    for toplevel in toplevels
        print(io, "@eval \$(")
        pprint(io, expr_to_str(toplevel))
        println(io, ")")
    end
    println(io, "end")
    String(take!(io))
end

gen_file(fname, node) = open(fname, "w") do f
        write(f, bootstrap(node))
end