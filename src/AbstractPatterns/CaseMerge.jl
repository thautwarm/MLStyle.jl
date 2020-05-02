abstract type AbstractCase end
export AbstractCase, EnumCase, SwitchCase,
       Leaf, Shaped

Continuation = Symbol
Branch = Pair{PatternInfo, Tuple{LineNumberNode, Continuation}}

"""for generating patterns with one-by-one checks
"""
struct EnumCase <: AbstractCase
    cases :: Vector{AbstractCase}
end

"""for generating patterns with a optimized switch
"""
struct SwitchCase <: AbstractCase
    cases :: Dict{TypeObject, AbstractCase}
end

"""specifying the code body of a case
"""
struct Leaf <: AbstractCase
    cont :: Continuation
end

"""checking the shape of the datum with the defined patterns
"""
struct Shaped <: AbstractCase
    pattern :: PatternInfo
    ln :: LineNumberNode
    case :: AbstractCase
end

@nospecialize

function case_split!(result::Vector{Branch}, branches :: Vector{Branch})
    for (p, (ln, branch)) in branches
        if p.pattern isa Or
            case_split!(result, Branch[info => (ln, branch) for info in p.pattern.ps])
        else
            push!(result, p => (ln, branch))
        end
    end
end

function build_dyn(top::TypeObject, branches::Vector{Branch})::AbstractCase
    length(branches) === 1 && return begin
        br = branches[1]
        Shaped(br.first, br.second[1], Leaf(br.second[2]))
    end
    @assert !isempty(branches)
    enum_cases = AbstractCase[]
    labels = Vector{TypeObject}(undef, length(branches))
    groups = [1]
    for i in eachindex(branches)
        current_type = branches[i].first.typetag
        @assert current_type <: top
        if current_type === top
            # Detected forcely specified matching order.
            # e.g:
            #    match val with
            #    | (_: Int) -> ...
            #    | _ -> ...
            #    | (_ : String) -> ..
            # Although Int and String are orthogonal,
            # the second pattern `_` breaks their merging
           push!(groups, i)
           push!(groups, i + 1)
           labels[i] = top
           continue
        end
        
        last_group_start = groups[end]
        non_orthogonal_types = TypeObject[]
        non_orthogonal_indices = Int[]    
        for j in last_group_start : i - 1
            if typeintersect(current_type, labels[j]) !== Base.Bottom
            # Merging branches
            # e.g:
            #    match val with
            #   | (_ : Int) ->
            #   | (_ : String) ->
            #   | (_ : Float64) ->
            # We gives the 3 patterns such a label array:
            #   [Real, String, Real]
            # where, the 1st and 3rd branches merged
                push!(non_orthogonal_indices, j)
                push!(non_orthogonal_types, labels[j])
            end
        end
        merged_type = reduce(typejoin, non_orthogonal_types, init=current_type)
        for j in non_orthogonal_indices
            labels[j] = merged_type
        end
        labels[i] = merged_type
    end

    push!(groups, length(branches) + 1)
    n_groups = length(groups)
    for i_group in 1:n_groups-1
        start = groups[i_group]
        final = groups[i_group+1] - 1
        
        if start === final
            br = branches[start]
            push!(enum_cases, Shaped(br.first, br.second[1], Leaf(br.second[2])))
            continue
        elseif start > final
            continue
        end
        
        switch_map = Dict{TypeObject, Vector{Branch}}()
        for i in start:final
            vec = get!(switch_map, labels[i]) do
                Branch[]
            end
            push!(vec, branches[i])
        end
        switch = Pair{TypeObject, AbstractCase}[
            top => build_dyn(top, branches) for (top, branches) in switch_map
        ]
        push!(
            enum_cases,
            SwitchCase(Dict(switch))
        )
    end

    if length(enum_cases) === 1
        enum_cases[1]
    else
        EnumCase(enum_cases)
    end
end

function case_merge(branches::Vector{Branch})
    top = reduce(typejoin, TypeObject[pattern.typetag for (pattern, _) in branches])
    build_dyn(top, branches)
end

@specialize