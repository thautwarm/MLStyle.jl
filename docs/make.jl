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
        MLStyle.render
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
