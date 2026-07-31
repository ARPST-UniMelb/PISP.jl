```@meta
EditURL = "../../../../literate/shared/source_material/demand_side_participation.jl"
```

# Demand-side participation

Demand-side participation assumptions quantify response at price bands and at reliability-response conditions.
The two editions publish the same broad subject through different table organisations.

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

## ISP 2024 repeated blocks

ISP 2024 arranges each scenario, NEM region, and season as a separate matrix block.
The sampled block shows the New South Wales summer assumptions for the opening scenario section.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
dsp_2024 = cells_table(
    WORKBOOK2024,
    "DSP",
    "B11:J15",
    [
        "Price band or response", "2023-24", "2024-25", "2025-26", "2026-27",
        "2027-28", "2028-29", "2029-30", "2030-31",
    ],
)
markdown_table(dsp_2024)
````

```@raw html
</details>
```

| **Price band or response** | **2023-24** | **2024-25** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| \$300 - \$500 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| \$500 - \$1,000 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| \$1,000 - \$7,500 | 93.74 | 105.33 | 117.55 | 130.37 | 142.99 | 193.32 | 240.22 | 278.9 |
| \$7,500 + | 94.74 | 106.46 | 118.8 | 131.76 | 144.51 | 195.38 | 242.78 | 281.88 |
| Reliability Response | 336.75 | 378.39 | 422.28 | 468.34 | 513.66 | 694.47 | 862.96 | 1001.92 |


## ISP 2026 normalised rows

ISP 2026 places region, price band, scenario, and season on every row.
This removes the need to infer those dimensions from a matrix block's location, but it also changes the schema consumed by a parser.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
dsp_2026 = cells_table(
    WORKBOOK2026,
    "DSP",
    "B10:L18",
    [
        "Region", "Price band or response", "Scenario", "Season", "2025-26", "2026-27",
        "2027-28", "2028-29", "2029-30", "2030-31", "2031-32",
    ],
)
markdown_table(dsp_2026)
````

```@raw html
</details>
```

| **Region** | **Price band or response** | **Scenario** | **Season** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** | **2031-32** |
|:--|:--|:--|:--|--:|--:|--:|--:|--:|--:|--:|
| NSW | \$300-\$500 | Slower Growth | Summer | 1 | 1 | 1 | 0.93 | 0.94 | 0.96 | 0.99 |
| NSW | \$500-\$7500 | Slower Growth | Summer | 20.97 | 21 | 21.03 | 19.52 | 19.78 | 20.23 | 20.8 |
| NSW | \$7500+ | Slower Growth | Summer | 107.74 | 107.9 | 108.06 | 100.31 | 101.64 | 103.94 | 106.87 |
| NSW | Reliability Response | Slower Growth | Summer | 349.74 | 350.26 | 350.78 | 325.61 | 329.93 | 337.41 | 346.91 |
| NSW | Reliability Response in % of Peak Demand\* | Slower Growth | Summer | 2.52 | 2.52 | 2.52 | 2.52 | 2.52 | 2.52 | 2.52 |
| QLD | \$300-\$500 | Slower Growth | Summer | 29.75 | 29.89 | 29.93 | 30.01 | 27.93 | 28.39 | 28.92 |
| QLD | \$500-\$7500 | Slower Growth | Summer | 70.26 | 70.59 | 70.7 | 70.88 | 65.97 | 67.04 | 68.3 |
| QLD | \$7500+ | Slower Growth | Summer | 143.58 | 144.26 | 144.47 | 144.84 | 134.81 | 136.99 | 139.58 |
| QLD | Reliability Response | Slower Growth | Summer | 186.58 | 187.46 | 187.74 | 188.23 | 175.18 | 178.02 | 181.38 |


## Active ISP 2024 source coverage

The current parser names every combination of three scenarios, five NEM regions, and two seasons.
The coverage ledger expands those selections into 30 active ranges so that no workbook block remains implicit.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
coverage = coverage_document(REPO_ROOT)
source_reads = coverage_table(coverage, "source_read")
dsp_ranges = filter(:owner => ==("shared-source-demand-side-participation"), source_reads)

dsp_coverage = DataFrame([
    (dimension = "Scenario", values = length(PISP.ID2SCE), interpretation = join(values(PISP.ID2SCE), ", ")),
    (dimension = "NEM region", values = 5, interpretation = "NSW, QLD, SA, TAS, and VIC"),
    (dimension = "Season", values = 2, interpretation = "Summer and Winter"),
    (dimension = "Explicit source ranges", values = nrow(dsp_ranges), interpretation = "3 × 5 × 2 active blocks"),
])
markdown_table(dsp_coverage)
````

```@raw html
</details>
```

| **dimension** | **values** | **interpretation** |
|:--|--:|:--|
| Scenario | 3 | Progressive Change, Step Change, Green Energy Exports |
| NEM region | 5 | NSW, QLD, SA, TAS, and VIC |
| Season | 2 | Summer and Winter |
| Explicit source ranges | 30 | 3 × 5 × 2 active blocks |


## Package mappings

PISP maps workbook price-band labels to package values and maps the maintained scenario IDs to the 2024 scenario names.
These lookups are package conventions that sit between the raw matrices and the generated demand-response records.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
scenario_mapping = DataFrame(
    scenario_id = collect(keys(PISP.ID2SCE)),
    scenario_name = collect(values(PISP.ID2SCE)),
)
markdown_table(scenario_mapping)
````

```@raw html
</details>
```

| **scenario\_id** | **scenario\_name** |
|--:|:--|
| 1 | Progressive Change |
| 2 | Step Change |
| 3 | Green Energy Exports |


A future ISP 2026 implementation needs a reviewed mapping for the new row schema and scenario set.
The visible similarity of price-band labels does not establish complete semantic equivalence.

