# ISP 2024 preprocessing workflow

PISP transforms the published ISP 2024 source material in two phases.
It first prepares an edition-specific local source tree, then constructs the static asset tables and time-varying schedules used by downstream studies.

The workflow below follows that transformation from the public build request to the written dataset.
The [data-sources reference](../generated/isp2024/reference/data-sources.md) identifies the source families, the [parameters and mappings reference](../generated/isp2024/reference/parameters-and-mappings.md) defines package conventions, and the [output-tables reference](../generated/isp2024/reference/output-tables.md) defines the resulting tables.

## End-to-end flow

```text
build request
    |
    +-- download configured sources, or reuse local files
    |
    v
extract archives
    |
    +-- normalise capacity, storage, and REZ outlook tables
    +-- assemble reference trace 4006
    |
    v
create scenario and time blocks
    |
    v
construct static asset tables
    |
    v
overlay time-varying schedules
    |
    +-- optionally insert build-out assets
    |
    v
write CSV and Arrow outputs
```

Source preparation runs once for each call to `PISP.build_ISP24_datasets`.
Dataset construction then runs once for every requested planning year or explicit date range.

## Prepare the local source tree

`downloadpath` identifies the root containing the ISP 2024 workbooks, extracted model material, outlook workbooks, and trace directories.
When `download_from_AEMO = true`, PISP acquires the configured sources before processing them.
When it is `false`, PISP starts from files already present under the same root.

Both paths continue through archive extraction and source preparation.
The acquisition flag therefore controls where the source bytes come from, not whether the remaining preprocessing stages run.

The complete file families and expected local layout are documented in [ISP 2024 data sources](../generated/isp2024/reference/data-sources.md).
The [source-data inventory](../generated/isp2024/validation/source-data-inventory.md) records the observed contents of the configured local source tree.

## Normalise the outlook workbooks

The generation and storage outlook archive publishes scenario workbooks with wide, source-oriented tables.
PISP reads the relevant capacity, storage, and renewable-energy-zone sheets and writes auxiliary tables with predictable scenario and time fields for the later parser stages.

These auxiliary workbooks are PISP-generated intermediates.
They preserve selected source values while changing the table shape needed by the package; they are not original AEMO publications.
See [data sources](../generated/isp2024/reference/data-sources.md) for the source roles and [parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md) for the package conventions applied during normalisation.

## Assemble reference trace 4006

Reference trace 4006 is assembled from selected windows of the historical demand, solar, and wind trace families.
The assembled series gives the planning horizon one continuous reference-weather sequence while retaining the source values from the selected historical windows.

The exact historical-year assignment is defined in [parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md).
The [composite-mapping analysis](../generated/isp2024/analyses/reference-trace-4006-composite-mapping.md) explains its planning-horizon composition, and [trace coverage and schema](../generated/isp2024/validation/trace-coverage-and-schema.md) checks the available trace families and fields.

Trace assembly belongs to source preparation.
The public builder invokes that stage before it decides whether to populate and write the heavy time-varying schedules, so `write_traces = false` does not suppress preparation of reference trace 4006.

## Define scenarios and time blocks

Each requested planning year or date range is expanded across the selected ISP scenarios.
Planning-year builds are divided at 1 July, matching the half-year structure used by the package, while explicit date ranges are split when they cross the same boundary.

The resulting problem rows provide the scenario and time keys used by the schedule builders.
See [building a problem table](../generated/isp2024/tutorials/building-problem-table.md) for the accepted inputs and resulting schema, and [domain concepts](../concepts.md) for the relationship between problem rows, static tables, and schedules.

## Construct static assets before schedules

PISP constructs buses, demands, transmission elements, generators, storage, and distributed-energy-resource rows before it builds their schedules.
This stage reconciles source names with package identifiers and retains intermediate identities needed by the later schedule calculations.

The static tables describe assets and comparatively stable attributes.
Package mappings and engineering assumptions that affect those rows are documented in [parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md) and [assumptions and scope](../assumptions.md).

## Overlay time-varying schedules

The schedule stage combines the problem rows, prepared traces, outlook tables, and static-asset identities.
It adds demand, availability, unit-count, retirement, inflow, storage, distributed-energy-resource, and electric-vehicle quantities where the configured build requires them.

Some schedule builders also complete static classifications while preparing their time series.
For this reason, skipping heavy trace calculations does not bypass every schedule-related function.
The [output-tables reference](../generated/isp2024/reference/output-tables.md) defines the schedule meanings and their joins to static assets.

## Understand the trace controls

The trace-related controls act at different stages of the workflow.

| Control | Stage | Behaviour |
| --- | --- | --- |
| `download_from_AEMO` | Source acquisition | Downloads configured sources when enabled; local extraction and preprocessing continue in either mode. |
| `build_traces` | Internal source preparation | Controls construction of composite trace 4006 inside `build_pipeline`; the public ISP 2024 builder currently uses the enabled default. |
| `write_traces` | Dataset construction | Controls heavy schedule calculation and writing, not source preparation. |
| `check_exist_trace` | Dataset construction | Skips heavy schedule calculation when the expected generator-availability output is already present for each requested format. |
| `skip_traces` | Internal schedule control | Carries the decision into schedule population; lightweight unit-count schedules are still computed and written. |

The [Quickstart](../quickstart.md) shows the public controls in a small build, while the [API reference](../api.md) defines their call signatures.

## Apply optional build-outs and write the dataset

An optional build-out workbook is applied after the base static tables and schedules have been populated.
New generator or storage rows are inserted together with their unit-count schedules, so they follow the same static-to-schedule relationship as parsed assets.
The workbook supplies technology, location, capacity, build year, and unit count; PISP supplies the remaining static-row defaults and computes capacity-dependent fields.
See [ISP 2024 build-out defaults](../generated/isp2024/reference/buildout-defaults.md) for the complete field-level values and override rules.

PISP then writes the selected CSV and Arrow outputs.
Static tables share the dataset root, while schedules are grouped by the requested planning year or date range.
See [working with PISP-generated outputs](../generated/isp2024/tutorials/working-with-pisp-outputs.md) for joins and downstream use.
