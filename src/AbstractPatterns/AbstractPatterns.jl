module AbstractPatterns
export spec_gen, RedyFlavoured, TypeObject
export and, or, literal, and, wildcard, decons,
       guard, effect
export PatternCompilationError, Target, PatternImpl, PComp
export APP, NoncachablePre, NoPre
export ChainDict, for_chaindict, child, for_chaindict_dup
export BasicPatterns
export P_bind, P_tuple, P_type_of, P_vector, P_capture, P_vector3, P_slow_view, P_fast_view
export P_svec, P_svec3
export SimpleCachablePre, see_captured_vars, see_captured_vars!
export CFGSpec, CFGJump, CFGLabel, CFGItem, init_cfg

mutable struct CFGSpec
    exp :: Expr
end

struct CFGItem
    kind :: Symbol
    name :: Symbol
end

CFGJump(x::Symbol) = CFGItem(Symbol("@goto"), x)
CFGLabel(x::Symbol) = CFGItem(Symbol("@label"), x)

init_cfg(ex::Expr) = init_cfg(CFGSpec(ex))
function init_cfg(cfg::CFGSpec)
    exp = copy(cfg.exp)
    cfg_info = Dict{Symbol, Symbol}()
    init_cfg!(exp, cfg_info)
    exp
end

const _const_lineno = LineNumberNode(32, "<codegen>")
function init_cfg!(ex::Expr, cf_info::Dict{Symbol, Symbol})
    args = ex.args
    for i in eachindex(args)
        @inbounds arg = args[i]
        if arg isa CFGItem
            label = get!(cf_info, arg.name) do
                gensym(arg.name)
            end
            @inbounds args[i] = Expr(:macrocall, arg.kind, _const_lineno, label)
        elseif arg isa Expr
            init_cfg!(arg, cf_info)
        elseif arg isa CFGSpec
            @inbounds args[i] = init_cfg(arg)
        end
    end
end

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

const _points_of_view = Dict{Function, Int}(tag_extract => 1, untagless => 2)
function spec_gen(branches :: Vector{Pair{Function, Tuple{LineNumberNode, Int}}})
    cores = Branch[]
    for (tf, ln_and_cont) in branches
        impls = (tag_extract(_points_of_view), untagless(_points_of_view))
        type, pat = tf(impls)
        push!(cores, PatternInfo(pat::TagfulPattern, type::TypeObject) => ln_and_cont)
    end
    split_cores = Branch[]
    case_split!(split_cores, cores)
    case_merge(split_cores)
end

end # module
