```@meta
EditURL = "../../../../literate/shared/source_material/scenarios_and_sensitivities.jl"
```

# Scenarios and sensitivities

AEMO's scenario workbooks describe alternative planning futures, while the generation and storage outlook workbooks provide one core result set per scenario and additional sensitivity cases.
Scenario names changed between ISP 2024 and ISP 2026, so names alone do not establish semantic equivalence.
AEMO describes Step Change as a refinement of the 2023 scenario with the same name ([2025 IASR, p. 18](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=18)), Slower Growth as the successor to Progressive Change ([p. 19](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=19)), and Accelerated Transition as a refinement of Green Energy Exports ([p. 20](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=20)); this lineage does not imply unchanged assumptions or model inputs.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
all(isfile, (WORKBOOK2024, WORKBOOK2026)) || error("both selected ISP inputs workbooks are required")
````

```@raw html
</details>
```

## ISP 2024 scenario framing

ISP 2024 uses Green Energy Exports, Step Change, and Progressive Change.
The source distinguishes these futures through demand drivers, energy efficiency, consumer participation, and other assumptions rather than through a single scalar ranking.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
scenario_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Scenarios",
    "B6:E12",
    ["Parameter", "Green Energy Exports", "Step Change", "Progressive Change"],
)
filter!(row -> any(value -> !ismissing(value), Tuple(row)[2:end]), scenario_2024)
PISPDocUtils.markdown_table(scenario_2024)
````

```@raw html
</details>
```

| **Parameter** | **Green Energy Exports** | **Step Change** | **Progressive Change** |
|:--|:--|:--|:--|
| National Decarbonisation target | At least 43% emissions reduction by 2030. Net zero by 2050. | At least 43% emissions reduction by 2030. Net zero by 2050. | 43% emissions reduction by 2030.  Net zero by 2050. |
| Global economic growth and policy coordination | High economic growth, stronger coordination | Moderate economic growth, stronger coordination | Slower economic growth, lesser coordination |
| Australian economic and demographic drivers | Higher (partly driven by green energy) | Moderate | Lower |
| Energy Efficiency | Higher | Moderate | Lower |
| Consumer engagement e.g. VPP and DSP uptake | Higher | High (VPP) and Moderate (DSP) | Lower |


## ISP 2026 scenario framing

ISP 2026 uses Slower Growth, Step Change, and Accelerated Transition.
Step Change is the only retained scenario name; even there, the surrounding assumptions and publication year differ, so direct reuse still requires semantic review.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
scenario_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Scenarios",
    "B6:E12",
    ["Parameter", "Slower Growth", "Step Change", "Accelerated Transition"],
)
filter!(row -> any(value -> !ismissing(value), Tuple(row)[2:end]), scenario_2026)
PISPDocUtils.markdown_table(scenario_2026)
````

```@raw html
</details>
```

| **Parameter** | **Slower Growth** | **Step Change** | **Accelerated Transition** |
|:--|:--|:--|:--|
| National Decarbonisation target | 43% emissions reduction by 2030.  Net zero by 2050. | At least 43% emissions reduction by 2030. Net zero by 2050. | At least 43% emissions reduction by 2030. Net zero by 2050. |
| Global economic growth and policy coordination | Slower economic growth, lesser coordination | Moderate economic growth, stronger coordination | High economic growth, stronger coordination |
| Australian economic and demographic drivers | Lower, with near-term economic growth calibrated with current economic conditions | Moderate economic growth, with near-term economic growth calibrated with current economic conditions | Higher, with near-term economic growth calibrated with current economic conditions |
| Energy Efficiency | Moderate | High | Higher |
| Coordination of CER (VPP and V2G) | Low long-term coordination, with gradual acceptance of coordination | Moderate long-term coordination, with gradual acceptance of coordination | High long-term coordination, with faster acceptance of coordination |


## Outlook workbook families

The directory names orient readers to the publication structure: ISP 2024 uses `Core`, ISP 2026 uses `Core scenarios`, and both editions provide `Sensitivities`.
Each workbook is a result package with many worksheets rather than a single flat table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
outlook_inventory = vcat(
    PISPDocUtils.directory_workbook_inventory(joinpath(ISP2024.download_root, "Core"), "2024"),
    PISPDocUtils.directory_workbook_inventory(joinpath(ISP2024.download_root, "Sensitivities"), "2024"),
    PISPDocUtils.directory_workbook_inventory(joinpath(ISP2026.download_root, "Core scenarios"), "2026"),
    PISPDocUtils.directory_workbook_inventory(joinpath(ISP2026.download_root, "Sensitivities"), "2026"),
)
outlook_counts = combine(groupby(outlook_inventory, [:edition, :group]), nrow => :workbooks)
sort!(outlook_counts, [:edition, :group])
PISPDocUtils.markdown_table(outlook_counts)
````

```@raw html
</details>
```

| **edition** | **group** | **workbooks** |
|:--|:--|--:|
| 2024 | Core | 3 |
| 2024 | Sensitivity | 9 |
| 2026 | Core | 3 |
| 2026 | Sensitivity | 6 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
outlook_cases = select(outlook_inventory, :edition, :group, :scenario_or_sensitivity)
PISPDocUtils.markdown_table(outlook_cases)
````

```@raw html
</details>
```

| **edition** | **group** | **scenario\_or\_sensitivity** |
|:--|:--|:--|
| 2024 | Core | Green Energy Exports |
| 2024 | Core | Progressive Change |
| 2024 | Core | Step Change |
| 2024 | Sensitivity | Green Energy Exports - Extended Eraring |
| 2024 | Sensitivity | Progressive Change - Extended Eraring |
| 2024 | Sensitivity | Step Change - Additional Load |
| 2024 | Sensitivity | Step Change - Alternative Worst Sequence |
| 2024 | Sensitivity | Step Change - Constrained Supply Chains |
| 2024 | Sensitivity | Step Change - Extended Eraring |
| 2024 | Sensitivity | Step Change - Low Hydrogen Flexibility |
| 2024 | Sensitivity | Step Change - Lower EV Uptake |
| 2024 | Sensitivity | Step Change - Reduced CER Coordination |
| 2026 | Core | Accelerated Transition |
| 2026 | Core | Slower Growth |
| 2026 | Core | Step Change |
| 2026 | Sensitivity | Step Change - Constrained Delivery |
| 2026 | Sensitivity | Step Change - Higher Demand |
| 2026 | Sensitivity | Step Change - Higher Energy Efficiency |
| 2026 | Sensitivity | Step Change - Lower Energy Efficiency |
| 2026 | Sensitivity | Step Change - No Further CER Coordination |
| 2026 | Sensitivity | Step Change - No Further VPP Uptake |


The 2024 set contains three core workbooks and nine sensitivities.
The 2026 set contains three core workbooks and six sensitivities.
Additions, removals, and renamed cases should be interpreted from their published assumptions, not inferred mechanically from similar filenames.

