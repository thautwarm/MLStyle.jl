module ExprTools
using MLStyle.MatchCore
export take_type_parameters!, get_type_parameters, get_type_parameters_ordered
export @reexport

@nospecialize
function take_type_parameters!(syms, ex)::Nothing
    @sswitch ex begin
        @case :($a >: $_) || :($a <: $_)
        @assert a isa Symbol
        push!(syms, a)
        return
        @case :($_ >: $b >: $_) || :($_ <: $b <: $_)
        @assert b isa Symbol
        push!(syms, b)
        return
        @case ::Symbol
        push!(syms, ex)
        return
        @case _
        return
    end
end

function get_type_parameters(args::AbstractArray{T, 1})::AbstractSet{Symbol} where {T}
    syms = Set{Symbol}()
    for arg in args
        take_type_parameters!(syms, arg)
    end
    syms
end

function get_type_parameters_ordered(args::AbstractArray{T, 1})::Vector{Symbol} where {T}
    syms = Symbol[]
    for arg in args
        take_type_parameters!(syms, arg)
    end
    unique!(syms)
    syms
end

macro reexport(m)
    m = __module__.eval(m)
    ns = names(m)
    m_name = nameof(m)
    ns = [n for n in ns if n !== m_name]
    isempty(ns) ? nothing : esc(:(export $(ns...)))
end
@specialize

end
