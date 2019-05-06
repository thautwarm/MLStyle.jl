# Type variable deconstruction patterns
module TypeVarDecons
using MLStyle
using MLStyle.Infras
using MLStyle.MatchCore
using MLStyle.Qualification
using MLStyle.TypeVarExtraction

export type_matching

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

def_pattern(TypeVarDecons,
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
            end)

end