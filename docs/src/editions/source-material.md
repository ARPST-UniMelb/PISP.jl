# AEMO ISP source material

The source pages describe the reports, workbooks, model archives, outlooks,
and traces used for ISP 2024 and ISP 2026.
They organise the material by subject so the two editions can be compared
without assuming that a matching filename or worksheet has the same structure.

The documentation follows the lifecycle:

```text
AEMO source data -> ParseISP transformation -> ParseISP datasets
```

The [ISP report catalogue](../generated/comparison/references/report-catalogue.md)
lists every configured ISP 2024 and ISP 2026 report with repository and AEMO
links, together with the reports that have an explicit counterpart.

## Browse the source subjects

| Subject | Reader question |
| --- | --- |
| [Source coverage](../generated/shared/source-material/coverage-and-ownership.md) | Which files, workbook selections, and mapping families are used by each documentation subject? |
| [Scenarios and sensitivities](../generated/shared/source-material/scenarios-and-sensitivities.md) | How are the scenario sets and outlook cases organised in each edition? |
| [Existing generation and storage](../generated/shared/source-material/existing-generation-and-storage.md) | How do the workbooks identify existing units, capacity, emissions, and storage properties? |
| [Generator operating assumptions](../generated/shared/source-material/generator-operation.md) | Where are minimum stable levels, minimum up/down times, and ramp rates represented? |
| [Generator reliability and retirement](../generated/shared/source-material/generator-reliability-and-retirement.md) | How are outage assumptions and expected closure records structured? |
| [Generation and storage outlook](../generated/shared/source-material/generation-and-storage-outlook.md) | What do the core and sensitivity workbooks publish? |
| [Network and transmission assumptions](../generated/shared/source-material/network-and-transmission.md) | How are transfer capability, reliability, augmentation options, and network geography represented? |
| [Renewable energy zones](../generated/shared/source-material/renewable-energy-zones.md) | Which zone identifiers and attributes are present, renamed, or expanded? |
| [Demand and distributed resources](../generated/shared/source-material/demand-and-distributed-resources.md) | How do demand allocation, data-centre demand, and distribution-network material differ? |
| [Demand-side participation](../generated/shared/source-material/demand-side-participation.md) | How does the repeated 2024 matrix layout compare with the row-oriented 2026 structure? |
| [Electric vehicles](../generated/shared/source-material/electric-vehicles.md) | Which vehicle-number, charging-share, consumption, and profile tables are published? |
| [Hydro inflows and energy constraints](../generated/shared/source-material/hydro-inflows-and-energy-constraints.md) | How do workbook reference-year tables and model CSVs differ between editions? |

The [raw-source comparison](../generated/comparison/analyses/raw-source-comparison.md)
summarises additions, removals, moves, worksheet dimensions, and schema
changes across these subjects.
The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md)
separately covers archive packaging, scenario directories, XML files, and trace
families.
Bulk trace payloads are described under [trace coverage](trace-coverage.md).

## Source collections

| Source material | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Report PDFs | The 2024 report downloader includes the main ISP report and selected appendices. | The 2026 report downloader includes the main ISP report and appendices A2, A3, A4, A6, and A7. |
| Inputs and assumptions workbook | The parser reads generation, storage, reliability, retirement, network, REZ, hydro, DSP, and other assumptions from the 2024 workbook. | The 2026 workbook covers the same broad subjects and adds rooftop PV, data-centre demand, distribution-network limits, hybrid-site limits, and expanded fuel and gas tables. |
| EV workbook | The 2023 IASR EV workbook supplies vehicle numbers, charging shares, and profiles used by the 2024 workflow. | The 2025 IASR EV workbook adds FCEV and hybrid vehicle families, annual consumption, and revised charging tables. |
| Model archive | The 2024 archive contains scenario models and model-side trace folders used by the package. | The 2026 archive contains Accelerated Transition, Slower Growth, and Step Change models with demand, DNSP, gas, hydro, load-subtractor, rooftop-PV, and timeslice folders. |
| Generation and storage outlook | The 2024 outlooks provide capacity, storage, REZ, and sensitivity tables used by preprocessing. | The 2026 outlooks provide revised core and sensitivity workbooks, storage tables, REZ capacity, and candidate development paths. |
| Solar and wind trace archives | The 2024 traces are organised by technology, project, and reference year. | The 2026 traces are published as separate project-level solar and wind archives using `RefYear5000` filenames. |
| `Auxiliary` material | The 2024 build creates and consumes `Auxiliary` outlook workbooks as ParseISP-generated preprocessing intermediates. | No equivalent 2026 `Auxiliary` layout or build consumer is documented. |
| Generated ParseISP datasets | `ParseISP.build_ISP24_datasets` writes the documented ISP 2024 static and schedule outputs. | No integrated ISP 2026 dataset builder or generated-output contract exists yet. |

The [2024 ISP PLEXOS Model Instructions, pp. 5 and 7](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5)
and the [2026 ISP PLEXOS Model Instructions, pp. 5 and 7](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5)
describe the scenario and trace collections used by each model release.

Similar names do not establish the same schema, keys, units, coverage, or
modelling role.
The [comparison guide](comparison.md) links the pages that make those
differences explicit.
