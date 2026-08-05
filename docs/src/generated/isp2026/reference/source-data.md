```@meta
EditURL = "../../../../literate/isp2026/reference/source_data.jl"
```

# ISP 2026: Source data

ISP 2026 source material is organised across the inputs and assumptions
workbook, the electric-vehicle workbook, generation and storage outlooks,
scenario models, and trace collections.
This reference lists the files, selections, keys, fields, and units used to
describe those sources.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using DataFrames
using TOML

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const SOURCE_MAP_PATH = joinpath(REPO_ROOT, "docs", "config", "isp2026-source-specs.toml")
const SOURCE_MAP = TOML.parsefile(SOURCE_MAP_PATH)

lineage_ids = reduce(vcat, values(SOURCE_MAP["lineage"]))
length(lineage_ids) == 80 || error("the ISP 2026 source index must contain 80 entries")
length(unique(lineage_ids)) == 80 || error("the ISP 2026 source index must contain unique entries")

function source_name(id)
    name = titlecase(replace(replace(id, "isp2026-" => ""), "-" => " "))
    return replace(
        name,
        "Ev" => "EV",
        "Rez" => "REZ",
        "Dsp" => "DSP",
        "Dnsp" => "DNSP",
        "Pv" => "PV",
        "Cdp" => "CDP",
    )
end

source_rows = DataFrame(map(
    filter(source -> source["group"] != "Known source boundaries", SOURCE_MAP["source"]),
) do source
    (
        source = source_name(source["id"]),
        group = source["group"],
        path = source["path"],
        selection = source["selection"],
        keys = source["keys"],
        fields_units = source["fields_units"],
    )
end)

function reader_table(rows)
    table = select(
        rows,
        :source,
        [:path, :selection] => ByRow((path, selection) -> "$(path) — $(selection)") => :source_selection,
        :keys,
        :fields_units,
    )
    return PISPDocUtils.markdown_table(
        table;
        column_labels = ["Source", "File and selection", "Keys", "Fields and units"],
    )
end
````

```@raw html
</details>
```

## How to read the tables

The 2026 PLEXOS Model Instructions describe the scenario models and the
demand, renewable-generation, gas, DNSP, seasonal-timeslice, and
load-subtractor traces supplied with the release
([p. 5](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7)).
The tables below identify the file or pattern, the selected worksheet or
folder, the keys, and the fields and units recorded for each source.

## Inputs and assumptions workbook

The workbook covers generation, storage, reliability, retirement, network,
renewable energy zones, hydro, demand-side participation, rooftop PV,
data-centre demand, distribution networks, hybrid-site limits, and fuel and
gas assumptions.

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

| **Source** | **File and selection** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| Existing Generation | 2026-isp-inputs-and-assumptions-workbook.xlsm — Existing Gen Data Summary!B10:AZ738 | IASR ID, station, region, subregion, REZ, technology, fuel, status | Capacity and rating fields in MW; reliability, heat-rate, storage, and status fields |
| Generator Emissions Intensity | 2026-isp-inputs-and-assumptions-workbook.xlsm — Emissions intensity!B8:E744 and G8:H29 | IASR ID or technology | Scope 1 emissions intensity in kg/MWh as-generated |
| Maximum Capacity | 2026-isp-inputs-and-assumptions-workbook.xlsm — Maximum capacity, generator and new-technology tables from row 10 | IASR ID or technology, region, status, commissioning year | Maximum generation or storage power in MW and storage energy in MWh |
| Summary Mapping | 2026-isp-inputs-and-assumptions-workbook.xlsm — Summary Mapping, header row 4 and records from row 7 | RowID, IASR ID, location, status | Fuel-cost, outage, MTTR, minimum-load, capacity-factor, heat-rate, and efficiency mappings |
| Generator Reliability Retirement | 2026-isp-inputs-and-assumptions-workbook.xlsm — Generator Reliability Settings; Retirement!B12:F738 | Technology or IASR ID, fuel, status, financial year | Outage percentages, MTTR, and expected closure year |
| Generator Operation | 2026-isp-inputs-and-assumptions-workbook.xlsm — Coal Min Stable Level; GPG Min Stable Level; Max Ramp Rates | Technology, fuel, unit or station | Minimum stable generation and ramp-rate values in the workbook's stated units |
| Storage Properties | 2026-isp-inputs-and-assumptions-workbook.xlsm — Storage properties | Storage technology | Power in MW, duration in hours, efficiencies, state of charge, and degradation |
| Hydro Scheme Inflows | 2026-isp-inputs-and-assumptions-workbook.xlsm — Hydro Scheme Inflows | Hydro scheme, month, reference year | Monthly inflow energy in GL |
| DSP | 2026-isp-inputs-and-assumptions-workbook.xlsm — DSP, normalized row table | Region, price band, scenario, season | Financial-year demand-side-participation values |
| Rooftop PV | 2026-isp-inputs-and-assumptions-workbook.xlsm — Rooftop PV!B15:AH63 and B68:AH116 | Scenario, region, financial year | Degraded capacity in MW and annual energy in GWh |
| Data Centre Forecasts | 2026-isp-inputs-and-assumptions-workbook.xlsm — Data Centre Forecasts!B11:AF16, B19:AF24, and B27:AF32 | Scenario, region, financial year | Annual electricity consumption in TWh |
| Distribution Network | 2026-isp-inputs-and-assumptions-workbook.xlsm — Distribution network!B18:G38, B43:H56, and B65:AZ1433 | DNSP, region, tranche or time-profile identifier | Pipeline/hosting capacity, augmentation cost, and CER generation limits in MW |
| Hybrid Site Limits | 2026-isp-inputs-and-assumptions-workbook.xlsm — Hybrid site limits!B9:G67 | IASR ID, site name, region, technology, status | Connection capacity in MW |
| Fuel And Gas | 2026-isp-inputs-and-assumptions-workbook.xlsm — Fuel Price Summary; Gas, Liquid fuel, H2 price; Gas System Properties | Fuel or gas-system item, region, scenario, financial year | Fuel-price and gas-system fields in the workbook's stated units |
| Network And REZ | 2026-isp-inputs-and-assumptions-workbook.xlsm — Network Capability; Flow Path Augmentation options; Renewable Energy Zones | Flow path or REZ identifier, region, subregion | Transfer capability, augmentation cost, and REZ attributes in stated workbook units |


## Electric-vehicle workbook

The 2025 IASR EV workbook contains vehicle numbers, annual consumption,
charging shares, and weekday and weekend charging profiles.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vehicle_rows = filter(row -> row.group == "2025 IASR EV workbook", source_rows)
reader_table(vehicle_rows)
````

```@raw html
</details>
```

| **Source** | **File and selection** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| EV Numbers | aemo-2025-iasr-ev-workbook.xlsx — BEV\_Numbers, PHEV\_Numbers, FCEV\_Numbers, Hybrid\_Numbers, and ICE\_Numbers!A1:AG303 | Scenario, region, vehicle type, financial year | Vehicle counts |
| EV Consumption | aemo-2025-iasr-ev-workbook.xlsx — BEV\_PHEV\_Consumption (GWh)!A1:AY261 | Scenario, region, vehicle type, financial year | Annual consumption in GWh |
| EV Charge Type | aemo-2025-iasr-ev-workbook.xlsx — BEV\_PHEV\_Charge\_Type (%)!A1:AG400 | Scenario, region, vehicle type, charge type, financial year | Share in percent |
| EV Profiles | aemo-2025-iasr-ev-workbook.xlsx — BEV\_PHEV\_Profile\_kW (Weekday) and (Weekend)!A1:AY296 | Scenario, region, vehicle type, charge type, interval | Charging profile in kW |


## Generation and storage outlook

Core and sensitivity workbooks provide generation capacity, storage power,
storage energy, renewable-energy-zone capacity, and development-path tables.
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

| **Source** | **File and selection** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| Outlook Capacity | Core scenarios/2026 ISP - {scenario} - Core.xlsx — Capacity!A1:AZ7738 | CDP, region, subregion, technology, financial year | Installed capacity in MW |
| Outlook Storage Capacity | Core scenarios/2026 ISP - {scenario} - Core.xlsx — Storage Capacity!A1:AB3432 | CDP, region, subregion, storage category, financial year | Storage power in MW |
| Outlook Storage Energy | Core scenarios/2026 ISP - {scenario} - Core.xlsx — Storage Energy!A1:AB3420 | CDP, region, subregion, Technology, financial year | Storage energy in GWh; the literal fourth header is Technology |
| Outlook REZ Capacity | Core scenarios/2026 ISP - {scenario} - Core.xlsx — REZ Generation Capacity!A1:AE8787 | CDP, region, REZ, REZ name, technology, financial year | Installed capacity in MW |
| Outlook CDP Catalogue | Core scenarios/2026 ISP - {scenario} - Core.xlsx — CDPs!A1:BG38 and Available CDPs!A1:A45 | CDP identifier and development-path description | Identifiers and descriptions; available values include CDP4 (ODP) |
| Outlook Sensitivities | Sensitivities/2026 ISP - Step Change - {sensitivity}.xlsx — Capacity, Storage Capacity, Storage Energy, REZ Generation Capacity, CDPs, and Available CDPs | Sensitivity, CDP, geography, technology or storage category, financial year | MW or GWh according to worksheet |


## Model and trace files

Scenario models and trace collections provide demand, DNSP, gas, hydro,
load-subtractor, rooftop-PV, solar, wind, and reference-year time series.

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

| **Source** | **File and selection** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| Model Demand | 2026 ISP Model/2026 ISP {scenario}/Traces/demand/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | Demand time series in the file's stated units |
| Model DNSP | 2026 ISP Model/2026 ISP {scenario}/Traces/dnsp/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | DNSP-level CER time series |
| Model Gas | 2026 ISP Model/2026 ISP {scenario}/Traces/gas/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day | Value column; filenames describe gas limits in TJ |
| Model Hydro | 2026 ISP Model/2026 ISP {scenario}/Traces/hydro/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day | Inflows column for daily files; file-specific hydro energy series |
| Model Load Subtractor | 2026 ISP Model/2026 ISP {scenario}/Traces/load\_subtractor/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | Load-subtractor time series |
| Model Rooftop PV | 2026 ISP Model/2026 ISP {scenario}/Traces/rooftop PV/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | Rooftop-PV time series |
| Model Timeslice | 2026 ISP Model/2026 ISP {scenario}/Traces/timeslice/timeslice\_RefYear5000.csv — Referenced by each scenario XML; file is not included in the extracted trace folders | Reference-year identifier from the XML file reference | Seasonal-timeslice classification described by the model instructions |
| Solar Traces | Traces/2026 ISP Solar traces/solar/\*.csv — All project CSV files | Project filename, Year, Month, Day, half-hour columns 01 to 48 | Solar availability time series |
| Wind Traces | Traces/2026 ISP Wind traces/wind/\*.csv — All project CSV files | Project filename, Year, Month, Day, half-hour columns 01 to 48 | Wind availability time series |


## Compare editions

The [raw-source comparison](../../comparison/analyses/raw-source-comparison.md)
compares worksheet selections, fields, units, and source-family changes.
The [model archive comparison](../../comparison/analyses/model-archive-comparison.md)
compares scenario directories, model files, and trace folders.
