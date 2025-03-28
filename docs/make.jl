using Documenter, FusionSpecies

makedocs(;
    modules=[FusionSpecies],
    format=Documenter.HTML(; analytics="G-65D8V8C8VQ"),
    sitename="FusionSpecies",
    checkdocs=:none,
    pages=["index.md", "License" => "license.md", "Notice" => "notice.md"]
)

#
# Deploy docs
# This function deploys the documentation to the gh-pages branch of the repository.
# The main documentation that will be hosted on
# https://projecttorreypines.github.io/FusionSpecies.jl/stable
# will be built from latest release tagged with a version number.
# The development documentation that will be hosted on
# https://projecttorreypines.github.io/FusionSpecies.jl/dev
# will be built from the latest commit on the chosen devbranch argument below.
# For testing purposes, the devbranch argument can be set to WIP branch like "docs".
# While merging with master, the devbranch argument should be set to "master".
deploydocs(;
    repo="github.com/ProjectTorreyPines/FusionSpecies.jl.git",
    target="build",
    branch="gh-pages",
    devbranch="master",
    versions=["stable" => "v^", "v#.#"]
)