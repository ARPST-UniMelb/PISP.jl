# Supported ISP editions

PISP distinguishes between an implemented ISP 2024 data-construction workflow and ISP 2026 source acquisition.
The distinction matters when choosing inputs, interpreting outputs, or planning a cross-release study.

| Capability or published evidence | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Acquire source material | Supported as part of the 2024 build workflow, with selected report-download support. | Selected source assets and report PDFs can be downloaded. |
| Parse and reconcile source material | Implemented by PISP. | Not provided by PISP. |
| Build a PISP dataset | Implemented by `PISP.build_ISP24_datasets`. | Not provided by PISP. |
| Generated-output contract | Static and schedule tables are documented for the 2024 build. | No PISP-generated output contract is available. |
| Published validation evidence | Release-specific validation pages cover supported 2024 sources and outputs. | No PISP 2026 validation pages are published. |
| Published analysis or EDA evidence | Release-specific analysis pages interpret supported 2024 sources and outputs. | No PISP 2026 analysis or EDA pages are published. |

These labels describe PISP support and its published evidence, not the completeness or comparability of the upstream ISP releases.
The ISP 2024 pages describe the source inputs, package-defined mappings, output tables, validation checks, and analyses associated with that implemented workflow.
The ISP 2026 pages describe the boundary of the available download support without treating downloaded material as parsed or generated PISP data.

Use the [ISP 2024 overview](isp2024.md) to navigate the implemented data workflow.
Use the [ISP 2026 overview](isp2026.md) to understand the source-acquisition boundary.
The [comparison guide](comparison.md) describes the crosswalks required before drawing any cross-release conclusion.
