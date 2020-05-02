module ExprTools
using MLStyle.MatchCore
export take_type_parameters!, get_type_parameters

function take_type_parameters!(syms::Set{Symbol}, ex)::Nothing
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

function get_type_parameters(args :: AbstractArray{T, 1})::Set{Symbol} where T
    syms = Set{Symbol}()
    for arg in args
        take_type_parameters!(syms, arg)
    end
    syms
end

end
