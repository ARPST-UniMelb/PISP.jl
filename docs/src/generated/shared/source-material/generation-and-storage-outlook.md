```@meta
EditURL = "../../../../literate/shared/source_material/generation_and_storage_outlook.jl"
```

# Generation and storage outlook

AEMO publishes one generation and storage outlook workbook for each core scenario and sensitivity.
The workbooks contain capacity, storage energy, storage power, REZ build, retirement, and other result tables across financial years.

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
const CORE2024 = joinpath(ISP2024.download_root, "Core")
const SENS2024 = joinpath(ISP2024.download_root, "Sensitivities")
const CORE2026 = joinpath(ISP2026.download_root, "Core scenarios")
const SENS2026 = joinpath(ISP2026.download_root, "Sensitivities")
const CORE_WORKBOOK_2024 = "2024 ISP - Green Energy Exports - Core.xlsx"
const CAPACITY_OUTLOOK_2024 = PISP.source_spec(:core_capacity_outlook, 2024)
const STORAGE_CAPACITY_OUTLOOK_2024 = PISP.source_spec(:core_storage_capacity_outlook, 2024)
const STORAGE_ENERGY_OUTLOOK_2024 = PISP.source_spec(:core_storage_energy_outlook, 2024)
const SAMPLE2024 = PISP.source_path(
    ISP2024.download_root,
    CAPACITY_OUTLOOK_2024;
    core_workbook = CORE_WORKBOOK_2024,
)
const SAMPLE2026 = joinpath(CORE2026, "2026 ISP - Accelerated Transition - Core.xlsx")
````

```@raw html
</details>
```

## Publication inventory

The two editions retain the core-plus-sensitivity packaging pattern, but the case names and workbook counts differ.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
outlook_inventory = vcat(
    PISPDocUtils.read_outlook_inventory(CORE2024, "2024"),
    PISPDocUtils.read_outlook_inventory(SENS2024, "2024"),
    PISPDocUtils.read_outlook_inventory(CORE2026, "2026"),
    PISPDocUtils.read_outlook_inventory(SENS2026, "2026"),
)
outlook_summary = combine(
    groupby(outlook_inventory, [:edition, :group]),
    nrow => :workbooks,
    :worksheet_count => minimum => :minimum_worksheets,
    :worksheet_count => maximum => :maximum_worksheets,
)
sort!(outlook_summary, [:edition, :group])
PISPDocUtils.markdown_table(outlook_summary)
````

```@raw html
</details>
```

| **edition** | **group** | **workbooks** | **minimum\_worksheets** | **maximum\_worksheets** |
|:--|:--|--:|--:|--:|
| 2024 | Core | 3 | 24 | 24 |
| 2024 | Sensitivity | 9 | 24 | 24 |
| 2026 | Core | 3 | 26 | 26 |
| 2026 | Sensitivity | 6 | 26 | 26 |


## Shared result subjects

Representative core workbooks in both editions contain the main capacity, storage, REZ, and retirement subjects.
Worksheet presence does not guarantee identical fields or interpretation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
outlook_sheets = ["Capacity", "Storage Capacity", "Storage Energy", "REZ Generation Capacity", "Retirements"]
outlook_sheet_names = [
    ("ISP 2024", XLSX.openxlsx(SAMPLE2024) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
    ("ISP 2026", XLSX.openxlsx(SAMPLE2026) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
]
outlook_sheet_presence = DataFrame([
    (edition = edition, worksheet = sheet, present = sheet in available)
    for (edition, available) in outlook_sheet_names
    for sheet in outlook_sheets
])
PISPDocUtils.markdown_table(outlook_sheet_presence)
````

```@raw html
</details>
```

| **edition** | **worksheet** | **present** |
|:--|:--|--:|
| ISP 2024 | Capacity | true |
| ISP 2024 | Storage Capacity | true |
| ISP 2024 | Storage Energy | true |
| ISP 2024 | REZ Generation Capacity | true |
| ISP 2024 | Retirements | true |
| ISP 2026 | Capacity | true |
| ISP 2026 | Storage Capacity | true |
| ISP 2026 | Storage Energy | true |
| ISP 2026 | REZ Generation Capacity | true |
| ISP 2026 | Retirements | true |


## Capacity table structure

The capacity worksheet is a long table keyed by candidate development path, region, subregion, and technology, followed by financial-year values.
The later sample starts in 2025-26 and retains the same leading keys before its financial-year values.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
capacity_source_2024 = PISP.read_xlsx_rows(SAMPLE2024, CAPACITY_OUTLOOK_2024)
capacity_2024 = DataFrame(
    capacity_source_2024[2:6, 1:8],
    Symbol.(["CDP", "Region", "Subregion", "Technology", "2023-24", "2024-25", "2025-26", "2026-27"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(capacity_2024)
````

```@raw html
</details>
```

| **CDP** | **Region** | **Subregion** | **Technology** | **2023-24** | **2024-25** | **2025-26** | **2026-27** |
|:--|:--|:--|:--|--:|--:|--:|--:|
| CDP1 | NSW | NNSW | Black coal | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Mid-merit gas | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Flexible gas with CCS | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Flexible gas | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Hydro | 0 | 0 | 0 | 0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
capacity_2026 = DataFrame(
    XLSX.readdata(SAMPLE2026, "Capacity", "A4:H8"),
    Symbol.(["CDP", "Region", "Subregion", "Technology", "2025-26", "2026-27", "2027-28", "2028-29"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(capacity_2026)
````

```@raw html
</details>
```

| **CDP** | **Region** | **Subregion** | **Technology** | **2025-26** | **2026-27** | **2027-28** | **2028-29** |
|:--|:--|:--|:--|--:|--:|--:|--:|
| CDP1 | NSW | NNSW | Black coal | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Mid-merit gas | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Flexible gas with CCS | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Flexible gas | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Hydro | 0 | 0 | 0 | 0 |


## Storage table structure

Storage power remains in MW and storage energy remains in GWh.
Category labels changed: ISP 2026 distinguishes utility-scale storage depths explicitly and updates the planning-year window.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
storage_capacity_source_2024 = PISP.read_xlsx_rows(SAMPLE2024, STORAGE_CAPACITY_OUTLOOK_2024)
storage_capacity_2024 = DataFrame(
    storage_capacity_source_2024[2:6, 1:8],
    Symbol.(["CDP", "Region", "Subregion", "Storage category", "2024-25", "2025-26", "2026-27", "2027-28"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(storage_capacity_2024)
````

```@raw html
</details>
```

| **CDP** | **Region** | **Subregion** | **Storage category** | **2024-25** | **2025-26** | **2026-27** | **2027-28** |
|:--|:--|:--|:--|--:|--:|--:|--:|
| CDP1 | NSW | NNSW | Snowy 2.0 | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Deep storage | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Medium storage | 0 | 0 | 275 | 595.264 |
| CDP1 | NSW | NNSW | Shallow storage | 0 | 30 | 230 | 430 |
| CDP1 | NSW | NNSW | Coordinated CER storage | 18.5777 | 39.8917 | 67.4968 | 106.406 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
storage_capacity_2026 = DataFrame(
    XLSX.readdata(SAMPLE2026, "Storage Capacity", "A4:H8"),
    Symbol.(["CDP", "Region", "Subregion", "Storage category", "2026-27", "2027-28", "2028-29", "2029-30"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(storage_capacity_2026)
````

```@raw html
</details>
```

| **CDP** | **Region** | **Subregion** | **Storage category** | **2026-27** | **2027-28** | **2028-29** | **2029-30** |
|:--|:--|:--|:--|--:|--:|--:|--:|
| CDP1 | NSW | NNSW | Snowy 2.0 | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Deep utility-scale storage | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Medium utility-scale storage | 0 | 400 | 500.001 | 500.001 |
| CDP1 | NSW | NNSW | Shallow utility-scale storage | 450 | 800.0 | 800.0 | 1120.0 |
| CDP1 | NSW | NNSW | Coordinated CER storage | 87.813 | 136.78 | 196.993 | 267.296 |


## Storage-energy table structure

Storage energy records use the same candidate-development-path, region, subregion, and storage-category keys as storage power, with values in GWh across financial years.
The 2024 table is read through PISP's registered source specification; the
2026 table is read from the corresponding core workbook.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
storage_energy_source_2024 = PISP.read_xlsx_rows(SAMPLE2024, STORAGE_ENERGY_OUTLOOK_2024)
storage_energy_2024 = DataFrame(
    storage_energy_source_2024[2:6, 1:8],
    Symbol.(["CDP", "Region", "Subregion", "Storage category", "2024-25", "2025-26", "2026-27", "2027-28"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(storage_energy_2024)
````

```@raw html
</details>
```

| **CDP** | **Region** | **Subregion** | **Storage category** | **2024-25** | **2025-26** | **2026-27** | **2027-28** |
|:--|:--|:--|:--|--:|--:|--:|--:|
| CDP1 | NSW | NNSW | Snowy 2.0 | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Deep storage | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Medium storage | 0 | 0 | 2.2 | 4.76212 |
| CDP1 | NSW | NNSW | Shallow storage | 0 | 0.039 | 0.439 | 0.639 |
| CDP1 | NSW | NNSW | Coordinated CER storage | 0.0371555 | 0.0797834 | 0.134994 | 0.225002 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
storage_energy_2026 = DataFrame(
    XLSX.readdata(SAMPLE2026, "Storage Energy", "A4:H8"),
    Symbol.(["CDP", "Region", "Subregion", "Storage category", "2026-27", "2027-28", "2028-29", "2029-30"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(storage_energy_2026)
````

```@raw html
</details>
```

| **CDP** | **Region** | **Subregion** | **Storage category** | **2026-27** | **2027-28** | **2028-29** | **2029-30** |
|:--|:--|:--|:--|--:|--:|--:|--:|
| CDP1 | NSW | NNSW | Snowy 2.0 | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Deep utility-scale storage | 0 | 0 | 0 | 0 |
| CDP1 | NSW | NNSW | Medium utility-scale storage | 0 | 3.2 | 4.0 | 4.00001 |
| CDP1 | NSW | NNSW | Shallow utility-scale storage | 0.9 | 1.5 | 1.5 | 2.7802 |
| CDP1 | NSW | NNSW | Coordinated CER storage | 0.231276 | 0.368492 | 0.538256 | 0.736053 |


## How PISP uses the outlooks

The current scraper reads the 2024 capacity, storage-capacity, storage-energy, and REZ worksheets and writes separate condensed `Auxiliary/` workbooks for parser use.
The `ess_vpps` path consumes scenario sheets from the generated storage-capacity and storage-energy workbooks for coordinated-CER/VPP storage.
Those intermediates are PISP-generated material, not AEMO source publications.
The ISP 2026 tables above define the revised worksheet names, keys, and units
that parser work must follow.
