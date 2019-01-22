Algebraic Data Types
==============================


Syntax
-----------------

```

@data [public | internal] TypeName[{TVars...}] begin

    ( ConstructorName[{Generalized TVars...}](fieldname*) 
    | ConstructorName[{Generalized TVars...}](TypeName*)
    | ConstructorName[{Generalized TVars...}]((fieldname=TypeNames)*)
    )*
    
end


```

Example: Describe arithmetic operations
--------------------------------------

```julia
using MLStyle
@data internal Arith begin
    Number(Int)
    Minus(Arith, Arith)
    Mult(Arith, Arith)
    Divide(Arith, Arith)
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



Generalized ADT
--------------------------


```julia


struct FuncType{A, B}
    fn :: Function 
end

@data public Exp{T} begin
    Sym{A} :: A => Exp{A}
    Val{A} :: A => Exp{A}
    App{A, B} :: (Exp{FuncType{A, B}}, Exp{A}) => Exp{B}
    Lam{A, B} :: (Symbol, Exp{B}) => Exp{FuncType{A, B}}
    If{A} :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A} 
end

function eval_exp(exp :: Exp{T}, context :: Dict{Type, Dict{Symbol, Any}})
    @match exp begin
        Sym(a :: T) => context[T][a]
        Val(a :: T) => a
        App{A, T}(f :: Exp{FuncType{A, T}}, arg :: Exp{A}) where A => eval_exp(f, context)(eval_exp(arg, context))
        Lam{A, B}(sym, exp::Exp{B}) where {A, B} => (x :: A) -> eval_exp(substitute(exp, sym => x))
        If(cond, exp1, exp2) => eval_exp(eval_exp(cond) ? exp1 : exp2)
    end
end

```


