@nospecialize
export TagfulPattern, And, Or,
       Literal, Wildcard,
       Deconstrucution, Guard, Effect,
       untagless, TagfulPattern,
       PatternInfo

abstract type TagfulPattern end


struct PatternInfo
    pattern ::TagfulPattern
    typetag :: TypeObject
end

struct And <: TagfulPattern
    ps :: Vector{PatternInfo}
end

struct Or <: TagfulPattern
    ps :: Vector{PatternInfo}
end

struct Literal{T} <: TagfulPattern
    val :: T
end

struct Wildcard <: TagfulPattern
end

struct Deconstrucution <: TagfulPattern
    comp :: PComp
    extract :: Function
    params :: Vector{PatternInfo}
end

struct Guard <: TagfulPattern
    predicate :: Any
end

struct Effect <: TagfulPattern
    perform :: Any
end

@specialize
function _uncurry_call_argtail(f)
    function (_, args...)
        f(args...)
    end
end
@nospecialize

function untagless(points_of_view::Dict{Function, Int})
    myviewpoint = points_of_view[untagless]
    typetag_viewpoint::Int = points_of_view[tag_extract]
    mk_info(all_info)::PatternInfo = PatternInfo(
        all_info[myviewpoint], all_info[typetag_viewpoint]
    )
    ! = mk_info
    function decons(comp::PComp, extract::Function, ps)
        Deconstrucution(comp, extract, PatternInfo[!p for p in ps])
    end
    and(ps::Vector{Vector{Any}}) = And(PatternInfo[!e for e in ps])
    or(ps::Vector{Vector{Any}}) = Or(PatternInfo[!e for e in ps])

    (
        and = and,
        or = or,
        literal = Literal,
        wildcard = Wildcard(),
        decons = decons,
        guard = Guard,
        effect = Effect
    )
end
@specialize    