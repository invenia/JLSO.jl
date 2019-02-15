using Documenter, JLSO

makedocs(
    modules=[JLSO],
    format=:html,
    pages=[
        "Home" => "index.md",
        "Usage" => "usage.md",
        "API" => "api.md",
    ],
    repo="https://github.com/invenia/JLSO.jl/blob/{commit}{path}#L{line}",
    sitename="JLSO.jl",
    authors="Rory Finnegan",
    assets=[
        "assets/invenia.css",
    ],
    strict = true,
    checkdocs = :none,
)
