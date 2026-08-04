# Source-to-dataset processing

PISP keeps reports, workbooks, model archives, parsed tables, and generated
datasets as separate layers.
This separation makes each parser decision traceable to a named source
selection and makes cross-edition differences visible before the data is
combined.

| Stage | Description |
| --- | --- |
| Source acquisition | Obtain the reports, workbooks, model archives, outlooks, and trace archives for the selected edition. |
| Archive extraction | Expand packaged workbooks, scenario models, and trace folders. |
| Source map | Record the file, worksheet or folder selection, keys, fields, units, and edition-specific differences. |
| Parsing and reconciliation | Read the source structures and align identifiers, categories, and fields. |
| Dataset build | Write the static and schedule tables used downstream. |
| Output contract | Define filenames, schemas, identifiers, units, and join relationships. |
| Validation and analysis | Check the source and output structures and interpret the resulting data. |

The ISP 2024 track follows these stages through
[`PISP.build_ISP24_datasets`](../generated/isp2024/tutorials/building-problem-table.md)
and the documented static and schedule outputs.
The edition-specific [ISP 2024 source-data reference](../generated/isp2024/reference/source-data.md)
and [ISP 2026 source-data reference](../generated/isp2026/reference/source-data.md)
use the same structure for files, selections, keys, fields, and units.
Their paired workbook-and-trace pages describe the corresponding workbook,
model-archive, and trace structures.

For ISP 2024, the documented PISP.jl workflow integrates these stages through dataset construction and published evidence.
For ISP 2026, PISP.jl provides source download and archive extraction, while parser work remains under review in ParseISP.jl and the parsing, dataset-build, and output-contract stages are not yet integrated into the documented public workflow.
[Supported ISP editions](supported-editions.md) is the detailed capability-status authority.

## Source and comparison pages

The [source-material guide](source-material.md) groups the non-trace workbooks
by subject across both editions.
The [ISP report catalogue](../generated/comparison/references/report-catalogue.md)
provides the complete report collections and explicit counterparts.
The [trace coverage](trace-coverage.md) page compares trace folders,
reference-year labels, schemas, and POE material.

The [model archive comparison](../generated/comparison/analyses/model-archive-comparison.md)
compares scenario directories, XML packaging, trace families, file counts,
sizes, and representative filenames.
The [raw-source comparison](../generated/comparison/analyses/raw-source-comparison.md)
compares workbook and outlook additions, removals, moves, dimensions, and
schema changes.

For the ISP 2024 workflow, consult [source data](../generated/isp2024/reference/source-data.md)
and [output tables](../generated/isp2024/reference/output-tables.md).
For ISP 2026, consult the [ISP 2026 overview](isp2026.md).
