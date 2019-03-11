module Toolz
include("InternalList.jl")
using .List: head, tail, cons, nil, reverse, linkedlist

export ($), isCapitalized

($)(f, a) = f(a)
isCapitalized(s :: AbstractString) :: Bool = !isempty(s) && isuppercase(s[1])
end
