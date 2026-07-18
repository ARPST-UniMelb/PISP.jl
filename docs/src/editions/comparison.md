# Comparing ISP 2024 and ISP 2026

PISP documentation separates comparison method from comparison results.
PISP.jl constructs ISP 2024 outputs through its documented build workflow.
For ISP 2026, PISP.jl supports source download and archive extraction, while parser development is under review and is not yet integrated into PISP.jl's documented dataset-build and output workflow.
No numerical result or compatibility conclusion follows from the presence of material from both releases.

## Required crosswalks

A cross-release study needs explicit evidence for each of the following relationships.

| Topic | Crosswalk or evidence required |
| --- | --- |
| Source materials | Identify the exact source files, their release-specific role, and unresolved source relationships. |
| Scenarios | Map labels, identifiers, definitions, and assumptions rather than matching names alone. |
| Time conventions | Reconcile dates, planning periods, financial-year conventions, and temporal resolution. |
| Money and cost values | Establish dollar basis, price year, escalation treatment, and any real or nominal convention. |
| Assets, geography, and REZs | Map identifiers, aggregation boundaries, geographic areas, renewable-energy-zone definitions, and asset inclusion rules. |
| Technologies and units | Reconcile technology groupings, units, and capacity definitions. |
| Split, merged, and missing records | Define how one-to-many, many-to-one, unmatched, and excluded records are retained and reported. |
| Traces | Establish trace identifiers, weather years, coverage, time axes, units, and selection rules. |
| Outputs | Define a 2026 data model before comparing it with the documented 2024 output contract. |

## Suggested method

1. Record the source materials and their release-specific definitions.
2. Build and validate the required crosswalks before aggregating or subtracting values.
3. Preserve one-to-many, many-to-one, unmatched, and excluded records as reviewable evidence; do not silently remove them with an inner join.
4. Align units, dollar basis, time conventions, scenarios, and aggregation levels.
5. Test the resulting mappings on a small, traceable subset.
6. State any remaining unmatched, inferred, or excluded material with the comparison result.

The [ISP 2024 overview](isp2024.md) describes the implemented output workflow.
The [ISP 2026 overview](isp2026.md) summarises the source, parser-review, and integration boundary for 2026 material.
The [supported editions](supported-editions.md) page is the detailed capability status authority.
The [trace coverage](trace-coverage.md) and [parameters and mappings](parameters-and-mappings.md) pages identify two areas that require release-specific treatment.
The [source-availability comparison](../generated/comparison/validation/source-availability-by-edition.md)
shows the observed acquisition and extraction structures without asserting
semantic equivalence.
