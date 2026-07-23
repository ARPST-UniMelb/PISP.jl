# Supported ISP editions

PISP distinguishes source acquisition and extraction from parser integration, dataset construction, generated outputs, validation, and analysis.
Separate ISP 2026 parser development is available in [ParseISP.jl](https://github.com/airampg/ParseISP.jl); it is not part of PISP.jl's documented integrated dataset-construction workflow.

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

These labels describe PISP support and published evidence, not the completeness or comparability of the upstream releases.
The ISP 2024 pages document an integrated source-to-output workflow; the ISP 2026 pages document acquisition, extraction, separate parser work, and the remaining integration boundary.

Use the [ISP 2024 overview](isp2024.md) to navigate the implemented data workflow.
Use the [ISP 2026 overview](isp2026.md) to understand the source, parser-review, and integration boundary.
Use the [ISP 2026 source-availability page](../generated/isp2026/validation/source-availability.md) for local source observations.
The [comparison guide](comparison.md) describes the crosswalks required before drawing any cross-release conclusion.
