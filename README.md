

MLStyle.jl
=========================

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
[![Docs](https://img.shields.io/badge/docs-latest-purple.svg)](https://thautwarm.github.io/MLStyle.jl/latest/) 
[![Join the chat at https://gitter.im/MLStyle-jl/community](https://badges.gitter.im/MLStyle-jl/community.svg)](https://gitter.im/MLStyle-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Index
- [What is MLStyle.jl](#what-is-mlstylejl)

- [Motivation](#motivation)

- [Why use MLStyle.jl](#why-use-mlstylejl)

- [Installation, Documentations and Tutorials](#installation-documentations-and-tutorials)

- [Preview](#preview)

    - [Homoiconic pattern matching for Julia ASTs](#homoiconic-pattern-matching-for-julia-asts)
    - [Generalized Algebraic Data Types](#generalized-algebraic-data-types)
    - [Active Patterns](#active-patterns)

- [Benchmark](#benchmark)

    - [Prerequisite](#prerequisite)

    - [Visualization](#visualization)

        - [Time Overhead](#time-overhead)
        - [Allocation](#allocation)
        - [Gallery](#gallery)

- [Contributing to MLStyle](https://github.com/thautwarm/MLStyle.jl#contributing-to-mlstyle)


## What is MLStyle.jl?

MLStyle.jl is a Julia package that provides multiple productivity tools from ML ([Meta Language](https://en.wikipedia.org/wiki/ML_(programming_language))) like [pattern matching](https://en.wikipedia.org/wiki/Pattern_matching) which is statically generated and extensible, ADTs/GADTs ([Algebraic Data Type](https://en.wikipedia.org/wiki/Algebraic_data_type), [Generalized Algebraic Data Type](https://en.wikipedia.org/wiki/Generalized_algebraic_data_type)) and [Active Patterns](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns).

Think of MLStyle.jl as a package bringing advanced functional programming idioms to Julia.


## Motivation

Those used to functional programming may feel limited when they don't have pattern matching and ADTs, and of course I'm one of them.

However, I don't want to make a trade-off here by using some available alternatives that miss features or are not well-optimized. Just like [why those greedy people created Julia](https://julialang.org/blog/2012/02/why-we-created-julia), I'm also so greedy that **I want to integrate all those useful features into one language, and make all of them convenient, efficient and extensible**.

On the other side, in recent years I was addicted to extending Python with metaprogramming and even internal mechanisms. Although I made something interesting like [pattern-matching](https://github.com/Xython/pattern-matching), [goto](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_goto.py), [ADTs](https://github.com/thautwarm/Redy/tree/master/Redy/ADT), [constexpr](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_constexpr.py), [macros](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_macro.py), etc., most of these implementations are also disgustingly evil. Fortunately, in Julia, all of them could be achieved straightforwardly without any black magic, at last, some of these ideas come into existence with MLStyle.jl.

Finally, we have such a library that provides **extensible pattern matching** for such an efficient language.

## Why use MLStyle.jl

- Straightforward

    I think there is no need to talk about why we should use pattern matching instead of manually writing something like conditional branches and nested visitors for datatypes.

- Performance Gain

    When dealing with complex conditional logics and visiting nested datatypes, the codes compiled via `MLStyle.jl` is usually as fast as handwritten code. You can check the [benchmarks](#benchmark) for details.

- Extensibility and Hygienic Scoping

    You can define your own patterns via the interfaces `def_pattern`, `def_app_pattern` and `def_gapp_pattern`. Almost all built-in patterns are defined at [Pervasives.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/src/Pervasives.jl).

    Once you define a pattern, you're tasked with giving some qualifiers to your own patterns to prevent visiting them from unexpected modules.

- You can use MLStyle in development via [Bootstrap mechanism](https://github.com/thautwarm/MLStyle.jl/tree/master/bootstrap):

    Now there's a code generation tool called `boostrap` available at [MLStyle/boostrap](https://github.com/thautwarm/MLStyle.jl/tree/master/bootstrap), which
    you can take advantage of to remove MLStyle dependency when making distributions.

    Also, MLStyle is implemented by itself now, via the bootstrap method.

- \* Modern Ways about AST Manipulations

    MLStyle.jl is not a superset of MacroToos.jl, but it provides something useful for AST manipulations. Furthermore, in terms of extracting sub-structures from a given AST, using expr patterns and AST patterns could speed code up by orders of magnitude.

## Installation, Documentations and Tutorials

Rich features are provided by MLStyle.jl and you can check the [documentation](https://thautwarm.github.io/MLStyle.jl/latest/) to get started.

For installation, open the package manager mode in the Julia REPL and `add MLStyle`.

For more examples or tutorials, see [this project](https://github.com/thautwarm/MLStyle-Playground) which will be frequently updated to present some interesting uses of MLStyle.jl.

## Preview
### Rock Paper Scissors
Here's a trivial example of MLStyle.jl in action:

```julia
using MLStyle
@data Shape begin # Define an algebraic data type Shape
    Rock()
    Paper()
    Scissors()
end

# Determine who wins a game of rock paper scissors with pattern matching
play(a::Shape, b::Shape) = @match (a,b) begin
    (Paper(), Rock())     => "Paper Wins!";
    (Rock(), Scissors())  => "Rock Wins!";
    (Scissors(), Paper()) => "Scissors Wins!";
    (a, b)                => a == b ? "Tie!" : play(b, a)
end
```


### Homoiconic pattern matching for Julia ASTs
Here's a less trivial use of MLStyle.jl for deconstructing and pattern matching Julia code. 
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
    Sym{A}    :: Symbol                        => Exp{A}
    Val{A}    :: A                             => Exp{A}
    App{A, B, A_} :: (Exp{Fun{A, B}}, Exp{A_}) => Exp{B}
    Lam{A, B} :: (Symbol, Exp{B})              => Exp{Fun{A, B}}
    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A})   => Exp{A}
end

```

A simple intepreter implemented via GADTs could be found at `test/untyped_lam.jl`.


### Active Patterns

Currently, MLStyle does not have [fully featured](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns) active patterns, but the subset of parametric active patterns that are implemented are very powerful.

```julia
@active Re{r :: Regex}(x) begin
    match(r, x)
end

@match "123" begin
    Re{r"\d+"}(x) => x
    _ => @error ""
end # RegexMatch("123")
```

## Benchmark

### Prerequisite

Recent benchmarks have been run, showing that MLStyle.jl can be extremely fast for complicated pattern matching, but due to its advanced machinery has noticeable overhead in some very simple cases such as straightforwardly destructuring shallow tuples, arrays and datatypes without recursive invocations.

All benchmark scripts are provided in the directory [Matrix-Benchmark](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark).


To run these cross-implementation benchmarks, some extra dependencies should be installed:

- `(v1.1) pkg> add https://github.com/thautwarm/Benchmarkplotting.jl#master` for making cross-implementation benchmark methods and plotting.

- `(v1.1) pkg> add Gadfly MacroTools Match BenchmarkTools StatsBase Statistics ArgParse DataFrames`.

- `(v1.1) pkg> add MLStyle#base` for a specific version of MLStyle.jl is required.

After installing dependencies, you can directly benchmark them with `julia matrix_benchmark.jl hw-tuple hw-array match macrotools match-datatype` in the root directory.

The benchmarks presented here are made by Julia **v1.1** on **Fedora 28**. For reports made on **Win10**, check [stats/windows/](https://github.com/thautwarm/MLStyle.jl/tree/master/stats/windows) directory.

### Visualization

#### Time Overhead

On the x-axis, after the name of test-case is the least time-consuming run's index in units of `ns`.

The y-label is the ratio of the implementation's time cost to that of the least time-consuming.


#### Allocation

On the x-axis, after the name of test-case is the least allocted one's index, the unit is `_ -> (_ + 1) bytes`).

The y-label is the ratio of the implementation's allocation cost to that of the least allocted.

#### Gallery

The benchmark results in dataframe format are available at [this directory](https://github.com/thautwarm/MLStyle.jl/tree/master/stats).

- [matrix-benchmark/versus-hw-array.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/matrix-benchmark/versus-hw-array.jl)

There are still some performamce issues with array patterns.

1. Time

[![hw-array](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(array)-on-time.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(array).txt)

2. Allocation

[![hw-array](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(array)-on-allocs.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(array).txt)


- [matrix-benchmark/versus-hw-tuple.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/matrix-benchmark/versus-hw-tuple.jl)

1. Time

[![hw-tuple](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(tuple)-on-time.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(tuple).txt)

2. Allocation

[![hw-tuple](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(tuple)-on-allocs.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-hw(tuple).txt)


- [matrix-benchmark/versus-macrotools.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/matrix-benchmark/versus-macrotools.jl)

1. Time

[![macrotools](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-macrotools(ast)-on-time.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-macrotools(ast).txt)


2. Allocation

[![macrotools](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-macrotools(ast)-on-allocs.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-macrotools(ast).txt)


- [matrix-benchmark/versus-match.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/matrix-benchmark/versus-match.jl)


1. Time

[![match.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(expr)-on-time.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(expr).txt)


2. Allocation

[![match.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(expr)-on-allocs.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(expr).txt)


- [matrix-benchmark/versus-match-datatype.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/matrix-benchmark/versus-match-datatype.jl)


1. Time

[![match.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(datatype)-on-time.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(datatype).txt)


2. Allocation

[![match.jl](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(datatype)-on-allocs.svg)](https://github.com/thautwarm/MLStyle.jl/blob/base-2/stats/vs-match(datatype).txt)


## Contributing to MLStyle

Thanks to all individuals referred in [Acknowledgements](./acknowledgements.txt)!


Feel free to ask questions about usage, development or extensions about MLStyle at [Gitter Room](https://gitter.im/MLStyle-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge).
