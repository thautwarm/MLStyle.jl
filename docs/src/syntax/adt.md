Algebraic Data Types
==============================


Syntax
-----------------

```

<Seq> a         = a (',' a)*
<TypeName>      = %Uppercase identifier%
<fieldname>     = %Lowercase identifier%
<TVar>          = %Uppercase identifier%
<ConsName>      = %Uppercase identifier%
<ImplicitTVar>  = %Uppercase identifier%
<Type>          = <TypeName> [ '{' <Seq TVar> '}' ]
<Module>        = %Uppercase identifier%

<ADT>           =
    '@data' ['public' | 'internal' | 'visible' 'in' <Seq Module>] <Type> 'begin'

        (<ConsName>[{<Seq TVar>}] (
            <Seq fieldname> | <Seq Type> | <Seq (<fieldname> :: <Type>)>
        ))*

    'end'

<GADT>           =
    '@data' ['public' | 'internal'] <Type> 'begin'

        (<ConsName>[{<Seq TVar>}] '::'
           ( '('
                (<Seq fieldname> | <Seq Type> | <Seq (<fieldname> :: <Type>)>)
             ')'
              | <fieldname>
              | <Type>
           )
           '=>' <Type> ['where' '{' <Seq ImplicitTvar> '}']
        )*

    'end'

```

Qualifier
----------------------


There are 3 default qualifiers for ADT definition:

- `internal`: The pattern created by the ADT can only be used in the module it's defined in.
- `public`: If the constructor is imported into current module, the corresponding pattern will be available.
- `visible in [mod...]`: Define a set of modules where the pattern is available.


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



Note that, for GADTs would use `where` syntax as a pattern, it means that you cannot
use GADTs and your custom `where` patterns at the same time. To resolve this, we introduce
the extension system like Haskell here.

Since that you can define your own `where` pattern and export it to any modules.
Given an arbitrary Julia module, if you don't use `@use GADT` to enable GADT extensions and,
the qualifier of the your `where` pattern makes it visible here(current module),
your own `where` pattern could work here.


Here's a simple intepreter implemented using GADTs.

Firstly, enable GADT extension.

```julia
using MLStyle
@use GADT
```

Then define the function type.

```julia
import Base: convert

struct Fun{T, R}
    fn :: Function
end

function (typed_fn :: Fun{T, R})(arg :: T) :: R where {T, R}
    typed_fn.fn(arg)
end

function convert(::Type{Fun{T, R}}, fn :: Function) where {T, R}
    Fun{T, R}(fn)
end

function convert(::Type{Fun{T, R}}, fn :: Fun{C, D}) where{T, R, C <: T, D <: R}
    Fun{T, R}(fn.fn)
end

⇒(::Type{A}, ::Type{B}) where {A, B} = Fun{A, B}
```

And now let's define the operators of our abstract machine.

```julia

@data public Exp{T} begin

    # The symbol referes to some variable in current context.
    Sym       :: Symbol => Exp{A} where {A}

    # Value.
    Val{A}    :: A => Exp{A}

    # Function application.
    # add constraints to implicit tvars to get covariance
    App{A, B} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B} where {A_ <: A}

    # Lambda/Anonymous function.
    Lam{A, B} :: (Symbol, Exp{B}) => Exp{Fun{A, B}}

    # If expression
    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A}
end
```

Something deserved to be remark here: when using this GADT syntax like

```
    ConsName{TVars1...} :: ... => Exp{TVars2...} where {TVar3...}
```

You can add constraints to both `TVars1` and `TVars3`, and `TVars2` should be
always empty or a sequence of `Symbol`s. Furthermore, `TVars3` are the so-called
implicit type variables, and `TVars1` are the normal generic type variables.

Let's back to our topic.

To make function abstractions, we need a `substitute` operation.

```julia

"""
e.g: substitute(some_exp, :a => another_exp)
"""
function substitute(template :: Exp{T}, pair :: Tuple{Symbol, Exp{G}}) where {T, G}
    (sym, exp) = pair
    @match template begin
        Sym(&sym) => exp
        Val(_) => template
        App(f, a) => App(substitute(f, pair), substitute(a, pair)) :: Exp{T}
        Lam(&sym, exp) => template
        If(cond, exp1, exp2) =>
            let (cond, exp1, exp2) = map(substitute, (cond, exp1, exp2))
                If(cond, exp1, exp2) :: Exp{T}
            end
    end
end
```

Then we could write how to execute our abstract machine.

```julia
function eval_exp(exp :: Exp{T}, ctx :: Dict{Symbol, Any}) where T
    @match exp begin
        Sym(a) => (ctx[a] :: T, ctx)
        Val(a :: T) => (a, ctx)
        App{A, T, A_}(f :: Exp{Fun{A, T}}, arg :: Exp{A_}) where {A, A_ <: A} =>
            let (f, ctx) = eval_exp(f, ctx),
                (arg, ctx) = eval_exp(arg, ctx)
                (f(arg), ctx)
            end
        Lam{A, B}(sym, exp::Exp{B}) where {A, B} =>
            let f(x :: A) = begin
                    A
                    eval_exp(substitute(exp, sym => Val(x)), ctx)[1]
                end

                (f, ctx)
            end
        If(cond, exp1, exp2) =>
            let (cond, ctx) = eval_exp(cond, ctx)
                eval_exp(cond ? exp1 : exp2, ctx)
            end
    end
end
```

This `eval_exp` takes 2 arguments, one of which is an `Exp{T}`, while another is the store(you can regard it as the scope),
the return is a tuple, the first of which is a value typed `T` and the second is the new store after the execution.

Following codes are about how to use this abstract machine.

```julia
add = Val{Number ⇒ Number ⇒ Number}(x -> y -> x + y)
sub = Val{Number ⇒ Number ⇒ Number}(x -> y -> x - y)
gt = Val{Number ⇒ Number ⇒ Bool}(x -> y -> x > y)
ctx = Dict{Symbol, Any}()

@assert 3 == eval_exp(App(App(add, Val(1)), Val(2)), ctx)[1]
@assert -1 == eval_exp(App(App(sub, Val(1)), Val(2)), ctx)[1]
@assert 1 == eval_exp(
    If(
        App(App(gt, Sym{Int}(:x)), Sym{Int}(:y)),
        App(App(sub, Sym{Int}(:x)), Sym{Int}(:y)),
        App(App(sub, Sym{Int}(:y)), Sym{Int}(:x))
    ), Dict{Symbol, Any}(:x => 1, :y => 2))[1]

```


