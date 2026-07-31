```@meta
EditURL = "../../../../literate/shared/source_material/hydro_inflows_and_energy_constraints.jl"
```

# Hydro inflows and energy constraints

Hydro source material spans bounded workbook assumptions and model CSVs.
The workbook gives historical reference-year inflows for named schemes, while the model archive supplies daily natural inflows and annual energy limits used by the current ISP 2024 parser.
The [2023 IASR, pp. 97–98](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=97) identifies the assumptions workbook as the source of monthly, annual, and seasonal inflow information for the represented hydro schemes.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using CSV
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

include(joinpath(REPO_ROOT, "docs", "source_material_support.jl"))
using .PISPDocsSourceMaterialSupport

const ISP2024 = edition_profile(REPO_ROOT, "2024")
const ISP2026 = edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
const MODEL2024 = joinpath(ISP2024.download_root, "2024 ISP Model")
````

```@raw html
</details>
```

## Workbook reference-year tables

The 2024 sample combines public-domain interpretations for Blowering, Eucumbene, and Guthega and reports monthly values plus an annual total without restating a unit in the immediate table block.
The 2026 workbook separates named schemes into their own blocks; the sample below begins with Blowering and labels the values in GL.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hydro_2024 = cells_table(
    WORKBOOK2024,
    "Hydro Scheme Inflows",
    "B35:O40",
    [
        "Reference year", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan",
        "Feb", "Mar", "Apr", "May", "Jun", "Annual total",
    ],
)
markdown_table(hydro_2024)
````

```@raw html
</details>
```

| **Reference year** | **Jul** | **Aug** | **Sep** | **Oct** | **Nov** | **Dec** | **Jan** | **Feb** | **Mar** | **Apr** | **May** | **Jun** | **Annual total** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| 2011 | 865.691 | 527.611 | 566.513 | 663.15 | 347.269 | 485.622 | 380.484 | 375.399 | 113.097 | 371.662 | 498.06 | 861.194 | 6055.75 |
| 2012 | 682.051 | 421.48 | 446.644 | 504.713 | 244.146 | 340.126 | 300.053 | 294.298 | 88.4854 | 290.871 | 391.582 | 677.175 | 4681.62 |
| 2013 | 549.799 | 331.752 | 348.095 | 386.675 | 181.598 | 270.421 | 241.482 | 239.259 | 72.1848 | 237.164 | 316.791 | 547.709 | 3722.93 |
| 2014 | 512.953 | 324.32 | 357.639 | 439.905 | 249.855 | 317.653 | 226.019 | 219.475 | 65.7618 | 216.286 | 293.455 | 507.597 | 3730.92 |
| 2015 | 475.341 | 282.593 | 295.945 | 328.714 | 155.304 | 238.896 | 208.573 | 207.929 | 62.8622 | 206.47 | 274.491 | 474.508 | 3211.63 |
| 2016 | 665.077 | 393.535 | 408.674 | 445.044 | 201.019 | 319.145 | 291.737 | 291.396 | 88.1532 | 289.51 | 384.32 | 664.339 | 4441.95 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hydro_2026 = cells_table(
    WORKBOOK2026,
    "Hydro Scheme Inflows",
    "B11:O16",
    [
        "Reference year", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan",
        "Feb", "Mar", "Apr", "May", "Jun", "Annual total",
    ],
)
markdown_table(hydro_2026)
````

```@raw html
</details>
```

| **Reference year** | **Jul** | **Aug** | **Sep** | **Oct** | **Nov** | **Dec** | **Jan** | **Feb** | **Mar** | **Apr** | **May** | **Jun** | **Annual total** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| 2011 | 4 | 4 | 11 | 97 | 220 | 291 | 76 | 33 | 76 | 20 | 62 | 80 | 974 |
| 2012 | 164 | 115 | 110 | 84 | 144 | 125 | 211 | 115 | 111 | 116 | 42 | 133 | 1470 |
| 2013 | 223 | 240 | 242 | 173 | 182 | 257 | 275 | 221 | 108 | 65 | 43 | 16 | 2045 |
| 2014 | 18 | 24 | 71 | 242 | 235 | 266 | 272 | 209 | 120 | 16 | 42 | 17 | 1532 |
| 2015 | 17 | 102 | 102 | 228 | 262 | 222 | 88 | 57 | 137 | 41 | 27 | 16 | 1299 |
| 2016 | 17 | 18 | 60 | 186 | 122 | 197 | 190 | 111 | 45 | 19 | 17 | 16 | 998 |


## Daily natural inflow CSV

A representative model file contains one daily inflow value keyed by year, month, and day.
Although its filename begins with `MonthlyNaturalInflow`, the records shown here are daily observations.
The parser groups files to hydro generators through package mappings and aggregates the daily records into the required temporal representation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
natural_inflow_path = first_matching_file(MODEL2024, r"^MonthlyNaturalInflow_Anthony_Pieman_.*\.csv$"i)
natural_inflow = CSV.read(natural_inflow_path, DataFrame)
natural_inflow_preview = first(natural_inflow, 5)
markdown_table(natural_inflow_preview)
````

```@raw html
</details>
```

| **Year** | **Month** | **Day** | **Inflows** |
|--:|--:|--:|--:|
| 2024 | 7 | 1 | 143.732 |
| 2024 | 7 | 2 | 143.732 |
| 2024 | 7 | 3 | 143.732 |
| 2024 | 7 | 4 | 143.732 |
| 2024 | 7 | 5 | 143.732 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
natural_inflow_profile = DataFrame([
    (property = "Source file", value = compact_path(natural_inflow_path, MODEL2024)),
    (property = "Rows", value = string(nrow(natural_inflow))),
    (property = "Columns", value = join(names(natural_inflow), ", ")),
])
markdown_table(natural_inflow_profile)
````

```@raw html
</details>
```

| **property** | **value** |
|:--|:--|
| Source file | 2024 ISP Green Energy Exports/Traces/hydro/MonthlyNaturalInflow\_Anthony\_Pieman\_RefYear4006\_HydrogenSuperpower.csv |
| Rows | 10592 |
| Columns | Year, Month, Day, Inflows |


## Annual energy-limit CSV

The annual file uses one year key followed by named hydro constraints.
These limits are distinct from the daily inflow series and are joined to generators through maintained hydro-constraint mappings.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
annual_energy_path = first_matching_file(MODEL2024, r"^MaxEnergyYear_.*\.csv$"i)
annual_energy = CSV.read(annual_energy_path, DataFrame)
annual_energy_preview = first(select(annual_energy, 1:6), 5)
markdown_table(annual_energy_preview)
````

```@raw html
</details>
```

| **Year** | **Barron Gorge Constraint** | **Blowering Constraint** | **Bogong - Mackay Constraint** | **Dartmouth Constraint** | **Eildon Constraint** |
|--:|--:|--:|--:|--:|--:|
| 2020 | 102.621 | 245.805 | 221.461 | 352.479 | 91.6749 |
| 2021 | 88.0508 | 153.535 | 162.121 | 444.835 | 97.9216 |
| 2022 | 54.5418 | 102.351 | 160.896 | 503.15 | 75.8569 |
| 2023 | 63.831 | 250.791 | 255.181 | 43.3978 | 51.1363 |
| 2024 | 76.7658 | 204.577 | 179.607 | 54.7648 | 92.4072 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
annual_energy_profile = DataFrame([
    (property = "Source file", value = compact_path(annual_energy_path, MODEL2024)),
    (property = "Rows", value = string(nrow(annual_energy))),
    (property = "Columns", value = string(ncol(annual_energy))),
])
markdown_table(annual_energy_profile)
````

```@raw html
</details>
```

| **property** | **value** |
|:--|:--|
| Source file | 2024 ISP Green Energy Exports/Traces/hydro/MaxEnergyYear\_LT\_RefYear4006\_HydrogenSuperpower.csv |
| Rows | 39 |
| Columns | 12 |


## Package hydro conventions

PISP maintains file assignments, energy-constraint assignments, scenario mappings, dam shares, and scheme groups for ISP 2024.
These objects encode package decisions and relationships that are not supplied as one ready-made AEMO table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hydro_conventions = DataFrame([
    (object = "PISP.HYDRO2FILE", role = "Generator-to-natural-inflow file assignments", entries = length(PISP.HYDRO2FILE)),
    (object = "PISP.HYDRO2CNS", role = "Generator-to-energy-constraint assignments", entries = length(PISP.HYDRO2CNS)),
    (object = "PISP.HYDROSCE", role = "PISP scenario to model hydro scenario", entries = length(PISP.HYDROSCE)),
    (object = "PISP.SNOWY_HYDRO_GROUPS", role = "Grouped Snowy scheme units", entries = length(PISP.SNOWY_HYDRO_GROUPS)),
])
markdown_table(hydro_conventions)
````

```@raw html
</details>
```

| **object** | **role** | **entries** |
|:--|:--|--:|
| PISP.HYDRO2FILE | Generator-to-natural-inflow file assignments | 30 |
| PISP.HYDRO2CNS | Generator-to-energy-constraint assignments | 15 |
| PISP.HYDROSCE | PISP scenario to model hydro scenario | 3 |
| PISP.SNOWY\_HYDRO\_GROUPS | Grouped Snowy scheme units | 2 |


This page covers bounded hydro inputs required by the parser, not the bulk renewable or demand trace payloads.
ISP 2026 workbook inflows are observed source evidence and are not presented as an integrated PISP 2026 hydro workflow.
