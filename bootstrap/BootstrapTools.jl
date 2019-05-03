module BootstrapTools
export bootstrap_gen_pipeline

_name = r"##(.*?)#(\d+)"
_macro_head_line = r"#=.*?=# "
_quote_resume_evidence = r"begin(\s+)no_this_is_quote"
_macro_resume_evidence = r"begin(\s+)no_this_is_macro(\s+)function"
_qualifier = "($(Expr(:$, :MatchCore)))"
replace2(r) = x -> replace(x, r)

string_process =
    replace2(_qualifier => "\$MatchCore") ∘
    replace2(_macro_resume_evidence => s"begin\1macro") ∘
    replace2(_quote_resume_evidence => s"quote\1") ∘
    replace2(_macro_head_line => "") ∘
    replace2(_name => s"_mangled_sym_\2")


struct Discard end
const discard = Discard()

rmlines = @λ begin
    Expr(:macrocall, f, ln, args...) -> Expr(:macrocall, f, ln, map(rmlines, args)...)
    e :: Expr           -> Expr(e.head, filter(x -> x !== discard, map(rmlines, e.args))...)
      :: LineNumberNode -> discard
    a                   -> a
end

function conditional_macro_expand(enable_macros)
    inner = @λ begin
        Expr(:meta, _...) -> nothing
        Expr(:macro, call, block) -> Expr(:block, :no_this_is_macro, Expr(:function, call, block))
        (Expr(:quote, args...) && e) -> Expr(:block, :no_this_is_quote, args...)
        (Expr(:macrocall, name && if name in enable_macros end, args...) && e) -> inner(macroexpand(NS, e))
        e :: Expr           -> Expr(e.head, map(inner, e.args)...)
        a                   -> a
    end
end

bootstrap_gen_pipeline =
    string_process  ∘
    string  ∘
    rmlines ∘
    conditional_macro_expand([Symbol("@match"), Symbol("@matchast")])

end