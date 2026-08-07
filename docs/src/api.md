# API Reference

ParseISP's dataset-construction API applies to ISP 2024.
The main public entry point is `ParseISP.build_ISP24_datasets`; the problem-table helpers explain the scenario/time split used by that build pipeline and are exercised in the tutorial.

Begin with the [Quickstart](quickstart.md) for installation, one small build, and output verification.
Use this page for the complete public signatures and additional examples.

## ISP 2024 dataset construction

```@docs
ParseISP.build_ISP24_datasets
ParseISP.fill_problem_table_year
ParseISP.fill_problem_table_drange
```

### Build examples

Build datasets for complete planning years:

```julia
using ParseISP

ParseISP.build_ISP24_datasets(
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
using ParseISP

ParseISP.build_ISP24_datasets(
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

`ParseISP.download_ISP24_reports` downloads selected ISP 2024 report PDFs.
`ParseISP.download_ISP26_reports` downloads selected ISP 2026 report PDFs, `ParseISP.download_isp2026_assets` downloads selected ISP 2026 source assets, and `ParseISP.ISPdatabuilder.extract_downloads` extracts downloaded source archives.

Download selected ISP report PDFs:

```julia
using ParseISP

ParseISP.download_ISP24_reports(
    outdir = joinpath(@__DIR__, "..", "data", "2024", "pisp-reports"),
    overwrite = false,
)

ParseISP.download_ISP26_reports(
    outdir = joinpath(@__DIR__, "..", "data", "2026", "pisp-reports"),
    overwrite = false,
)
```

Download and extract the selected ISP 2026 source assets:

```julia
using ParseISP

isp2026_downloads_dir = joinpath(
    @__DIR__,
    "..",
    "data",
    "2026",
    "pisp-downloads",
)

source_paths = ParseISP.download_isp2026_assets(
    outdir = isp2026_downloads_dir,
    overwrite = false,
)

ParseISP.ISPdatabuilder.extract_downloads(
    data_root = isp2026_downloads_dir,
)
```

The [ISP 2026 overview](editions/isp2026.md) identifies the separate parser-development repository and the boundary between source acquisition and ParseISP.jl dataset construction.
[Supported ISP editions](editions/supported-editions.md) is the capability authority.
