Algebraic Data Types
==============================

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
            Mult(fst, snd   => fst * snd
            Divide(fst, snd => fst / snd
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




