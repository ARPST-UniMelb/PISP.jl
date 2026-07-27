# Comparing ISP 2024 and ISP 2026

PISP.jl moves ISP data through three stages, and each release of AEMO's Integrated System Plan (ISP) is at a different stage:

- **`pisp-reports`** — the official AEMO PDF reports for a release (methodology, model instructions, assumptions).
- **`pisp-downloads`** — the raw source data behind those reports (PLEXOS models, input workbooks, trace archives), downloaded and extracted onto disk.
- **`pisp-datasets`** — the structured, ready-to-use dataset PISP.jl builds from the raw downloads.

The table below is what actually exists today.

| Stage | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| `pisp-reports` | `PISP.download_ISP24_reports` | `PISP.download_ISP26_reports` |
| `pisp-downloads` | Downloaded automatically inside `PISP.build_ISP24_datasets` (`download_from_AEMO = true`) | `PISP.download_isp2026_assets`, then `PISP.ISPdatabuilder.extract_downloads` |
| `pisp-datasets` | `PISP.build_ISP24_datasets` | Not yet. The 2026 parser is developed separately in [ParseISP.jl](https://github.com/airampg/ParseISP.jl) and is not integrated into PISP.jl. |

In short: you can fetch reports and source data for both releases today, but PISP.jl only builds a dataset from ISP 2024. Downloaded ISP 2026 material is source material, not a validated dataset, until ParseISP.jl's parser is integrated.

## Before you compare numbers across releases

ISP 2024 and ISP 2026 are not laid out the same way. Before treating a value from one release as comparable to the other, check:

- **Scenarios** — names and definitions differ between releases; a matching label doesn't guarantee a matching definition.
- **Weather years and traces** — ISP 2024 uses 14 historical weather years across six trace folders (demand, hydro, load subtractor, solar, timeslice, wind); ISP 2026 uses 16 years and adds three more folders (DNSP, gas, rooftop PV).
- **Money and time** — check the price year and whether values are real or nominal before subtracting or ratio-ing them, along with the financial-year convention.
- **Matching records across releases** — a mapping between 2024 and 2026 identifiers can be one-to-many or many-to-one; don't reduce it with an inner join, since that silently drops anything that doesn't match on both sides.
- **File and folder layout** — similarly named files or folders across releases are not guaranteed to hold the same fields.

The [ISP 2024 overview](isp2024.md), [ISP 2026 overview](isp2026.md), and [supported editions](supported-editions.md) pages have the full detail behind this table.
The [source availability by edition](../generated/comparison/validation/source-availability-by-edition.md) page shows what's actually present in the locally configured 2024 and 2026 download folders.
