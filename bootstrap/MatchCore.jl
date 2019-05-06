MatchCore = :(
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
            $_ => throw(SyntaxError("Malformed syntax, expect `begin a => b; ... end` as match's branches., at " * string(init_loc)))
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
                _ => throw(SyntaxError("Malformed ast template, should be formed as `a => b`, at "* string(last_lnode) * "."))
            end
        end |> xs -> filter(x -> x !== nothing, xs)
        final = let loc_str = string(init_loc),
                    exc_throw = Expr(:call, InternalException, "Non-exhaustive pattern found, at " * loc_str * "!")
                    @format [init_loc, throw, exc_throw] quote
                        init_loc
                        throw(exc_throw)
                    end
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
        throw(PatternUnsolvedException("invalid usage or unknown case $case"))
     end
end)