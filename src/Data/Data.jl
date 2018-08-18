module Data
export List, Cons, Nil, Optional
using MLStyle.Err
using MLStyle

include("List.jl")
Optional{T} = Union{Some{T}, Nothing}

end
