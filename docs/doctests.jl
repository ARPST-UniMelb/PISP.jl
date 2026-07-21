# Run the package's docstring doctests (the `jldoctest` blocks in `src/` docstrings)
# without building the full documentation. This is deliberately data-free: it does
# not require the ISP datasets or the rendered Literate pages, so it stays cheap and
# reproducible on any checkout.
#
# Usage:
#   julia --project=docs docs/doctests.jl
using Documenter
using PISP

DocMeta.setdocmeta!(PISP, :DocTestSetup, :(using PISP; using DataFrames; using Dates); recursive = true)

doctest(PISP; manual = false)
