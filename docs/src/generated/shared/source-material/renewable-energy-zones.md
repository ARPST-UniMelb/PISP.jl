```@meta
EditURL = "../../../../literate/shared/source_material/renewable_energy_zones.jl"
```

# Renewable energy zones

Renewable energy zone records connect zone identifiers and names to NEM regions and ISP subregions.
PISP uses the ISP 2024 table when allocating utility-scale solar and wind build-out from the generation and storage outlook material.

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
const RENEWABLE_ENERGY_ZONES_2024 = PISP.source_spec(:renewable_energy_zones, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, RENEWABLE_ENERGY_ZONES_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
````

```@raw html
</details>
```

## ISP 2024 zone records

The 2024 source includes the NTNDP zone, ISP subregion, and regional cost zone beside each REZ identifier.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
rez_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, RENEWABLE_ENERGY_ZONES_2024)
rez_2024 = DataFrame(
    rez_source_2024[2:9, 1:6],
    Symbol.(["ID", "Name", "NEM region", "NTNDP zone", "ISP subregion", "Regional cost zone"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(rez_2024)
````

```@raw html
</details>
```

| **ID** | **Name** | **NEM region** | **NTNDP zone** | **ISP subregion** | **Regional cost zone** |
|:--|:--|:--|:--|:--|:--|
| Q1 | Far North QLD | QLD | NQ | NQ | Low1 |
| Q2 | North Qld Clean Energy Hub | QLD | NQ | NQ | Low1 |
| Q3 | Northern Qld | QLD | NQ | NQ | Low |
| Q4 | Isaac | QLD | NQ | CQ | Low1 |
| Q5 | Barcaldine | QLD | CQ | CQ | Medium |
| Q6 | Fitzroy | QLD | CQ | CQ | Low |
| Q7 | Wide Bay | QLD | CQ | SQ | Low1 |
| Q8 | Darling Downs | QLD | SWQ | SQ | Low1 |


## ISP 2026 zone records

The corresponding 2026 table is narrower in its leading columns and no longer places the NTNDP and regional cost-zone fields in this block.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
rez_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Renewable energy zones", "B7:E15"),
    Symbol.(["ID", "Name", "NEM region", "ISP subregion"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(rez_2026)
````

```@raw html
</details>
```

| **ID** | **Name** | **NEM region** | **ISP subregion** |
|:--|:--|:--|:--|
| Q1 | Far North QLD | QLD | NQ |
| Q2 | Hughenden Hub | QLD | NQ |
| Q3 | Northern Qld | QLD | NQ |
| Q4 | Isaac | QLD | CQ |
| Q5 | Barcaldine | QLD | CQ |
| Q6 | Fitzroy | QLD | CQ |
| Q7 | Wide Bay | QLD | SQ |
| Q8 | Darling Downs | QLD | SQ |
| Q9 | Banana | QLD | CQ |


## Name changes under retained identifiers

A retained REZ identifier does not guarantee an unchanged name or planning definition.
In the sampled Queensland records, Q2 changes from North Qld Clean Energy Hub to Hughenden Hub.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
rez_names = innerjoin(
    select(rez_2024, :ID, :Name => :name_2024),
    select(rez_2026, :ID, :Name => :name_2026),
    on = :ID,
)
renamed_rez = filter(row -> row.name_2024 != row.name_2026, rez_names)
PISPDocUtils.markdown_table(renamed_rez)
````

```@raw html
</details>
```

| **ID** | **name\_2024** | **name\_2026** |
|:--|:--|:--|
| Q2 | North Qld Clean Energy Hub | Hughenden Hub |


## Transformation boundary

The current solar and wind builders read the ISP 2024 REZ table, select the relevant zone IDs for each PISP subregion, and combine them with scenario outlook capacity.
Both builders currently apply the package-defined candidate development path `CDP14` across the maintained scenario IDs.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
rez_conventions = DataFrame([
    (subject = "Solar outlook candidate development path", convention = "CDP14 for each current PISP scenario"),
    (subject = "Wind outlook candidate development path", convention = "CDP14 for each current PISP scenario"),
    (subject = "Subregion geography", convention = "PISP.NEMBUSNAME and PISP.BUS2AREA"),
])
PISPDocUtils.markdown_table(rez_conventions)
````

```@raw html
</details>
```

| **subject** | **convention** |
|:--|:--|
| Solar outlook candidate development path | CDP14 for each current PISP scenario |
| Wind outlook candidate development path | CDP14 for each current PISP scenario |
| Subregion geography | PISP.NEMBUSNAME and PISP.BUS2AREA |


The candidate-development-path choices are package conventions, not values read from the REZ worksheet.
The current solar and wind builders continue to use the ISP 2024 zone records.
