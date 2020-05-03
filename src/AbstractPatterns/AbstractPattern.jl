module AbstractPattern
export spec_gen, runterm, MK, RedyFlavoured, TypeObject
export and, or, literal, and, wildcard, decons,
       guard, effect, self
export PatternCompilationError, Target, PatternImpl, PComp
export APP, NoncachablePre, NoPre
export ChainDict, for_chaindict, child, for_chaindict_dup
export BasicPatterns
export P_bind, P_tuple, P_type_of, P_vector, P_capture, P_vector3, P_slow_view, P_fast_view
export P_svec, P_svec3
export SimpleCachablePre, see_captured_vars

include("DataStructure.jl")
include("Target.jl")
include("PatternSignature.jl")
include("Print.jl")
include("structures/Print.jl")
include("structures/TypeTagExtraction.jl")
include("ADT.jl")
include("CaseMerge.jl")
include("UserSignature.jl")
include("Retagless.jl")
include("impl/RedyFlavoured.jl")
include("impl/BasicPatterns.jl")
using .BasicPatterns

@nospecialize
function MK(m::Any)
    m.backend
end

function runterm(term, xs)
    points_of_view = Dict{Function, Int}(x => i for (i, x) in enumerate(xs))
    impls = Tuple(x(points_of_view) for x in xs)
    term(impls)
end

function spec_gen(branches :: Vector)
    cores = Branch[]
    ln = LineNumberNode(1, "<unknown>")
    for branch in branches
        branch isa LineNumberNode && begin
            ln = branch
            continue
        end
        (branch, cont) = branch :: Pair{F, Symbol} where F <: Function
        points_of_view = Dict{Function, Int}(tag_extract => 1, untagless => 2)
        impls = (tag_extract(points_of_view), untagless(points_of_view))
        type, pat = branch(impls)
        push!(cores, PatternInfo(pat::TagfulPattern, type::TypeObject) => (ln, cont))
    end
    split_cores = Branch[]
    case_split!(split_cores, cores)
    case_merge(split_cores)
end

end # module
