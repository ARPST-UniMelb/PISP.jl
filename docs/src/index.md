# PISP.jl

PISP.jl parses publicly available AEMO 2024 Integrated System Plan (ISP)
material into structured, NEM-schema-like power-system datasets — static
tables (`Bus`, `Demand`, `DER`, `ESS`, `Generator`, `Line`) and time-varying
schedules, written out as CSV and/or Arrow.

The single public high-level entry point is `PISP.build_ISP24_datasets(;
kwargs...)`, which builds one or more "planning problems" — either whole
AEMO planning years (`years`, 2025–2050) or arbitrary date windows
(`drange`) — and always splits each at the 1 July Australian financial-year
boundary internally.

## Tutorial

[Building a `PISPtimeConfig` problem table](@ref) walks through the two
helpers PISP uses internally to seed that split-year "problem table" before
any AEMO file is read — `PISP.fill_problem_table_year` and
`PISP.fill_problem_table_drange`. It runs entirely in memory: no AEMO
downloads or private data are needed, so every value shown is real, executed
output, not illustrative pseudo-code.

## API reference

See [API Reference](@ref) for the docstrings of the functions the tutorial
exercises, plus PISP's actual public entry point.

## Docs stack

This site is built with [Documenter.jl](https://documenter.juliadocs.org/)
consuming [Literate.jl](https://fredrikekre.github.io/Literate.jl/)-generated
tutorial pages, per this workspace's ADR 0009. It is a local build only —
there is no `deploydocs()` call and no hosted version of this site yet.
