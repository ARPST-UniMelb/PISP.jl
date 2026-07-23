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
and the [edition comparison page](../generated/comparison/validation/source-availability-by-edition.md)
report selected observations from configured roots. They deliberately avoid
recursive file totals: dot-file filtering is a local hygiene choice, not an
upstream completeness measure, and a file's presence does not establish parser
integration or a generated-data contract.

The compact evidence tables report configured report targets, archive groups,
extracted landmarks, trace groups, and demand-trace observations. A local
observation means only that the item was present in the supplied checkout at
render time.
For the implemented 2024 workflow, consult [data sources](../generated/isp2024/reference/data-sources.md) and [output tables](../generated/isp2024/reference/output-tables.md).
For 2026 source material, consult the [ISP 2026 overview](isp2026.md).
