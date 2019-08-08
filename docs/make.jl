using Documenter, JLSO

makedocs(
    modules=[JLSO],
    format=Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages=[
        "Home" => "index.md",
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

deploydocs(;
    repo="github.com/invenia/JLSO.jl",
)
