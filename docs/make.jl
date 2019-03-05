using Documenter
using MLStyle


makedocs(
    modules = [
        MLStyle.MatchCore,
        MLStyle.DataType,
        MLStyle.Err,
        MLStyle.Extension,
        MLStyle.Infras,
        MLStyle.Pervasives,
        MLStyle.StandardPatterns,
        MLStyle.Render
    ],
    clean = false,
    format = :html,
    sitename = "MLStyle.jl",
    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home"   => "index.md",
        "Syntax" => Any[
            "syntax/adt.md",
            "syntax/pattern.md",
            "syntax/pattern-function.md",
            "syntax/when.md",
            "syntax/extension.md",
            "syntax/qualifier.md"
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
    html_prettyurls = !("local" in ARGS),
)

deploydocs(
    repo="github.com/thautwarm/MLStyle.jl",
    target="build",
    julia="1.0",
    deps=nothing,
    make=nothing)
