# Supported ISP editions

ParseISP documentation covers the source material for ISP 2024 and ISP 2026.
The ISP 2024 track also follows the package workflow through generated static
and schedule tables.

ParseISP distinguishes source acquisition and extraction from parser integration, dataset construction, generated outputs, validation, and analysis.
Separate ISP 2026 parser development is available in [ParseISP.jl](https://github.com/airampg/ParseISP.jl). It is not part of ParseISP.jl's documented integrated dataset-construction workflow.

| Capability or published evidence | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Report and source download | Supported as part of the 2024 build workflow, with selected report-download support. | `ParseISP.download_ISP26_reports` and `ParseISP.download_isp2026_assets` download selected reports and source assets. |
| Archive extraction | Integrated into the ISP 2024 source workflow. | Available through `ParseISP.ISPdatabuilder.extract_downloads` for downloaded source assets. |
| Parser development | The ISP 2024 parser is integrated into ParseISP.jl. | Under review in [ParseISP.jl](https://github.com/airampg/ParseISP.jl). Detailed coverage, readiness, and API stability remain unverified. |
| ParseISP.jl parser integration | Implemented in the documented ISP 2024 workflow. | Not yet integrated into the documented public ParseISP.jl workflow. |
| Build a ParseISP dataset | Implemented by `ParseISP.build_ISP24_datasets`. | Not yet integrated into the documented public ParseISP.jl workflow. |
| Generated-output contract | Static and schedule tables are documented for the 2024 build. | Not yet established for the documented ParseISP.jl workflow. |
| Published validation evidence | Release-specific validation pages cover supported 2024 sources and outputs. | The workbook-and-trace structure page documents configured reports, workbooks, model archives, and traces. Processed-data validation depends on the parser work in the previous two rows. |
| Published analysis or EDA evidence | Release-specific analysis pages interpret supported 2024 sources and outputs. | No processed-data analysis or trace-schema result is published. |

These labels describe ParseISP support and published evidence, not the completeness or comparability of the upstream releases.
The ISP 2024 pages document an integrated source-to-output workflow. The ISP 2026 pages document acquisition, extraction, separate parser work, and the remaining integration boundary.

| Documentation area | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Reports | The report catalogue lists the configured 2024 reports and their AEMO links. | The report catalogue lists the configured 2026 reports and their AEMO links. |
| Workbooks and outlooks | Edition pages describe the inputs workbook, EV workbook, generation and storage outlooks, mappings, and build inputs. | The source-data reference and shared subject pages describe workbook selections, keys, fields, units, and changes from 2024. |
| Model and traces | The 2024 trace page documents filenames, selectors, schemas, dates, and units used by the package. | The 2026 source pages document scenario folders, trace families, project-level solar and wind archives, and the `RefYear5000` filename convention. |

Use the [ISP 2024 overview](isp2024.md) for the source-to-dataset workflow.
Use the [ISP 2026 overview](isp2026.md) to understand the source, parser-review, and integration boundary.
The [comparison guide](comparison.md) describes the crosswalks required before drawing any cross-release conclusion.
