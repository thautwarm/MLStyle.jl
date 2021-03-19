# Benchmark

In terms of data shape validation, MLStyle can often be faster than carefully optimized handwritten code.

All of the scripts for the benchmarks are provided in the directory: [Matrix-Benchmark](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark).

To run these cross-implementation benchmarks, some extra Julia packages should be installed:

- `(v1.4) pkg> add Gadfly MacroTools Rematch Match BenchmarkTools StatsBase Statistics ArgParse DataFrames`.

- `(v1.4) pkg> add MLStyle` for a specific version of MLStyle.jl is required.

After installing dependencies, you can directly benchmark them with `julia matrix_benchmark.jl tuple array datatype misc structfields vs-match` in the root directory.

The benchmarks presented here are made by Julia **v1.4** on **Windows 10(64 bit)**.

*Benchmark results for other platforms and Julia versions are welcome to get accepted as a pull request, if you figure out a better way to organize the files and their presentations in this README.*

(*We leave out the benchmarks of the space used. That should be considered unnecessary as the costs are always zero. *)

On the x-axis, after the name of test-case is the least time-consuming run's index in units of `ns`.

The y-axis is the ratio of the implementation's time cost, made relative to that of the least time-consuming.

The benchmark results in dataframe format are available at [this directory](https://github.com/thautwarm/MLStyle.jl/tree/master/stats).

## Arrays

- code: [matrix-benchmark/bench-array.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-array.jl)

[![matrix-benchmark/bench-array.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-array.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-array.txt)

## Tuples

- code: [matrix-benchmark/bench-tuple.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-tuple.jl)

[![matrix-benchmark/bench-tuple.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-tuple.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-tuple.txt)

## Data Types

- code: [matrix-benchmark/bench-datatype.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-datatype.jl)

[![matrix-benchmark/bench-datatype.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-datatype.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-datatype.txt)

## Extracting Struct Definitions

- code: [matrix-benchmark/bench-structfields.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-structfields.jl)

[![matrix-benchmark/bench-structfields.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-structfields.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-structfields.txt)

## Misc

- code: [matrix-benchmark/bench-misc.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-misc.jl)

[![matrix-benchmark/bench-misc.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-misc.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-misc.txt)

## An Example from Match.jl Documentation

- code: [matrix-benchmark/bench-vs-match.jl](https://github.com/thautwarm/MLStyle.jl/blob/master/matrix-benchmark/bench-vs-match.jl)

[![matrix-benchmark/bench-versus-match.jl](https://raw.githubusercontent.com/thautwarm/MLStyle.jl/master/stats/bench-versus-match.svg)](https://github.com/thautwarm/MLStyle.jl/blob/master/stats/bench-vs-match.txt)
