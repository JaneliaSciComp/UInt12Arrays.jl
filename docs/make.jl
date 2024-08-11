using UInt12Arrays
using Documenter

DocMeta.setdocmeta!(UInt12Arrays, :DocTestSetup, :(using UInt12Arrays); recursive=true)

makedocs(;
    modules=[UInt12Arrays],
    authors="Mark Kittisopikul <markkitt@gmail.com> and contributors",
    sitename="UInt12Arrays.jl",
    format=Documenter.HTML(;
        canonical="https://mkitti.github.io/UInt12Arrays.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mkitti/UInt12Arrays.jl",
    devbranch="main",
)
