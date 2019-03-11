using MLStyle

module NS
using MLStyle.Modules.AST
using MLStyle
using MLStyle.Render
end

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


MatchCore =:(
module MatchCore
    using MLStyle
    using MLStyle.Toolz.List
    using MLStyle.Err
    using MLStyle.Render
    

    export Failed, failed
    struct Failed end
    const failed = Failed()

    export Qualifier
    Qualifier = Function


    export internal, invasive, share_with, share_through

    internal = (my_mod, umod) -> my_mod === umod
    invasive = (my_mod, umod) -> true
    share_with(ms::Set{Module}) = (_, umod) -> umod in ms

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
    function get_pattern(case, use_mod :: Module)
        for (def_mod, desc) in PATTERNS
            if qualifier_test(desc.qualifiers, use_mod, def_mod) && desc.predicate(case)
                return desc.rewrite
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


    export mangle    
    function mangle(mod::Module)
        get!(INTERNAL_COUNTER, mod) do
            0
        end |> id -> begin
            INTERNAL_COUNTER[mod] = id + 1
            mod_name = get_name_of_module(mod)
            gensym("$mod_name $id")
        end

    end

    export gen_match, @match
    macro match(target, cbl)
       gen_match(target, cbl, __source__, __module__) |> esc
    end

    function gen_match(target, cbl, init_loc :: LineNumberNode, mod :: Module)
        branches = @matchast cbl quote
            begin
                $((branches && Many(:($a => $b) || ::LineNumberNode))...)
            end => branches
            _ => @syntax_err "Malformed syntax, expect `begin a => b; ... end` as match's branches."
        end
        loc = init_loc
        branches_located = map(branches) do each
            @match each begin
                :($pattern => $body) =>
                    (pattern, body, loc)
                curloc::LineNumberNode =>
                    begin
                        loc = curloc
                        nothing
                    end
            end
        end |> xs -> filter(x -> x !== nothing, xs)
        final =
            @format [init_loc, throw, InternalException] quote
                init_loc
                throw(InternalException("Non-exhaustive pattern found!"))
            end
        result = mangle(mod)  # return of pattern matching
        tag_sym = mangle(mod) # value to match
        
        foldr(branches_located, init=final) do (pattern, body, loc), last
            expr = mk_pattern(tag_sym, pattern, mod)(body)
            @format [
                result,
                expr,
                loc,
                MatchCore,
                last
            ] quote
                loc
                result = expr
                result === $MatchCore.failed ? last : result
            end
        end |> main_logic ->
        @format [tag_sym, target, main_logic] quote
            let tag_sym = target
                main_logic
            end
        end
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
end)

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

# bootstrap_gen_pipeline(
#     quote
#     @format  [a] quote
#     a + 1
#     end
#     end) |> println

open("../src/MatchCore.jl", "w") do f
    write(f, """
# This file is automatically generated by MLStyle Boostrap Tools.
    """)
    write(f, bootstrap_gen_pipeline(MatchCore))
end

