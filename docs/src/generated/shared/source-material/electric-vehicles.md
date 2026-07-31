```@meta
EditURL = "../../../../literate/shared/source_material/electric_vehicles.jl"
```

# Electric vehicles

The IASR electric-vehicle workbooks provide vehicle numbers, energy consumption, charging-mode shares, and weekday and weekend charging profiles.
PISP combines the 2023 IASR workbook with ISP 2024 subregional demand allocation when it constructs the current EV demand representation.
The [2023 IASR, p. 59](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=59) explains the earlier charging-profile categories, while the [2025 IASR, p. 94](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=94) defines the revised static and dynamic charging categories.

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
const EV2023 = joinpath(ISP2024.download_root, "2023-iasr-ev-workbook.xlsx")
const EV2025 = joinpath(ISP2026.download_root, "aemo-2025-iasr-ev-workbook.xlsx")
````

```@raw html
</details>
```

## Workbook subjects

Both workbooks retain BEV/PHEV consumption, charging shares, and static weekday and weekend profiles.
The 2025 workbook adds a hybrid-vehicle numbers worksheet and revises the charging-mode taxonomy.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ev_sheet_presence = worksheet_presence(
    ["2023 IASR" => EV2023, "2025 IASR" => EV2025],
    [
        "BEV_Numbers", "PHEV_Numbers", "FCEV_Numbers", "ICE_Numbers", "Hybrid_Numbers",
        "BEV_PHEV_Consumption (GWh)", "BEV_PHEV_Charge_Type (%)",
        "BEV_PHEV_Profile_kW (Weekday)", "BEV_PHEV_Profile_kW (Weekend)",
    ],
)
markdown_table(ev_sheet_presence)
````

```@raw html
</details>
```

| **edition** | **worksheet** | **present** |
|:--|:--|--:|
| 2023 IASR | BEV\_Numbers | true |
| 2023 IASR | PHEV\_Numbers | true |
| 2023 IASR | FCEV\_Numbers | true |
| 2023 IASR | ICE\_Numbers | true |
| 2023 IASR | Hybrid\_Numbers | false |
| 2023 IASR | BEV\_PHEV\_Consumption (GWh) | true |
| 2023 IASR | BEV\_PHEV\_Charge\_Type (%) | true |
| 2023 IASR | BEV\_PHEV\_Profile\_kW (Weekday) | true |
| 2023 IASR | BEV\_PHEV\_Profile\_kW (Weekend) | true |
| 2025 IASR | BEV\_Numbers | true |
| 2025 IASR | PHEV\_Numbers | true |
| 2025 IASR | FCEV\_Numbers | true |
| 2025 IASR | ICE\_Numbers | true |
| 2025 IASR | Hybrid\_Numbers | true |
| 2025 IASR | BEV\_PHEV\_Consumption (GWh) | true |
| 2025 IASR | BEV\_PHEV\_Charge\_Type (%) | true |
| 2025 IASR | BEV\_PHEV\_Profile\_kW (Weekday) | true |
| 2025 IASR | BEV\_PHEV\_Profile\_kW (Weekend) | true |


## Battery-electric vehicle numbers

The samples use the first scenario and New South Wales block in each workbook.
The planning years and scenario names shift between publications, so the values are not a like-for-like revision series without additional scenario interpretation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
bev_2023 = cells_table(
    EV2023,
    "BEV_Numbers",
    "B8:J14",
    ["Vehicle type", "2022-23", "2023-24", "2024-25", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30"],
)
markdown_table(bev_2023)
````

```@raw html
</details>
```

| **Vehicle type** | **2022-23** | **2023-24** | **2024-25** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| Articulated Truck | 0 | 0 | 0 | 0 | 2 | 4 | 10 | 41 |
| Bus | 112 | 137 | 257 | 567 | 1018 | 1603 | 2395 | 3208 |
| Large Light Commercial | 44 | 217 | 1352 | 9500 | 17226 | 28203 | 41777 | 57120 |
| Large Residential | 4439 | 7525 | 14003 | 28209 | 47998 | 76428 | 111591 | 151553 |
| Medium Light Commercial | 327 | 562 | 1062 | 2176 | 3719 | 5933 | 8672 | 11770 |
| Medium Residential | 11210 | 14740 | 20392 | 29604 | 45575 | 69110 | 98203 | 131313 |
| Motorcycle | 3637 | 4220 | 5013 | 6088 | 8510 | 12214 | 16793 | 22007 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
bev_2025 = cells_table(
    EV2025,
    "BEV_Numbers",
    "B8:J14",
    ["Vehicle type", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"],
)
markdown_table(bev_2025)
````

```@raw html
</details>
```

| **Vehicle type** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** | **2031-32** | **2032-33** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| Articulated Truck | 0 | 1 | 1 | 5 | 16 | 109 | 288 | 544 |
| Bus | 257 | 652 | 1126 | 1700 | 2399 | 3135 | 3865 | 4588 |
| Large Light Commercial | 1035 | 2462 | 4573 | 7115 | 10120 | 17021 | 27434 | 40954 |
| Large Residential | 30373 | 58498 | 98240 | 145027 | 200768 | 257400 | 315119 | 373635 |
| Medium Light Commercial | 1613 | 2784 | 4389 | 6183 | 8234 | 11129 | 14530 | 18306 |
| Medium Residential | 66388 | 99505 | 142439 | 188496 | 241787 | 294866 | 347992 | 400946 |
| Motorcycle | 3781 | 6768 | 11095 | 16245 | 22456 | 29269 | 36458 | 43995 |


## Hybrid vehicles in the later workbook

The 2025 IASR publication adds projected hybrid stocks as a separate source family.
The current ISP 2024 EV parser has no maintained output-field mapping for this worksheet.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hybrid_2025 = cells_table(
    EV2025,
    "Hybrid_Numbers",
    "B8:J14",
    ["Vehicle type", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"],
)
markdown_table(hybrid_2025)
````

```@raw html
</details>
```

| **Vehicle type** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** | **2031-32** | **2032-33** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| Articulated Truck | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Bus | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Large Light Commercial | 5569 | 9459 | 14785 | 20688 | 27395 | 33825 | 38961 | 42713 |
| Large Residential | 130115 | 159830 | 189538 | 209003 | 225125 | 236442 | 243638 | 247195 |
| Medium Light Commercial | 1209 | 2123 | 3346 | 4645 | 6041 | 7375 | 8430 | 9191 |
| Medium Residential | 107064 | 130754 | 154624 | 170036 | 182372 | 190957 | 196328 | 198860 |
| Motorcycle | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


## Charging-mode changes

The earlier source uses labels such as convenience, daytime, highway-fast, and nighttime charging.
The later source uses unscheduled, public, off-peak-and-solar, and time-of-use categories, which changes the source vocabulary even where the workbook subject remains recognisable.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
charge_type_2023 = cells_table(
    EV2023,
    "BEV_PHEV_Charge_Type (%)",
    "B11:J14",
    ["Charging mode", "2022-23", "2023-24", "2024-25", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30"],
)
markdown_table(charge_type_2023)
````

```@raw html
</details>
```

| **Charging mode** | **2022-23** | **2023-24** | **2024-25** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| Buses and Trucks - Convenience Charging | 0.857 | 0.8486 | 0.8402 | 0.8318 | 0.8233 | 0.8149 | 0.8065 | 0.7981 |
| Buses and Trucks - Daytime Charging | 0.043 | 0.0514 | 0.0598 | 0.0683 | 0.0767 | 0.0851 | 0.0935 | 0.1019 |
| Buses and Trucks - Highway Fast Charging | 0.1 | 0.1 | 0.1 | 0.1 | 0.1 | 0.1 | 0.1 | 0.1 |
| Buses and Trucks - Nighttime Charging | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
charge_type_2025 = cells_table(
    EV2025,
    "BEV_PHEV_Charge_Type (%)",
    "B9:J14",
    ["Charging mode", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"],
)
markdown_table(charge_type_2025)
````

```@raw html
</details>
```

| **Charging mode** | **2025-26** | **2026-27** | **2027-28** | **2028-29** | **2029-30** | **2030-31** | **2031-32** | **2032-33** |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|
| Buses and Trucks - Unscheduled Charging | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| Buses and Trucks - TOU Grid Solar Charging | 0.0328 | 0.0368 | 0.0408 | 0.0448 | 0.0488 | 0.0527 | 0.0567 | 0.0607 |
| Buses and Trucks - Public Charging | 0.0249 | 0.0255 | 0.0261 | 0.0267 | 0.0274 | 0.028 | 0.0286 | 0.0292 |
| Buses and Trucks - Off-peak and Solar Charging | 0.9423 | 0.9377 | 0.9331 | 0.9285 | 0.9239 | 0.9193 | 0.9147 | 0.9101 |
| Buses and Trucks - TOU Dynamic Charging | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| Commercial - Unscheduled Charging | 0.9033 | 0.8976 | 0.8919 | 0.8862 | 0.8805 | 0.8748 | 0.8691 | 0.8634 |


## PISP output-field ownership

The maintained mapping assigns four 2023 number worksheets to parsed output fields.
Charging profiles, vehicle categories, state names, scenario names, bus IDs, and demand relationships are handled by additional package mappings recorded in the coverage ledger.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vehicle_number_mapping = getfield(PISP, :EV_2024_VEHICLE_NUMBER_VALUE_COLUMN_BY_SHEET)
ev_output_fields = DataFrame(
    source_worksheet = collect(keys(vehicle_number_mapping)),
    parsed_field = string.(collect(values(vehicle_number_mapping))),
)
markdown_table(ev_output_fields)
````

```@raw html
</details>
```

| **source\_worksheet** | **parsed\_field** |
|:--|:--|
| BEV\_Numbers | number\_bev |
| PHEV\_Numbers | number\_phev |
| FCEV\_Numbers | number\_fcev |
| ICE\_Numbers | number\_ice |


The 2025 IASR workbook is documented here as observed source evidence.
PISP does not currently claim an integrated ISP 2026 EV preprocessing or dataset workflow.
