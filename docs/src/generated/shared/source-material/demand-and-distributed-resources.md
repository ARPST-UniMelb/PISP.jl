```@meta
EditURL = "../../../../literate/shared/source_material/demand_and_distributed_resources.jl"
```

# Demand and distributed resources

The ISP inputs workbooks contain regional demand forecasts and supporting material for distributed energy resources, subregional allocation, and emerging loads.
ISP 2026 expands this source family with dedicated data-centre and distribution-network worksheets.

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
const SUBREGIONAL_ALLOCATION_2024 = PISP.source_spec(:ev_subregional_demand_allocation, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, SUBREGIONAL_ALLOCATION_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
````

```@raw html
</details>
```

## Source-family presence

Both workbooks contain demand forecasts, rooftop and non-scheduled PV, and embedded or aggregated storage material.
The later edition adds dedicated data-centre, distribution-network, distribution-cost, and hybrid-site-limit subjects, while the 2024 workbook contains the subregional allocation table used by the current EV transformation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_sheets = [
    "Demand and Energy Forecasts", "Rooftop PV", "PVNSG",
    "Embedded energy storages", "Aggregated energy storages",
    "Sub-regional demand allocation", "Data Centre Forecasts", "Distribution network",
    "Distribution cost forecasts", "Hybrid site limits",
]
demand_sheet_names = [
    ("ISP 2024", XLSX.openxlsx(WORKBOOK2024) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
    ("ISP 2026", XLSX.openxlsx(WORKBOOK2026) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
]
demand_sheet_presence = DataFrame([
    (edition = edition, worksheet = sheet, present = sheet in available)
    for (edition, available) in demand_sheet_names
    for sheet in demand_sheets
])
PISPDocUtils.markdown_table(demand_sheet_presence)
````

```@raw html
</details>
```

| **edition** | **worksheet** | **present** |
|:--|:--|--:|
| ISP 2024 | Demand and Energy Forecasts | true |
| ISP 2024 | Rooftop PV | true |
| ISP 2024 | PVNSG | true |
| ISP 2024 | Embedded energy storages | true |
| ISP 2024 | Aggregated energy storages | true |
| ISP 2024 | Sub-regional demand allocation | true |
| ISP 2024 | Data Centre Forecasts | false |
| ISP 2024 | Distribution network | false |
| ISP 2024 | Distribution cost forecasts | false |
| ISP 2024 | Hybrid site limits | false |
| ISP 2026 | Demand and Energy Forecasts | true |
| ISP 2026 | Rooftop PV | true |
| ISP 2026 | PVNSG | true |
| ISP 2026 | Embedded energy storages | true |
| ISP 2026 | Aggregated energy storages | true |
| ISP 2026 | Sub-regional demand allocation | false |
| ISP 2026 | Data Centre Forecasts | true |
| ISP 2026 | Distribution network | true |
| ISP 2026 | Distribution cost forecasts | true |
| ISP 2026 | Hybrid site limits | true |


## ISP 2024 subregional allocation

The allocation table expresses a regional total as shares assigned to ISP subregions over time.
PISP uses a later block of this worksheet to distribute EV demand to buses; the rows below illustrate the same source structure without reproducing the full transformation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
subregional_allocation_source_2024 = PISP.read_xlsx_rows(
    WORKBOOK2024,
    SUBREGIONAL_ALLOCATION_2024,
)
subregional_allocation_2024 = DataFrame(
    subregional_allocation_source_2024[6:10, 1:9],
    Symbol.([
        "Region or subregion", "2023-24", "2024-25", "2025-26", "2026-27",
        "2027-28", "2028-29", "2029-30", "2030-31",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(subregional_allocation_2024)
````

```@raw html
</details>
```

| **Region or subregion** | **2023-24** | **2024-25** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| NSW | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 |
| Northern NSW (NNSW) | 0.0537313 | 0.0743021 | 0.0921672 | 0.100005 | 0.104659 | 0.107558 | 0.109539 | 0.110578 |
| Central NSW (CNSW) | 0.0380675 | 0.0499269 | 0.0628185 | 0.0677593 | 0.0706487 | 0.0724371 | 0.0737125 | 0.0744052 |
| South NSW (SNSW) | 0.121101 | 0.104881 | 0.0909874 | 0.0822932 | 0.0771875 | 0.0746148 | 0.0759373 | 0.0783838 |
| Sydney, Newcastle and Wooloongong (SNW) | 0.7871 | 0.77089 | 0.754027 | 0.749942 | 0.747505 | 0.74539 | 0.740811 | 0.736633 |


## ISP 2026 data-centre demand

The dedicated data-centre worksheet reports annual energy in TWh by NEM region and scenario.
The sampled rows are from the Slower Growth scenario block.
It separates an emerging load category that was not published as its own worksheet in the 2024 source set.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
data_centres_2026 = DataFrame(
    XLSX.readdata(
        WORKBOOK2026,
        "Data Centre Forecasts",
        "B12:J16",
    ),
    Symbol.(["Region", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(data_centres_2026)
````

```@raw html
</details>
```

| **Region** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** | **2031-32** | **2032-33** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| NSW | 3.2933 | 3.78811 | 4.304 | 4.84718 | 5.40975 | 5.9327 | 6.43974 | 6.84137 |
| QLD | 0.0855609 | 0.0855609 | 0.0857953 | 0.0855609 | 0.0855609 | 0.0855609 | 0.0857953 | 0.0855609 |
| SA | 0.117467 | 0.117491 | 0.117647 | 0.11754 | 0.117565 | 0.117589 | 0.117745 | 0.117638 |
| TAS | 0.017108 | 0.0280599 | 0.0390772 | 0.049978 | 0.06093 | 0.0718819 | 0.0829622 | 0.0938 |
| VIC | 1.0453 | 1.39655 | 1.78505 | 2.1635 | 2.53963 | 2.91104 | 3.24685 | 3.51815 |


## ISP 2026 distribution-network hosting material

The distribution-network table reports provider coverage, solar-PV hosting capacity, battery-storage hosting capacity, and the near-term connection pipeline by ISP subregion.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
distribution_network_2026 = DataFrame(
    XLSX.readdata(
        WORKBOOK2026,
        "Distribution network",
        "B20:G25",
    ),
    Symbol.([
        "ISP subregion", "Distribution network service provider", "Solar PV hosting (MW)",
        "Battery storage hosting (MW)", "Solar PV pipeline to 2029-30 (MW)",
        "Battery pipeline to 2029-30 (MW)",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(distribution_network_2026)
````

```@raw html
</details>
```

| **ISP subregion** | **Distribution network service provider** | **Solar PV hosting (MW)** | **Battery storage hosting (MW)** | **Solar PV pipeline to 2029-30 (MW)** | **Battery pipeline to 2029-30 (MW)** |
|:--|:--|--:|--:|--:|--:|
| NQ | Ergon Energy | 3170 | 39234 | 0 | 0 |
| GG | Ergon Energy | 243 | 2370 | 0 | 0 |
| CQ | Ergon Energy | 2699 | 24677 | 0 | 0 |
| SQ | Energex, Ergon Energy | 6913 | 90136 | 0 | 0 |
| NNSW | Essential Energy | 1378 | 8769 | 0 | 0 |
| CNSW | Essential Energy | 1872 | 13675 | 0 | 0 |


## How the source material differs

The ISP 2024 dataset builder derives demand-by-bus relationships from its generated demand table and separately applies the EV allocation workflow.
ISP 2026 adds data-centre forecasts, distribution-network limits, rooftop-PV
tables, and hybrid-site limits that require new source selections and mappings.
