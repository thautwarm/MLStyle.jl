module StandardPatterns
# This module is designed for creating complex patterns from the primtive ones.

using MLStyle
using MLStyle.Toolz.List: cons, nil
using MLStyle.Infras
using MLStyle.MatchCore
using MLStyle.Qualification

struct TypeVar
    t :: Symbol
end

struct Relation
    l :: Symbol
    op :: Symbol
    r
end


function any_constraint(t, forall)

    function is_rel(::Relation)
        true
    end

    function is_rel(::TypeVar)
        false
    end

    !(t isa Symbol) || any(is_rel, collect(extract_tvars(forall)))
end

macro type_matching(t, forall)
    quote
        NAME = mangle(mod)
        __T__ = $t
        __FORALL__ = $forall
        if !($any_constraint(__T__, __FORALL__))
            function (body)
                @format [body, tag, NAME, TARGET, __T__] quote
                    @inline __L__ function NAME(TARGET :: __T__) where {$(__FORALL__...)}
                        __T__ # if not put this here, an error would be raised : "local variable XXX cannot be used in closure declaration"
                        body
                    end
                    NAME(tag)
                end
            end
        else
            function (body)
                @format [body, tag, NAME, TARGET, __T__] quote
                    @inline __L__ function NAME(TARGET :: __T__) where {$(__FORALL__...)}
                        __T__
                        body
                    end
                    @inline __L__ function NAME(_)
                        failed
                    end
                    NAME(tag)
                end
            end
        end
    end |> esc
end

function extract_tvars(t :: AbstractArray)
    @match t begin
        [] => nil()
        [hd && if hd isa Symbol end, tl...] => cons(TypeVar(hd), extract_tvars(tl))
        [:($hd <: $r), tl...] =>  cons(Relation(hd, :<:, r), extract_tvars(tl))
        [:($hd >: $(r)), tl...] =>  cons(Relation(hd, Symbol(">:"), r), extract_tvars(tl))
        _ => @error "invalid tvars"
    end
end

def_pattern(StandardPatterns,
        predicate = x -> x isa Expr && x.head == :(::),
        rewrite = (tag, case, mod) ->
                let args   = (case.args..., ),
                    TARGET = mangle(mod)
                    function for_type(t)
                        @match t begin
                            :($typ where {$(tvars...)}) => (@type_matching typ tvars)
                            _ => @typed_as t

                        end
                    end

                    function f(args :: NTuple{2, Any})
                        pat, t = args
                        for_type(t) ∘ mk_pattern(TARGET, pat, mod)
                    end

                    function f(args :: NTuple{1, Any})
                        t = args[1]
                        for_type(t)
                    end
                    f(args)
                end
)

export @active, def_active_pattern

function def_active_pattern(qualifier_ast, case, active_body, mod)
    (case_name, IDENTS, param) = @match case begin
        :($(case_name :: Symbol)($param)) => (case_name, nothing, param)
        :($(case_name :: Symbol){$(idents...)}($param)) => (case_name, idents, param)
    end
    TARGET = mangle(mod)

    if !isdefined(mod, case_name)
        mod.eval(quote struct $case_name end end)
    end
    qualifier = get_qualifier(qualifier_ast, mod)
    case_obj = getfield(mod, case_name)
    if IDENTS === nothing
        def_app_pattern(mod,
            predicate = (hd_obj, args) -> hd_obj === case_obj,
            rewrite = (tag, hd_obj, args, mod) -> begin
                    (test_var, pat) = @match length(args) begin
                        0 => (false, true)
                        1 => (nothing, args[1])
                        _ => (nothing, Expr(:tuple, args...))
                    end

                    function (body)
                        @format [tag, test_var, param, TARGET, active_body, body] quote
                            let  TARGET =
                                let param = tag
                                    active_body
                                end
                                TARGET === test_var ?  failed : body
                            end
                        end
                    end ∘ mk_pattern(TARGET, pat, mod)
                end,
            qualifiers = Set([qualifier]))
    else
        n_idents = length(IDENTS)
        def_gapp_pattern(mod,
            predicate = (spec_vars, hd_obj, args) -> hd_obj === case_obj && length(spec_vars) === n_idents,
            rewrite   = (tag, forall, spec_vars, hd_obj, args, mod) -> begin
                    (test_var, pat) = @match length(args) begin
                        0 => (false, true)
                        1 => (nothing, args[1])
                        _ => (nothing, Expr(:tuple, args...))
                    end
                    assign_elts_and_active_body =
                        let arr = [:($IDENT = $(spec_vars[i]))
                                    for (i, IDENT)
                                    in enumerate(IDENTS)]
                            Expr(:let, Expr(:block, arr...), Expr(:block, active_body))
                        end
                    function (body)
                        @format [tag, test_var, param, TARGET, assign_elts_and_active_body, body] quote
                            let TARGET =
                                let param = tag
                                    assign_elts_and_active_body
                                end
                                TARGET === test_var ?  failed : body
                            end
                        end
                    end ∘ mk_pattern(TARGET, pat, mod)
            end,
        qualifiers = Set([qualifier]))
    end
    nothing
end


"""
Simple active pattern.
You can give a qualifier in the first argument of `@active` to customize its visibility in other modules.

    @active F(x) begin
        if x > 0
            nothing
        else
            :ok
        end
    end

    @match -1 begin
        F(:ok) => false
        _ => true
    end # true

    @active public IsEven(x) begin
        x % 2 === 0
    end

    @match 4 begin
        IsEven() => :ok
        _ => :err
    end # :ok
"""
macro active(qualifier, case, active_body)
   def_active_pattern(qualifier, case, active_body, __module__)
end

macro active(case, active_body)
    def_active_pattern(:public, case, active_body, __module__)
end

end