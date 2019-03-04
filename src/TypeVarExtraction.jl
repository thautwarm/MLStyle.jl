module TypeVarExtraction

using MLStyle
using MLStyle.Toolz.List: cons, nil
using MLStyle.Infras
using MLStyle.MatchCore
using MLStyle.Qualification

export TypeVar, Relation, ChainRelation
export any_constraint, to_tvar, extract_tvars

struct TypeVar
    t :: Symbol
end

struct Relation
    l :: Symbol
    op :: Symbol
    r
end

struct ChainRelation
    var :: Symbol
    lower
    super
end

function any_constraint(t, forall)

    function is_rel(::Relation)
        true
    end

    function is_rel(::ChainRelation)
        true
    end

    function is_rel(::TypeVar)
        false
    end

    !(t isa Symbol) || any(is_rel, collect(extract_tvars(forall)))
end

function extract_tvars(t :: AbstractArray)
    @match t begin
        [] => nil()
        [hd && if hd isa Symbol end, tl...] => cons(TypeVar(hd), extract_tvars(tl))
        [:($hd <: $r), tl...] =>  cons(Relation(hd, :<:, r), extract_tvars(tl))
        [:($hd >: $(r)), tl...] =>  cons(Relation(hd, Symbol(">:"), r), extract_tvars(tl))
        [:($lower <: $hd <: $super), tl...] ||
        [:($super >: $hd >: $lower), tl...] => cons(ChainRelation(hd, lower, super))
        _ => @syntax_err "invalid tvars($t)"
    end
end

to_tvar(t::TypeVar) = t.t
to_tvar(t::Relation) = t.l
to_tvar(t::ChainRelation) = t.var

end