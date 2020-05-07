# MLStyle.jl

[![Build Status](https://travis-ci.org/thautwarm/MLStyle.jl.svg?branch=master)](https://travis-ci.org/thautwarm/MLStyle.jl)
[![codecov](https://codecov.io/gh/thautwarm/MLStyle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thautwarm/MLStyle.jl)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/LICENSE)
[![Docs](https://img.shields.io/badge/docs-latest-purple.svg)](https://thautwarm.github.io/MLStyle.jl/latest/) 
[![Join the chat at https://gitter.im/MLStyle-jl/community](https://badges.gitter.im/MLStyle-jl/community.svg)](https://gitter.im/MLStyle-jl/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Providing intuitive, fast, consistent and extensible functional programming infrastructures, and metaprogramming facilities.

Check everything in [Documentation Website](https://thautwarm.github.io/MLStyle.jl/latest/).

## Preview

```julia
using MLStyle

@data Shape begin # Define an algebraic data type Shape
    Rock
    Paper
    Scissors
end

# Determine who wins a game of rock paper scissors with pattern matching
play(a::Shape, b::Shape) = @match (a, b) begin
    (Paper,    Rock)      => "Paper Wins!";
    (Rock,     Scissors)  => "Rock Wins!";
    (Scissors, Paper)     => "Scissors Wins!";
    (a, b)                => a == b ? "Tie!" : play(b, a)
end
```

## Benchmarks

### Arrays

- code: [matrix-benchmark/bench-array.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-array.jl)

[![matrix-benchmark/bench-array.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-array.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-array.txt)


### Tuples

- code: [matrix-benchmark/bench-tuple.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-tuple.jl)

[![matrix-benchmark/bench-tuple.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-tuple.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-tuple.txt)

### Data Types

- code: [matrix-benchmark/bench-datatype.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-datatype.jl)

[![matrix-benchmark/bench-datatype.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-datatype.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-datatype.txt)

### Extracting Struct Definitions

- code: [matrix-benchmark/bench-structfields.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-structfields.jl)

[![matrix-benchmark/bench-structfields.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-structfields.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-structfields.txt)


### Misc

- code: [matrix-benchmark/bench-misc.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-misc.jl)

[![matrix-benchmark/bench-misc.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-misc.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-misc.txt)


### An Example from Match.jl Documentation

- code: [matrix-benchmark/bench-vs-match.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-vs-match.jl)

[![matrix-benchmark/bench-versus-match.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-versus-match.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-vs-match.txt)

## Acknowledgements

Thanks to all individuals referred in [Acknowledgements](https://github.com/thautwarm/MLStyle.jl/blob/master/acknowledgements.txt)!