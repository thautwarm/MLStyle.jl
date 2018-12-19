module List

import Base: length, (:), map

# abstract type linkedlist{T} end

# struct cons{T} <: linkedlist{T}
#     head :: T
#     tail :: linkedlist{T}
# end

# struct nil{T} <: linkedlist{T} end



# length(l :: nil{T}) where T = 0
# length(l :: cons{T} where T) = 1 + length(l.tail)

# head(l :: nil{T} ) where T   = nothing
# head(l :: cons{T}) where T   = l.head

# tail(l :: nil{T} ) where T  = nothing
# tail(l :: cons{T}) where T  = l.tail

# iter(f, l :: nil{T} ) where T  = nothing
# iter(f, l :: cons{T}) where T  = begin f(l.head); iter(f, l.tail) end

# map(f, l :: nil{T} ) where T  = nil()
# map(f, l :: cons{T}) where T  = cons(f(l.head), map(f, l.tail))

# (^)(hd :: T, tl :: linkedlist{T}) where T = cons(hd, tl)

abstract type linkedlist end

struct cons <: linkedlist
    head
    tail :: linkedlist
end

struct nil <: linkedlist end

length(l :: nil) = 0
length(l :: cons) = 1 + length(l.tail)

head(l :: nil )   = nothing
head(l :: cons)   = l.head

tail(l :: nil )   = nothing
tail(l :: cons)   = l.tail

iter(f, l :: nil )  = nothing
iter(f, l :: cons)  = begin f(l.head); iter(f, l.tail) end

map(f, l :: nil )   = nil()
map(f, l :: cons)   = cons(f(l.head), map(f, l.tail))

(^)(hd, tl :: linkedlist) = cons(hd, tl)


end
