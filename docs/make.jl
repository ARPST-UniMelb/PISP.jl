# Documenter.jl site build for PISP.jl.
#
# This file must never depend on the separate, explicit render step
# (`docs/render_literate.jl`) that produces `docs/src/generated/`. That
# output is committed to Git, not gitignored, so a normal build here only
# publishes already-rendered Markdown: no network access, no dependency on
# AEMO data or a website that might change. See the `arpst-unimelb-agents`
# workspace's
# `memories/decisions/adr/0009-documenter-jl-plus-literate-jl-docs-stack.md`.
#
# `modules` is deliberately omitted below: passing `modules = [PISP]` would
# turn on `checkdocs` (default `:all`), which would fail/warn on every
# docstring in the package not referenced from a `@docs` block on this
# site — most of PISP's source docstrings are unrelated to this tutorial
# and authoring a full API reference is out of scope for this task. The
# `@docs` block in `docs/src/api.md` still resolves the three functions it
# names directly; it does not depend on `modules` being set.
#
# This is a **local build only**. There is no `deploydocs()` call — per
# ADR 0009, deployment stays out of scope until PISP.jl's docs have a
# pushed remote and CI to run against. Open `docs/build/index.html`
# directly in a browser; no server is required.
#
# Usage (from the repository root):
#   julia --project=docs docs/make.jl
#   open docs/build/index.html

using Documenter
using PISP

const DOCS_DIR = @__DIR__

makedocs(;
    sitename = "PISP.jl",
    build = joinpath(DOCS_DIR, "build"),
    source = joinpath(DOCS_DIR, "src"),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "generated/problem_table.md",
        "API Reference" => "api.md",
    ],
)

# No `deploydocs()` call — see module docstring above and ADR 0009. If this
# ever needs to be added, guard it behind a CI check, e.g.:
#
#   if get(ENV, "CI", "false") == "true"
#       deploydocs(repo = "github.com/yasirroni/PISP.jl.git")
#   end
#
# so it stays provably inert on a local run like this one.
