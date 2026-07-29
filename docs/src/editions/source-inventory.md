# Source-to-dataset processing

The PISP transformation layer progresses from acquired source material through parsed and reconciled data to generated datasets.

PISP keeps source material, parsed structures, and generated datasets as distinct layers.
Keeping those layers separate makes it possible to distinguish an acquired file from a dataset that has been parsed, reconciled, and written by the package.

The workflow proceeds through separate stages:

| Stage | Description |
| --- | --- |
| Source acquisition | Downloads or locates the published reports, workbooks, and archives. |
| Archive extraction | Makes packaged source files available for inspection and parsing. |
| Parser development | Defines how edition-specific source fields and structures are read. |
| Parsed and reconciled PISP data | Aligns source names, identifiers, and fields before dataset construction. |
| PISP.jl integration | Exposes the verified parser and mappings through the package workflow. |
| Dataset build | Writes the static and schedule tables consumed downstream. |
| Output contract | Defines filenames, schemas, identifiers, units, and join relationships. |
| Published validation | Checks selected sources and outputs against explicit evidence. |
| Published EDA | Interprets supported data without expanding the package capability boundary. |

For ISP 2024, the documented PISP.jl workflow integrates these stages through dataset construction and published evidence.
For ISP 2026, PISP.jl provides source download and archive extraction, while parser work remains under review in ParseISP.jl and the parsed-data, dataset-build, and output-contract stages are not yet integrated into the documented public workflow.
[Supported ISP editions](supported-editions.md) is the detailed capability-status authority.

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
