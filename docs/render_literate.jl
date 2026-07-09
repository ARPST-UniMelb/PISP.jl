# Regenerates every `docs/src/generated/*.md` from `docs/literate/*.jl`.
#
# `docs/make.jl` never imports or calls `Literate` — rendering the Literate.jl sources is this separate, explicit step, and its output under `docs/src/generated/` is committed to Git, not gitignored. A normal `makedocs()` build only publishes already-rendered Markdown, so it stays hermetic: no network access, no dependency on AEMO data or a website that might change. Keeping the two steps apart is what makes that hermetic guarantee possible.
#
# Two tutorials, one small literal list and a loop over it — still no TOML manifest, no ledger, no CLI flags. That is deliberately as much structure as this file has; revisit only if a third tutorial or a second repo-specific concern actually needs more than a literal list.
#
# **Not every tutorial here is data-free.** Unlike `problem_table.jl`, `pisp_outputs_validation.jl` reads a local AEMO/PISP data build from `data/pisp-datasets/out-ref4006-poe10/csv/` that is not produced by this repository's normal test/CI path — see that tutorial's own header for the full precondition. On a bare clone without that local data build, this loop renders `problem_table.jl` fine and then fails on `pisp_outputs_validation.jl`; that failure is caught below and reported with a clear, named message instead of surfacing as a cryptic `CSV.read`/file-not-found error deep inside the tutorial. That is expected and does not affect `docs/make.jl`, which never depends on this script or on any local data at all.
#
# Usage (from the repository root):
#   julia --project=docs docs/render_literate.jl

using Literate

const DOCS_DIR = @__DIR__
const LITERATE_DIR = joinpath(DOCS_DIR, "literate")
const GENERATED_DIR = joinpath(DOCS_DIR, "src", "generated")
const REPO_ROOT = joinpath(DOCS_DIR, "..")
const PISP_DATA_ROOT = joinpath(
    REPO_ROOT, "data", "pisp-datasets", "out-ref4006-poe10", "csv",
)

mkpath(GENERATED_DIR)

# Name each tutorial source once here; every other Plan/Acceptance-criteria statement about "no manifest" refers to not needing anything more structured than this literal list.
const LITERATE_SOURCES = [
    "problem_table.jl",
    "pisp_outputs_validation.jl",
]

for source_name in LITERATE_SOURCES
    source_path = joinpath(LITERATE_DIR, source_name)
    # A missing *source file* is a real bug in this repo — let Literate's own `isfile` check fail loudly rather than swallowing it here.
    if source_name == "pisp_outputs_validation.jl" && !isdir(PISP_DATA_ROOT)
        error(
            "expected local AEMO/PISP data build not found at " *
            "\"$PISP_DATA_ROOT\" — see docs/literate/pisp_outputs_validation.jl's " *
            "header for the local-data precondition this tutorial needs before " *
            "it can be regenerated.",
        )
    end
    Literate.markdown(
        source_path,
        GENERATED_DIR;
        flavor = Literate.DocumenterFlavor(),
        execute = true,
    )
end
