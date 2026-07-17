# Source inventory

PISP keeps source material, parsed structures, and generated datasets as distinct layers.
Keeping those layers separate makes it possible to distinguish an acquired file from a dataset that has been parsed, reconciled, and written by the package.

| Workflow layer | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Source acquisition | The documented 2024 build has a configured download root and source workflow. | The package has download targets for selected source assets and report PDFs. |
| Parsed and reconciled data | Produced within the PISP 2024 workflow. | Not produced by PISP. |
| Generated dataset | Static and schedule outputs can be written by the 2024 build. | Not produced by PISP. |
| Published validation or analysis evidence | Registry-managed pages cover selected 2024 source and output questions. | No PISP 2026 validation or analysis pages are available. |

## Observed local inventory

The following counts were observed in the local default-profile roots.
They describe non-hidden files present for this documentation build, not a claim about complete upstream coverage, source currency, extraction state, or the files available in another checkout.

| Edition | Download root observation | Report root observation |
| --- | --- | --- |
| ISP 2024 | 8,250 non-hidden files; 68,352,904 KiB (65.19 GiB). | 10 PDFs; 50,848 KiB (49.66 MiB). |
| ISP 2026 | 817 non-hidden files; 2,380,248 KiB (2.27 GiB). | 10 PDFs; 57,192 KiB (55.85 MiB). |

### ISP 2024 download-root observation

| Top-level location | Non-hidden files |
| --- | ---: |
| `2024 ISP Model` | 90 |
| `Auxiliary` | 7 |
| `Core` | 3 |
| `Sensitivities` | 9 |
| `Traces` | 8,074 |
| `zip` | 64 |
| Root workbooks | 3 |

| File extension | Files |
| --- | ---: |
| CSV | 8,158 |
| XLSX | 22 |
| XML | 6 |
| ZIP | 64 |

### ISP 2026 download-root observation

| Top-level location | Non-hidden files |
| --- | ---: |
| `2026 ISP Model` | 348 |
| `Core scenarios` | 3 |
| `Sensitivities` | 6 |
| `Traces` | 454 |
| `zip` | 4 |
| Root workbooks | 2 |

| File extension | Files |
| --- | ---: |
| CSV | 799 |
| XLSM | 1 |
| XLSX | 10 |
| XML | 3 |
| ZIP | 4 |

The presence of a file in a source download does not establish parser coverage, output schema, or analytical comparability.
For the implemented 2024 workflow, consult [data sources](../generated/isp2024/reference/data-sources.md) and [output tables](../generated/isp2024/reference/output-tables.md).
For 2026 source material, consult the [ISP 2026 overview](isp2026.md).
