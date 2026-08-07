```@meta
EditURL = "../../../../literate/shared/source_material/network_and_transmission.jl"
```

# Network and transmission assumptions

AEMO publishes seasonal flow-path capability, transmission reliability, and candidate augmentation options as related but distinct source subjects.
The capability tables describe transfer approximations under system conditions; the reliability tables describe outage behaviour; the augmentation tables describe possible future changes.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using ParseISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const NETWORK_CAPABILITY_2024 = ParseISP.source_spec(:network_capability, 2024)
const TRANSMISSION_RELIABILITY_2024 = ParseISP.source_spec(:transmission_reliability, 2024)
const AUGMENTATION_OPTIONS_2024 = ParseISP.source_spec(:flow_path_augmentation_options, 2024)
const WORKBOOK2024 = ParseISP.source_path(ISP2024.download_root, NETWORK_CAPABILITY_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
````

```@raw html
</details>
```

## Seasonal flow-path capability

Both editions publish forward and reverse capability approximations for peak demand, summer typical, and winter reference conditions.
The ParseISP 2024 source selection contains the flow-path identifier and six capability fields.
ISP 2026 also places dominant constraints and a notes field beside those values and revises several sampled limits, so an implementation cannot substitute the later sheet solely by matching flow-path names.
The 2024 workbook's flow-path column embeds a stray soft-hyphen character in one row, which the sample below strips before display.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
capability_source_2024 = ParseISP.read_xlsx_rows(WORKBOOK2024, NETWORK_CAPABILITY_2024)
capability_2024 = DataFrame(
    capability_source_2024[3:7, 1:7],
    Symbol.([
        "Flow path", "Forward peak (MW)", "Forward summer (MW)", "Forward winter (MW)",
        "Reverse peak (MW)", "Reverse summer (MW)", "Reverse winter (MW)",
    ]);
    makeunique = true,
)
capability_2024[!, Symbol("Flow path")] = replace.(capability_2024[!, Symbol("Flow path")], "\\uad" => "", Char(0x00ad) => "")
ParseISPDocUtils.markdown_table(capability_2024)
````

```@raw html
</details>
```

| **Flow path** | **Forward peak (MW)** | **Forward summer (MW)** | **Forward winter (MW)** | **Reverse peak (MW)** | **Reverse summer (MW)** | **Reverse winter (MW)** |
|:--|:--|:--|:--|:--|:--|:--|
| CQ - NQ (Note 10) | 1200 | 1200 | 1400 | 1200 | 1200 | 1400 |
| CQ – GG (Note 4) | 700 | 700 | 1050 | 750 | 750 | 1100 |
| SQ – CQ | 1100 | 1100 | 1100 | 2100 | 2100 | 2100 |
| NNSW – SQ (Northern part of "QNI") | 685 (with QNI Minor) | 745 (with QNI Minor) | 745 (with QNI Minor) | 1,205 (with QNI minor) (Note 5) | 1,165 (with QNI minor) (Note 5 | 1,170 (with QNI minor) (Note 5) |
| NNSW – SQ (“Terranora”) | 0 | 50 | 50 | 130 | 150 | 200 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
capability_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Network capability", "B8:K12"),
    Symbol.([
        "Flow path", "Forward peak (MW)", "Forward summer (MW)", "Forward winter (MW)",
        "Reverse peak (MW)", "Reverse summer (MW)", "Reverse winter (MW)",
        "Forward constraint", "Reverse constraint", "Notes",
    ]);
    makeunique = true,
)
capability_2026.Notes = coalesce.(capability_2026.Notes, "Not reported")
ParseISPDocUtils.markdown_table(capability_2026)
````

```@raw html
</details>
```

| **Flow path** | **Forward peak (MW)** | **Forward summer (MW)** | **Forward winter (MW)** | **Reverse peak (MW)** | **Reverse summer (MW)** | **Reverse winter (MW)** | **Forward constraint** | **Reverse constraint** | **Notes** |
|:--|--:|--:|--:|--:|--:|--:|:--|:--|:--|
| CQ-NQ | 1200 | 1200 | 1400 | 800 | 800 | 800 | Voltage stability in NQ for the loss of NQ or CQ transmission network elements. | Thermal capability of Broadsound to Nebo 275 kV line 1 for the loss of second Broadsound to Nebo 275 kV line or thermal capability of Dysart to Peak Downs/Moranbah 132 kV line. | Limits were determined with the inclusion of a minor Strathmore to Ross line upgrade. AEMO is working with Powerlink to further investigate possible voltage or transient stability limits associated with CQ – NQ reverse flow capability. |
| CQ-GG | 700 | 700 | 1050 | 750 | 750 | 1100 | Thermal overload of Calvale to Wurdong 275 kV line | Thermal capacity of Calliope River-Woolooga for the loss of one of the parallel lines | CQ-GG limits are heavily influenced by the amount of generation and northern and central QLD, particularly at Gladstone. The provided transfer limit is a representation with typical generation output from Stanwell and Calvale and reduced generation at Gladstone. This limit will be further reviewed with hourly simulation results. |
| SQ-CQ | 415 | 415 | 850 | 2100 | 2100 | 2100 | Thermal capability of Blackwall -South Pine 275 kV line. | Transient stability or voltage stability for a contingency of the Calvale-Halys 275 kV circuit. | It is assumed Powerlink will establish a new substation at Karana Downs for teeing-in both Blackwall – Rocklea 275 kV lines to South Pine. |
| NNSW-SQ | 950 | 950 | 950 | 1450 | 1450 | 1450 | QNI forward direction maximum transfer capacity of 950 MW (design limit with QNI minor). | Thermal capacity of Sapphire-Armidale 330 kV line for an outage of Dumaresq-Armidale 330 kV line. This assumes no Sapphire wind and/or Tilbuster solar generation. | These transfer limits include the completion of the QNI minor project. QNI minor is currently undergoing inter-network testing to release the designed maximum capacity. QLD to NSW transfer limit influenced by generation output from Sapphire Wind Farm and Tilbuster Solar Farm. |
| NNSW-SQ (Terranora) | 0 | 50 | 50 | 130 | 150 | 200 | Thermal capability of Lismore - Dunoon 132 kV lines. | Thermal capability of Mudgeeraba 275/110 kV transformers | Not reported |


## Transmission reliability

ISP 2024 represents credible-contingency and reclassification outage rates in separate columns.
ISP 2026 instead uses separate rows for those event types and one unplanned-outage-rate field, with mean time to repair beside it.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
transmission_reliability_source_2024 = ParseISP.read_xlsx_rows(
    WORKBOOK2024,
    TRANSMISSION_RELIABILITY_2024,
)
transmission_reliability_2024 = DataFrame(
    transmission_reliability_source_2024[2:5, 1:6],
    Symbol.([
        "Line or flow path", "Implementation", "Credible-contingency outage rate",
        "Reclassification outage rate", "Credible-contingency MTTR", "Reclassification MTTR",
    ]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(transmission_reliability_2024)
````

```@raw html
</details>
```

| **Line or flow path** | **Implementation** | **Credible-contingency outage rate** | **Reclassification outage rate** | **Credible-contingency MTTR** | **Reclassification MTTR** |
|:--|:--|--:|:--|--:|:--|
| Mortlake – Heywood – South East (V-SA) | Static annual FOR | 0.0009 | 0.0001 | 7.8 | 4.7 |
| Murraylink | Static annual FOR | 0.0007 | NA | 12.4 | NA |
| Basslink | Static annual FOR | 0.0539 | NA | 213.9 | NA |
| Liddell – Muswellbrook – Tamworth – Armidale – Dumaresq – Bulli Creek (QNI) | Static annual FOR | 0.0019 | 0.014 | 14.5 | 4.3 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
transmission_reliability_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Transmission Reliability", "B8:E13"),
    Symbol.(["Line or flow path and event", "Implementation", "Unplanned outage rate (%)", "Mean time to repair"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(transmission_reliability_2026)
````

```@raw html
</details>
```

| **Line or flow path and event** | **Implementation** | **Unplanned outage rate (%)** | **Mean time to repair** |
|:--|:--|--:|--:|
| Liddell – Bulli Creek (QNI) Credible Contingency | Static annual unplanned outage rate | 0.00287 | 21.1 |
| Liddell – Bulli Creek (QNI) Reclassification | Static annual unplanned outage rate | 0.01761 | 3.9 |
| Murraylink – Credible Contingency | Static annual unplanned outage rate | 0.0132 | 65.3 |
| Basslink – Credible Contingency | Static annual unplanned outage rate | 0.04527 | 189.5 |
| Mortlake – South East (VSA) Credible Contingency | Annual, set to 0% post PEC stage 2 | 0.00028 | 2.2 |
| Mortlake – South East (VSA) Reclassification | Annual, set to 0% post PEC stage 2 | 9.0e-5 | 4.7 |


## Candidate augmentation options

The augmentation workbooks retain option names, directional transfer increases, costs, easement length, and lead time.
The cost basis changes from 2023 dollars to 2025 dollars, and ISP 2026 adds prerequisite and notes fields around the option record.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
augmentation_source_2024 = ParseISP.read_xlsx_rows(WORKBOOK2024, AUGMENTATION_OPTIONS_2024)
augmentation_2024 = DataFrame(
    augmentation_source_2024[3:4, [1, 4, 6, 7, 8, 9, 12, 13]],
    Symbol.([
        "Flow path", "Option", "Power-flow direction", "Forward increase (MW)",
        "Reverse increase (MW)", "Indicative cost (\$2023 million)", "Easement (km)", "Lead time",
    ]);
    makeunique = true,
)
ParseISPDocUtils.fill_down!(augmentation_2024, [Symbol("Flow path"), Symbol("Power-flow direction")])
ParseISPDocUtils.markdown_table(augmentation_2024)
````

```@raw html
</details>
```

| **Flow path** | **Option** | **Power-flow direction** | **Forward increase (MW)** | **Reverse increase (MW)** | **Indicative cost (\$2023 million)** | **Easement (km)** | **Lead time** |
|:--|:--|:--|--:|--:|--:|--:|:--|
| CQ-NQ | CQ-NQ Option 1 | CQ to NQ | 1100 | 1100 | 1239 | 350 | Medium |
| CQ-NQ | CQ-NQ Option 2 | CQ to NQ | 3000 | 3000 | 4184 | 750 | Long |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
augmentation_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Flow path augmentation options", "B14:Q15")[:, [1, 4, 7, 8, 9, 10, 13, 14, 15, 16]],
    Symbol.([
        "Flow path", "Option", "Power-flow direction", "Forward increase (MW)",
        "Reverse increase (MW)", "Indicative cost (\$2025 million)", "Easement (km)",
        "Lead time", "Additional REZ capacity", "Notes",
    ]);
    makeunique = true,
)
ParseISPDocUtils.fill_down!(augmentation_2026, [Symbol("Flow path"), Symbol("Power-flow direction")])
augmentation_2026.Notes = coalesce.(augmentation_2026.Notes, "Not reported")
ParseISPDocUtils.markdown_table(augmentation_2026)
````

```@raw html
</details>
```

| **Flow path** | **Option** | **Power-flow direction** | **Forward increase (MW)** | **Reverse increase (MW)** | **Indicative cost (\$2025 million)** | **Easement (km)** | **Lead time** | **Additional REZ capacity** | **Notes** |
|:--|:--|:--|--:|--:|--:|--:|:--|:--|:--|
| CQ-NQ | CQ-NQ Option 3 | CQ to NQ | 350 | 500 | 208.948 | 0 | Short: (4 years) | CQ1: 600 | Not reported |
| CQ-NQ | CQ-NQ Option 4 | CQ to NQ | 500 | 1000 | 1850.16 | 307 | Long: (7 years) | CQ1: 1,600 | Not reported |


Flow-path and direction labels are merged across option rows in the source workbooks.
The displayed samples fill those identifiers down for readability and show blank notes as `Not reported`.

## ParseISP network geography

ParseISP applies maintained subregion names and subregion-to-NEM-region mappings when it builds the ISP 2024 network model.
These dictionaries are package conventions rather than extra AEMO workbook rows.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
network_geography = DataFrame(
    isp_subregion = collect(keys(ParseISP.NEMBUSNAME)),
    pisp_name = collect(values(ParseISP.NEMBUSNAME)),
    nem_region = [ParseISP.BUS2AREA[key] for key in keys(ParseISP.NEMBUSNAME)],
)
ParseISPDocUtils.markdown_table(network_geography)
````

```@raw html
</details>
```

| **isp\_subregion** | **pisp\_name** | **nem\_region** |
|:--|:--|:--|
| NQ | Northern Queensland | QLD |
| CQ | Central Queensland | QLD |
| GG | Gladstone Grid | QLD |
| SQ | Southern Queensland | QLD |
| NNSW | Northern New South Wales | NSW |
| CNSW | Central New South Wales | NSW |
| SNW | Sydney, Newcastle & Wollongong | NSW |
| SNSW | Southern New South Wales | NSW |
| VIC | Victoria | VIC |
| TAS | Tasmania | TAS |
| CSA | Central South Australia | SA |
| SESA | South East South Australia | SA |


ParseISP currently implements these selections for ISP 2024.
The ISP 2026 evidence above identifies source changes that require a reviewed parser design before they can define a 2026 dataset.
