# Regenerates `docs/src/generated/problem_table.md` from
# `docs/literate/problem_table.jl`.
#
# `docs/make.jl` never imports or calls `Literate` — rendering the
# Literate.jl source is this separate, explicit step, and its output under
# `docs/src/generated/` is committed to Git, not gitignored. A normal
# `makedocs()` build only publishes already-rendered Markdown, so it stays
# hermetic: no network access, no dependency on AEMO data or a website that
# might change. See the `arpst-unimelb-agents` workspace's
# `memories/decisions/adr/0009-documenter-jl-plus-literate-jl-docs-stack.md`
# for why the two steps are kept apart.
#
# One tutorial, one hardcoded call — no manifest, no ledger, no CLI flags.
# Revisit that if a second Literate source is ever added here.
#
# Usage (from the repository root):
#   julia --project=docs docs/render_literate.jl

using Literate

const DOCS_DIR = @__DIR__
const LITERATE_DIR = joinpath(DOCS_DIR, "literate")
const GENERATED_DIR = joinpath(DOCS_DIR, "src", "generated")

mkpath(GENERATED_DIR)

Literate.markdown(
    joinpath(LITERATE_DIR, "problem_table.jl"),
    GENERATED_DIR;
    flavor = Literate.DocumenterFlavor(),
    execute = true,
)
