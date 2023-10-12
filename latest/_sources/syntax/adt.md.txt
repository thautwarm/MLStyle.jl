Algebraic Data Types
==============================


Cheat Sheet 
-----------------

Cheat sheet for regular ADT definitions:

```julia
@data A <: B begin
    C1 # is an enum
    
    # C1 is a value but C2 is a constructor
    C2()
    
    # the capitalized means types(field names are "_1", "_2", ...)
    # C3(1, "2")._1 == 1
    C3(Int, String)
  
    C4(::Int, ::String)   # "::" means types
    
    # the lowercase means field names
    # C5(:ss, 1.0).a == :ss
    C5(a, b)
    
    C6(a::Int, b::Vector{<:AbstractString})
end
```

Cheat sheet for GADT definitions:

```julia
@data Ab{T} <: AB begin
    
    C1 :: Ab{X} #  C1 is an enum. X is not type variable!
    C2 :: () => Ab{Int}

    # where is for inference, the clauses must be assignments
    C3{A<:Number, B} :: (a::A, b::Symbol) => Ab{B} where {B = Type{A}}
    # C3(1, :a) :: C3{Int, Tuple{Int}}
    # C3(1, :a) :: Ab{Int, Tuple{Int}}
end
```

Examples
-------------------------

```julia
@data E begin
    E1
    E2(Int)
end

@assert E1 isa E && E2 <: E
@match E1 begin
    E2(x) => x
    E1 => 2
end # => 2

@match E2(10) begin
    E2(x) => x
    E1 => 2
end # => 10

@data A begin
    A1(Int, Int)
    A2(a :: Int, b :: Int)
    A3(a, b) # equals to `A3(a::Any, b::Any)`
end

@data B{T} begin
    B1(T, Int)
    B2(a :: T)
end

@data C{T} begin
    C1(T)
    C2{A} :: Vector{A} => C{A}
end

abstract type DD end
some_type_to_int(x::Type{Int}) = 1
some_type_to_int(x::Type{<:Tuple}) = 2

@data D{T} <: DD begin
    D1{T} :: Int => D{T}
    D2{A, B} :: (A, B, Int) => D{Tuple{A, B}}
    D3{A, N} :: A => D{Array{A, N}} where {N = some_type_to_int(A)}
end
# z :: D3{Int64,1}(10) = D3(10) :: D{Array{Int64,1}}
```

Example: Modeling Arithmetic Operations
----------------------------------------------

```julia
using MLStyle
@data Arith begin
    Number(Int)
    Add(Arith, Arith)
    Minus(Arith, Arith)
    Mult(Arith, Arith)
    Divide(Arith, Arith)
end
```

The above code makes a clear description about Arithmetic operations and provides a corresponding implementation.

If you want to transpile above ADTs to some specific language, there is a clear step:

```julia-console
julia> eval_arith(arith :: Arith) =
          # locally and hygienically change the meaning of '!'
           let ! = eval_arith
               @match arith begin
                   Number(v)        => v
                   Add(fst, snd)    => !fst + !snd
                   Minus(fst, snd)  => !fst - !snd
                   Mult(fst, snd)   => !fst * !snd
                   Divide(fst, snd) => !fst / !snd
               end
           end
eval_arith (generic function with 1 method)

julia> eval_arith(
           Minus(
               Number(2),
               Divide(Number(20),
                      Mult(Number(2),
                           Number(5)))))
0.0
```

About Type Parameters
----------------------------------------------------

`where` is used for type parameter introduction.

The following 2 patterns are equivalent:
```julia
A{T1...}(T2...) where {T3...}
A{T1...}(T2...) :: A{T1...} where {T3...}
```

Check [Advanced Type Pattern](https://thautwarm.github.io/MLStyle.jl/latest/syntax/pattern/#Advanced-Type-Pattern-1) for more about `where` use in matching.
