
<a id='MLStyle.jl-1'></a>

# MLStyle.jl


[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl) [![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE) [![Docs](https://img.shields.io/badge/docs-latest-purple.svg)](https://thautwarm.github.io/MLStyle.jl/latest/) [![Join the chat at https://gitter.im/MLStyle-jl/community](https://badges.gitter.im/MLStyle-jl/community.svg)](https://gitter.im/MLStyle-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


***This is the documentation for unreleased v0.4, which has a lot of improvements, i.e. "changes".***


***You may now check docs of v0.3.1.***


<a id='What-is-MLStyle.jl?-1'></a>

## What is MLStyle.jl?


MLStyle.jl is a Julia package that provides multiple productivity tools from ML ([Meta Language](https://en.wikipedia.org/wiki/ML_(programming_language))) like [pattern matching](https://en.wikipedia.org/wiki/Pattern_matching) which is statically generated and extensible, ADTs/GADTs ([Algebraic Data Type](https://en.wikipedia.org/wiki/Algebraic_data_type), [Generalized Algebraic Data Type](https://en.wikipedia.org/wiki/Generalized_algebraic_data_type)) and [Active Patterns](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns).


Think of MLStyle.jl as a package bringing advanced functional programming idioms to Julia.


<a id='Motivation-1'></a>

## Motivation


Those used to functional programming may feel limited when they don't have pattern matching and ADTs, and of course I'm one of them.


However, I don't want to make a trade-off here by using some available alternatives that miss features or are not well-optimized. Just like [why those greedy people created Julia](https://julialang.org/blog/2012/02/why-we-created-julia), I'm also so greedy that **I want to integrate all those useful features into one language, and make all of them convenient, efficient and extensible**.


On the other side, in recent years I was addicted to extending Python with metaprogramming and even internal mechanisms. Although I made something interesting like [pattern-matching](https://github.com/Xython/pattern-matching), [goto](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_goto.py), [ADTs](https://github.com/thautwarm/Redy/tree/master/Redy/ADT), [constexpr](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_constexpr.py), [macros](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_macro.py), etc., most of these implementations are also disgustingly evil. Fortunately, in Julia, all of them could be achieved straightforwardly without any black magic, at last, some of these ideas come into existence with MLStyle.jl.


Finally, we have such a library that provides **extensible pattern matching** for such an efficient language.


<a id='Why-use-MLStyle.jl-1'></a>

## Why use MLStyle.jl


  * Straightforward

    I think there is no need to talk about why we should use pattern matching instead of manually writing something like conditional branches and nested data visitors.
  * Performance Gain

    When dealing with conditional logics or visiting nested data, the codes compiled via `MLStyle.jl` is usually faster than the handwritten code. You can check the [benchmarks](#benchmark) section for details.
  * Extensibility and Hygienic Scoping

    You can define your own patterns via the interfaces:

      * `pattern_uncall(::Type{P}, self, type_params, type_args, args)`
      * `pattern_unref(::Type{P}, self, args)`

    Check documentations for details.
  * **You can use MLStyle only in development time** by expanding the macros(MLStyle generates **enclosed** codes which requires no runtime support, which means **the generated code can run without MLStyle installed**!)

    Also, MLStyle is implemented by itself now, via the bootstrap method.
  * * Modern Ways about AST Manipulations

    MLStyle.jl is not a superset of MacroToos.jl, but it provides something useful for AST manipulations. Furthermore, in terms of extracting sub-structures from a given AST, using expr patterns and AST patterns could speed code up by orders of magnitude.


<a id='Installation,-Documentations-and-Tutorials-1'></a>

## Installation, Documentations and Tutorials


Rich features are provided by MLStyle.jl and you can check the [documentation](https://thautwarm.github.io/MLStyle.jl/latest/) to get started.


For installation, open the package manager mode in the Julia REPL and `add MLStyle`.


For more examples or tutorials, see [this project](https://github.com/thautwarm/MLStyle-Playground) which will be frequently updated to present some interesting uses of MLStyle.jl.


<a id='Preview-1'></a>

## Preview


<a id='Rock-Paper-Scissors-1'></a>

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
play(a::Shape, b::Shape) = @match (a, b) begin
    (Paper(),    Rock())      => "Paper Wins!";
    (Rock(),     Scissors())  => "Rock Wins!";
    (Scissors(), Paper())     => "Scissors Wins!";
    (a, b)                => a == b ? "Tie!" : play(b, a)
end
```


For a pattern like `A()`, there's a chance for them to get used with `A`:


```julia
# use pattern `A()` with the syntax `A`
MLStyle.is_enum(::Type{Rock}) = true
MLStyle.is_enum(::Type{Paper}) = true
MLStyle.is_enum(::Type{Scissors}) = true

play(a::Shape, b::Shape) = @match (a, b) begin
    (Paper,    Rock)      => "Paper Wins!";
    (Rock,     Scissors)  => "Rock Wins!";
    (Scissors, Paper)     => "Scissors Wins!";
    (a, b)                => a == b ? "Tie!" : play(b, a)
end
```


<a id='Homoiconic-pattern-matching-for-Julia-ASTs-1'></a>

### Homoiconic pattern matching for Julia ASTs


Here's a less trivial use of MLStyle.jl for deconstructing and pattern matching Julia code. 


```julia
rmlines = @λ begin
    e :: Expr           => Expr(e.head, filter(x -> x !== :magic_symbol_oh_really, map(rmlines, e.args))...)
      :: LineNumberNode => :magic_symbol_oh_really
    a                   => a
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


<a id='Generalized-Algebraic-Data-Types-1'></a>

### Generalized Algebraic Data Types


```julia
@use GADT

@data public Exp{T} begin
    Sym{A}    :: Symbol                           => Exp{A}
    Val{A}    :: A                                => Exp{A}
    Lam{A, B} :: (Symbol, Exp{B})                 => Exp{Fun{A, B}}
    If{A}     :: (Exp{Bool}, Exp{A}, Exp{A})      => Exp{A}
    App{A, B, A′<:A} :: (Exp{Fun{A, B}}, Exp{A′}) => Exp{B}
end
```


A simple interpreter implemented via GADTs could be found at `test/untyped_lam.jl`.


<a id='Active-Patterns-1'></a>

### Active Patterns


Currently, MLStyle does not have [fully featured](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns) active patterns, but the subset of parametric active patterns that are implemented are very powerful.


```julia
@active Re{r :: Regex}(x) begin
    ret = match(r, x)
    ret !== nothing && return Some(ret)
end

@match "123" begin
    Re{r"\d+"}(x) => x
    _ => @error ""
end # RegexMatch("123")

@active IsEven(x) begin
    x % 2 == 0
end

@match (1, 2, 3) begin
    (1, IsEven, a) => a
end # => 3
```


<a id='Benchmark-1'></a>

## Benchmark


See [Benchmark](https://github.com/thautwarm/MLStyle.jl#benchmark).


<a id='Contributing-to-MLStyle-1'></a>

## Contributing to MLStyle


Thanks to all individuals referred in [Acknowledgements](./acknowledgements.txt)!


Feel free to ask questions about usage, development or extensions about MLStyle at [Gitter Room](https://gitter.im/MLStyle-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge).

