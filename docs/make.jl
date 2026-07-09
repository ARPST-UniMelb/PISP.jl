# Documenter.jl site build for PISP.jl.
#
# This file must never depend on the separate, explicit render step
# (`docs/render_literate.jl`) that produces `docs/src/generated/`. That
# output is committed to Git, not gitignored, so a normal build here only
# publishes already-rendered Markdown: no network access, no dependency on
# AEMO data or a website that might change.
#
# `modules` is deliberately omitted below: passing `modules = [PISP]` would
# turn on `checkdocs` (default `:all`), which would fail/warn on every
# docstring in the package not referenced from a `@docs` block on this
# site — most of PISP's source docstrings are unrelated to this tutorial,
# and a full API reference has not been written yet. The `@docs` block in
# `docs/src/api.md` still resolves the three functions it names directly;
# it does not depend on `modules` being set.
#
# This is a **local build only**. There is no `deploydocs()` call —
# deployment stays out of scope until PISP.jl's docs have a pushed remote
# and CI to run against. Open `docs/build/index.html` directly in a
# browser; no server is required.
#
# Usage (from the repository root):
#   julia --project=docs docs/make.jl
#   open docs/build/index.html

using Documenter
using PISP

const DOCS_DIR = @__DIR__
const SRC = joinpath(DOCS_DIR, "src")
const BUILD = joinpath(DOCS_DIR, "build")

format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", "false") == "true",
    inventory_version = "dev",
    edit_link = "main",
)

makedocs(;
    sitename = "PISP.jl",
    format = format,
    build = BUILD,
    source = SRC,
    pages = [
        "Home" => "index.md",
        "Tutorial" => "generated/problem_table.md",
        "PISP output validation" => "generated/pisp_outputs_validation.md",
        "Caveats" => "caveats.md",
        "Concepts" => "concepts.md",
        "API Reference" => "api.md",
    ],
)

# No `deploydocs()` call — see the module docstring above. If this ever
# needs to be added, guard it behind a CI check, e.g.:
#
#   if get(ENV, "CI", "false") == "true"
#       deploydocs(repo = "github.com/yasirroni/PISP.jl.git")
#   end
#
# so it stays provably inert on a local run like this one.
