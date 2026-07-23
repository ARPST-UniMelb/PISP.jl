# API Reference

PISP's dataset-construction API applies to ISP 2024.
The main public entry point is `PISP.build_ISP24_datasets`; the problem-table helpers explain the scenario/time split used by that build pipeline and are exercised in the tutorial.

Begin with the [Quickstart](quickstart.md) for installation, one small build, and output verification.
Use this page for the complete public signatures and additional examples.

## ISP 2024 dataset construction

```@docs
PISP.build_ISP24_datasets
PISP.fill_problem_table_year
PISP.fill_problem_table_drange
```

### Build examples

Build datasets for complete planning years:

```julia
using PISP

PISP.build_ISP24_datasets(
    downloadpath = joinpath(@__DIR__, "..", "data", "2024", "pisp-downloads"),
    poe = 10,
    reftrace = 4006,
    years = [2030, 2031],
    output_root = joinpath(@__DIR__, "..", "data", "2024", "pisp-datasets"),
    write_csv = true,
    write_arrow = false,
    scenarios = [1, 2, 3],
)
```

Use `drange` instead of `years` to build specific date windows:

```julia
using PISP

PISP.build_ISP24_datasets(
    downloadpath = joinpath(@__DIR__, "..", "data", "2024", "pisp-downloads"),
    poe = 10,
    reftrace = 4006,
    drange = [
        ("01-01-2030", "31-03-2030"),
        ("01-07-2031", "30-09-2031"),
    ],
    output_root = joinpath(@__DIR__, "..", "data", "2024", "pisp-datasets"),
    write_csv = true,
    write_arrow = false,
    scenarios = [1, 2, 3],
)
```

## Source acquisition

`PISP.download_ISP24_reports` downloads selected ISP 2024 report PDFs.
`PISP.download_ISP26_reports` downloads selected ISP 2026 report PDFs, `PISP.download_isp2026_assets` downloads selected ISP 2026 source assets, and `PISP.ISPdatabuilder.extract_downloads` extracts downloaded source archives.

Download selected ISP report PDFs:

```julia
using PISP

PISP.download_ISP24_reports(
    outdir = joinpath(@__DIR__, "..", "data", "2024", "pisp-reports"),
    overwrite = false,
)

PISP.download_ISP26_reports(
    outdir = joinpath(@__DIR__, "..", "data", "2026", "pisp-reports"),
    overwrite = false,
)
```

Download and extract the selected ISP 2026 source assets:

```julia
using PISP

isp2026_downloads_dir = joinpath(
    @__DIR__,
    "..",
    "data",
    "2026",
    "pisp-downloads",
)

source_paths = PISP.download_isp2026_assets(
    outdir = isp2026_downloads_dir,
    overwrite = false,
)

PISP.ISPdatabuilder.extract_downloads(
    data_root = isp2026_downloads_dir,
)
```

The [ISP 2026 overview](editions/isp2026.md) identifies the separate parser-development repository and the boundary between source acquisition and PISP.jl dataset construction.
[Supported ISP editions](editions/supported-editions.md) is the capability authority.
