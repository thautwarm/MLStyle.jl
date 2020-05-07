using Documenter
using MLStyle


makedocs(
    modules = [
        MLStyle.MatchCore,
        MLStyle.DataType,
        MLStyle.Err,
        MLStyle.Pervasives,
        MLStyle.Record,

        # standard patterns
        MLStyle.Active,
        MLStyle.LambdaCases,
        MLStyle.WhenCases
    ],
    clean = false,
    sitename = "MLStyle.jl",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Home"   => "index.md",
        "Syntax" => Any[
            "syntax/adt.md",
            "syntax/switch.md",
            "syntax/pattern.md",
            "syntax/pattern-function.md",
            "syntax/when.md",
        ],
        "Tutorials" => Any[
            "tutorials/capture.md",
            "tutorials/query-lang.md",
        ],
        "Modules" => Any[
            "modules/ast.md",
            "modules/cond.md"
        ]
    ],
)

deploydocs(
    repo="github.com/thautwarm/MLStyle.jl",
    target="build",
    deps=nothing,
    make=nothing)
