```@meta
EditURL = "../../../../literate/isp2026/validation/workbook_and_trace_structure.jl"
```

# ISP 2026: Workbook and trace structure

ISP 2026 source material combines the inputs and assumptions workbook, the
electric-vehicle workbook, generation and storage outlooks, scenario models,
and trace collections.
The tables below describe their workbook, model-archive, and trace structure.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using DataFrames
using TOML
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const PROFILE = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const SOURCE_MAP_PATH = joinpath(REPO_ROOT, "docs", "config", "isp2026-source-specs.toml")
const SOURCE_MAP = TOML.parsefile(SOURCE_MAP_PATH)
const SOURCE_SPECS = SOURCE_MAP["source"]

required_source_fields = Set([
    "id",
    "group",
    "format",
    "path",
    "selection",
    "keys",
    "fields_units",
])
all(source -> required_source_fields ⊆ keys(source), SOURCE_SPECS) || error(
    "every ISP 2026 source entry must define its file, selection, keys, fields, and units",
)

inputs_workbook = joinpath(PROFILE.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
ev_workbook = joinpath(PROFILE.download_root, "aemo-2025-iasr-ev-workbook.xlsx")
inputs_sheets = XLSX.openxlsx(inputs_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end
ev_sheets = XLSX.openxlsx(ev_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end

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
required_inputs_sheets ⊆ inputs_sheets || error(
    "the ISP 2026 inputs workbook is missing a documented worksheet",
)
required_ev_sheets ⊆ ev_sheets || error(
    "the ISP 2026 electric-vehicle workbook is missing a documented worksheet",
)

scenario_names = ["Accelerated Transition", "Slower Growth", "Step Change"]
trace_families = ["demand", "dnsp", "gas", "hydro", "load_subtractor", "rooftop PV"]
model_root = joinpath(PROFILE.download_root, "2026 ISP Model")
core_root = joinpath(PROFILE.download_root, "Core scenarios")
sensitivity_root = joinpath(PROFILE.download_root, "Sensitivities")
renewable_trace_root = joinpath(PROFILE.download_root, "Traces")
scenario_roots = [joinpath(model_root, "2026 ISP $scenario") for scenario in scenario_names]
scenario_trace_roots = [
    joinpath(model_root, "2026 ISP $scenario", "Traces", family)
    for scenario in scenario_names for family in trace_families
]
all(isdir, scenario_roots) || error("the ISP 2026 model archive is missing a scenario directory")
all(isdir, scenario_trace_roots) || error("an ISP 2026 scenario model is missing a documented trace folder")
isdir(core_root) || error("the ISP 2026 core scenario outlook directory was not found")
isdir(sensitivity_root) || error("the ISP 2026 sensitivity outlook directory was not found")
isdir(renewable_trace_root) || error("the ISP 2026 renewable trace directory was not found")
````

```@raw html
</details>
```

## Workbook structure

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
workbook_structure = DataFrame(
    source_collection = [
        "Inputs and assumptions workbook",
        "Electric-vehicle workbook",
        "Generation and storage outlook",
    ],
    files = [
        "2026-isp-inputs-and-assumptions-workbook.xlsm",
        "aemo-2025-iasr-ev-workbook.xlsx",
        "Core scenario and sensitivity workbooks",
    ],
    selections = [
        join(sort!(collect(required_inputs_sheets)), ", "),
        join(sort!(collect(required_ev_sheets)), ", "),
        "Capacity, Storage Capacity, Storage Energy, REZ Generation Capacity, and development-path tables",
    ],
)
PISPDocUtils.markdown_table(
    workbook_structure;
    column_labels = ["Source collection", "Files", "Selections"],
)
````

```@raw html
</details>
```

| **Source collection** | **Files** | **Selections** |
|:--|:--|:--|
| Inputs and assumptions workbook | 2026-isp-inputs-and-assumptions-workbook.xlsm | DSP, Data Centre Forecasts, Distribution network, Emissions intensity, Existing Gen Data Summary, Generator Reliability Settings, Hybrid site limits, Hydro Scheme Inflows, Maximum capacity, Retirement, Rooftop PV, Storage properties, Summary Mapping |
| Electric-vehicle workbook | aemo-2025-iasr-ev-workbook.xlsx | BEV\_Numbers, BEV\_PHEV\_Charge\_Type (%), BEV\_PHEV\_Consumption (GWh), BEV\_PHEV\_Profile\_kW (Weekday), BEV\_PHEV\_Profile\_kW (Weekend), FCEV\_Numbers, Hybrid\_Numbers, ICE\_Numbers, PHEV\_Numbers |
| Generation and storage outlook | Core scenario and sensitivity workbooks | Capacity, Storage Capacity, Storage Energy, REZ Generation Capacity, and development-path tables |


## Model archive structure

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
model_structure = DataFrame(
    source_collection = ["Scenario models", "Model trace folders", "Renewable trace collections"],
    files = [
        join(["2026 ISP $scenario" for scenario in scenario_names], ", "),
        "Traces inside each scenario model",
        "Separate solar and wind trace collections",
    ],
    selections = [
        "One scenario directory and model XML file per scenario",
        join(trace_families, ", "),
        "Project or region and reference-year label",
    ],
)
PISPDocUtils.markdown_table(
    model_structure;
    column_labels = ["Source collection", "Files", "Selections"],
)
````

```@raw html
</details>
```

| **Source collection** | **Files** | **Selections** |
|:--|:--|:--|
| Scenario models | 2026 ISP Accelerated Transition, 2026 ISP Slower Growth, 2026 ISP Step Change | One scenario directory and model XML file per scenario |
| Model trace folders | Traces inside each scenario model | demand, dnsp, gas, hydro, load\_subtractor, rooftop PV |
| Renewable trace collections | Separate solar and wind trace collections | Project or region and reference-year label |


## Trace schema

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_sources = filter(
    source -> source["group"] in ("Model trace folders", "Separate renewable trace archives"),
    SOURCE_SPECS,
)
trace_schema = DataFrame([
    (
        trace_family = titlecase(replace(replace(source["id"], "isp2026-" => ""), "-" => " ")),
        file_or_pattern = "$(source["path"]) — $(source["selection"])",
        keys = source["keys"],
        fields_units = source["fields_units"],
    )
    for source in trace_sources
])
PISPDocUtils.markdown_table(
    trace_schema;
    column_labels = ["Trace family", "File or pattern", "Keys", "Fields and units"],
)
````

```@raw html
</details>
```

| **Trace family** | **File or pattern** | **Keys** | **Fields and units** |
|:--|:--|:--|:--|
| Model Demand | 2026 ISP Model/2026 ISP {scenario}/Traces/demand/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | Demand time series in the file's stated units |
| Model Dnsp | 2026 ISP Model/2026 ISP {scenario}/Traces/dnsp/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | DNSP-level CER time series |
| Model Gas | 2026 ISP Model/2026 ISP {scenario}/Traces/gas/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day | Value column; filenames describe gas limits in TJ |
| Model Hydro | 2026 ISP Model/2026 ISP {scenario}/Traces/hydro/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day | Inflows column for daily files; file-specific hydro energy series |
| Model Load Subtractor | 2026 ISP Model/2026 ISP {scenario}/Traces/load\_subtractor/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | Load-subtractor time series |
| Model Rooftop Pv | 2026 ISP Model/2026 ISP {scenario}/Traces/rooftop PV/\*.csv — All CSV files in each scenario directory | Filename series, Year, Month, Day, half-hour columns 01 to 48 | Rooftop-PV time series |
| Model Timeslice | 2026 ISP Model/2026 ISP {scenario}/Traces/timeslice/timeslice\_RefYear5000.csv — Referenced by each scenario XML; file is not included in the extracted trace folders | Reference-year identifier from the XML file reference | Seasonal-timeslice classification described by the model instructions |
| Solar Traces | Traces/2026 ISP Solar traces/solar/\*.csv — All project CSV files | Project filename, Year, Month, Day, half-hour columns 01 to 48 | Solar availability time series |
| Wind Traces | Traces/2026 ISP Wind traces/wind/\*.csv — All project CSV files | Project filename, Year, Month, Day, half-hour columns 01 to 48 | Wind availability time series |


## Compare editions

The [raw-source comparison](../../comparison/analyses/raw-source-comparison.md)
compares workbook selections and schemas.
The [model archive comparison](../../comparison/analyses/model-archive-comparison.md)
compares scenario directories, model files, and trace folders.
