# Source material

PISP uses edition-specific AEMO reports, workbooks, archives, and traces.
The table identifies the actual source artefacts and distinguishes an acquired 2026 source from an integrated PISP.jl dataset input.

| Source material | ISP 2024 role in PISP | ISP 2026 acquisition and integration status |
| --- | --- | --- |
| Report PDFs | `PISP.download_ISP24_reports` downloads selected reports for documentation and source consultation. | `PISP.download_ISP26_reports` downloads selected report PDFs. Report acquisition does not define an integrated parser or dataset-build consumer. |
| Report appendices | The 2024 report downloader includes selected appendices for documentation and source consultation. | The 2026 report downloader includes appendices A2, A3, A4, A6, and A7. These remain source material unless processed through a separately verified workflow. |
| Inputs and assumptions workbook | The implemented parser and `PISP.build_ISP24_datasets` consume the configured 2024 workbook. | `PISP.download_isp2026_assets` downloads the 2026 inputs-and-assumptions workbook. Detailed parser coverage is not established by PISP.jl documentation. |
| EV workbook | The 2024 parser uses the configured 2023 IASR EV workbook when constructing EV-related DER schedules. | The 2026 asset downloader obtains the 2025 IASR EV workbook. Its fields are not part of a documented PISP.jl 2026 output contract. |
| Model archive | The implemented 2024 workflow consumes model-side material, including hydro-inflow inputs. | The 2026 asset downloader obtains the model archive, and `PISP.ISPdatabuilder.extract_downloads` extracts downloaded archives. |
| Generation and storage outlook archive | The implemented 2024 workflow uses outlook material to derive development and schedule inputs. | The 2026 asset downloader obtains the outlook archive, and the extraction helper prepares its contents for inspection. |
| Solar trace archive | The implemented 2024 workflow downloads and consumes release-specific solar traces. | The 2026 asset downloader obtains and can extract the solar-trace archive; no PISP.jl 2026 trace contract is documented. |
| Wind trace archive | The implemented 2024 workflow downloads and consumes release-specific wind traces. | The 2026 asset downloader obtains and can extract the wind-trace archive; no PISP.jl 2026 trace contract is documented. |
| `Auxiliary` material | The 2024 build creates and consumes `Auxiliary` outlook workbooks as package-derived support material. | No equivalent 2026 `Auxiliary` layout or build consumer is documented. |
| Generated PISP datasets | `PISP.build_ISP24_datasets` writes the documented ISP 2024 static and schedule outputs. | PISP.jl does not document an integrated ISP 2026 dataset builder or generated-output contract. |

The [ISP 2024 data sources](../generated/isp2024/reference/data-sources.md) page explains the source families consumed by the implemented 2024 workflow.
The [ISP 2026 overview](isp2026.md) describes source download and extraction, the ParseISP.jl review state, and the current PISP.jl integration boundary.

For report-backed trace-folder meanings, see the 2024 and 2026 PLEXOS Model
Instructions, physical pp. 5 and 7. The local source pages use those reports to
explain trace groups, not to infer that similarly named local folders are
equivalent across editions.

Similar source names do not establish a shared schema, coverage, scenario definition, modelling role, parser compatibility, or generated-output contract.
The [comparison guide](comparison.md) defines the release-specific evidence and crosswalks required before comparing editions.
