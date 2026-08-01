```@meta
EditURL = "../../../../literate/comparison/analysis/raw_source_comparison.jl"
```

# ISP 2024 and ISP 2026 raw-source comparison

The raw-source comparison tracks how AEMO's non-trace inputs changed before any PISP transformation.
It is distinct from the model-archive comparison, which inventories archive packaging, and from PISP output-schema comparisons, which describe generated datasets.

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
const EV2023 = joinpath(ISP2024.download_root, "2023-iasr-ev-workbook.xlsx")
const EV2025 = joinpath(ISP2026.download_root, "aemo-2025-iasr-ev-workbook.xlsx")
````

```@raw html
</details>
```

## Publication scale

The later inputs workbook is larger and contains more worksheets.
The EV publication also gains one worksheet, while the outlook package keeps three core workbooks but reduces the supplied sensitivity count.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
publication_inventory = PISPDocUtils.workbook_inventory([
    "ISP 2024 inputs and assumptions" => WORKBOOK2024,
    "ISP 2026 inputs and assumptions" => WORKBOOK2026,
    "2023 IASR EV" => EV2023,
    "2025 IASR EV" => EV2025,
])
PISPDocUtils.markdown_table(publication_inventory)
````

```@raw html
</details>
```

| **edition** | **workbook** | **worksheet\_count** | **size\_mib** |
|:--|:--|--:|--:|
| ISP 2024 inputs and assumptions | 2024-isp-inputs-and-assumptions-workbook.xlsx | 76 | 10.8 |
| ISP 2026 inputs and assumptions | 2026-isp-inputs-and-assumptions-workbook.xlsm | 84 | 23.0 |
| 2023 IASR EV | 2023-iasr-ev-workbook.xlsx | 10 | 0.5 |
| 2025 IASR EV | aemo-2025-iasr-ev-workbook.xlsx | 11 | 0.6 |


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


## Worksheet presence

Some source subjects retain a recognisable worksheet, some move or change name, and some appear only in one edition.
Presence alone is structural evidence; it does not prove that fields, units, or row meaning remain compatible.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
worksheet_comparison = PISPDocUtils.worksheet_presence(
    ["ISP 2024" => WORKBOOK2024, "ISP 2026" => WORKBOOK2026],
    [
        "Existing Gen Data Summary", "Generator Reliability Settings", "Retirement",
        "Network Capability", "Network capability", "Flow Path Augmentation options",
        "Flow path augmentation options", "Renewable Energy Zones", "Renewable energy zones",
        "Generation limits", "Coal Min Stable Level", "Min Up&Down Times", "DSP",
        "Hydro Scheme Inflows", "Data Centre Forecasts", "Distribution network", "Hybrid site limits",
    ],
)
PISPDocUtils.markdown_table(worksheet_comparison)
````

```@raw html
</details>
```

| **edition** | **worksheet** | **present** |
|:--|:--|--:|
| ISP 2024 | Existing Gen Data Summary | true |
| ISP 2024 | Generator Reliability Settings | true |
| ISP 2024 | Retirement | true |
| ISP 2024 | Network Capability | true |
| ISP 2024 | Network capability | false |
| ISP 2024 | Flow Path Augmentation options | true |
| ISP 2024 | Flow path augmentation options | false |
| ISP 2024 | Renewable Energy Zones | true |
| ISP 2024 | Renewable energy zones | false |
| ISP 2024 | Generation limits | true |
| ISP 2024 | Coal Min Stable Level | false |
| ISP 2024 | Min Up&Down Times | true |
| ISP 2024 | DSP | true |
| ISP 2024 | Hydro Scheme Inflows | true |
| ISP 2024 | Data Centre Forecasts | false |
| ISP 2024 | Distribution network | false |
| ISP 2024 | Hybrid site limits | false |
| ISP 2026 | Existing Gen Data Summary | true |
| ISP 2026 | Generator Reliability Settings | true |
| ISP 2026 | Retirement | true |
| ISP 2026 | Network Capability | false |
| ISP 2026 | Network capability | true |
| ISP 2026 | Flow Path Augmentation options | false |
| ISP 2026 | Flow path augmentation options | true |
| ISP 2026 | Renewable Energy Zones | false |
| ISP 2026 | Renewable energy zones | true |
| ISP 2026 | Generation limits | false |
| ISP 2026 | Coal Min Stable Level | true |
| ISP 2026 | Min Up&Down Times | false |
| ISP 2026 | DSP | true |
| ISP 2026 | Hydro Scheme Inflows | true |
| ISP 2026 | Data Centre Forecasts | true |
| ISP 2026 | Distribution network | true |
| ISP 2026 | Hybrid site limits | true |


## Declared worksheet dimensions

Workbook dimensions provide a bounded indication of source scale.
They include stored cells and formatting, so they are useful for comparison but not a substitute for counting parsed records.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
dimension_2024 = PISPDocUtils.sheet_dimension_table(
    WORKBOOK2024,
    [
        "Scenarios", "Existing Gen Data Summary", "New Entrant Data Summary",
        "Generator Reliability Settings", "Retirement", "Network Capability",
        "Flow Path Augmentation options", "Renewable Energy Zones", "Maximum capacity",
        "Storage properties", "DSP", "Hydro Scheme Inflows",
    ],
)
dimension_2024.edition = fill("2024", nrow(dimension_2024))

dimension_2026 = PISPDocUtils.sheet_dimension_table(
    WORKBOOK2026,
    [
        "Scenarios", "Existing Gen Data Summary", "New Entrant Data Summary",
        "Generator Reliability Settings", "Retirement", "Network capability",
        "Flow path augmentation options", "Renewable energy zones", "Maximum capacity",
        "Storage properties", "DSP", "Hydro Scheme Inflows",
    ],
)
dimension_2026.edition = fill("2026", nrow(dimension_2026))

source_dimensions = select(
    vcat(dimension_2024, dimension_2026),
    :edition,
    :worksheet,
    :workbook_declared_dimension,
)
PISPDocUtils.markdown_table(source_dimensions)
````

```@raw html
</details>
```

| **edition** | **worksheet** | **workbook\_declared\_dimension** |
|:--|:--|:--|
| 2024 | Scenarios | A1:F206 |
| 2024 | Existing Gen Data Summary | A1:AD408 |
| 2024 | New Entrant Data Summary | A1:AE302 |
| 2024 | Generator Reliability Settings | A1:Q67 |
| 2024 | Retirement | A1:M461 |
| 2024 | Network Capability | A1:K145 |
| 2024 | Flow Path Augmentation options | A1:P115 |
| 2024 | Renewable Energy Zones | A1:X60 |
| 2024 | Maximum capacity | A1:BD269 |
| 2024 | Storage properties | A1:O118 |
| 2024 | DSP | A1:AH299 |
| 2024 | Hydro Scheme Inflows | A1:T101 |
| 2026 | Scenarios | A1:H202 |
| 2026 | Existing Gen Data Summary | A1:AV738 |
| 2026 | New Entrant Data Summary | A1:BC545 |
| 2026 | Generator Reliability Settings | A1:P92 |
| 2026 | Retirement | A1:J744 |
| 2026 | Network capability | A1:Y152 |
| 2026 | Flow path augmentation options | A1:U133 |
| 2026 | Renewable energy zones | A1:Y100 |
| 2026 | Maximum capacity | A1:AD984 |
| 2026 | Storage properties | A1:W128 |
| 2026 | DSP | A1:AJ242 |
| 2026 | Hydro Scheme Inflows | A1:W164 |


## Semantic source-family changes

The comparison below separates observed additions, removals, relocations, and schema changes.
Any proposed parser correspondence remains a manual semantic-review item until units, keys, and downstream meaning have been checked.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
source_family_changes = DataFrame([
    (
        family = "Scenarios and sensitivities",
        isp_2024 = "Green Energy Exports, Step Change, Progressive Change; 9 sensitivities",
        isp_2026 = "Accelerated Transition, Step Change, Slower Growth; 6 sensitivities",
        observed_change = "Scenario set and sensitivity set changed",
        review_status = "Manual semantic review",
    ),
    (
        family = "Existing generation",
        isp_2024 = "Station-level leading summary",
        isp_2026 = "Unit-level IASR IDs and status fields",
        observed_change = "Keys and record granularity changed",
        review_status = "Manual semantic review",
    ),
    (
        family = "Generator operation",
        isp_2024 = "Generation limits and Min Up&Down Times worksheets",
        isp_2026 = "Coal Min Stable Level; no directly named Min Up&Down Times sheet",
        observed_change = "Source split and removal/relocation",
        review_status = "Manual semantic review",
    ),
    (
        family = "Generator reliability",
        isp_2024 = "Technology rows with full and partial outage fields",
        isp_2026 = "Property-by-year rows with long-duration separation",
        observed_change = "Schema and time dimension changed",
        review_status = "Manual semantic review",
    ),
    (
        family = "Network and transmission",
        isp_2024 = "Seasonal limits, reliability columns, and 2023-dollar augmentation costs",
        isp_2026 = "Revised limits, reliability event rows, and 2025-dollar augmentation costs",
        observed_change = "Fields, values, and cost basis changed",
        review_status = "Manual semantic review",
    ),
    (
        family = "Renewable energy zones",
        isp_2024 = "REZ, NTNDP, subregion, and cost-zone fields",
        isp_2026 = "Narrower leading REZ table; some retained IDs have new names",
        observed_change = "Fields removed or relocated; names changed",
        review_status = "Manual semantic review",
    ),
    (
        family = "Demand and distributed resources",
        isp_2024 = "Demand, DER, and subregional allocation material",
        isp_2026 = "Adds data-centre, distribution-network, and hybrid-site worksheets",
        observed_change = "New source families added",
        review_status = "Observed source only",
    ),
    (
        family = "Demand-side participation",
        isp_2024 = "Scenario-region-season matrix blocks",
        isp_2026 = "Normalised region-price-scenario-season rows",
        observed_change = "Table shape and keys changed",
        review_status = "Manual semantic review",
    ),
    (
        family = "Electric vehicles",
        isp_2024 = "2023 IASR numbers, consumption, charging shares, and profiles",
        isp_2026 = "2025 IASR revises charging categories and adds hybrids",
        observed_change = "Scenario years, vocabulary, and vehicle family changed",
        review_status = "Observed source only",
    ),
    (
        family = "Hydro",
        isp_2024 = "Workbook reference years plus model inflow and energy-limit CSVs",
        isp_2026 = "Reorganised workbook scheme blocks",
        observed_change = "Workbook organisation changed; model integration not established",
        review_status = "Manual semantic review",
    ),
])
PISPDocUtils.markdown_table(source_family_changes; alignment = [:l, :l, :l, :l, :l])
````

```@raw html
</details>
```

| **family** | **isp\_2024** | **isp\_2026** | **observed\_change** | **review\_status** |
|:--|:--|:--|:--|:--|
| Scenarios and sensitivities | Green Energy Exports, Step Change, Progressive Change; 9 sensitivities | Accelerated Transition, Step Change, Slower Growth; 6 sensitivities | Scenario set and sensitivity set changed | Manual semantic review |
| Existing generation | Station-level leading summary | Unit-level IASR IDs and status fields | Keys and record granularity changed | Manual semantic review |
| Generator operation | Generation limits and Min Up&Down Times worksheets | Coal Min Stable Level; no directly named Min Up&Down Times sheet | Source split and removal/relocation | Manual semantic review |
| Generator reliability | Technology rows with full and partial outage fields | Property-by-year rows with long-duration separation | Schema and time dimension changed | Manual semantic review |
| Network and transmission | Seasonal limits, reliability columns, and 2023-dollar augmentation costs | Revised limits, reliability event rows, and 2025-dollar augmentation costs | Fields, values, and cost basis changed | Manual semantic review |
| Renewable energy zones | REZ, NTNDP, subregion, and cost-zone fields | Narrower leading REZ table; some retained IDs have new names | Fields removed or relocated; names changed | Manual semantic review |
| Demand and distributed resources | Demand, DER, and subregional allocation material | Adds data-centre, distribution-network, and hybrid-site worksheets | New source families added | Observed source only |
| Demand-side participation | Scenario-region-season matrix blocks | Normalised region-price-scenario-season rows | Table shape and keys changed | Manual semantic review |
| Electric vehicles | 2023 IASR numbers, consumption, charging shares, and profiles | 2025 IASR revises charging categories and adds hybrids | Scenario years, vocabulary, and vehicle family changed | Observed source only |
| Hydro | Workbook reference years plus model inflow and energy-limit CSVs | Reorganised workbook scheme blocks | Workbook organisation changed; model integration not established | Manual semantic review |


Detailed evidence is organised by subject under [AEMO ISP source material](../../shared/source-material/coverage-and-ownership.md).
The [model archive comparison](model-archive-comparison.md) remains the authority for archive packaging, and the existing PISP dataset pages remain the authority for generated output schemas.
No table on this page claims that ISP 2026 has an integrated PISP preprocessing or dataset workflow.

