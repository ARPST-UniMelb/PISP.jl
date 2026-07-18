# Source material

PISP works with AEMO Integrated System Plan material drawn from several source families.
The relationship between a source family and a PISP workflow is edition-specific.
PISP.jl provides ISP 2026 asset and report downloaders and an archive-extraction helper.
The source-only pages report local availability separately from any parser or
generated-output capability.
The [supported editions](supported-editions.md) page is the detailed status authority.

| Source family | ISP 2024 PISP consumer or support | ISP 2026 PISP support boundary | Cross-release relationship status |
| --- | --- | --- | --- |
| Report PDFs | `PISP.download_ISP24_reports` downloads selected reports for documentation and source consultation. | `PISP.download_ISP26_reports` downloads selected report PDFs. No PISP.jl parser or dataset-build consumer for report PDFs is yet integrated or documented. | Unknown |
| Appendices | The 2024 report downloader includes selected appendices for documentation and source consultation. | The 2026 report downloader includes appendices A2, A3, A4, A6, and A7. No PISP.jl parser or dataset-build consumer for these appendices is yet integrated or documented. | Unknown |
| Inputs and assumptions workbooks | The implemented 2024 parser and `PISP.build_ISP24_datasets` consume the configured 2024 input workbook. | `PISP.download_isp2026_assets` downloads the 2026 inputs-and-assumptions workbook, and the extraction helper prepares downloaded archives where applicable. Integration into PISP.jl and detailed under-review parser coverage are not established. | Unknown |
| EV workbook | The implemented 2024 parser uses the configured 2023 IASR EV workbook when building EV DER schedules. | The 2026 asset downloader obtains the 2025 IASR EV workbook. Integration into PISP.jl and detailed under-review parser coverage are not established. | Unknown |
| Model archive | The implemented 2024 workflow consumes model-side material, including hydro-inflow inputs. | The 2026 asset downloader obtains the model archive, and `PISP.ISPdatabuilder.extract_downloads` provides archive extraction. No PISP.jl parser or build consumer for this family is yet integrated or documented. | Unknown |
| Generation and storage outlook archive | The implemented 2024 workflow uses outlook material to derive development and schedule inputs. | The 2026 asset downloader obtains the outlook archive, and the extraction helper can prepare downloaded archives. No PISP.jl parser or build consumer for this family is yet integrated or documented. | Unknown |
| Solar trace archive | The implemented 2024 workflow downloads and uses release-specific solar traces. | The 2026 asset downloader obtains the solar-trace archive, and the extraction helper can prepare downloaded archives. No PISP.jl trace contract is yet integrated or documented. | Unknown |
| Wind trace archive | The implemented 2024 workflow downloads and uses release-specific wind traces. | The 2026 asset downloader obtains the wind-trace archive, and the extraction helper can prepare downloaded archives. No PISP.jl trace contract is yet integrated or documented. | Unknown |
| `Auxiliary` material | The 2024 build pipeline creates and consumes `Auxiliary` outlook workbooks as package-derived support material. | No PISP.jl 2026 `Auxiliary` layout or build consumer is yet integrated or documented. | Edition-only: ISP 2024 PISP support material |
| Generated PISP datasets | `PISP.build_ISP24_datasets` writes the implemented 2024 PISP dataset outputs. | Under-review parser development does not yet establish an integrated PISP.jl dataset-build workflow or generated-output contract. | Edition-only: ISP 2024 package output |

The [ISP 2024 data sources](../generated/isp2024/reference/data-sources.md) page explains the source families consumed by the implemented 2024 workflow.
The [ISP 2026 overview](isp2026.md) describes source download and extraction, the ParseISP.jl review state, and the current PISP.jl integration boundary.

For report-backed trace-folder meanings, see the 2024 and 2026 PLEXOS Model
Instructions, physical pp. 5 and 7. The local source pages use those reports to
explain trace groups, not to infer that similarly named local folders are
equivalent across editions.

An unknown relationship is not a compatibility claim. Similar source names do
not establish a shared schema, coverage, scenario definition, modelling role,
parser compatibility, or generated-output contract. Those relationships need
release-specific evidence and an explicit crosswalk.
