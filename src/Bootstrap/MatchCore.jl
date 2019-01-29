module MatchCore
using .Proto
using Enums

AST = Any

@enum AccessWay Ref Val

@_data VisitKind begin
    Type(Any)
    Index(Int)
    Field(Symbol)
end

@_data Path begin
    Conn(kind :: VisitKind, next :: Path)
    End()
end

# compilation symbol
@_data CSymbol begin
    CSymbol(path :: Path, name :: Symbol, typ :: Any, access :: AccessWay)
end

@_data CTree begin
    CNode(target :: CSymbol, childs :: Vector{CTree}, forward :: Vector{AST})
    CLeaf(body :: Any)
end

MetaInfo = Dict{Path, CTree}

function compile_pattern(node :: CTree)

end
function optimize_pattern(node :: CTree, meta :: MetaInfo)
    @match node begin
    CNode(target = target, childs = childs) =>
        begin

        end

    end
end


export @match
macro match(target, cbl)
   @_match cbl begin
        :(begin $(Many(::LineNumberNode || :($_ => $_))...) end) =>

            ()
   end
end

end