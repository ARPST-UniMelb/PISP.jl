# Comparing ISP 2024 and ISP 2026

The comparison pages align reports, workbooks, model archives, trace families,
and package mappings without treating similar names as equivalent data.

The [ISP report catalogue](../generated/comparison/references/report-catalogue.md)
contains the complete configured report lists for both editions.
Its counterpart table includes only reports with an explicit semantic match.
All other reports remain in their edition catalogue.

The [raw-source comparison](../generated/comparison/analyses/raw-source-comparison.md)
compares the non-trace inputs and assumptions workbooks, EV workbooks, and generation and
storage outlooks.
It shows worksheet additions and removals, moved source families, declared
worksheet dimensions, and schema changes.
The [source-material subject pages](source-material.md) provide the detailed
workbook selections, keys, fields, and units behind those comparisons.

The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md)
compares scenario directories, XML files, trace families, file counts, sizes,
and representative filenames.
It follows AEMO's published scenario lineage: Step Change refines the 2023
scenario with the same name
([2025 IASR, p. 18](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=18)),
Slower Growth succeeds Progressive Change
([p. 19](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=19)),
and Accelerated Transition refines Green Energy Exports
([p. 20](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=20)).

The [trace coverage](trace-coverage.md) page compares trace families,
reference-year labels, POE terminology, schemas, and time-series layouts.
The [parameters and mappings](parameters-and-mappings.md) page identifies the
scenario, geography, technology, and source-field crosswalks needed by parser
and dataset work.

```@meta
# Wind, solar, and timeslice traces are published separately from these raw-source and model-archive comparisons. Units, keys, time coverage, model-XML references, package mappings, and generated CSV schemas each need their own release-specific validation before data from the two editions can be treated as equivalent.

# A cross-edition data comparison must align units, keys, time coverage, scenario meaning, technology categories, and missing records before numerical differences are interpreted.
```
