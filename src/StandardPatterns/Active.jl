# Active patterns
module Active
using MLStyle
using MLStyle.Infras
using MLStyle.MatchCore
using MLStyle.Qualification
using MLStyle.TypeVarExtraction

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
Simple active pattern implementation.
You can give a qualifier in the first argument of `@active` to customize its visibility in other modules.
```julia
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
```
"""
macro active(qualifier, case, active_body)
   def_active_pattern(qualifier, case, active_body, __module__)
end

macro active(case, active_body)
    def_active_pattern(:public, case, active_body, __module__)
end

end