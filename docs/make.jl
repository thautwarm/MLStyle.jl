using Documenter
using MLStyle, MLStyle.Data


DataModule = [MLStyle.Data.List, MLStyle.Data.TypedFn]
makedocs(
    modules = [MLStyle.ADT, MLStyle.Match, MLStyle.Feature, MLStyle.Err,
               DataModule...],

    clean = false,
    format = :html,
    sitename = "MLStyle.jl",

    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home" => "index.md",
        "Syntax" => Any[
            "syntaxl/adt.md",
            "syntax/pattern.md",
            "syntax/matching.md",
            "syntax/pattern-function.md",
        ],
        "Data" => Any[
            "data/list.md",
            "data/typed-function.md",
        ],
        "Feature" => Any[
            "feature/type-level.md"
        ],
    ],
    html_prettyurls = !("local" in ARGS),
)