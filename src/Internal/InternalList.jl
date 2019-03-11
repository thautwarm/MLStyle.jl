module List
import Base: length, (:), map, iterate, reverse, filter
export cons, nil, linkedlist

# if generic:
# map(f, l :: nil{T} ) where T  = nil()

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

function filter(f :: Function, l :: linkedlist)
    l2 = nil()
    for h in l
        if f(h)
          l2 = cons(h, l2)
        end
    end
    reverse(l2)
end

iterate(l :: linkedlist, ::nil) = nothing
function iterate(l :: linkedlist, state::cons = l)
    state.head, state.tail
end

function reverse(l :: linkedlist)
    l2 = nil()
    for hd in l
        l2 = cons(hd, l2)
    end
    l2
end

end


