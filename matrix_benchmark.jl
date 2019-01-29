# If you want to run this matrix-benchmarks, you should install
# a dependency `Benchmarkplotting` which is not registered on JuliaRegistries.
#    pkg> add https://github.com/thautwarm/Benchmarkplotting.jl
using MLStyle
using ArgParse

versus_items = ("hw-tuple", "hw-array", "macrotools", "match")

function parse_cmd()
    s = ArgParseSettings()
    @add_arg_table s begin
        "versus"
            help = join(", ", versus_items)
            required = true
            action => :store_arg
            nargs = '+'
    end
    parse_args(ARGS, s)
end

check_versus(x) = x in versus_items

function benchmark(x)
    filename = "matrix-benchmark/versus-$x.jl"
    open(filename) do f
        include_string(Main, read(f, String), filename);
    end
end

action = @λ begin
    [] -> nothing
    [function check_versus end && hd, tl...] ->
        begin
            benchmark(hd)
            action(tl)
        end
    [hd, tl...] ->
        begin
            @warn "Unknown versus item: $hd"
            action(hd)
        end
end

function main()
    parsed_args = parse_cmd()
    Dict([a => b for (a, b) in parsed_args])["versus"] |> action
end

main()