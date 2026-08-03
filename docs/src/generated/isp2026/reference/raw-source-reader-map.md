```@meta
EditURL = "../../../../literate/isp2026/reference/raw_source_reader_map.jl"
```

# ISP 2026: Raw-source reader map

ISP 2026 workbooks, outlook files, and model traces contain structured inputs.
This reference maps the observed source selections to their keys, fields,
units, and candidate PISP consumers.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames
using TOML
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const INVENTORY_PATH = joinpath(REPO_ROOT, "docs", "config", "isp2026-source-specs.toml")
const INVENTORY = TOML.parsefile(INVENTORY_PATH)
const PROFILE = PISPDocUtils.edition_profile(REPO_ROOT, "2026")

lineage_ids = reduce(vcat, values(INVENTORY["lineage"]))
length(lineage_ids) == 80 || error("the ISP 2024 lineage must contain 80 entries")
length(unique(lineage_ids)) == 80 || error("the ISP 2024 lineage IDs must be unique")

source_rows = DataFrame(map(INVENTORY["source"]) do source
    (
        id = source["id"],
        group = source["group"],
        status = source["status"],
        format = source["format"],
        path = source["path"],
        selection = source["selection"],
        keys = source["keys"],
        fields_units = source["fields_units"],
        lineage_count = length(source["lineage_2024"]),
        possible_reader = source["possible_reader"],
    )
end)

length(unique(source_rows.id)) == nrow(source_rows) || error("ISP 2026 source IDs must be unique")
isempty(PISP.source_specs(2026)) || error("this documentation assumes no registered ISP 2026 SourceSpecs")

required_locations = [
    joinpath(PROFILE.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm"),
    joinpath(PROFILE.download_root, "aemo-2025-iasr-ev-workbook.xlsx"),
    joinpath(PROFILE.download_root, "Core scenarios"),
    joinpath(PROFILE.download_root, "Sensitivities"),
    joinpath(PROFILE.download_root, "2026 ISP Model"),
    joinpath(PROFILE.download_root, "Traces", "2026 ISP Solar traces", "solar"),
    joinpath(PROFILE.download_root, "Traces", "2026 ISP Wind traces", "wind"),
]
all(ispath, required_locations) || error("one or more required ISP 2026 source locations are unavailable")

inputs_workbook = required_locations[1]
ev_workbook = required_locations[2]
required_inputs_sheets = Set([
    "Existing Gen Data Summary",
    "Emissions intensity",
    "Maximum capacity",
    "Summary Mapping",
    "Generator Reliability Settings",
    "Retirement",
    "Storage properties",
    "Hydro Scheme Inflows",
    "DSP",
    "Rooftop PV",
    "Data Centre Forecasts",
    "Distribution network",
    "Hybrid site limits",
])
required_ev_sheets = Set([
    "BEV_Numbers",
    "PHEV_Numbers",
    "FCEV_Numbers",
    "Hybrid_Numbers",
    "ICE_Numbers",
    "BEV_PHEV_Consumption (GWh)",
    "BEV_PHEV_Charge_Type (%)",
    "BEV_PHEV_Profile_kW (Weekday)",
    "BEV_PHEV_Profile_kW (Weekend)",
])

observed_inputs_sheets = XLSX.openxlsx(inputs_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end
observed_ev_sheets = XLSX.openxlsx(ev_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end
required_inputs_sheets ⊆ observed_inputs_sheets || error("the ISP 2026 inputs workbook is missing a documented worksheet")
required_ev_sheets ⊆ observed_ev_sheets || error("the 2025 IASR EV workbook is missing a documented worksheet")
````

```@raw html
</details>
```

## Evidence and lineage

The 2026 PLEXOS Model Instructions describe three scenario models and the
demand, renewable-generation, gas-availability, DNSP-level CER,
seasonal-timeslice, and load-subtractor traces used by those models
([p. 5](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7)).
The extracted scenario folders and separate solar and wind archives provide
the file-level evidence for the trace selections below.

The lineage links every registered ISP 2024 source specification to observed,
relocated, absent, generated, user-supplied, or legacy-supplement evidence.
Individual ISP 2024 DSP specifications remain distinct in the lineage even
though the 2026 workbook stores DSP as one row-oriented table.

## Source status

“Observed” means the named file and structure were inspected. “Changed” or
“relocated” means the source role has a 2024 lineage but a different 2026
layout. Boundary rows identify absent, generated, user-supplied, legacy, or
unresolved material rather than treating it as a current source read.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
status_labels = Dict(
    "observed" => "Observed source structure",
    "changed" => "Changed source structure",
    "relocated" => "Relocated source structure",
    "unresolved" => "Referenced but unresolved",
    "not-observed" => "No counterpart observed",
    "generated-by-pisp" => "PISP-generated in the 2024 workflow",
    "user-supplied" => "User-supplied input",
    "legacy-supplement" => "Legacy supplement",
)
status_summary = combine(groupby(source_rows, :status), nrow => :source_selections)
status_summary.status = [status_labels[status] for status in status_summary.status]
rename!(status_summary, :status => :evidence_status)
sort!(status_summary, :evidence_status)
PISPDocUtils.markdown_table(status_summary; column_labels = ["Evidence status", "Source selections"])
````

```@raw html
</details>
```

| **Evidence status** | **Source selections** |
|:--|--:|
| Changed source structure | 1 |
| Legacy supplement | 1 |
| No counterpart observed | 2 |
| Observed source structure | 28 |
| PISP-generated in the 2024 workflow | 1 |
| Referenced but unresolved | 1 |
| Relocated source structure | 4 |
| User-supplied input | 1 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function reader_table(rows)
    table = select(
        rows,
        :id => :source_id,
        [:path, :selection, :keys] => ByRow((path, selection, keys) -> "$(path) — $(selection); keys: $(keys)") => :source_selection,
        :fields_units => :content,
        :possible_reader => :candidate_consumer,
    )
    return PISPDocUtils.markdown_table(
        table;
        column_labels = ["Source ID", "Source selection", "Content and units", "Candidate PISP consumer"],
    )
end
````

```@raw html
</details>
```

## Inputs and assumptions workbook

The inputs workbook retains the major generation, storage, reliability,
retirement, network, REZ, hydro, and DSP subjects used in 2024, but several
layouts have changed. It also adds reader-relevant rooftop-PV, data-centre,
distribution-network, hybrid-site, fuel, and gas structures.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
inputs_rows = filter(row -> row.group == "Inputs and assumptions workbook", source_rows)
reader_table(inputs_rows)
````

```@raw html
</details>
```

| **Source ID** | **Source selection** | **Content and units** | **Candidate PISP consumer** |
|:--|:--|:--|:--|
| isp2026-existing-generation | 2026-isp-inputs-and-assumptions-workbook.xlsm — Existing Gen Data Summary!B10:AZ738; keys: IASR ID, station, region, subregion, REZ, technology, fuel, status | Capacity and rating fields in MW; reliability, heat-rate, storage, and status fields | generator\_table and renewable\_generation\_schedules |
| isp2026-generator-emissions-intensity | 2026-isp-inputs-and-assumptions-workbook.xlsm — Emissions intensity!B8:E744 and G8:H29; keys: IASR ID or technology | Scope 1 emissions intensity in kg/MWh as-generated | generator\_table |
| isp2026-maximum-capacity | 2026-isp-inputs-and-assumptions-workbook.xlsm — Maximum capacity, generator and new-technology tables from row 10; keys: IASR ID or technology, region, status, commissioning year | Maximum generation or storage power in MW and storage energy in MWh | generator\_table and ess\_tables |
| isp2026-summary-mapping | 2026-isp-inputs-and-assumptions-workbook.xlsm — Summary Mapping, header row 4 and records from row 7; keys: RowID, IASR ID, location, status | Fuel-cost, outage, MTTR, minimum-load, capacity-factor, heat-rate, and efficiency mappings | generator\_table and ess\_tables |
| isp2026-generator-reliability-retirement | 2026-isp-inputs-and-assumptions-workbook.xlsm — Generator Reliability Settings; Retirement!B12:F738; keys: Technology or IASR ID, fuel, status, financial year | Outage percentages, MTTR, and expected closure year | generator\_table and line\_table |
| isp2026-generator-operation | 2026-isp-inputs-and-assumptions-workbook.xlsm — Coal Min Stable Level; GPG Min Stable Level; Max Ramp Rates; keys: Technology, fuel, unit or station | Minimum stable generation and ramp-rate values in the workbook's stated units | generator\_table |
| isp2026-storage-properties | 2026-isp-inputs-and-assumptions-workbook.xlsm — Storage properties; keys: Storage technology | Power in MW, duration in hours, efficiencies, state of charge, and degradation | ess\_tables |
| isp2026-hydro-scheme-inflows | 2026-isp-inputs-and-assumptions-workbook.xlsm — Hydro Scheme Inflows; keys: Hydro scheme, month, reference year | Monthly inflow energy in GL | build\_hourly\_snowy and gen\_inflow\_sched |
| isp2026-dsp | 2026-isp-inputs-and-assumptions-workbook.xlsm — DSP, normalized row table; keys: Region, price band, scenario, season | Financial-year demand-side-participation values | der\_pred\_sched |
| isp2026-rooftop-pv | 2026-isp-inputs-and-assumptions-workbook.xlsm — Rooftop PV!B15:AH63 and B68:AH116; keys: Scenario, region, financial year | Degraded capacity in MW and annual energy in GWh | No current PISP reader; candidate input to distributed-PV capacity and energy mapping |
| isp2026-data-centre-forecasts | 2026-isp-inputs-and-assumptions-workbook.xlsm — Data Centre Forecasts!B11:AF16, B19:AF24, and B27:AF32; keys: Scenario, region, financial year | Annual electricity consumption in TWh | No current PISP reader; candidate input to demand construction |
| isp2026-distribution-network | 2026-isp-inputs-and-assumptions-workbook.xlsm — Distribution network!B18:G38, B43:H56, and B65:AZ1433; keys: DNSP, region, tranche or time-profile identifier | Pipeline/hosting capacity, augmentation cost, and CER generation limits in MW | No current PISP reader; candidate input to distribution-project and CER-limit modelling |
| isp2026-hybrid-site-limits | 2026-isp-inputs-and-assumptions-workbook.xlsm — Hybrid site limits!B9:G67; keys: IASR ID, site name, region, technology, status | Connection capacity in MW | No current PISP reader; candidate constraint for co-located technologies |
| isp2026-fuel-and-gas | 2026-isp-inputs-and-assumptions-workbook.xlsm — Fuel Price Summary; Gas, Liquid fuel, H2 price; Gas System Properties; keys: Fuel or gas-system item, region, scenario, financial year | Fuel-price and gas-system fields in the workbook's stated units | No current PISP reader; candidate input to fuel-cost and gas-limit modelling |
| isp2026-network-and-rez | 2026-isp-inputs-and-assumptions-workbook.xlsm — Network Capability; Flow Path Augmentation options; Renewable Energy Zones; keys: Flow path or REZ identifier, region, subregion | Transfer capability, augmentation cost, and REZ attributes in stated workbook units | line\_table, line\_invoptions, and renewable\_generation\_schedules |


## Electric-vehicle workbook

The 2025 IASR EV workbook preserves number, charge-type, and weekday/weekend
profile roles while adding FCEV and hybrid vehicle families and a separate
annual-consumption table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ev_rows = filter(row -> row.group == "2025 IASR EV workbook", source_rows)
reader_table(ev_rows)
````

```@raw html
</details>
```

| **Source ID** | **Source selection** | **Content and units** | **Candidate PISP consumer** |
|:--|:--|:--|:--|
| isp2026-ev-numbers | aemo-2025-iasr-ev-workbook.xlsx — BEV\_Numbers, PHEV\_Numbers, FCEV\_Numbers, Hybrid\_Numbers, and ICE\_Numbers!A1:AG303; keys: Scenario, region, vehicle type, financial year | Vehicle counts | ev\_der\_sched |
| isp2026-ev-consumption | aemo-2025-iasr-ev-workbook.xlsx — BEV\_PHEV\_Consumption (GWh)!A1:AY261; keys: Scenario, region, vehicle type, financial year | Annual consumption in GWh | No current PISP reader; candidate input to EV demand construction |
| isp2026-ev-charge-type | aemo-2025-iasr-ev-workbook.xlsx — BEV\_PHEV\_Charge\_Type (%)!A1:AG400; keys: Scenario, region, vehicle type, charge type, financial year | Share in percent | ev\_der\_sched |
| isp2026-ev-profiles | aemo-2025-iasr-ev-workbook.xlsx — BEV\_PHEV\_Profile\_kW (Weekday) and (Weekend)!A1:AY296; keys: Scenario, region, vehicle type, charge type, interval | Charging profile in kW | ev\_der\_sched |


## Generation and storage outlook

Core and sensitivity workbooks expose capacity, storage power, storage
energy, REZ capacity, and CDP catalogues. `Storage Energy` uses the literal
key header `Technology`, while `Storage Capacity` uses `storage category`.
`Available CDPs` includes `CDP4 (ODP)`, consistent with AEMO's identification
of CDP 4 as the 2026 ODP ([2026 ISP Cost Benefit Analysis, p. 162](../../../../../data/2026/pisp-reports/a6-cost-benefit-analysis.pdf#page=162)).

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
outlook_rows = filter(row -> row.group == "Generation and storage outlook", source_rows)
reader_table(outlook_rows)
````

```@raw html
</details>
```

| **Source ID** | **Source selection** | **Content and units** | **Candidate PISP consumer** |
|:--|:--|:--|:--|
| isp2026-outlook-capacity | Core scenarios/2026 ISP - {scenario} - Core.xlsx — Capacity!A1:AZ7738; keys: CDP, region, subregion, technology, financial year | Installed capacity in MW | build\_capacity\_outlook\_aux and renewable\_generation\_schedules |
| isp2026-outlook-storage-capacity | Core scenarios/2026 ISP - {scenario} - Core.xlsx — Storage Capacity!A1:AB3432; keys: CDP, region, subregion, storage category, financial year | Storage power in MW | build\_storage\_outlook\_aux and ess\_vpps |
| isp2026-outlook-storage-energy | Core scenarios/2026 ISP - {scenario} - Core.xlsx — Storage Energy!A1:AB3420; keys: CDP, region, subregion, Technology, financial year | Storage energy in GWh; the literal fourth header is Technology | build\_storage\_outlook\_aux and ess\_vpps |
| isp2026-outlook-rez-capacity | Core scenarios/2026 ISP - {scenario} - Core.xlsx — REZ Generation Capacity!A1:AE8787; keys: CDP, region, REZ, REZ name, technology, financial year | Installed capacity in MW | build\_rez\_capacity\_aux and renewable\_generation\_schedules |
| isp2026-outlook-cdp-catalogue | Core scenarios/2026 ISP - {scenario} - Core.xlsx — CDPs!A1:BG38 and Available CDPs!A1:A45; keys: CDP identifier and development-path description | Identifiers and descriptions; available values include CDP4 (ODP) | No current PISP reader; candidate authority for validating development-path selections |
| isp2026-outlook-sensitivities | Sensitivities/2026 ISP - Step Change - {sensitivity}.xlsx — Capacity, Storage Capacity, Storage Energy, REZ Generation Capacity, CDPs, and Available CDPs; keys: Sensitivity, CDP, geography, technology or storage category, financial year | MW or GWh according to worksheet | No current PISP reader; candidate extension of outlook readers with sensitivity selection |


## Model and renewable trace files

Demand, DNSP, rooftop-PV, and load-subtractor CSVs use `Year`, `Month`,
`Day`, and half-hour columns `01` to `48`. Gas files use a daily `Value`
field, while daily hydro files use `Inflows`. The model XML references
`timeslice_RefYear5000.csv`, but that file is not present in the extracted
trace folders. Its file schema and consumer contract remain unresolved.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_rows = filter(
    row -> row.group in ("Model trace folders", "Separate renewable trace archives"),
    source_rows,
)
reader_table(trace_rows)
````

```@raw html
</details>
```

| **Source ID** | **Source selection** | **Content and units** | **Candidate PISP consumer** |
|:--|:--|:--|:--|
| isp2026-model-demand | 2026 ISP Model/2026 ISP {scenario}/Traces/demand/\*.csv — All CSV files in each scenario directory; keys: Filename series, Year, Month, Day, half-hour columns 01 to 48 | Demand time series in the file's stated units | dem\_load\_sched |
| isp2026-model-dnsp | 2026 ISP Model/2026 ISP {scenario}/Traces/dnsp/\*.csv — All CSV files in each scenario directory; keys: Filename series, Year, Month, Day, half-hour columns 01 to 48 | DNSP-level CER time series | No current PISP reader |
| isp2026-model-gas | 2026 ISP Model/2026 ISP {scenario}/Traces/gas/\*.csv — All CSV files in each scenario directory; keys: Filename series, Year, Month, Day | Value column; filenames describe gas limits in TJ | No current PISP reader |
| isp2026-model-hydro | 2026 ISP Model/2026 ISP {scenario}/Traces/hydro/\*.csv — All CSV files in each scenario directory; keys: Filename series, Year, Month, Day | Inflows column for daily files; file-specific hydro energy series | gen\_inflow\_sched |
| isp2026-model-load-subtractor | 2026 ISP Model/2026 ISP {scenario}/Traces/load\_subtractor/\*.csv — All CSV files in each scenario directory; keys: Filename series, Year, Month, Day, half-hour columns 01 to 48 | Load-subtractor time series | No current PISP reader |
| isp2026-model-rooftop-pv | 2026 ISP Model/2026 ISP {scenario}/Traces/rooftop PV/\*.csv — All CSV files in each scenario directory; keys: Filename series, Year, Month, Day, half-hour columns 01 to 48 | Rooftop-PV time series | gen\_pmax\_distpv |
| isp2026-model-timeslice | 2026 ISP Model/2026 ISP {scenario}/Traces/timeslice/timeslice\_RefYear5000.csv — Referenced by each scenario XML; file not observed in the extracted folders; keys: Unresolved | Seasonal-timeslice classification described by the model instructions | No current PISP reader; the referenced source file is unavailable |
| isp2026-solar-traces | Traces/2026 ISP Solar traces/solar/\*.csv — All project CSV files; keys: Project filename, Year, Month, Day, half-hour columns 01 to 48 | Solar availability time series | gen\_pmax\_solar |
| isp2026-wind-traces | Traces/2026 ISP Wind traces/wind/\*.csv — All project CSV files; keys: Project filename, Year, Month, Day, half-hour columns 01 to 48 | Wind availability time series | gen\_pmax\_wind |


### Observed trace files by scenario

These counts come from the current extracted directories and distinguish
scenario-model traces from separately published project-level renewable
archives.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
scenario_names = ["Accelerated Transition", "Slower Growth", "Step Change"]
trace_families = ["demand", "dnsp", "gas", "hydro", "load_subtractor", "rooftop PV"]
model_root = joinpath(PROFILE.download_root, "2026 ISP Model")

observed_trace_files = DataFrame([
    (
        scope = scenario,
        trace_family = family,
        csv_files = count(
            name -> endswith(lowercase(name), ".csv"),
            readdir(joinpath(model_root, "2026 ISP $scenario", "Traces", family)),
        ),
    )
    for scenario in scenario_names for family in trace_families
])

for (family, directory) in [
    "solar" => joinpath(PROFILE.download_root, "Traces", "2026 ISP Solar traces", "solar"),
    "wind" => joinpath(PROFILE.download_root, "Traces", "2026 ISP Wind traces", "wind"),
]
    push!(
        observed_trace_files,
        (
            scope = "Separate renewable archive",
            trace_family = family,
            csv_files = count(name -> endswith(lowercase(name), ".csv"), readdir(directory)),
        ),
    )
end

PISPDocUtils.markdown_table(
    observed_trace_files;
    column_labels = ["Scenario or archive", "Trace family", "Observed CSV files"],
)
````

```@raw html
</details>
```

| **Scenario or archive** | **Trace family** | **Observed CSV files** |
|:--|:--|--:|
| Accelerated Transition | demand | 15 |
| Accelerated Transition | dnsp | 38 |
| Accelerated Transition | gas | 11 |
| Accelerated Transition | hydro | 23 |
| Accelerated Transition | load\_subtractor | 9 |
| Accelerated Transition | rooftop PV | 19 |
| Slower Growth | demand | 15 |
| Slower Growth | dnsp | 38 |
| Slower Growth | gas | 11 |
| Slower Growth | hydro | 23 |
| Slower Growth | load\_subtractor | 9 |
| Slower Growth | rooftop PV | 19 |
| Step Change | demand | 15 |
| Step Change | dnsp | 38 |
| Step Change | gas | 11 |
| Step Change | hydro | 23 |
| Step Change | load\_subtractor | 9 |
| Step Change | rooftop PV | 19 |
| Separate renewable archive | solar | 248 |
| Separate renewable archive | wind | 206 |


## Known source boundaries

These rows distinguish missing 2026 sources, PISP-generated 2024
intermediates, user inputs, and legacy supplements from published 2026 source
selections.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
boundary_rows = filter(row -> row.group == "Known source boundaries", source_rows)
reader_table(boundary_rows)
````

```@raw html
</details>
```

| **Source ID** | **Source selection** | **Content and units** | **Candidate PISP consumer** |
|:--|:--|:--|:--|
| isp2026-ev-subregional-allocation | 2026-isp-inputs-and-assumptions-workbook.xlsm — No Sub-regional demand allocation worksheet observed; keys: Not applicable | Not applicable | No replacement allocation source or method is defined |
| isp2026-generator-minimum-up-down | 2026-isp-inputs-and-assumptions-workbook.xlsm — No Min Up&Down Times worksheet observed; keys: Not applicable | Not applicable | No replacement source or maintained package assumption is defined |
| isp2026-generated-auxiliary | Auxiliary — No published 2026 counterpart; 2024 files are PISP preprocessing outputs; keys: No 2026 preprocessing contract | Capacity or storage quantities derived from outlook workbooks | No current 2026 generator |
| isp2026-user-buildout | PISP-buildouts/buildouts.xlsx — User-provided buildout worksheet; keys: Technology, subregion, capacity, year, count | User-supplied build schedule | read\_buildout\_table for user schedules, independent of AEMO 2026 source files |
| isp2026-legacy-minimum-up-time | 2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx — Generation limits!O9:Q69; keys: Generator or technology | Minimum-up-time values | No 2026 source counterpart or package assumption is defined |


