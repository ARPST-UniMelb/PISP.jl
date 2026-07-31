# AEMO ISP source material

The ISP source-data layer comprises AEMO publications, their data meaning, and the boundary between acquisition and integrated PISP processing.
The documentation follows the lifecycle:

```text
AEMO source data -> PISP transformation -> PISP datasets
```

The shared source pages compare non-trace ISP 2024 and ISP 2026 material by subject.
ISP 2024 pages can connect source evidence to the implemented PISP workflow.
ISP 2026 pages describe observed source structure and do not imply an integrated PISP preprocessing or dataset-build workflow.
[Supported ISP editions](supported-editions.md) remains the authority for workflow support.

## Browse the source subjects

| Subject | Reader question |
| --- | --- |
| [Coverage and ownership](../generated/shared/source-material/coverage-and-ownership.md) | Which active workbook and CSV reads, parameter files, and mapping families have a canonical documentation owner? |
| [Scenarios and sensitivities](../generated/shared/source-material/scenarios-and-sensitivities.md) | How are the scenario sets and outlook cases organised in each edition? |
| [Existing generation and storage](../generated/shared/source-material/existing-generation-and-storage.md) | How do the workbooks identify existing units, capacity, emissions, and storage properties? |
| [Generator operating assumptions](../generated/shared/source-material/generator-operation.md) | Where are minimum stable levels, minimum up/down times, and ramp rates represented? |
| [Generator reliability and retirement](../generated/shared/source-material/generator-reliability-and-retirement.md) | How are outage assumptions and expected closure records structured? |
| [Generation and storage outlook](../generated/shared/source-material/generation-and-storage-outlook.md) | What do the core and sensitivity workbooks publish, and where does PISP preprocessing begin? |
| [Network and transmission assumptions](../generated/shared/source-material/network-and-transmission.md) | How are transfer capability, reliability, augmentation options, and network geography represented? |
| [Renewable energy zones](../generated/shared/source-material/renewable-energy-zones.md) | Which zone identifiers and attributes are present, renamed, or expanded? |
| [Demand and distributed resources](../generated/shared/source-material/demand-and-distributed-resources.md) | How do demand allocation, data-centre demand, and distribution-network material differ? |
| [Demand-side participation](../generated/shared/source-material/demand-side-participation.md) | How does the repeated 2024 matrix layout compare with the row-oriented 2026 structure? |
| [Electric vehicles](../generated/shared/source-material/electric-vehicles.md) | Which vehicle-number, charging-share, and charging-profile subjects are published? |
| [Hydro inflows and energy constraints](../generated/shared/source-material/hydro-inflows-and-energy-constraints.md) | How do workbook reference-year tables and model CSVs relate to PISP hydro conventions? |

The [raw-source comparison](../generated/comparison/analyses/raw-source-comparison.md) synthesises additions, removals, relocations, dimensions, and schema changes across these subjects.
The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md) separately covers archive packaging, scenario directories, XML files, and trace families.
Bulk trace payloads remain under [trace coverage](trace-coverage.md).

## Source roles

| Source material | ISP 2024 role in PISP | ISP 2026 acquisition and integration status |
| --- | --- | --- |
| Report PDFs | `PISP.download_ISP24_reports` downloads selected reports for documentation and source consultation. | `PISP.download_ISP26_reports` downloads selected report PDFs. Report acquisition does not define an integrated parser or dataset-build consumer. |
| Report appendices | The 2024 report downloader includes selected appendices for documentation and source consultation. | The 2026 report downloader includes appendices A2, A3, A4, A6, and A7. These remain source material unless processed through a separately verified workflow. |
| Inputs and assumptions workbook | The implemented parser and `PISP.build_ISP24_datasets` consume the configured 2024 workbook. | `PISP.download_isp2026_assets` downloads the 2026 inputs-and-assumptions workbook. The shared pages document observed fields without claiming integrated parser coverage. |
| EV workbook | The 2024 parser uses the configured 2023 IASR EV workbook when constructing EV-related DER schedules. | The asset downloader obtains the 2025 IASR EV workbook. Its fields are not part of a documented PISP.jl 2026 output contract. |
| Model archive | The implemented 2024 workflow consumes model-side material, including hydro-inflow inputs. | The asset downloader obtains the 2026 model archive, and `PISP.ISPdatabuilder.extract_downloads` extracts downloaded archives. |
| Generation and storage outlook archive | The implemented 2024 workflow uses outlook material to derive development and schedule inputs. | The asset downloader obtains the 2026 outlook archive, and the extraction helper prepares its contents for inspection. |
| Solar and wind trace archives | The implemented 2024 workflow downloads and consumes release-specific traces. | The 2026 asset downloader obtains and can extract the trace archives; no PISP.jl 2026 trace contract is documented. |
| `Auxiliary` material | The 2024 build creates and consumes `Auxiliary` outlook workbooks as PISP-generated preprocessing intermediates. | No equivalent 2026 `Auxiliary` layout or build consumer is documented. |
| Generated PISP datasets | `PISP.build_ISP24_datasets` writes the documented ISP 2024 static and schedule outputs. | PISP.jl does not document an integrated ISP 2026 dataset builder or generated-output contract. |

A report artefact is a citable source document; a statement within that report is a claim or assumption supported by that source.
PISP documentation keeps those roles distinct when describing source material and modelling meaning.

For report-backed trace-folder meanings, see the [2024 ISP PLEXOS Model Instructions, p. 5](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=7), and the [2026 ISP PLEXOS Model Instructions, p. 5](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7).
The trace pages use those reports to explain trace groups, not to infer that similarly named local folders are equivalent across editions.

Similar source names do not establish a shared schema, coverage, scenario definition, modelling role, parser compatibility, or generated-output contract.
The [comparison guide](comparison.md) defines the evidence and crosswalks required before comparing editions.
