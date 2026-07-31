```@meta
EditURL = "../../../../literate/shared/source_material/existing_generation_and_storage.jl"
```

# Existing generation and storage

The inputs workbooks describe existing generation, committed and anticipated projects, storage technology properties, and source identifiers used elsewhere in the ISP material.
ISP 2024 presents the main generation summary at station level, whereas ISP 2026 exposes unit-level IASR identifiers in the corresponding summary.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
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
````

```@raw html
</details>
```

## ISP 2024 station-level summary

Each row below represents a station and combines location, technology, maximum capacity, and seasonal ratings.
PISP uses this source with `Summary Mapping`, maximum-capacity, emissions, reliability, and package mappings to construct unit-level generator records.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
existing_2024 = cells_table(
    WORKBOOK2024,
    "Existing Gen Data Summary",
    "B13:K18",
    [
        "Station", "Generator type", "Region", "ISP sub-region", "REZ", "Fuel/technology",
        "Maximum capacity (MW)", "Summer peak (MW)", "Summer typical (MW)", "Winter (MW)",
    ],
)
markdown_table(existing_2024)
````

```@raw html
</details>
```

| **Station** | **Generator type** | **Region** | **ISP sub-region** | **REZ** | **Fuel/technology** | **Maximum capacity (MW)** | **Summer peak (MW)** | **Summer typical (MW)** | **Winter (MW)** |
|:--|:--|:--|:--|:--|:--|--:|--:|--:|--:|
| Bayswater | Steam Sub Critical | NSW | CNSW | N/A | Black Coal NSW | 2715 | 2595 | 2715 | 2715 |
| Eraring | Steam Sub Critical | NSW | SNW | N/A | Black Coal NSW | 2880 | 0 | 0 | 0 |
| Mt Piper | Steam Sub Critical | NSW | CNSW | N/A | Black Coal NSW | 1390 | 1380 | 1390 | 1430 |
| Vales Point B | Steam Sub Critical | NSW | SNW | N/A | Black Coal NSW | 1320 | 1320 | 1320 | 1320 |
| Callide B | Steam Sub Critical | QLD | CQ | N/A | Black Coal QLD | 700 | 0 | 0 | 0 |
| Callide C | Steam Super Critical | QLD | CQ | N/A | Black Coal QLD | 844 | 854 | 886 | 886 |


## ISP 2026 unit-level summary

The later workbook places IASR IDs and project status directly beside station and technology fields.
Bayswater therefore appears as four records rather than one station aggregate.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
existing_2026 = cells_table(
    WORKBOOK2026,
    "Existing Gen Data Summary",
    "B13:Q18",
    [
        "IASR ID", "Station", "Technology", "Fuel", "Region", "ISP sub-region", "REZ", "Cost zone",
        "Status", "Storage capacity", "Maximum capacity (MW)", "Minimum load", "Summer peak (MW)",
        "Summer typical (MW)", "Winter (MW)", "Minimum stable level (MW)",
    ];
    columns = collect(1:16),
)
markdown_table(existing_2026)
````

```@raw html
</details>
```

| **IASR ID** | **Station** | **Technology** | **Fuel** | **Region** | **ISP sub-region** | **REZ** | **Cost zone** | **Status** | **Storage capacity** | **Maximum capacity (MW)** | **Minimum load** | **Summer peak (MW)** | **Summer typical (MW)** | **Winter (MW)** | **Minimum stable level (MW)** |
|:--|:--|:--|:--|:--|:--|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|
| BW01 | Bayswater | Steam Sub Critical | Black Coal | NSW | CNSW | Not Applicable | Not Applicable | Existing | Not Applicable | 660 | 0 | 630 | 660 | 660 | 170 |
| BW02 | Bayswater | Steam Sub Critical | Black Coal | NSW | CNSW | Not Applicable | Not Applicable | Existing | Not Applicable | 685 | 0 | 655 | 685 | 685 | 170 |
| BW03 | Bayswater | Steam Sub Critical | Black Coal | NSW | CNSW | Not Applicable | Not Applicable | Existing | Not Applicable | 685 | 0 | 655 | 685 | 685 | 170 |
| BW04 | Bayswater | Steam Sub Critical | Black Coal | NSW | CNSW | Not Applicable | Not Applicable | Existing | Not Applicable | 685 | 0 | 655 | 685 | 685 | 170 |
| CALL\_B\_1 | Callide B | Steam Sub Critical | Black Coal | QLD | CQ | Not Applicable | Not Applicable | Existing | Not Applicable | 350 | 0 | 325 | 0 | 0 | 140 |
| CALL\_B\_2 | Callide B | Steam Sub Critical | Black Coal | QLD | CQ | Not Applicable | Not Applicable | Existing | Not Applicable | 350 | 0 | 325 | 0 | 0 | 140 |


## Storage technology properties

ISP 2024 organises battery durations as columns and properties as rows.
ISP 2026 uses one row per technology, adds compressed air and separate coordinated-CER categories, and reports energy capacity as hours for a 1 MW reference power.
A blank ISP 2024 source cell is shown as `Not reported` rather than as a Julia missing-value marker.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
storage_2024 = cells_table(
    WORKBOOK2024,
    "Storage properties",
    "B5:H13",
    ["Property", "Battery 1 h", "Battery 2 h", "Battery 4 h", "Battery 8 h", "VPP", "Units"],
)
for column in names(storage_2024)
    storage_2024[!, column] = coalesce.(storage_2024[!, column], "Not reported")
end
markdown_table(storage_2024)
````

```@raw html
</details>
```

| **Property** | **Battery 1 h** | **Battery 2 h** | **Battery 4 h** | **Battery 8 h** | **VPP** | **Units** |
|:--|:--|:--|:--|:--|:--|:--|
| Maximum power1 | 1 | 1 | 1 | 1 | 1 | MW |
| Energy capacity2 | 1 | 2 | 4 | 8 | 2.2 | MWh |
| Round trip efficiency (aggregated)3 | not applicable | not applicable | not applicable | not applicable | 85 | % |
| Charge efficiency (utility) | 91.6515 | 91.6515 | 92.1954 | 91.1043 | not applicable | % |
| Discharge efficiency (utility) | 91.6515 | 91.6515 | 92.1954 | 91.1043 | not applicable | % |
| Round trip efficiency (utility) | 84 | 84 | 85 | 83 | not applicable | % |
| Annual degradation (utility) | 1.8 | 1.8 | 1.8 | 1.8 | Not reported | % |
| Allowable max state of charge | 100 | 100 | 100 | 100 | 85 | % |
| Allowable min state of charge | 0 | 0 | 0 | 0 | 0 | % |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
storage_2026 = cells_table(
    WORKBOOK2026,
    "Storage properties",
    "B6:I13",
    [
        "Technology", "Maximum power (MW)", "Energy capacity (h)", "Charge efficiency (%)",
        "Discharge efficiency (%)", "Maximum state of charge (%)", "Minimum state of charge (%)",
        "Round-trip efficiency (%)",
    ],
)
markdown_table(storage_2026)
````

```@raw html
</details>
```

| **Technology** | **Maximum power (MW)** | **Energy capacity (h)** | **Charge efficiency (%)** | **Discharge efficiency (%)** | **Maximum state of charge (%)** | **Minimum state of charge (%)** | **Round-trip efficiency (%)** |
|:--|--:|--:|--:|--:|--:|--:|--:|
| Battery storage (1hr storage) | 1.0 | 1.0 | 92.0 | 92.0 | 99.15 | 0.0 | 84.0 |
| Battery storage (2hrs storage) | 1.0 | 2.0 | 92.0 | 92.0 | 99.05 | 0.0 | 84.0 |
| Battery storage (4hrs storage) | 1.0 | 4.0 | 92.5 | 92.5 | 98.8 | 0.0 | 85.0 |
| Battery storage (8hrs storage) | 1.0 | 8.0 | 93.0 | 93.0 | 98.25 | 0.0 | 85.0 |
| Compressed air | 1.0 | 8.0 | 81.0 | 81.0 | 100.0 | 0.0 | 0.0 |
| Distributed Resources Batteries | 1.0 | 2.0 | 92.0 | 92.0 | 99.05 | 0.0 | 84.0 |
| VPP (aggregated ESS) - Coordinated CER | 1.0 | 2.2 | 92.2 | 92.2 | 85.0 | 0.0 | 85.0 |
| VPP (aggregated ESS) - V2G | 1.0 | 2.2 | 92.2 | 92.2 | 85.0 | 0.0 | 85.0 |


## PISP conventions applied after source reading

The current package includes maintained generator, battery, and pumped-hydro dictionaries.
These objects are package conventions and supplements; they are not additional AEMO source rows.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
package_collections = DataFrame([
    (collection = "Generator unit mappings", object = "PISP.units", entries = length(PISP.units)),
    (collection = "Battery defaults", object = "PISP.databess", entries = length(PISP.databess)),
    (collection = "Pumped-hydro defaults", object = "PISP.dataps", entries = length(PISP.dataps)),
])
markdown_table(package_collections)
````

```@raw html
</details>
```

| **collection** | **object** | **entries** |
|:--|:--|--:|
| Generator unit mappings | PISP.units | 68 |
| Battery defaults | PISP.databess | 55 |
| Pumped-hydro defaults | PISP.dataps | 7 |


PISP currently implements the ISP 2024 transformation path.
The ISP 2026 tables above are observed source evidence and do not imply an integrated 2026 PISP dataset builder.
