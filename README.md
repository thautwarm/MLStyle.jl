

MLStyle.jl
=========================

P.S: this project is still in an early development stage.     

```julia

using MLStyle

abstract type C{T} end

@case C1{T}(a :: T) <: C{T}
@case C2{T}(a :: T, b :: Int) <: C{T}

@match C1(2) begin
    C1(3)         => nothing
    C1(a){a > 2}  =>  nothing
    C1(a){a <= 2} => a 
end

=> 2


fn(c:: C) = 
    
    @match c begin
    
      C2(2, 3){false} => nothing

      C1(a)    | 
      C2(a, 3) |
      C2(2, a)        => a 
      
      _               => @error ""
   end 

fn(C1(2)) # => 2
fn(C2(2, 5)) # => 5
fn(C2(7, 3)) # => 7
fn(C2(7, 5)) # => error

```

Incoming Features
======================

- Compatible to `Match.jl`.
  all `{ ... }` could be replaced by `begin ... end`.

- Pattern matching for functions.
  ```julia
  @def f { 
     ((a, b), true)   => <body1>
     (nothing, false) => <body2>
     
     _                => <body3>
  }
  ```
- Numeric dependent types.

- Range pattern.
 
  ```julia
  @match num begin
     1 .. 10 => #do stuff
  end
  ```
 
- Various monad utilities.
