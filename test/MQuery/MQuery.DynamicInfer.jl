const MAX_FIELDS = 10

function return_type(f, ts::A) where {T <: Type, A <:AbstractArray{T, 1}}
    ts = Base.return_types(f, ts)
    if length(ts) === 1
        ts[1]
    else
        Union{ts...}
    end
end


function return_type(f, ts :: NTuple{N, T}) where {N, T <: Type}
    ts = Base.return_types(f, ts)
    if length(ts) === 1
        ts[1]
    else
        Union{ts...}
    end
end

function return_type(f, t :: Type)
    return_type(f, (t,))
end

for i = 1:MAX_FIELDS
    types = [Symbol("T", j) for j = 1:i]
    inp = :(Type{Tuple{$(types...)}})
    out = Expr(:vect, types...)
    @eval @inline type_unpack(n::Int, ::$inp) where {$(types...)} = $out
end

function type_unpack(n::Int, :: Type{Tuple{}})
    throw("TypeError at query expression.")
end

function type_unpack(n::Int, :: Type{Any})
    fill(Any, n)
end