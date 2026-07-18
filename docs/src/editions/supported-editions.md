# Supported ISP editions

PISP distinguishes among source acquisition, archive extraction, parser development, package integration, dataset construction, and published evidence.
For ISP 2026, source download and archive extraction are available in PISP.jl, while parser development is under review in [ParseISP.jl](https://github.com/airampg/ParseISP.jl) and is not yet integrated into the documented PISP.jl dataset-construction workflow.
The distinction matters when choosing inputs, interpreting outputs, or planning a cross-release study.

| Capability or published evidence | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Report and source download | Supported as part of the 2024 build workflow, with selected report-download support. | `PISP.download_ISP26_reports` and `PISP.download_isp2026_assets` download selected reports and source assets. |
| Archive extraction | Integrated into the ISP 2024 source workflow. | Available through `PISP.ISPdatabuilder.extract_downloads` for downloaded source assets. |
| Parser development | The ISP 2024 parser is integrated into PISP.jl. | Under review in [ParseISP.jl](https://github.com/airampg/ParseISP.jl). Detailed coverage, readiness, and API stability are not established by these docs. |
| PISP.jl parser integration | Implemented in the documented ISP 2024 workflow. | Not yet integrated into the documented public PISP.jl workflow. |
| Build a PISP dataset | Implemented by `PISP.build_ISP24_datasets`. | Not yet integrated into the documented public PISP.jl workflow. |
| Generated-output contract | Static and schedule tables are documented for the 2024 build. | Not yet established for the documented PISP.jl workflow. |
| Published validation evidence | Release-specific validation pages cover supported 2024 sources and outputs. | A source-only availability page documents configured reports, archives, landmarks, and limitations; no processed-data validation is claimed. |
| Published analysis or EDA evidence | Release-specific analysis pages interpret supported 2024 sources and outputs. | No processed-data analysis or trace-schema result is published. |

These labels describe PISP support and its published evidence, not the completeness or comparability of the upstream ISP releases.
The ISP 2024 pages describe the source inputs, package-defined mappings, output tables, validation checks, and analyses associated with that implemented workflow.
The ISP 2026 pages describe source download and extraction, the under-review parser status, and the boundary between that work and PISP.jl dataset construction.
Under-review parser development is not evidence of an integrated dataset builder, generated-output contract, validation result, or analysis result.

Use the [ISP 2024 overview](isp2024.md) to navigate the implemented data workflow.
Use the [ISP 2026 overview](isp2026.md) to understand the source, parser-review, and integration boundary.
Use the [ISP 2026 source-availability page](../generated/isp2026/validation/source-availability.md) for local source observations.
The [comparison guide](comparison.md) describes the crosswalks required before drawing any cross-release conclusion.
