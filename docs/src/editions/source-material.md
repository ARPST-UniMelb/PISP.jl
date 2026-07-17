# Source material

PISP works with AEMO Integrated System Plan material drawn from several source
families. The relationship between a source family and a PISP workflow is
edition-specific. PISP provides ISP 2026 asset and report downloaders, but it
does not yet provide an ISP 2026 parser, build consumer, or generated-output
contract.

| Source family | ISP 2024 PISP consumer or support | ISP 2026 PISP support boundary | Cross-release relationship status |
| --- | --- | --- | --- |
| Report PDFs | `PISP.download_ISP24_reports` downloads selected reports for documentation and source consultation. | `PISP.download_ISP26_reports` downloads selected report PDFs; no PISP parser or build consumer exists. | Unknown |
| Appendices | The 2024 report downloader includes selected appendices for documentation and source consultation. | The 2026 report downloader includes appendices A2, A3, A4, A6, and A7; no PISP parser or build consumer exists. | Unknown |
| Inputs and assumptions workbooks | The implemented 2024 parser and `PISP.build_ISP24_datasets` consume the configured 2024 input workbook. | `PISP.download_isp2026_assets` downloads the 2026 inputs-and-assumptions workbook; no PISP parser or build consumer exists. | Unknown |
| EV workbook | The implemented 2024 parser uses the configured 2023 IASR EV workbook when building EV DER schedules. | The 2026 asset downloader obtains the 2025 IASR EV workbook; no PISP parser or build consumer exists. | Unknown |
| Model archive | The implemented 2024 workflow consumes model-side material, including hydro-inflow inputs. | The 2026 asset downloader obtains the model archive only; it does not extract or parse it. | Unknown |
| Generation and storage outlook archive | The implemented 2024 workflow uses outlook material to derive development and schedule inputs. | The 2026 asset downloader obtains the outlook archive only; it does not extract or parse it. | Unknown |
| Solar trace archive | The implemented 2024 workflow downloads and uses release-specific solar traces. | The 2026 asset downloader obtains the solar-trace archive only; it does not derive trace data. | Unknown |
| Wind trace archive | The implemented 2024 workflow downloads and uses release-specific wind traces. | The 2026 asset downloader obtains the wind-trace archive only; it does not derive trace data. | Unknown |
| `Auxiliary` material | The 2024 build pipeline creates and consumes `Auxiliary` outlook workbooks as package-derived support material. | No 2026 `Auxiliary` layout or PISP build consumer is implemented. | Edition-only: ISP 2024 PISP support material |
| Generated PISP datasets | `PISP.build_ISP24_datasets` writes the implemented 2024 PISP dataset outputs. | No ISP 2026 parser, build workflow, or generated PISP dataset output exists. | Edition-only: ISP 2024 package output |

The [ISP 2024 data sources](../generated/isp2024/reference/data-sources.md)
page explains the source families consumed by the implemented 2024 workflow.
The [ISP 2026 overview](isp2026.md) describes the acquisition-only support
available for 2026 material.

An unknown relationship is not a compatibility claim. Similar source names do
not establish a shared schema, coverage, scenario definition, modelling role,
parser compatibility, or generated-output contract. Those relationships need
release-specific evidence and an explicit crosswalk.
