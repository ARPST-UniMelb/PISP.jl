# API Reference

PISP's dataset-construction API applies to ISP 2024.
The main public entry point is `PISP.build_ISP24_datasets`; the problem-table helpers explain the scenario/time split used by that build pipeline and are exercised in the tutorial.

## ISP 2024 dataset construction

```@docs
PISP.build_ISP24_datasets
PISP.fill_problem_table_year
PISP.fill_problem_table_drange
```

## Source acquisition

`PISP.download_ISP24_reports` downloads selected ISP 2024 report PDFs.
`PISP.download_ISP26_reports` downloads selected ISP 2026 report PDFs, and `PISP.download_isp2026_assets` downloads selected ISP 2026 source assets.

The ISP 2026 helpers acquire source material only.
They do not provide an ISP 2026 parser, dataset builder, generated-output contract, validation result, or analysis result.
See [Supported ISP editions](editions/supported-editions.md) for the complete support boundary.
