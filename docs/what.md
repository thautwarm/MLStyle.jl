# What is MLStyle.jl?

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
[![Docs](https://img.shields.io/badge/docs-latest-purple.svg)](https://thautwarm.github.io/MLStyle.jl/latest/)
[![Join the chat at https://gitter.im/MLStyle-jl/community](https://badges.gitter.im/MLStyle-jl/community.svg)](https://gitter.im/MLStyle-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


***This is the documentation for the unreleased v0.4, which has a lot of improvements, i.e. "changes".***

***You may now check docs of v0.3.1.***: [MLStyle v0.3.1](https://thautwarm.github.io/MLStyle.jl/stable/)

MLStyle.jl is a Julia package that provides multiple productivity tools from ML ([Meta Language](https://en.wikipedia.org/wiki/ML_(programming_language))) like [pattern matching](https://en.wikipedia.org/wiki/Pattern_matching) which is statically generated and extensible, ADTs/GADTs ([Algebraic Data Type](https://en.wikipedia.org/wiki/Algebraic_data_type), [Generalized Algebraic Data Type](https://en.wikipedia.org/wiki/Generalized_algebraic_data_type)) and [Active Patterns](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns).

Think of MLStyle.jl as a package bringing advanced functional programming idioms to Julia.

## Motivations

Those used to functional programming may feel limited when they don't have pattern matching and ADTs, and of course I'm one of them.

When making this package I didn't want to make a trade-off by using some alternatives that don't have enough features or are not well-optimized. Just like [why those greedy people created Julia](https://julialang.org/blog/2012/02/why-we-created-julia), I'm also greedy. **I want to integrate all those useful functional programming features into one language, and make all of them convenient, efficient and extensible**.

In recent years I was addicted to extending Python with metaprogramming and even internal mechanisms. Although I made some interesting packages like [pattern-matching](https://github.com/Xython/pattern-matching), [goto](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_goto.py), [ADTs](https://github.com/thautwarm/Redy/tree/master/Redy/ADT), [constexpr](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_constexpr.py), [macros](https://github.com/thautwarm/Redy/blob/master/Redy/Opt/builtin_features/_macro.py), etc., most of these implementations are also disgustingly evil. Fortunately, in Julia, these features could be achieved straightforwardly without using any black magic. At last, some of these ideas come into existence with MLStyle.jl.

Finally, we have such a library that provides **extensible pattern matching** for julia.
