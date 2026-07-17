```@meta
EditURL = "../../../literate/validation/temperature_data_coverage.jl"
```

# Assessing temperature-related information and climate-zone variation

Temperature can affect demand, renewable output, thermal ratings, and equipment reliability, but those effects are not automatically represented by a planning dataset. This page loads the ISP assumptions workbook, PISP's own output files, and summer solar traces for selected climate-zone proxies, then builds the tables and figures that describe what temperature-related material is (and is not) present.

No observed temperature time series is loaded, and no causal temperature-response model is estimated. Climate-zone comparisons are descriptive solar-trace comparisons, not direct measurements of thermal derating.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using XLSX
using Printf
using Statistics
using Plots

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

EdaSupport.snapshot_metadata_line(
    REPO_ROOT;
    context = "2024 ISP inputs and assumptions workbook, 2024 ISP PISP output files (out-ref4006-poe10 schedule), and 2019 climate-zone summer solar traces",
)

const SCRIPT_STEM = "05_temperature_analysis"
const TRACES = joinpath("data", "2024", "pisp-downloads", "Traces")  # kept relative: this is the path form recorded in the tables below
const DOWNLOADS = joinpath("data", "2024", "pisp-downloads")  # kept relative, same reason as TRACES

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a relative path above to an absolute file location for reading

const TEMP_KEYWORDS = ["temp", "heat", "thermal", "derate", "pv", "solar", "wind", "rooftop", "inverter"]
const HH_COLS_SOL = string.(1:48)
const CLIMATE_ZONES = [
    ("Hot_Inland", "Bomen_SAT"),
    ("Hot_SA", "Cultana_SAT"),
    ("Moderate_VIC", "Bannerton_SAT"),
    ("Cool_TAS", "Derby_SAT"),
]

is_keyword_match(name) = any(kw -> occursin(kw, lowercase(name)), TEMP_KEYWORDS)
is_rooftop_match(name) = occursin("rooftop", lowercase(name)) || occursin("rtpv", lowercase(name))
function is_reliability_match(name)
    lname = lowercase(name)
    return occursin("reliability", lname) || occursin("outage", lname) || occursin("generator", lname)
end
````

```@raw html
</details>
```

````
Snapshot: PISP.jl commit bba8297+dirty, generated 2026-07-17 — 2024 ISP inputs and assumptions workbook, 2024 ISP PISP output files (out-ref4006-poe10 schedule), and 2019 climate-zone summer solar traces

````

Trim a raw XLSX matrix down to the bounding box of non-missing cells. A worksheet's declared dimension (and hence XLSX.jl's `sheet[:]`) can report extra trailing all-empty rows/columns beyond the sheet's real content, so this drops trailing rows/columns that hold no value before reporting a sheet's shape. Verified against this workbook: e.g. "Rooftop PV" has a raw shape of (64, 35) but a trimmed shape of (62, 33) — rows 63-64 and columns 34-35 are entirely `missing`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function trim_sheet(matrix)
    nrows, ncols = size(matrix)
    last_row = 0
    for r in 1:nrows
        if any(x -> x !== missing, view(matrix, r, :))
            last_row = r
        end
    end
    last_col = 0
    for c in 1:ncols
        if any(x -> x !== missing, view(matrix, :, c))
            last_col = c
        end
    end
    (last_row == 0 || last_col == 0) && return Matrix{Any}(undef, 0, 0)
    return matrix[1:last_row, 1:last_col]
end
````

```@raw html
</details>
```

A blank header cell gets a placeholder name using its 0-based column index.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function header_names(row)
    return [ismissing(v) ? "Unnamed: $(j - 1)" : string(v) for (j, v) in enumerate(row)]
end

function empty_df(schema::Vector{Pair{Symbol, DataType}})
    return DataFrame([name => Type[] for (name, Type) in schema]...)
end
````

```@raw html
</details>
```

## Step 1 — inventory the ISP assumptions workbook's sheets

The workbook lists all its worksheets; a keyword match identifies material for review, it does not by itself prove that a sheet contains a usable temperature dependency.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
workbook_path = joinpath(DOWNLOADS, "2024-isp-inputs-and-assumptions-workbook.xlsx")
println("Workbook exists: ", isfile(abs_path(workbook_path)))

sheet_inventory_rows = NamedTuple[]
relevant_shape_rows = NamedTuple[]
rooftop_rows = NamedTuple[]
reliability_shape_rows = NamedTuple[]

if isfile(abs_path(workbook_path))
    XLSX.openxlsx(abs_path(workbook_path)) do xf
        sheet_names = XLSX.sheetnames(xf)
        println("\n=== ISP Assumptions Workbook Sheets ($(length(sheet_names))) ===")
        for (i, name) in enumerate(sheet_names)
            println(@sprintf("  %2d. %s", i, name))
        end

        println("\n=== Potentially Relevant Sheets ===")
        for name in sheet_names
            is_keyword_match(name) && println("  - ", name)
        end

        for (i, name) in enumerate(sheet_names)
            push!(
                sheet_inventory_rows,
                (
                    sheet_index = i,
                    sheet_name = name,
                    is_keyword_match = is_keyword_match(name) ? 1 : 0,
                    is_rooftop_match = is_rooftop_match(name) ? 1 : 0,
                    is_reliability_match = is_reliability_match(name) ? 1 : 0,
                ),
            )
        end

        relevant_sheets = [name for name in sheet_names if is_keyword_match(name)]

        for sheet in first(relevant_sheets, min(10, length(relevant_sheets)))
            m = trim_sheet(xf[sheet][:])
            n_rows, n_cols = size(m)
            println("\n--- Sheet: $sheet (shape: ($n_rows, $n_cols)) ---")
            push!(relevant_shape_rows, (sheet_name = sheet, n_rows = n_rows, n_cols = n_cols, read_ok = 1))
        end

        for sheet in sheet_names
            if is_rooftop_match(sheet)
                m = trim_sheet(xf[sheet][:])
                total_rows, n_cols = size(m)
                n_rows = max(total_rows - 1, 0)
                cols = total_rows > 0 ? header_names(m[1, :]) : String[]
                println("\n=== Rooftop PV Sheet ($sheet) ===")
                println("Columns: ", cols)
                push!(
                    rooftop_rows,
                    (
                        sheet_name = sheet,
                        n_rows = n_rows,
                        n_cols = n_cols,
                        columns_preview = join(cols[1:min(5, length(cols))], "|"),
                    ),
                )
            end
        end

        for sheet in sheet_names
            if is_reliability_match(sheet)
                m = trim_sheet(xf[sheet][:])
                n_rows, n_cols = size(m)
                println("\n=== Reliability Sheet: $sheet (shape: ($n_rows, $n_cols)) ===")
                push!(reliability_shape_rows, (sheet_name = sheet, n_rows = n_rows, n_cols = n_cols))
            end
        end
    end
end

workbook_sheet_inventory = isempty(sheet_inventory_rows) ?
    empty_df([:sheet_index => Int, :sheet_name => String, :is_keyword_match => Int, :is_rooftop_match => Int, :is_reliability_match => Int]) :
    DataFrame(sheet_inventory_rows)
write_table(workbook_sheet_inventory, SCRIPT_STEM, "workbook_sheet_inventory")
markdown_table(workbook_sheet_inventory)
````

```@raw html
</details>
```

| **sheet\_index** | **sheet\_name** | **is\_keyword\_match** | **is\_rooftop\_match** | **is\_reliability\_match** |
|--:|--:|--:|--:|--:|
| 1 | Disclaimer | 0 | 0 | 0 |
| 2 | Change Log | 0 | 0 | 0 |
| 3 | Assumptions Summary | 0 | 0 | 0 |
| 4 | Scenarios | 0 | 0 | 0 |
| 5 | Renewable Energy Zones | 0 | 0 | 0 |
| 6 | New Entrant Data Summary | 0 | 0 | 0 |
| 7 | Existing Gen Data Summary | 0 | 0 | 0 |
| 8 | Fuel Price Summary | 0 | 0 | 0 |
| 9 | Regional Build Costs Summary | 0 | 0 | 0 |
| 10 | Energy Policy Targets | 0 | 0 | 0 |
| 11 | Carbon Budgets | 0 | 0 | 0 |
| 12 | Demand and Energy Forecasts | 0 | 0 | 0 |
| 13 | DSP | 0 | 0 | 0 |
| 14 | Economic Growth Forecasts | 0 | 0 | 0 |
| 15 | Energy Efficiency | 0 | 0 | 0 |
| 16 | Rooftop PV | 1 | 1 | 0 |
| 17 | PVNSG | 1 | 0 | 0 |
| 18 | Battery & Plug-in EVs | 0 | 0 | 0 |
| 19 | Fuel cell EVs | 0 | 0 | 0 |
| 20 | EV V2G | 0 | 0 | 0 |
| 21 | Electrification | 0 | 0 | 0 |
| 22 | Embedded energy storages | 0 | 0 | 0 |
| 23 | Aggregated energy storages | 0 | 0 | 0 |
| 24 | Sub-regional demand allocation | 0 | 0 | 0 |
| 25 | Network representation | 0 | 0 | 0 |
| 26 | Network losses | 0 | 0 | 0 |
| 27 | Network Capability | 0 | 0 | 0 |
| 28 | Flow Path Augmentation options | 0 | 0 | 0 |
| 29 | Flow Path costs forecast | 0 | 0 | 0 |
| 30 | Transmission Reliability | 0 | 0 | 1 |
| 31 | Maximum capacity | 0 | 0 | 0 |
| 32 | Seasonal ratings | 0 | 0 | 0 |
| 33 | Reserves | 0 | 0 | 0 |
| 34 | Generation limits | 0 | 0 | 0 |
| 35 | Maintenance | 0 | 0 | 0 |
| 36 | Generator Reliability Settings | 0 | 0 | 1 |
| 37 | Hydro Climate Factor | 0 | 0 | 0 |
| 38 | Hydro Scheme Inflows | 0 | 0 | 0 |
| 39 | Build costs | 0 | 0 | 0 |
| 40 | Locational Cost Factors | 0 | 0 | 0 |
| 41 | Lead time and project life | 0 | 0 | 0 |
| 42 | Financial parameters | 0 | 0 | 0 |
| 43 | Capacity Factors  | 0 | 0 | 0 |
| 44 | Connection cost | 0 | 0 | 0 |
| 45 | Connection Costs forecast | 0 | 0 | 0 |
| 46 | REZ Augmentations Options | 0 | 0 | 0 |
| 47 | REZ Costs forecast | 0 | 0 | 0 |
| 48 | Non-REZ Assumptions | 0 | 0 | 0 |
| 49 | Build limits - PHES | 0 | 0 | 0 |
| 50 | Build limits | 0 | 0 | 0 |
| 51 | Power System Constraints | 0 | 0 | 0 |
| 52 | Storage properties | 0 | 0 | 0 |
| 53 | Coal and Biomass price | 0 | 0 | 0 |
| 54 | Gas, Liquid fuel, H2 price | 0 | 0 | 0 |
| 55 | Retirement | 0 | 0 | 0 |
| 56 | Heat rates | 1 | 0 | 0 |
| 57 | Auxiliary | 0 | 0 | 0 |
| 58 | Fixed OPEX | 0 | 0 | 0 |
| 59 | Variable OPEX | 0 | 0 | 0 |
| 60 | Emissions intensity | 0 | 0 | 0 |
| 61 | H2 GPG\_emissions reduction  | 0 | 0 | 0 |
| 62 | GPG emissions reduction - BioM | 0 | 0 | 0 |
| 63 | Marginal Loss Factors | 0 | 0 | 0 |
| 64 | Affine Heat rates | 1 | 0 | 0 |
| 65 | Max Ramp Rates | 0 | 0 | 0 |
| 66 | CCGT Unit Max Capacity | 0 | 0 | 0 |
| 67 | GPG Min Stable Level | 0 | 0 | 0 |
| 68 | Min Up&Down Times | 0 | 0 | 0 |
| 69 | Costs Summary - PEM | 0 | 0 | 0 |
| 70 | Build Costs - PEM | 0 | 0 | 0 |
| 71 | Hydrogen demand - Domestic | 0 | 0 | 0 |
| 72 | Hydrogen demand\_Export&Steel | 0 | 0 | 0 |
| 73 | Hydrogen monthly profiles | 0 | 0 | 0 |
| 74 | Hydrogen export ports | 0 | 0 | 0 |
| 75 | Other hydrogen assumptions | 0 | 0 | 0 |
| 76 | Summary Mapping | 0 | 0 | 0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
workbook_relevant_sheet_shapes = isempty(relevant_shape_rows) ?
    empty_df([:sheet_name => String, :n_rows => Int, :n_cols => Int, :read_ok => Int]) :
    DataFrame(relevant_shape_rows)
write_table(workbook_relevant_sheet_shapes, SCRIPT_STEM, "workbook_relevant_sheet_shapes")
markdown_table(workbook_relevant_sheet_shapes)
````

```@raw html
</details>
```

| **sheet\_name** | **n\_rows** | **n\_cols** | **read\_ok** |
|--:|--:|--:|--:|
| Rooftop PV | 62 | 33 | 1 |
| PVNSG | 62 | 33 | 1 |
| Heat rates | 70 | 7 | 1 |
| Affine Heat rates | 194 | 11 | 1 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
workbook_rooftop_sheet_summary = isempty(rooftop_rows) ?
    empty_df([:sheet_name => String, :n_rows => Int, :n_cols => Int, :columns_preview => String]) :
    DataFrame(rooftop_rows)
write_table(workbook_rooftop_sheet_summary, SCRIPT_STEM, "workbook_rooftop_sheet_summary")
markdown_table(workbook_rooftop_sheet_summary)
````

```@raw html
</details>
```

| **sheet\_name** | **n\_rows** | **n\_cols** | **columns\_preview** |
|--:|--:|--:|--:|
| Rooftop PV | 61 | 33 | Unnamed: 0\|Go to Assumptions Summary\|Unnamed: 2\|Unnamed: 3\|Unnamed: 4 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
workbook_reliability_sheet_shapes = isempty(reliability_shape_rows) ?
    empty_df([:sheet_name => String, :n_rows => Int, :n_cols => Int]) :
    DataFrame(reliability_shape_rows)
write_table(workbook_reliability_sheet_shapes, SCRIPT_STEM, "workbook_reliability_sheet_shapes")
markdown_table(workbook_reliability_sheet_shapes)
````

```@raw html
</details>
```

| **sheet\_name** | **n\_rows** | **n\_cols** |
|--:|--:|--:|
| Transmission Reliability | 11 | 7 |
| Generator Reliability Settings | 64 | 14 |


## Step 2 — which temperature-related fields reach the PISP output dataset?

The output inventory and generator-column table distinguish information present in the downloaded workbook from fields actually exported by PISP.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
csv_dir = joinpath("data", "2024", "pisp-datasets", "out-ref4006-poe10", "csv")
sched_dir = joinpath("data", "2024", "pisp-datasets", "out-ref4006-poe10")

output_inventory_rows = NamedTuple[]
println("\n=== PISP Output Files ===")
if isdir(abs_path(csv_dir))
    for name in sort(filter(n -> endswith(lowercase(n), ".csv"), readdir(abs_path(csv_dir))))
        println("  CSV: ", name)
        push!(output_inventory_rows, (kind = "csv", name = name))
    end
end

if isdir(abs_path(sched_dir))
    for name in sort(filter(n -> startswith(n, "schedule-"), readdir(abs_path(sched_dir))))
        if isdir(abs_path(joinpath(sched_dir, name)))
            println("  Schedule: ", name)
            push!(output_inventory_rows, (kind = "schedule", name = name))
        end
    end
end

pisp_output_inventory = isempty(output_inventory_rows) ? empty_df([:kind => String, :name => String]) : DataFrame(output_inventory_rows)
write_table(pisp_output_inventory, SCRIPT_STEM, "pisp_output_inventory")
markdown_table(pisp_output_inventory)
````

```@raw html
</details>
```

| **kind** | **name** |
|--:|--:|
| csv | Bus.csv |
| csv | DER.csv |
| csv | Demand.csv |
| csv | ESS.csv |
| csv | Generator.csv |
| csv | Line.csv |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
gen_path = joinpath(csv_dir, "Generator.csv")
generator_details_rows = NamedTuple[]
generator_temp_row = (generator_table_exists = 0, total_columns = missing, n_temp_columns = missing, temp_columns_list = "")

if isfile(abs_path(gen_path))
    gen_df = CSV.read(abs_path(gen_path), DataFrame)
    println("\n=== Generator Table (shape: $(size(gen_df))) ===")
    println("Columns: ", names(gen_df))

    is_solar(tech) = occursin(r"PV|SOLAR|DISTPV"i, tech)
    is_wind(tech) = occursin(r"WIND"i, tech)
    solar_gens = filter(row -> is_solar(row.tech), gen_df)
    wind_gens = filter(row -> is_wind(row.tech), gen_df)

    println("\nSolar generators: ", nrow(solar_gens))
    println("\nWind generators: ", nrow(wind_gens))

    for (category, subset) in (("solar", solar_gens), ("wind", wind_gens))
        for row in eachrow(subset)
            push!(
                generator_details_rows,
                (
                    category = category,
                    id_gen = row.id_gen,
                    name = row.name,
                    tech = row.tech,
                    forate = row.forate,
                    derate = row.derate,
                    pmin = row.pmin,
                    pmax = row.pmax,
                    n = row.n,
                ),
            )
        end
    end

    temp_cols = [col for col in names(gen_df) if any(kw -> occursin(kw, lowercase(col)), ["temp", "heat", "thermal"])]
    println("\nTemperature-related columns in Generator: ", temp_cols)
    generator_temp_row = (
        generator_table_exists = 1,
        total_columns = ncol(gen_df),
        n_temp_columns = length(temp_cols),
        temp_columns_list = join(temp_cols, "|"),
    )
end

generator_solar_wind_details = isempty(generator_details_rows) ?
    empty_df([:category => String, :id_gen => Int, :name => String, :tech => String, :forate => Float64, :derate => Float64, :pmin => Float64, :pmax => Float64, :n => Int]) :
    DataFrame(generator_details_rows)
write_table(generator_solar_wind_details, SCRIPT_STEM, "generator_solar_wind_details")
markdown_table(generator_solar_wind_details)
````

```@raw html
</details>
```

| **category** | **id\_gen** | **name** | **tech** | **forate** | **derate** | **pmin** | **pmax** | **n** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| solar | 92 | RTPV\_NQ | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 93 | RTPV\_CQ | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 94 | RTPV\_GG | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 95 | RTPV\_SQ | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 96 | RTPV\_NNSW | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 97 | RTPV\_CNSW | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 98 | RTPV\_SNW | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 99 | RTPV\_SNSW | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 100 | RTPV\_VIC | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 101 | RTPV\_TAS | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 102 | RTPV\_CSA | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 103 | RTPV\_SESA | RoofPV | 1.0 | 0.0 | 0.0 | 100.0 | 1 |
| solar | 104 | LSPV\_CQ | LargePV | 1.0 | 0.0 | 0.0 | 869.9 | 1 |
| solar | 105 | LSPV\_VIC | LargePV | 1.0 | 0.0 | 0.0 | 1313.68 | 1 |
| solar | 106 | LSPV\_NNSW | LargePV | 1.0 | 0.0 | 0.0 | 721.0 | 1 |
| solar | 107 | LSPV\_SQ | LargePV | 1.0 | 0.0 | 0.0 | 2042.66 | 1 |
| solar | 108 | LSPV\_CSA | LargePV | 1.0 | 0.0 | 0.0 | 648.04 | 1 |
| solar | 109 | LSPV\_NQ | LargePV | 1.0 | 0.0 | 0.0 | 599.97 | 1 |
| solar | 110 | LSPV\_SNSW | LargePV | 1.0 | 0.0 | 0.0 | 2345.46 | 1 |
| solar | 111 | LSPV\_CNSW | LargePV | 1.0 | 0.0 | 0.0 | 2053.78 | 1 |
| solar | 112 | LSPV\_TAS | LargePV | 1.0 | 0.0 | 0.0 | 0.0 | 1 |
| solar | 113 | LSPV\_SESA | LargePV | 1.0 | 0.0 | 0.0 | 42.9 | 1 |
| wind | 114 | WIND\_CQ | Wind | 1.0 | 0.0 | 0.0 | 450.0 | 1 |
| wind | 115 | WIND\_VIC | Wind | 1.0 | 0.0 | 0.0 | 5362.16 | 1 |
| wind | 116 | WIND\_NNSW | Wind | 1.0 | 0.0 | 0.0 | 442.48 | 1 |
| wind | 117 | WIND\_SQ | Wind | 1.0 | 0.0 | 0.0 | 877.88 | 1 |
| wind | 118 | WIND\_CSA | Wind | 1.0 | 0.0 | 0.0 | 2435.99 | 1 |
| wind | 119 | WIND\_NQ | Wind | 1.0 | 0.0 | 0.0 | 380.52 | 1 |
| wind | 120 | WIND\_SNSW | Wind | 1.0 | 0.0 | 0.0 | 1873.85 | 1 |
| wind | 121 | WIND\_CNSW | Wind | 1.0 | 0.0 | 0.0 | 507.24 | 1 |
| wind | 122 | WIND\_TAS | Wind | 1.0 | 0.0 | 0.0 | 563.35 | 1 |
| wind | 123 | WIND\_SESA | Wind | 1.0 | 0.0 | 0.0 | 324.5 | 1 |
| wind | 124 | WIND\_SNW | Wind | 1.0 | 0.0 | 0.0 | 0.0 | 1 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
generator_temperature_columns = DataFrame([generator_temp_row])
write_table(generator_temperature_columns, SCRIPT_STEM, "generator_temperature_columns")
markdown_table(generator_temperature_columns)
````

```@raw html
</details>
```

| **generator\_table\_exists** | **total\_columns** | **n\_temp\_columns** | **temp\_columns\_list** |
|--:|--:|--:|--:|
| 1 | 48 | 0 |  |


## Step 3 — how do selected climate-zone solar traces differ in summer?

The zone labels are analytical groupings attached to representative sites. The summary describes summer solar capacity-factor distributions and does not isolate temperature from cloud, season, geography, or trace construction.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
zone_summary_rows = NamedTuple[]
println("\n=== Solar CF by Climate Zone (Summer 2019) ===")
for (zone, loc) in CLIMATE_ZONES
    f = joinpath(TRACES, "solar_2019", "$(loc)_RefYear2019.csv")
    isfile(abs_path(f)) || continue
    df = CSV.read(abs_path(f), DataFrame)
    summer = filter(row -> row.Month in (12, 1, 2), df)
    nrow(summer) == 0 && continue

    daily = [mean(row[col] for col in HH_COLS_SOL) for row in eachrow(summer)]
    midday_cols = string.(24:35)
    midday = [mean(row[col] for col in midday_cols) for row in eachrow(summer)]

    mean_daily = mean(daily)
    mean_midday = mean(midday)
    min_midday = minimum(midday)
    p5_midday = quantile(midday, 0.05)

    println(
        @sprintf(
            "  %s (%s): mean_daily=%.3f, mean_midday=%.3f, min_midday=%.3f, p5_midday=%.3f",
            zone, loc, mean_daily, mean_midday, min_midday, p5_midday,
        ),
    )

    push!(
        zone_summary_rows,
        (
            zone = zone,
            location = loc,
            n_summer_days = nrow(summer),
            mean_daily_cf = mean_daily,
            mean_midday_cf = mean_midday,
            min_midday_cf = min_midday,
            p5_midday_cf = p5_midday,
        ),
    )
end

climate_zone_summer_cf_summary = isempty(zone_summary_rows) ?
    empty_df([:zone => String, :location => String, :n_summer_days => Int, :mean_daily_cf => Float64, :mean_midday_cf => Float64, :min_midday_cf => Float64, :p5_midday_cf => Float64]) :
    DataFrame(zone_summary_rows)
write_table(climate_zone_summer_cf_summary, SCRIPT_STEM, "climate_zone_summer_cf_summary")
markdown_table(climate_zone_summer_cf_summary)
````

```@raw html
</details>
```

| **zone** | **location** | **n\_summer\_days** | **mean\_daily\_cf** | **mean\_midday\_cf** | **min\_midday\_cf** | **p5\_midday\_cf** |
|--:|--:|--:|--:|--:|--:|--:|
| Hot\_Inland | Bomen\_SAT | 3068 | 0.379055 | 0.771988 | 0.054019 | 0.219576 |
| Hot\_SA | Cultana\_SAT | 3068 | 0.37932 | 0.847259 | 0.230202 | 0.303985 |
| Moderate\_VIC | Bannerton\_SAT | 3068 | 0.404872 | 0.859197 | 0.1881 | 0.307869 |
| Cool\_TAS | Derby\_SAT | 3068 | 0.387393 | 0.810406 | 0.0913513 | 0.321397 |


## Step 4 — plot the summer daily capacity-factor distribution by climate zone

Each climate zone's summer daily-mean capacity factor is drawn as an overlaid density histogram, showing how much the four representative sites overlap or diverge.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p1 = plot(legend=:topright, title="Summer 2019 — Daily Solar CF Distribution by Climate Zone",
          xlabel="Daily Mean Capacity Factor", ylabel="Density", size=(800, 600))
for (zone, loc) in CLIMATE_ZONES
    f = joinpath(TRACES, "solar_2019", "$(loc)_RefYear2019.csv")
    isfile(abs_path(f)) || continue
    df = CSV.read(abs_path(f), DataFrame)
    summer = filter(row -> row.Month in (12, 1, 2), df)
    nrow(summer) == 0 && continue
    daily = [mean(row[col] for col in HH_COLS_SOL) for row in eachrow(summer)]
    histogram!(p1, daily, bins=50, alpha=0.5, label="$(zone) ($(loc))", normalize=:pdf)
end
savefig(p1, figure_path(SCRIPT_STEM, "05_cf_by_climate_zone.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "05_cf_by_climate_zone.png"), "05_cf_by_climate_zone.png")
````

```@raw html
</details>
```

![Summer daily solar capacity-factor distribution by climate zone](05_cf_by_climate_zone.png)

## Step 5 — plot midday capacity factor against daily mean capacity factor

For each climate zone, midday-mean capacity factor is plotted against daily-mean capacity factor for every summer day, with a 1:1 reference line showing how far midday output sits above the daily average.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p2 = plot(layout=(2,2), figsize=(14,10), size=(1000, 800))
for (idx, (zone, loc)) in enumerate(CLIMATE_ZONES)
    f = joinpath(TRACES, "solar_2019", "$(loc)_RefYear2019.csv")
    isfile(abs_path(f)) || continue
    df = CSV.read(abs_path(f), DataFrame)
    summer = filter(row -> row.Month in (12, 1, 2), df)
    nrow(summer) == 0 && continue
    daily = [mean(row[col] for col in HH_COLS_SOL) for row in eachrow(summer)]
    midday = [mean(row[col] for col in string.(24:35)) for row in eachrow(summer)]
    scatter!(p2[idx], daily, midday, markersize=2, alpha=0.3, color=:orange, label="", legend=false)
    plot!(p2[idx], [0, 0.5], [0, 0.5], label="1:1", color=:black, linestyle=:dash, alpha=0.3, linewidth=1)
    plot!(p2[idx], title="$(zone) ($(loc))", xlabel="Daily Mean CF", ylabel="Midday Mean CF",
          xlim=(0, 0.5), ylim=(0, 0.8), grid=true, gridstyle=:dash, gridalpha=0.3)
end
savefig(p2, figure_path(SCRIPT_STEM, "05_midday_vs_daily_scatter.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "05_midday_vs_daily_scatter.png"), "05_midday_vs_daily_scatter.png")
````

```@raw html
</details>
```

![Midday capacity factor against daily mean capacity factor by climate zone](05_midday_vs_daily_scatter.png)

## Summary

- The ISP assumptions workbook and PISP's own output files contain some temperature-, derating-, and reliability-adjacent fields, but a keyword match only flags material for review, it does not establish a usable temperature dependency.
- No observed temperature series is loaded here; the climate-zone comparison is a descriptive summer solar-trace comparison across four representative sites, not a measurement of thermal derating.

