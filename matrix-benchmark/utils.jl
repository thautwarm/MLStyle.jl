module Utils
export report
using Gadfly
using DataFrames
using Printf
using StatsBase
using Statistics

set_default_plot_size(16cm, 6cm)

function report(result::DataFrame, layouts...; benchfield::Symbol)
    result = copy(result)
    result[!, :label] = (x -> @sprintf "%.2f" x).(result[!, benchfield])
    means = []
    
    case_names = unique(result.case)
    case_names_with_unit = Dict()
    for case_name in case_names
        idx = result[!, :case] .== case_name
        tmp = result[idx, benchfield]
        minval = minimum(tmp)
        gmean = geomean(tmp)
        result[idx, benchfield] = tmp ./ (minval / 10.0)
        push!(means, gmean)
        minval_repr = @sprintf "%.2f" minval
        case_names_with_unit[case_name] = Symbol(case_name, "(1 unit=$minval_repr)")
    end

    casemean = DataFrame(case = case_names, geomean = means)
    benchmarks = innerjoin(result, casemean, on = :case)

    benchmarks[:, :case] = map(x -> case_names_with_unit[x], benchmarks[:, :case])
    casemean[:, :case] = map(x -> case_names_with_unit[x], casemean[:, :case])

    rename!(benchmarks, :implementation => :Implementation)
    
    plot(
        benchmarks,
        x = :Implementation,
        y = benchfield,
        label = :label,
        color = :Implementation,
        xgroup = :case,
        # Theme(bar_spacing=2mm),
        Guide.ylabel(nothing),
        Guide.xlabel(nothing),
        # Coord.cartesian(ymin=0, ymax=3),
        Scale.y_log10,
        # Geom.label(position=:above),
        # Stat.dodge(axis=:y),
        Geom.subplot_grid(Geom.label(position=:above), Geom.bar(position=:dodge)),
        # Scale.x_discrete,
        Scale.color_discrete(levels=unique(benchmarks[:, :Implementation])),
        layouts...,
    ), casemean[:, 1:2]

end
end