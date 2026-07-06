# Literate.jl proof-of-concept driver for PISP.jl.
#
# This is intentionally NOT a Documenter.jl site build. It only processes
# the Literate.jl source(s) under `docs/literate/` into runnable, rendered
# Markdown under `docs/generated/`, and executes the code while doing so
# (`execute = true`) so the generated output reflects real values, not
# just syntax-highlighted source.
#
# Usage (from the repository root):
#   julia --project=docs docs/make.jl

using Literate

const LITERATE_DIR = joinpath(@__DIR__, "literate")
const GENERATED_DIR = joinpath(@__DIR__, "generated")

mkpath(GENERATED_DIR)

Literate.markdown(
    joinpath(LITERATE_DIR, "problem_table.jl"),
    GENERATED_DIR;
    documenter = false,
    execute = true,
)
