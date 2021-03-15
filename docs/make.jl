using Documenter, JLSO

makedocs(
    modules=[JLSO],
    format=Documenter.HTML(
        assets=["assets/invenia.css"],
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages=[
        "Home" => "index.md",
        "Metadata" => "metadata.md",
        "Upgrading" => "upgrading.md",
        "API" => "api.md",
    ],
    repo="https://github.com/invenia/JLSO.jl/blob/{commit}{path}#L{line}",
    sitename="JLSO.jl",
    authors="Invenia Technical Computing Corporation",
    strict=true,
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/invenia/JLSO.jl",
    devbranch = "master",
    push_preview = true,
)
