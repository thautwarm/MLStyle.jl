"""
check https://github.com/thautwarm/MLStyle.jl/blob/master/matrix_benchmark.jl
"""

include("matrix-benchmark/sampler.jl")
include("matrix-benchmark/utils.jl")
export ArbitrarySampler
export Utils

versus_items = ("datatype", "misc", "tuple", "array", "structfields", "vs-match")

function run_all()
    for item in versus_items
        run_one(item)
    end
end

function run_one(item)
    filename = "matrix-benchmark/bench-$item.jl"
    open(filename) do f
        include_string(Main, read(f, String), filename);
    end
end