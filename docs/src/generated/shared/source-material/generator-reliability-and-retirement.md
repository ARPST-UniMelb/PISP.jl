```@meta
EditURL = "../../../../literate/shared/source_material/generator_reliability_and_retirement.jl"
```

# Generator reliability and retirement

Reliability assumptions describe the frequency, duration, and partial effect of outages.
Retirement tables identify expected closure years, while PISP applies additional package-defined scenario schedules when generating ISP 2024 datasets.
AEMO documents the earlier unplanned-outage assumptions in the [2023 IASR, pp. 90–93](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=90) and the revised long-duration and other unplanned-outage treatment in the [2025 IASR, pp. 122–125](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=122).

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const RELIABILITY_2024 = PISP.source_spec(:existing_generator_reliability, 2024)
const RETIREMENTS_2024 = PISP.source_spec(:generator_retirements, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, RELIABILITY_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
````

```@raw html
</details>
```

## ISP 2024 reliability structure

The 2024 table places full and partial outage rates, mean time to repair, and partial-outage derating in one technology-level block.
PISP reads the existing and new-entrant blocks separately and maps them into generator and storage fields.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
reliability_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, RELIABILITY_2024)
reliability_2024 = DataFrame(
    reliability_source_2024[2:9, 1:6],
    Symbol.([
        "Fuel or technology", "Full outage fraction", "Partial outage fraction",
        "Full-outage MTTR (h)", "Partial-outage MTTR (h)", "Partial derating factor",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(reliability_2024)
````

```@raw html
</details>
```

| **Fuel or technology** | **Full outage fraction** | **Partial outage fraction** | **Full-outage MTTR (h)** | **Partial-outage MTTR (h)** | **Partial derating factor** |
|:--|--:|:--|--:|:--|:--|
| Brown Coal | 0.0775 | 0.1156 | 90.05 | 12.2 | 0.1791 |
| Black Coal NSW | 0.0631 | 0.3146 | 157.62 | 33.97 | 0.166 |
| Black Coal QLD | 0.0675 | 0.1286 | 185.0 | 56.42 | 0.2516 |
| OCGT | 0.0721 | 0.0112 | 44.08 | 106.48 | 0.0999 |
| Small peaking plants | 0.0958 | 0.0032 | 150.2 | 189.52 | 0.337 |
| Hydro | 0.0511 | 0.0171 | 38.1 | 473.44 | 0.1518 |
| CCGT + Steam Turbine | 0.0504 | 0.0166 | 61.19 | 40.35 | 0.1521 |
| Batteries | 0.0184 | - | 26.05 | - | - |


## ISP 2026 reliability structure

ISP 2026 separates long-duration outages from other unplanned outages and reports annual values across the planning horizon.
That change is more than a renamed sheet: the source is now a property-by-year table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
long_duration_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Generator Reliability Settings", "B11:E16"),
    Symbol.(["Fuel or technology", "Property", "2025-26", "2026-27"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(long_duration_2026)
````

```@raw html
</details>
```

| **Fuel or technology** | **Property** | **2025-26** | **2026-27** |
|:--|:--|--:|--:|
| All Coal Average | Long duration outage factor (%) | 0.00913 | 0.00913 |
| All Gas and Liquid Average | Long duration outage factor (%) | 0.00532 | 0.00532 |
| Hydro | Long duration outage factor (%) | 0.00212 | 0.00212 |
| All Coal Average | Long duration MTTR (Hrs) | 6062.1 | 6062.1 |
| All Gas and Liquid Average | Long duration MTTR (Hrs) | 6223.4 | 6223.4 |
| Hydro | Long duration MTTR (Hrs) | 4291.6 | 4291.6 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
other_outages_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Generator Reliability Settings", "B23:E29"),
    Symbol.(["Fuel or technology", "Property", "2025-26", "2026-27"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(other_outages_2026)
````

```@raw html
</details>
```

| **Fuel or technology** | **Property** | **2025-26** | **2026-27** |
|:--|:--|--:|--:|
| Brown Coal | Full outage (% of time) | 0.079231 | 0.0910324 |
| Black Coal NSW | Full outage (% of time) | 0.053274 | 0.0489497 |
| Black Coal QLD | Full outage (% of time) | 0.0927088 | 0.0718383 |
| All Gas and Liquid Average | Full outage (% of time) | 0.0844688 | 0.08655 |
| Hydro | Full outage (% of time) | 0.0596427 | 0.0596427 |
| Biomass | Full outage (% of time) | 0.04 | 0.04 |
| Batteries | Full outage (% of time) | 0.0284 | 0.0284 |


## Expected closure years

Both editions use unit identifiers, but ISP 2026 adds technology and status fields and revises some expected closure years.
For example, the sampled Callide B records move from 2028 in the 2024 source to 2031 in the 2026 source.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
retirement_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, RETIREMENTS_2024)
retirement_2024 = DataFrame(
    retirement_source_2024[2:10, 1:3],
    Symbol.(["Station", "DUID", "Expected closure year"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(retirement_2024)
````

```@raw html
</details>
```

| **Station** | **DUID** | **Expected closure year** |
|:--|:--|--:|
| Bayswater | BW01 | 2033 |
| Bayswater | BW02 | 2033 |
| Bayswater | BW03 | 2033 |
| Bayswater | BW04 | 2033 |
| Callide B | CALL\_B\_1 | 2028 |
| Callide B | CALL\_B\_2 | 2028 |
| Callide C | CPP\_3 | 2051 |
| Callide C | CPP\_4 | 2051 |
| Eraring\* | ER01 | 2025 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
retirement_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Retirement", "B13:F20"),
    Symbol.(["IASR ID", "Station", "Technology", "Status", "Expected closure year"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(retirement_2026)
````

```@raw html
</details>
```

| **IASR ID** | **Station** | **Technology** | **Status** | **Expected closure year** |
|:--|:--|:--|:--|--:|
| BW01 | Bayswater | Steam Sub Critical | Existing | 2033 |
| BW02 | Bayswater | Steam Sub Critical | Existing | 2033 |
| BW03 | Bayswater | Steam Sub Critical | Existing | 2033 |
| BW04 | Bayswater | Steam Sub Critical | Existing | 2033 |
| CALL\_B\_1 | Callide B | Steam Sub Critical | Existing | 2031 |
| CALL\_B\_2 | Callide B | Steam Sub Critical | Existing | 2031 |
| CPP\_3 | Callide C | Steam Super Critical | Existing | 2051 |
| CPP\_4 | Callide C | Steam Super Critical | Existing | 2051 |


## Package-defined ISP 2024 schedules

`Retirements2024` and `Reduction2024` are package conventions rather than AEMO workbook rows.
They provide scenario-specific schedules used by the current dataset builder and are documented as transformations, not raw source facts.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
retirement_conventions = DataFrame([
    (
        scenario_id = scenario_id,
        scenario = PISP.ID2SCE[scenario_id],
        retirement_stations = length(PISP.Retirements2024[scenario_id]),
        capacity_reduction_stations = length(PISP.Reduction2024[scenario_id]),
    )
    for scenario_id in sort(collect(keys(PISP.ID2SCE)))
])
PISPDocUtils.markdown_table(retirement_conventions)
````

```@raw html
</details>
```

| **scenario\_id** | **scenario** | **retirement\_stations** | **capacity\_reduction\_stations** |
|--:|:--|--:|--:|
| 1 | Progressive Change | 50 | 1 |
| 2 | Step Change | 50 | 1 |
| 3 | Green Energy Exports | 50 | 1 |
