# Source inventory

PISP keeps source material, parsed structures, and generated datasets as distinct layers.
Keeping those layers separate makes it possible to distinguish an acquired file from a dataset that has been parsed, reconciled, and written by the package.

| Workflow layer | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Source acquisition | The documented 2024 build has a configured download root and source workflow. | PISP.jl has download targets for selected source assets and report PDFs. |
| Archive extraction | Integrated into the documented 2024 source workflow. | Available through `PISP.ISPdatabuilder.extract_downloads`. |
| Parser development | The ISP 2024 parser is integrated into PISP.jl. | Under review; detailed coverage and readiness are unverified here. See [Supported ISP editions](supported-editions.md). |
| Parsed and reconciled PISP data | Produced within the PISP 2024 workflow. | No PISP.jl parsed-data contract is yet integrated or documented. |
| Generated dataset | Static and schedule outputs can be written by the 2024 build. | An ISP 2026 dataset-build entry point and generated-output contract are not yet integrated into PISP.jl's documented public workflow. |
| Published validation or analysis evidence | Registry-managed pages cover selected 2024 source and output questions. | No PISP 2026 validation or analysis pages are published. |

## Observed local availability

The [ISP 2026 source-availability page](../generated/isp2026/validation/source-availability.md)
reports selected report, archive, and extracted-path observations from the
configured ISP 2026 roots.

The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md)
reads the ISP 2024 and ISP 2026 model ZIPs directly. It compares scenario
directories, XML packaging, trace families, file counts, sizes, and
representative filenames as the first concrete input to a 2024-to-2026 parser
crosswalk.

For the implemented 2024 workflow, consult [data sources](../generated/isp2024/reference/data-sources.md) and [output tables](../generated/isp2024/reference/output-tables.md).
For 2026 source material, consult the [ISP 2026 overview](isp2026.md).
