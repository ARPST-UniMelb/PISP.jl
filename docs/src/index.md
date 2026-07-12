# PISP.jl

AEMO publishes the Integrated System Plan as a collection of workbooks, model archives, outlook files, and time-series traces.
Using those materials in a power-system study requires more than downloading them: scenario labels must be reconciled, assets must be assigned to a common network representation, financial-year conventions must be handled, and time-varying traces must remain linked to the static assets they describe.

PISP.jl performs that data-preparation work for the 2024 Integrated System Plan.
It converts the published material and package-defined mappings into a consistent set of power-system tables that downstream modelling tools can consume.
PISP is a dataset builder, not a dispatch, unit-commitment, capacity-expansion, or power-flow model.

## What becomes available

A PISP build produces three connected forms of information:

| Dataset layer | What it provides | Typical use |
|---|---|---|
| Static asset tables | Buses, demand nodes, generators, storage, transmission corridors, and demand-side resources. | Define the assets and their time-invariant parameters. |
| Schedule tables | Scenario- and time-dependent demand, capacity, unit-count, transfer-limit, inflow, and DER values. | Reconstruct how the static system changes across a study period. |
| Scenario and time metadata | Scenario identifiers, requested planning years or date ranges, trace selection, and financial-year blocks. | Keep schedules comparable and reproducible. |

The static tables and schedules form one dataset model.
A schedule should be joined to its corresponding static table rather than interpreted as an independent asset inventory.
See [Domain concepts](@ref) for the relationships and [Output tables](@ref) for the exported files.

## Who the package is for

PISP is intended for researchers and model developers who need a structured NEM planning dataset before running a downstream optimisation, simulation, or reliability workflow.
It is particularly useful when a study needs to preserve the distinctions among ISP scenario, planning period, reference trace, probability of exceedance, and asset identity.

The package does not remove the need for modelling judgement.
Users still need to review the aggregated network representation, hard-coded mappings, source vintage, reliability assumptions, and technology-specific caveats before treating the generated data as study-ready.

## Dataset workflow

```text
AEMO ISP source material
          |
          v
PISP parsing, reconciliation, and package mappings
          |
          +-----------------------+
          |                       |
          v                       v
static asset tables        schedule tables
          |                       |
          +-----------+-----------+
                      |
                      v
downstream power-system model or data analysis
```

A typical workflow is:

1. Select the ISP scenarios, planning years or date ranges, reference trace, and demand probability of exceedance.
2. Provide or download the required source material.
3. Build the static and schedule tables.
4. Review the assumptions and mappings that affect the intended study.
5. Join schedules to static assets by the documented identifiers and scenario fields.

## Build entry point

The high-level entry point is `PISP.build_ISP24_datasets(; kwargs...)`.
It accepts whole planning years through `years` or explicit time windows through `drange`.
Where the underlying ISP inputs use Australian financial years, PISP splits the requested period at 1 July so each problem block remains aligned with the source convention.

The [Building a `PISPtimeConfig` problem table](@ref) tutorial shows how those scenario/time blocks are constructed before source files are parsed.

## Understand the data before using it

- [Data sources](@ref) explains why several source vintages and source families are required, and identifies the local input layout.
- [Domain concepts](@ref) explains the asset relationships, scenario model, trace selection, and static-versus-schedule design.
- [Output tables](@ref) documents the exported files, join keys, units, and reconstruction rules.
- [Parameters and mappings](@ref) records package-defined values that materially affect the dataset.
- [Assumptions and scope](@ref) defines the modelling boundaries and validation responsibilities that remain with the user.

## Tutorials

[Building a `PISPtimeConfig` problem table](@ref) explains the scenario/time index that PISP creates before reading AEMO files.
It runs entirely in memory.

[Working with PISP-generated outputs](@ref) loads a local PISP output build and relates generator and demand schedules back to the static asset tables.
The tutorial documents its default build path and the environment variables used to select another generated dataset.

## API reference

See [API Reference](@ref) for the public build entry point and the problem-table helpers used by the tutorials.
