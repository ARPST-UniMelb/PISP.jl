```@meta
EditURL = "../../../../literate/shared/source_material/generator_operation.jl"
```

# Generator operating assumptions

AEMO provides minimum stable levels, minimum up/down times, and ramp limits for time-sequential modelling.
These fields constrain how quickly thermal units can move and how low they can operate when committed.
The [2023 IASR, pp. 88–89](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=88) describes the earlier operating assumptions, while the [2025 IASR, pp. 121–122](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=121) explains the later coal minimum-stable-level bands.

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
const WORKBOOK2019 = joinpath(ISP2024.download_root, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
````

```@raw html
</details>
```

## Worksheet organisation changed

ISP 2024 has a general `Generation limits` sheet and a separate minimum-up/down sheet.
ISP 2026 replaces the coal section with `Coal Min Stable Level` and does not contain a worksheet named `Min Up&Down Times`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
sheet_names_2024 = Set(PISPDocUtils.sheet_names(WORKBOOK2024))
sheet_names_2026 = Set(PISPDocUtils.sheet_names(WORKBOOK2026))
operating_sheet_presence = DataFrame([
    (edition = "2024", worksheet = name, present = name in sheet_names_2024)
    for name in ("Generation limits", "Coal Min Stable Level", "GPG Min Stable Level", "Min Up&Down Times", "Max Ramp Rates")
])
append!(
    operating_sheet_presence,
    DataFrame([
        (edition = "2026", worksheet = name, present = name in sheet_names_2026)
        for name in ("Generation limits", "Coal Min Stable Level", "GPG Min Stable Level", "Min Up&Down Times", "Max Ramp Rates")
    ]),
)
PISPDocUtils.markdown_table(operating_sheet_presence)
````

```@raw html
</details>
```

| **edition** | **worksheet** | **present** |
|:--|:--|--:|
| 2024 | Generation limits | true |
| 2024 | Coal Min Stable Level | false |
| 2024 | GPG Min Stable Level | true |
| 2024 | Min Up&Down Times | true |
| 2024 | Max Ramp Rates | true |
| 2026 | Generation limits | false |
| 2026 | Coal Min Stable Level | true |
| 2026 | GPG Min Stable Level | true |
| 2026 | Min Up&Down Times | false |
| 2026 | Max Ramp Rates | true |


## Minimum stable levels

The 2024 coal table uses station and unit identifiers with a single minimum-stable-level value.
The 2026 coal table retains a backcast value and adds a typical lowest band, exposing a distinction that is absent from the earlier source table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
coal_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Generation limits",
    "B9:D14",
    ["Station", "Generating unit", "Minimum stable level (MW)"],
)
PISPDocUtils.markdown_table(coal_2024)
````

```@raw html
</details>
```

| **Station** | **Generating unit** | **Minimum stable level (MW)** |
|:--|:--|--:|
| Bayswater | BW01 | 250 |
| Bayswater | BW02 | 250 |
| Bayswater | BW03 | 250 |
| Bayswater | BW04 | 250 |
| Eraring | ER01 | 210 |
| Eraring | ER02 | 210 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
coal_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Coal Min Stable Level",
    "B14:F20",
    ["IASR ID", "Station", "Technology", "IASR 2023 backcast (MW)", "Typical lowest band (MW)"],
)
PISPDocUtils.markdown_table(coal_2026)
````

```@raw html
</details>
```

| **IASR ID** | **Station** | **Technology** | **IASR 2023 backcast (MW)** | **Typical lowest band (MW)** |
|:--|:--|:--|--:|--:|
| BW01 | Bayswater | Steam Sub Critical | 250 | 260 |
| BW02 | Bayswater | Steam Sub Critical | 250 | 200 |
| BW03 | Bayswater | Steam Sub Critical | 250 | 200 |
| BW04 | Bayswater | Steam Sub Critical | 250 | 200 |
| ER01 | Eraring | Steam Sub Critical | 210 | 182 |
| ER02 | Eraring | Steam Sub Critical | 210 | 182 |
| ER03 | Eraring | Steam Sub Critical | 210 | 182 |


Gas-powered generation remains a unit-level table in both editions, but ISP 2026 uses IASR IDs and revised technology labels.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
gpg_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "GPG Min Stable Level",
    "B10:E15",
    ["Station", "Generating unit", "Technology", "Minimum stable level (MW)"],
)
PISPDocUtils.markdown_table(gpg_2024)
````

```@raw html
</details>
```

| **Station** | **Generating unit** | **Technology** | **Minimum stable level (MW)** |
|:--|:--|:--|--:|
| Condamine | CPSA\_GT1 | CCGT - Gas Turbine | 20.0 |
| Condamine | CPSA\_GT2 | CCGT - Gas Turbine | 20.0 |
| Condamine | CPSA\_ST | CCGT - Steam Turbine | 13.1 |
| Darling Downs | DDPS1\_GT1 | CCGT - Gas Turbine | 58.3 |
| Darling Downs | DDPS1\_GT2 | CCGT - Gas Turbine | 58.3 |
| Darling Downs | DDPS1\_GT3 | CCGT - Gas Turbine | 58.3 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
gpg_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "GPG Min Stable Level",
    "B12:E18",
    ["IASR ID", "Station", "Technology", "Minimum stable level (MW)"],
)
PISPDocUtils.markdown_table(gpg_2026)
````

```@raw html
</details>
```

| **IASR ID** | **Station** | **Technology** | **Minimum stable level (MW)** |
|:--|:--|:--|--:|
| ANGAS1 | Angaston | Reciprocating engine | 3.0 |
| ANGAS2 | Angaston | Reciprocating engine | 3.0 |
| BDL01 | Bairnsdale | OCGT (small GT) | 20.0 |
| BDL02 | Bairnsdale | OCGT (small GT) | 20.0 |
| BARCALDN | Barcaldine Power Station | OCGT (small GT) | 20.0 |
| BIPS1\_01 | Barker Inlet Power Station | Reciprocating engine | 8.0 |
| BIPS1\_02 | Barker Inlet Power Station | Reciprocating engine | 8.0 |


## Minimum up/down times

The current PISP parser uses the 2024 sheet and supplements it with unit values from the 2019 workbook.
Because ISP 2026 does not contain a directly corresponding worksheet, an updated implementation would require manual source and semantic review rather than a sheet-name substitution.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
minimum_up_down_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Min Up&Down Times",
    "B9:E15",
    ["Station", "Generating unit", "Technology", "Minimum up/down time (h)"],
)
PISPDocUtils.markdown_table(minimum_up_down_2024)
````

```@raw html
</details>
```

| **Station** | **Generating unit** | **Technology** | **Minimum up/down time (h)** |
|:--|:--|:--|--:|
| Condamine | CPSA\_GT1 | CCGT - Gas Turbine | 4.0 |
| Condamine | CPSA\_GT2 | CCGT - Gas Turbine | 4.0 |
| Darling Downs | DDPS1\_GT1 | CCGT - Gas Turbine | 4.0 |
| Darling Downs | DDPS1\_GT2 | CCGT - Gas Turbine | 4.0 |
| Darling Downs | DDPS1\_GT3 | CCGT - Gas Turbine | 4.0 |
| Newport | NPS | Gas-powered steam turbine | 4.0 |
| Osborne | OsborneGT | CCGT - Gas Turbine | 4.0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
minimum_up_2019 = PISPDocUtils.cells_table(
    WORKBOOK2019,
    "Generation limits",
    "O10:Q16",
    ["Station", "Generating unit", "Minimum up time (h)"],
)
PISPDocUtils.markdown_table(minimum_up_2019)
````

```@raw html
</details>
```

| **Station** | **Generating unit** | **Minimum up time (h)** |
|:--|:--|--:|
| Bayswater | BW01 | 8 |
| Bayswater | BW02 | 8 |
| Bayswater | BW03 | 8 |
| Bayswater | BW04 | 8 |
| Eraring | ER01 | 8 |
| Eraring | ER02 | 8 |
| Eraring | ER03 | 8 |


## Ramp rates

ISP 2026 retains separate maximum ramp-up and ramp-down values and explicitly marks some reciprocating-engine records as sufficiently high rather than assigning a numeric limit.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ramp_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Max Ramp Rates",
    "B9:F15",
    ["Station", "Generating unit", "Technology", "Ramp up (MW/min)", "Ramp down (MW/min)"],
)
PISPDocUtils.markdown_table(ramp_2024)
````

```@raw html
</details>
```

| **Station** | **Generating unit** | **Technology** | **Ramp up (MW/min)** | **Ramp down (MW/min)** |
|:--|:--|:--|--:|--:|
| Bayswater | BW01 | Black Coal | 4.0 | 4.0 |
| Bayswater | BW02 | Black Coal | 4.0 | 4.0 |
| Bayswater | BW03 | Black Coal | 4.0 | 4.0 |
| Bayswater | BW04 | Black Coal | 4.0 | 4.0 |
| Callide B | CALL\_B\_1 | Black Coal | 4.0 | 4.0 |
| Callide B | CALL\_B\_2 | Black Coal | 4.0 | 4.0 |
| Callide C | CPP\_3 | Black Coal | 4.0 | 4.0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ramp_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Max Ramp Rates",
    "B9:F15",
    ["IASR ID", "Station", "Technology", "Ramp up (MW/min)", "Ramp down (MW/min)"],
)
PISPDocUtils.markdown_table(ramp_2026)
````

```@raw html
</details>
```

| **IASR ID** | **Station** | **Technology** | **Ramp up (MW/min)** | **Ramp down (MW/min)** |
|:--|:--|:--|:--|:--|
| ANGAS1 | Angaston | Reciprocating engine | Assumed sufficiently high | Assumed sufficiently high |
| ANGAS2 | Angaston | Reciprocating engine | Assumed sufficiently high | Assumed sufficiently high |
| BDL01 | Bairnsdale | OCGT (small GT) | 9.0 | 5.0 |
| BDL02 | Bairnsdale | OCGT (small GT) | 9.0 | 7.2 |
| BARCALDN | Barcaldine Power Station | OCGT (small GT) | 3.3 | 3.3 |
| BIPS1\_01 | Barker Inlet Power Station | Reciprocating engine | 5.0 | 4.25 |
| BIPS1\_02 | Barker Inlet Power Station | Reciprocating engine | 5.0 | 4.25 |


