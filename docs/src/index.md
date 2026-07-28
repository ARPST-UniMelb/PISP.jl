# PISP.jl

AEMO publishes the Integrated System Plan as workbooks, model archives, outlook files, and time-series traces.
Using those materials in a power-system study requires scenario reconciliation, common asset identifiers, financial-year handling, and explicit links between static assets and time-varying schedules.

PISP.jl implements this data-preparation workflow for the 2024 Integrated System Plan.
It converts supported ISP 2024 material and package-defined mappings into connected power-system tables for downstream optimisation, simulation, reliability, and data-analysis workflows.
PISP.jl also provides ISP 2026 report and source-asset acquisition plus archive extraction; [Supported ISP editions](editions/supported-editions.md) defines the complete capability boundary.

## Choose an entry point

- [Quickstart](quickstart.md) installs PISP.jl, builds a small ISP 2024 dataset, and checks representative outputs.
- [ISP 2024](editions/isp2024.md) leads to the implemented source, output, tutorial, validation, and analysis documentation.
- [Supported ISP editions](editions/supported-editions.md) is the support authority for acquisition, parsing, construction, outputs, validation, and analysis.
- [ISP 2026](editions/isp2026.md) describes report/source acquisition, archive extraction, separate parser work, and the current integration boundary.
- [Compare ISP 2024 and ISP 2026](editions/comparison.md) defines the reconciliation required before cross-release comparison.

## ISP 2024 source context

AEMO describes the ISP as a collection of supporting materials, including workbooks, outlook material, traces, and appendices ([2024 Integrated System Plan, p. 92](../../data/2024/pisp-reports/2024-integrated-system-plan.pdf#page=92)).
The public market-model package includes PLEXOS model instructions ([2024 ISP PLEXOS Model Instructions, p. 2](../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=2)) and scenario-specific model data ([2024 ISP PLEXOS Model Instructions, p. 5](../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5)).
The source documents define reference-trace and network conventions ([2024 ISP PLEXOS Model Instructions, pp. 5–7](../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5); [2023 Inputs, Assumptions and Scenarios Report, p. 141](../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=141)) and capacity-outlook probability-of-exceedance profiles ([ISP Methodology, p. 39](../../data/2024/pisp-reports/2023-isp-methodology.pdf#page=39)).
AEMO publishes and maintains all of this material on its [2024 Integrated System Plan page](https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp), the same live page PISP.jl's own downloader targets, rather than only as the dated PDF snapshots cited above.

## ISP 2024 output model

An ISP 2024 PISP build produces three connected forms of information:

| Dataset layer | What it provides | Typical use |
|---|---|---|
| Static asset tables | Buses, demand nodes, generators, storage, transmission corridors, and demand-side resources. | Define the assets and their time-invariant parameters. |
| Schedule tables | Scenario- and time-dependent demand, capacity, unit-count, transfer-limit, inflow, and DER values. | Reconstruct how the static system changes across a study period. |
| Scenario and time metadata | Scenario identifiers, requested planning years or date ranges, trace selection, and financial-year blocks. | Keep schedules comparable and reproducible. |

The static tables and schedules form one dataset model.
A schedule should be joined to its corresponding static table rather than interpreted as an independent asset inventory.
See [Domain concepts](concepts.md) for the relationships and [ISP 2024 output tables](generated/isp2024/reference/output-tables.md) for the exported files.

## Who the package is for

PISP is intended for researchers and model developers who need a structured ISP 2024 NEM planning dataset before running a downstream optimisation, simulation, or reliability workflow.
It is particularly useful when a study needs to preserve the distinctions among ISP scenario, planning period, reference trace, probability of exceedance, and asset identity.

The package does not remove the need for modelling judgement.
Users still need to review the aggregated network representation, hard-coded mappings, source vintage, reliability assumptions, and technology-specific caveats before treating the generated data as study-ready.

## ISP 2024 dataset workflow

```text
AEMO ISP 2024 source material
          |
          v
PISP 2024 parsing, reconciliation, and package mappings
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

A typical ISP 2024 workflow is:

1. Select the ISP scenarios, planning years or date ranges, reference trace, and demand probability of exceedance.
2. Provide or download the required source material.
3. Build the static and schedule tables.
4. Review the assumptions and mappings that affect the intended study.
5. Join schedules to static assets by the documented identifiers and scenario fields.

## Build entry point

The high-level entry point is `PISP.build_ISP24_datasets(; kwargs...)`.
It accepts whole planning years through `years` or explicit time windows through `drange`.
Where the underlying ISP inputs use Australian financial years, PISP splits the requested period at 1 July so each problem block remains aligned with the source convention.

New users should begin with the [Quickstart](quickstart.md), which installs the package, builds one short date range, and checks representative files.

The [Building a `PISPtimeConfig` problem table](generated/isp2024/tutorials/building-problem-table.md) tutorial shows how those scenario/time blocks are constructed before source files are parsed.

## Understand ISP 2024 data before using it

- [Data sources](generated/isp2024/reference/data-sources.md) explains why several source vintages and source families are required, and identifies the local input layout.
- [Domain concepts](concepts.md) explains the asset relationships, scenario model, trace selection, and static-versus-schedule design.
- [Output tables](generated/isp2024/reference/output-tables.md) documents the exported files, join keys, units, and reconstruction rules.
- [Parameters and mappings](generated/isp2024/reference/parameters-and-mappings.md) records package-defined values that materially affect the dataset.
- [Assumptions and scope](assumptions.md) defines the modelling boundaries and validation responsibilities that remain with the user.

## ISP 2024 tutorials

[Building a `PISPtimeConfig` problem table](generated/isp2024/tutorials/building-problem-table.md) explains the scenario/time index that PISP creates before reading AEMO files.
It runs entirely in memory.

[Working with PISP-generated outputs](generated/isp2024/tutorials/working-with-pisp-outputs.md) loads a local ISP 2024 PISP output build and relates generator and demand schedules back to the static asset tables.
The tutorial documents its default build path and the environment variables used to select another generated dataset.

## API reference

See the [API reference](api.md) for the public ISP 2024 build entry point, problem-table helpers, and source-acquisition helpers.
