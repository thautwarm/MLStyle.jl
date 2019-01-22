

MLStyle.jl
=========================

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
[![Docs](https://img.shields.io/badge/docs-latest-orange.svg)](https://thautwarm.github.io/MLStyle.jl/latest/)

Rich features are provided by MLStyle.jl and you can check [documents](https://thautwarm.github.io/MLStyle.jl/latest/) to get started.

For installation, open package manager mode in Julia shell and `add MLStyle`:
```
pkg> add MLStyle
```

## Preview

In this README I'm glad to share some non-trivial code snippets.

### Homoiconic pattern matching for Julia ASTs

```julia
rmlines = @λ begin
    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)
      :: LineNumberNode -> nothing
    a                   -> a
end
expr = quote
    struct S{T}
        a :: Int
        b :: T
    end
end |> rmlines

@match expr begin
    quote
        struct $name{$tvar}
            $f1 :: $t1
            $f2 :: $t2
        end
    end =>
    quote
        struct $name{$tvar}
            $f1 :: $t1
            $f2 :: $t2
        end
    end |> rmlines == expr
end
```

### Generalized Algebraic Data Types

 ```julia
@use GADT

@data public Exp{T} begin
    Sym       :: Symbol => Exp{A} where {A}
    Val{A}    :: A => Exp{A}
    App{A, B} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B} where {A_ <: A}
    Lam{A, B} :: (Symbol, Exp{B}) => Exp{Fun{A, B}}
    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A}) => Exp{A}
end

```

A simple intepreter implementation using GADTs could be found at `test/untyped_lam.jl`.
