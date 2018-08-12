

MLStyle.jl
=========================

P.S: this project is still in an early development stage.

```julia

using MLStyle

abstract type C{T} end

@case C1{T}(a :: T) <: C{T}
@case C2{T}(a :: T, b :: Int) <: C{T}

@match C1(2) {
    C1(3)         => nothing
    C1(a){a > 2}  =>  nothing
    C1(a){a <= 2} => a 
}

=> 2


fn(c:: C) = 
    
    @match c {
    
    C2(2, 3){false} => nothing

    C1(a)    | 
    C2(a, 3) |
    C2(2, a)        => a 
    
    _               => @error ""
}

fn(C1(2)) # => 2
fn(C2(2, 5)) # => 5
fn(C2(7, 3)) # => 7
fn(C2(7, 5)) # => error

```

Incoming Features
======================

- Compatible to `Match.jl`.
- Numeric dependent types.
