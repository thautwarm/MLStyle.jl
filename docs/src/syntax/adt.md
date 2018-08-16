Algebraic Data Types
==============================

What's the so-called ADT?

- An efficient way to represent data.
- An elegant way to composite data.
- An effective way to manipulate data.
- An easy way to analyse data.


Example: Describe arithmetic operations
--------------------------------------

```julia
using MLStyle
@data Arith begin 
    Number(v :: Int)
    Minus(fst :: Arith, snd :: Arith)
    Mult(fst :: Arith, snd :: Arith)
    Divide(fst :: Arith, snd :: Arith)
end
```

Above codes makes a clarified description about `Arithmetic` and provides a corresponding implementation.

If you want to transpile above ADTs to some specific language, there is a clear step: 

```julia

eval_arith(arith :: Arith) = 
    let wrap_op(op)  = (a, b) -> op(eval_arith(a), eval_arith(b)),
        (+, -, *, /) = map(wrap_op, (+, -, *, /))
        @match arith begin
            Number(v)       => v
            Minus(fst, snd) => fst - snd
            Mult(fst, snd)   => fst * snd
            Divide(fst, snd) => fst / snd
        end
    end

eval_arith(
    Minus(
        Number(2), 
        Divide(Number(20), 
               Mult(Number(2), 
                    Number(5)))))
# => 0
```

Case Class
----------

Just like the similar one in Scala
```julia
abstract type A end
@case C{T}(a :: Int, b)
@case D(a, b)
@case E <: A
```

In terms of data structure definition, following codes could be expanded to
```julia
abstract type A end
struct C{T}
    a :: Int
    b
end

struct D
    a
    b
end

struct E <: A
end

<additional codes>
```

Take care that any instance of `E` is a **singleton** thanks to Julia's language design pattern.

However the two snippet above are not equivalent, for there are other hidden details to support
**pattern matching** on these data structures.

See [pattern.md](https://github.com/thautwarm/MLStyle.jl/blob/master/docs/src/syntax/pattern.md).




