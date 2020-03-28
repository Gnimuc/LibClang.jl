using LibClang
using Documenter

makedocs(;
    modules=[LibClang],
    authors="Yupei Qi <qiyupei@gmail.com>",
    repo="https://github.com/Gnimuc/LibClang.jl/blob/{commit}{path}#L{line}",
    sitename="LibClang.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Gnimuc.github.io/LibClang.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Gnimuc/LibClang.jl",
)
