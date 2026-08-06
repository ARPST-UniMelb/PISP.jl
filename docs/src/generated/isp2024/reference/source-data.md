```@meta
EditURL = "../../../../literate/isp2024/reference/source_data.jl"
```

# ISP 2024: Source data

ISP 2024 source material is organised across the inputs and assumptions
workbook, the electric-vehicle workbook, generation and storage outlooks,
scenario models, and trace collections.
This reference lists the files, selections, keys, fields, and units used to
describe those sources.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using DataFrames
using ParseISP

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const PROFILE = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")

function source_name(id)
    name = titlecase(replace(string(id), "_" => " "))
    return replace(
        name,
        "Ev" => "EV",
        "Rez" => "REZ",
        "Dsp" => "DSP",
        "Pv" => "PV",
    )
end

function source_group(row)
    workbook = row.workbook_or_pattern
    if row.source_format == "csv"
        return "Model and trace files"
    elseif occursin("2023-iasr-ev-workbook", workbook)
        return "Electric-vehicle workbook"
    elseif occursin("Core/", workbook)
        return "Generation and storage outlook"
    end
    return "Inputs and assumptions workbook"
end

function source_selection(row)
    row.source_format == "csv" && return row.workbook_or_pattern
    selection = isempty(row.cell_range) ? row.worksheet : "$(row.worksheet)!$(row.cell_range)"
    return selection
end

function fields_and_units(row)
    parts = String[]
    isempty(row.columns) || push!(parts, replace(row.columns, "; " => ", "))
    isempty(row.units) || push!(parts, replace(row.units, "; " => ", "))
    return isempty(parts) ? "See the named source selection" : join(parts, ". ")
end

source_rows = DataFrame([
    (
        source = source_name(row.id),
        group = source_group(row),
        path = row.workbook_or_pattern,
        selection = source_selection(row),
        keys = isempty(row.keys) ? "Defined by the selected table" : replace(row.keys, "; " => ", "),
        fields_units = fields_and_units(row),
    )
    for row in ParseISP.source_spec_rows(2024)
])

function reader_table(rows)
    table = select(
        rows,
        :source,
        [:path, :selection] => ByRow((path, selection) -> "$(path) — $(selection)") => :source_selection,
        :keys,
        :fields_units,
    )
    return ParseISPDocUtils.markdown_table(
        table;
        column_labels = ["Source", "File and selection", "Keys", "Fields and units"],
    )
end
````

```@raw html
</details>
```

## How to read the tables

The 2024 PLEXOS Model Instructions describe the scenario models and the
demand, hydro, load-subtracter, solar, timeslice, and wind traces supplied
with the release
([p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=7)).
The tables below identify the file or pattern, the selected worksheet or
folder, the keys, and the fields and units recorded for each source.

## Inputs and assumptions workbook

The workbook covers generation, storage, reliability, retirement, network,
renewable energy zones, hydro, demand-side participation, and supporting
mappings.

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
| Additional Generator Summary | 2024-isp-inputs-and-assumptions-workbook.xlsx — Existing Gen Data Summary!B382:U397 | Defined by the selected table | See the named source selection |
| Anticipated Generator Maximum Capacity | 2024-isp-inputs-and-assumptions-workbook.xlsx — Maximum capacity!K8:N24 | Defined by the selected table | See the named source selection |
| Auxiliary REZ Generation Capacity | Auxiliary/2024 ISP - {scenario} - Core\_REZCAP.xlsx — REZ Generation Capacity!A1:AG2238 | Defined by the selected table | CDP, REZ, Technology |
| Bess Maximum Capacity | 2024-isp-inputs-and-assumptions-workbook.xlsx — Maximum capacity!P8:U62 | Defined by the selected table | See the named source selection |
| Bess Storage Properties | 2024-isp-inputs-and-assumptions-workbook.xlsx — Storage properties!B4:H13 | Defined by the selected table | See the named source selection |
| Bess Summary Mapping | 2024-isp-inputs-and-assumptions-workbook.xlsx — Summary Mapping!B314:AB370 | Defined by the selected table | See the named source selection |
| Buildout Schedule | ParseISP-buildouts/buildouts.xlsx — buildout\_1 | Defined by the selected table | tech, subregion, year, capacity, n. capacity=MW |
| Coal Minimum Stable Generation | 2024-isp-inputs-and-assumptions-workbook.xlsx — Generation limits!B8:D52 | Defined by the selected table | See the named source selection |
| Committed Generator Maximum Capacity | 2024-isp-inputs-and-assumptions-workbook.xlsx — Maximum capacity!F8:I35 | Defined by the selected table | See the named source selection |
| Condensed Capacity Outlook | Auxiliary/CapacityOutlook2024\_Condensed.xlsx — CapacityOutlook!A1:G14356 | Defined by the selected table | Scenario, Subregion, Technology, date, value. value=MW |
| DSP Green Energy Exports Nsw Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B10:AG15 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Nsw Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B20:AG25 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Qld Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B30:AG35 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Qld Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B39:AG44 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Sa Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B49:AG54 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Sa Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B58:AG63 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Tas Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B68:AG73 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Tas Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B77:AG82 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Vic Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B87:AG92 | Defined by the selected table | See the named source selection |
| DSP Green Energy Exports Vic Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B96:AG101 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Nsw Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B108:AG113 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Nsw Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B118:AG123 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Qld Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B128:AG133 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Qld Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B137:AG142 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Sa Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B147:AG152 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Sa Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B156:AG161 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Tas Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B166:AG171 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Tas Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B175:AG180 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Vic Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B185:AG190 | Defined by the selected table | See the named source selection |
| DSP Progressive Change Vic Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B194:AG199 | Defined by the selected table | See the named source selection |
| DSP Step Change Nsw Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B206:AG211 | Defined by the selected table | See the named source selection |
| DSP Step Change Nsw Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B216:AG221 | Defined by the selected table | See the named source selection |
| DSP Step Change Qld Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B226:AG231 | Defined by the selected table | See the named source selection |
| DSP Step Change Qld Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B235:AG240 | Defined by the selected table | See the named source selection |
| DSP Step Change Sa Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B245:AG250 | Defined by the selected table | See the named source selection |
| DSP Step Change Sa Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B254:AG259 | Defined by the selected table | See the named source selection |
| DSP Step Change Tas Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B264:AG269 | Defined by the selected table | See the named source selection |
| DSP Step Change Tas Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B273:AG278 | Defined by the selected table | See the named source selection |
| DSP Step Change Vic Summer | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B283:AG288 | Defined by the selected table | See the named source selection |
| DSP Step Change Vic Winter | 2024-isp-inputs-and-assumptions-workbook.xlsx — DSP!B292:AG297 | Defined by the selected table | See the named source selection |
| EV Subregional Demand Allocation | 2024-isp-inputs-and-assumptions-workbook.xlsx — Sub-regional demand allocation!B127:AG182 | Defined by the selected table | See the named source selection |
| Existing Generator Maximum Capacity | 2024-isp-inputs-and-assumptions-workbook.xlsx — Maximum capacity!B8:D260 | Defined by the selected table | See the named source selection |
| Existing Generator Reliability | 2024-isp-inputs-and-assumptions-workbook.xlsx — Generator Reliability Settings!B20:G28 | Defined by the selected table | See the named source selection |
| Existing Generator Summary | 2024-isp-inputs-and-assumptions-workbook.xlsx — Existing Gen Data Summary!B10:U319 | Defined by the selected table | See the named source selection |
| Existing Generators | 2024-isp-inputs-and-assumptions-workbook.xlsx — Existing Gen Data Summary!B11:K297 | Defined by the selected table | See the named source selection |
| Flow Path Augmentation Options | 2024-isp-inputs-and-assumptions-workbook.xlsx — Flow Path Augmentation options!B11:N94 | Defined by the selected table | See the named source selection |
| Generator Emissions Intensity | 2024-isp-inputs-and-assumptions-workbook.xlsx — Emissions intensity!B7:D73 | Defined by the selected table | See the named source selection |
| Generator Maximum Ramp Rates | 2024-isp-inputs-and-assumptions-workbook.xlsx — Max Ramp Rates!B8:F72 | Defined by the selected table | See the named source selection |
| Generator Minimum Up Down Times | 2024-isp-inputs-and-assumptions-workbook.xlsx — Min Up&Down Times!B8:E25 | Defined by the selected table | See the named source selection |
| Generator Retirements | 2024-isp-inputs-and-assumptions-workbook.xlsx — Retirement!B9:D460 | Defined by the selected table | See the named source selection |
| Generator Summary Mapping | 2024-isp-inputs-and-assumptions-workbook.xlsx — Summary Mapping!B4:I680 | Defined by the selected table | See the named source selection |
| Generator Summary Mapping Mlf | 2024-isp-inputs-and-assumptions-workbook.xlsx — Summary Mapping!AA6:AA680 | Defined by the selected table | See the named source selection |
| Generator Summary Mapping Names | 2024-isp-inputs-and-assumptions-workbook.xlsx — Summary Mapping!B6:B680 | Defined by the selected table | See the named source selection |
| Gpg Minimum Stable Generation | 2024-isp-inputs-and-assumptions-workbook.xlsx — GPG Min Stable Level!B9:E34 | Defined by the selected table | See the named source selection |
| Hydro Scheme Inflows | 2024-isp-inputs-and-assumptions-workbook.xlsx — Hydro Scheme Inflows!B34:N47 | Defined by the selected table | Reference Year (FYE), Jul, Aug, Sep, Oct, Nov, Dec, Jan, Feb, Mar, Apr, May, Jun |
| Legacy Generator Minimum Up Time | 2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx — Generation limits!O9:Q69 | Defined by the selected table | Generator Station, Generating unit, Min Up Time (hours). Min Up Time (hours)=h |
| Network Capability | 2024-isp-inputs-and-assumptions-workbook.xlsx — Network Capability!B6:H21 | Defined by the selected table | See the named source selection |
| New Generator Reliability | 2024-isp-inputs-and-assumptions-workbook.xlsx — Generator Reliability Settings!I20:N40 | Defined by the selected table | See the named source selection |
| Pumped Storage Properties | 2024-isp-inputs-and-assumptions-workbook.xlsx — Storage properties!B22:K26 | Defined by the selected table | See the named source selection |
| Renewable Energy Zones | 2024-isp-inputs-and-assumptions-workbook.xlsx — Renewable Energy Zones!B7:G50 | Defined by the selected table | See the named source selection |
| Transmission Reliability | 2024-isp-inputs-and-assumptions-workbook.xlsx — Transmission Reliability!B7:G11 | Defined by the selected table | See the named source selection |
| Vpp Capacity Outlook | Auxiliary/StorageCapacityOutlook\_2024\_ISP.xlsx — {scenario}!A1:AG1769 | Defined by the selected table | See the named source selection |
| Vpp Energy Outlook | Auxiliary/StorageEnergyOutlook\_2024\_ISP.xlsx — {scenario}!A1:AG1769 | Defined by the selected table | See the named source selection |


## Electric-vehicle workbook

The 2023 IASR EV workbook contains vehicle numbers, charging shares, and
weekday and weekend charging profiles.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vehicle_rows = filter(row -> row.group == "Electric-vehicle workbook", source_rows)
reader_table(vehicle_rows)
````

```@raw html
</details>
```

| **Source** | **File and selection** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| EV Bev Phev Charge Type | 2023-iasr-ev-workbook.xlsx — BEV\_PHEV\_Charge\_Type (%)!B:BF | Defined by the selected table | See the named source selection |
| EV Bev Phev Profile Weekday | 2023-iasr-ev-workbook.xlsx — BEV\_PHEV\_Profile\_kW (Weekday)!B:AY | Defined by the selected table | See the named source selection |
| EV Bev Phev Profile Weekend | 2023-iasr-ev-workbook.xlsx — BEV\_PHEV\_Profile\_kW (Weekend)!B:AY | Defined by the selected table | See the named source selection |
| EV Vehicle Numbers | 2023-iasr-ev-workbook.xlsx — \*\_Numbers!B:AZ | Defined by the selected table | See the named source selection |


## Generation and storage outlook

Core outlook workbooks provide generation capacity, storage power, storage
energy, and renewable-energy-zone capacity tables.

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
| Core Capacity Outlook | Core/{core\_workbook} — Capacity!A3:AG5000 | Defined by the selected table | See the named source selection |
| Core REZ Generation Capacity | Core/{core\_workbook} — REZ Generation Capacity!A3:AG5000 | Defined by the selected table | See the named source selection |
| Core Storage Capacity Outlook | Core/{core\_workbook} — Storage Capacity!A3:AG5000 | Defined by the selected table | See the named source selection |
| Core Storage Energy Outlook | Core/{core\_workbook} — Storage Energy!A3:AG5000 | Defined by the selected table | See the named source selection |


## Model and trace files

Scenario models and trace collections provide demand, hydro, solar, wind,
distributed-PV, and reference-year time series.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_rows = filter(row -> row.group == "Model and trace files", source_rows)
reader_table(trace_rows)
````

```@raw html
</details>
```

| **Source** | **File and selection** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| Distributed PV Demand Trace | demand\_{subregion}\_{scenario}/{subregion}\_RefYear\_{reference\_year}\_{scenario\_code}\_POE{poe}\_PV\_TOT.csv — demand\_{subregion}\_{scenario}/{subregion}\_RefYear\_{reference\_year}\_{scenario\_code}\_POE{poe}\_PV\_TOT.csv | Year, Month, Day | Year, Month, Day |
| Existing Solar Trace | solar\_{reference\_year}/{generator\_file} — solar\_{reference\_year}/{generator\_file} | Year, Month, Day | Year, Month, Day |
| Existing Wind Trace | wind\_{reference\_year}/{generator\_file} — wind\_{reference\_year}/{generator\_file} | Year, Month, Day | Year, Month, Day |
| Hydro Annual Energy Limit Trace | 2024 ISP {scenario}/Traces/hydro/{file\_name}\_{hydro\_scenario}.csv — 2024 ISP {scenario}/Traces/hydro/{file\_name}\_{hydro\_scenario}.csv | Year | Year |
| Hydro Natural Inflow Trace | 2024 ISP {scenario}/Traces/hydro/{file\_name}\_{hydro\_scenario}.csv — 2024 ISP {scenario}/Traces/hydro/{file\_name}\_{hydro\_scenario}.csv | Year, Month, Day | Year, Month, Day, Inflows |
| Operational Demand Trace | demand\_{subregion}\_{scenario}/{subregion}\_RefYear\_{reference\_year}\_{scenario\_code}\_POE{poe}\_OPSO\_MODELLING\_PVLITE.csv — demand\_{subregion}\_{scenario}/{subregion}\_RefYear\_{reference\_year}\_{scenario\_code}\_POE{poe}\_OPSO\_MODELLING\_PVLITE.csv | Year, Month, Day | Year, Month, Day |
| Reference Year Trace | Traces/{technology}\_{reference\_year}/{trace\_file} — Traces/{technology}\_{reference\_year}/{trace\_file} | Year, Month, Day | Year, Month, Day |
| REZ Solar Trace | solar\_{reference\_year}/{rez\_trace\_file} — solar\_{reference\_year}/{rez\_trace\_file} | Year, Month, Day | Year, Month, Day |
| REZ Wind Trace | wind\_{reference\_year}/{rez\_trace\_file} — wind\_{reference\_year}/{rez\_trace\_file} | Year, Month, Day | Year, Month, Day |


## Compare editions

The [raw-source comparison](../../comparison/analyses/raw-source-comparison.md)
compares worksheet selections, fields, units, and source-family changes.
The [model archive comparison](../../comparison/analyses/model-archive-comparison.md)
compares scenario directories, model files, and trace folders.
