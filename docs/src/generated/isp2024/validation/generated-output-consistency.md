```@meta
EditURL = "../../../../literate/isp2024/validation/generated_output_consistency.jl"
```

# ISP 2024: Generated-output consistency

PISP writes a static asset dataset (`Generator.csv`, `Demand.csv`, `Bus.csv`) alongside time-varying schedules (`Generator_pmax_sched.csv`, `Demand_load_sched.csv`) for one generated build. This page loads one such build, joins the static and schedule tables, and checks identifier coverage, schedule coverage, generator classification, and daily solar/wind/demand alignment, computed live on this page and written to `eda/tables/julia/06_pisp_outputs/` as evidence. It also builds the three PISP-output figures shown in the generated docs site.

By default it reads `data/2024/pisp-datasets/out-ref4006-poe10/csv/` and `schedule-2030/`; set `PISP_DOCS_ISP2024_OUTPUT_ROOT` or `PISP_DOCS_ISP2024_SCHEDULE_TAG` to select another local generated build.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Printf
using Statistics
using Plots

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_06_pisp_outputs"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const OUTPUT_ROOT = ISP2024_PROFILE.output_root
OUTPUT_ROOT === nothing && error(
    "ISP 2024 profile does not define output_root; set PISP_DOCS_ISP2024_OUTPUT_ROOT to select a local output build.",
)
const OUT = normpath(OUTPUT_ROOT)
const SCHEDULE_TAG = ISP2024_PROFILE.schedule_tag
SCHEDULE_TAG === nothing && error(
    "ISP 2024 profile does not define schedule_tag; set PISP_DOCS_ISP2024_SCHEDULE_TAG to select a local schedule.",
)
const SCHEDULE_DIR = joinpath(OUT, SCHEDULE_TAG)

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # no-op here since OUT/SCHEDULE_DIR are already absolute; kept for consistency with the other EDA pages

const AREA_NAMES = Dict(1 => "QLD", 2 => "NSW", 3 => "VIC", 4 => "TAS", 5 => "SA")
````

```@raw html
</details>
```

Schedule dates look like "2030-01-01T00:00:00.0"; this fallback handles the case where the column is read back as text rather than the DateTime CSV.jl already infers.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
parse_schedule_datetime(s::AbstractString) = DateTime(replace(s, r"\.\d+$" => ""))
parse_schedule_datetime(d::DateTime) = d

is_solar_tech(tech) = occursin(r"PV|SOLAR"i, tech)
is_wind_tech(tech) = occursin(r"WIND"i, tech)

function append_relationship_diagnostics!(summary_rows, detail_rows, relationship, left_label, right_label, left_ids, right_ids)
    left_set = Set(skipmissing(left_ids))
    right_set = Set(skipmissing(right_ids))
    left_unmatched = sort(collect(setdiff(left_set, right_set)))
    right_unmatched = sort(collect(setdiff(right_set, left_set)))

    push!(
        summary_rows,
        (
            relationship = relationship,
            left_label = left_label,
            right_label = right_label,
            left_unique_ids = length(left_set),
            right_unique_ids = length(right_set),
            left_unmatched_ids = length(left_unmatched),
            right_unmatched_ids = length(right_unmatched),
        ),
    )

    for id in left_unmatched
        push!(detail_rows, (relationship = relationship, unmatched_side = left_label, id = string(id)))
    end
    for id in right_unmatched
        push!(detail_rows, (relationship = relationship, unmatched_side = right_label, id = string(id)))
    end
end
````

```@raw html
</details>
```

Capacity factor for solar and wind divides each generator's scheduled mean output by that generator's own scheduled maximum, not by the static `pmax` recorded in `Generator.csv`.
The static field is not a reliable capacity reference for these generators: rooftop PV rows carry a fixed placeholder pmax (src/parsers/PISP-2024parser.jl:1070, `gen_pmax_distpv`), and utility-scale solar/wind rows record only currently operating capacity, which a future-year schedule can exceed once ISP-outlook build-out is reflected in the trace (`gen_pmax_wind`, ~1386 vs. ~1477 in the same file).
SiennaNEM.jl, which builds unit-commitment models from this same PISP output, applies the same convention (src/read_data.jl:214-229, `update_system_data_bound!`) and calls the static pmax "dummy" for these generators (src/create_system.jl:342,368).
See PISP.jl's own the generated Parameters and mappings page and docs/src/assumptions.md for the full caveat.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function capacity_factor_duration_frame(gen_pmax::DataFrame, gens::DataFrame, tech::AbstractString)
    ids = Set(gens.id_gen)

    sched = gen_pmax[in.(gen_pmax.id_gen, Ref(ids)), :]
    grouped = combine(groupby(sched, :id_gen), :value => mean => :mean_value, :value => maximum => :max_value)

    cf_values = Float64[]
    for row in eachrow(grouped)
        cf = row.mean_value / row.max_value
        isnan(cf) && continue
        push!(cf_values, cf)
    end
    sorted_desc = sort(cf_values; rev = true)
    return DataFrame(tech = tech, rank = 1:length(sorted_desc), capacity_factor = sorted_desc)
end

function build_dem_load_full(dem_load::DataFrame, dem_df::DataFrame, bus_df::DataFrame)
    area_map = Dict(row.id_bus => row.id_area for row in eachrow(bus_df))
    dem_load_full = innerjoin(dem_load, dem_df[:, [:id_dem, :id_bus]], on = :id_dem)
    dem_load_full.datetime = parse_schedule_datetime.(dem_load_full.date)
    dem_load_full.area = [area_map[b] for b in dem_load_full.id_bus]
    dem_load_full.area_name = [AREA_NAMES[a] for a in dem_load_full.area]
    return dem_load_full
end

function build_gen_pmax_ts(gen_pmax::DataFrame, gen_df::DataFrame)
    gen_pmax_ts = innerjoin(gen_pmax, gen_df[:, [:id_gen, :tech]], on = :id_gen)
    gen_pmax_ts.datetime = parse_schedule_datetime.(gen_pmax_ts.date)
    return gen_pmax_ts
end

function daily_tech_sum(gen_pmax_ts::DataFrame, tech_predicate)
    subset = gen_pmax_ts[tech_predicate.(gen_pmax_ts.tech), :]
    subset = transform(subset, :datetime => ByRow(Date) => :date_only)
    return combine(groupby(subset, :date_only), :value => sum => :total)
end
````

```@raw html
</details>
```

## Step 1 — load the static asset tables and the 2030 schedule outputs

`Generator.csv`, `Demand.csv`, and `Bus.csv` describe the static network; `Generator_pmax_sched.csv` and `Demand_load_sched.csv` under the `schedule-2030` tag describe the time-varying build for this generated dataset.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
gen_df = CSV.read(abs_path(joinpath(OUT, "Generator.csv")), DataFrame)
dem_df = CSV.read(abs_path(joinpath(OUT, "Demand.csv")), DataFrame)
bus_df = CSV.read(abs_path(joinpath(OUT, "Bus.csv")), DataFrame)

gen_pmax = CSV.read(abs_path(joinpath(SCHEDULE_DIR, "Generator_pmax_sched.csv")), DataFrame)
dem_load = CSV.read(abs_path(joinpath(SCHEDULE_DIR, "Demand_load_sched.csv")), DataFrame)
````

```@raw html
</details>
```

## Step 2 — record which output root and schedule directory were used

The recorded paths are relative to the repository root so this evidence table stays comparable across machines and reproducible from any checkout.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
build_metadata = DataFrame([
    (
        pisp_output_root = replace(relpath(OUT, REPO_ROOT), '\\' => '/'),
        schedule_tag = SCHEDULE_TAG,
        schedule_directory = replace(relpath(SCHEDULE_DIR, REPO_ROOT), '\\' => '/'),
    ),
])
write_table(build_metadata, SCRIPT_STEM, "build_metadata")
markdown_table(build_metadata)
````

```@raw html
</details>
```

| **pisp\_output\_root** | **schedule\_tag** | **schedule\_directory** |
|--:|--:|--:|
| data/2024/pisp-datasets/out-ref4006-poe10/csv | schedule-2030 | data/2024/pisp-datasets/out-ref4006-poe10/csv/schedule-2030 |


## Step 3 — generator table shape and classification counts

`Generator.csv` classifies each generator by `fuel` and by `tech`; these counts show which classifications are available for later technology-specific filtering.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
println("=== Generator Table ===")
println("Shape: ", (nrow(gen_df), ncol(gen_df)))

generator_fuel_counts = combine(groupby(gen_df, :fuel), nrow => :count)
write_table(generator_fuel_counts, SCRIPT_STEM, "generator_fuel_counts")
markdown_table(generator_fuel_counts)
````

```@raw html
</details>
```

| **fuel** | **count** |
|--:|--:|
| Coal | 15 |
| Diesel | 7 |
| Hydro | 30 |
| Hydrogen | 2 |
| Natural Gas | 37 |
| Solar | 22 |
| Wind | 11 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
generator_tech_counts = combine(groupby(gen_df, :tech), nrow => :count)
write_table(generator_tech_counts, SCRIPT_STEM, "generator_tech_counts")
markdown_table(generator_tech_counts)
````

```@raw html
</details>
```

| **tech** | **count** |
|--:|--:|
| Black Coal NSW | 4 |
| Black Coal QLD | 8 |
| Brown Coal VIC | 2 |
| Brown Coal | 1 |
| Diesel | 7 |
| Run-of-River | 2 |
| Reservoir | 28 |
| Hydrogen-based gas turbines | 2 |
| OCGT | 28 |
| CCGT | 9 |
| RoofPV | 12 |
| LargePV | 10 |
| Wind | 11 |


## Step 4 — schedule shapes and time coverage

The two schedule tables share the same long-format layout (one row per identifier per timestamp); their row/column shapes and represented time interval describe the extent of this generated build.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
println("\n=== Generator_pmax_sched ===")
println("Shape: ", (nrow(gen_pmax), ncol(gen_pmax)))
println("\n=== Demand_load_sched ===")
println("Shape: ", (nrow(dem_load), ncol(dem_load)))

schedule_shapes = DataFrame([
    (schedule = "Generator_pmax_sched", n_rows = nrow(gen_pmax), n_cols = ncol(gen_pmax)),
    (schedule = "Demand_load_sched", n_rows = nrow(dem_load), n_cols = ncol(dem_load)),
])
write_table(schedule_shapes, SCRIPT_STEM, "schedule_shapes")
markdown_table(schedule_shapes)
````

```@raw html
</details>
```

| **schedule** | **n\_rows** | **n\_cols** |
|--:|--:|--:|
| Generator\_pmax\_sched | 289083 | 5 |
| Demand\_load\_sched | 105120 | 5 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
schedule_time_coverage_rows = NamedTuple[]
for (schedule_name, schedule) in [
    ("Generator_pmax_sched", gen_pmax),
    ("Demand_load_sched", dem_load),
]
    timestamps = parse_schedule_datetime.(schedule.date)
    push!(
        schedule_time_coverage_rows,
        (
            schedule = schedule_name,
            first_timestamp = minimum(timestamps),
            last_timestamp = maximum(timestamps),
            unique_timestamps = length(unique(timestamps)),
            unique_days = length(unique(Date.(timestamps))),
        ),
    )
end
schedule_time_coverage = DataFrame(schedule_time_coverage_rows)
write_table(schedule_time_coverage, SCRIPT_STEM, "schedule_time_coverage")
markdown_table(schedule_time_coverage)
````

```@raw html
</details>
```

| **schedule** | **first\_timestamp** | **last\_timestamp** | **unique\_timestamps** | **unique\_days** |
|--:|--:|--:|--:|--:|
| Generator\_pmax\_sched | 2030-01-01T00:00:00 | 2044-07-01T00:00:00 | 8761 | 366 |
| Demand\_load\_sched | 2030-01-01T00:00:00 | 2030-12-31T23:00:00 | 8760 | 365 |


## Step 5 — join coverage between schedules, static tables, and the bus table

Each relationship below compares one schedule or static identifier column against the identifier column it should join against, recording how many identifiers are unmatched on either side.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
join_summary_rows = NamedTuple[]
join_detail_rows = NamedTuple[]

append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "generator schedule to static generator",
    "Generator_pmax_sched.id_gen",
    "Generator.id_gen",
    gen_pmax.id_gen,
    gen_df.id_gen,
)
append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "demand schedule to static demand",
    "Demand_load_sched.id_dem",
    "Demand.id_dem",
    dem_load.id_dem,
    dem_df.id_dem,
)
append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "generator bus to bus table",
    "Generator.id_bus",
    "Bus.id_bus",
    gen_df.id_bus,
    bus_df.id_bus,
)
append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "demand bus to bus table",
    "Demand.id_bus",
    "Bus.id_bus",
    dem_df.id_bus,
    bus_df.id_bus,
)

join_coverage = DataFrame(join_summary_rows)
write_table(join_coverage, SCRIPT_STEM, "join_coverage")
markdown_table(join_coverage)
````

```@raw html
</details>
```

| **relationship** | **left\_label** | **right\_label** | **left\_unique\_ids** | **right\_unique\_ids** | **left\_unmatched\_ids** | **right\_unmatched\_ids** |
|--:|--:|--:|--:|--:|--:|--:|
| generator schedule to static generator | Generator\_pmax\_sched.id\_gen | Generator.id\_gen | 34 | 124 | 0 | 90 |
| demand schedule to static demand | Demand\_load\_sched.id\_dem | Demand.id\_dem | 12 | 12 | 0 | 0 |
| generator bus to bus table | Generator.id\_bus | Bus.id\_bus | 12 | 12 | 0 | 0 |
| demand bus to bus table | Demand.id\_bus | Bus.id\_bus | 12 | 12 | 0 | 0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
unmatched_ids = isempty(join_detail_rows) ? DataFrame(relationship = String[], unmatched_side = String[], id = String[]) : DataFrame(join_detail_rows)
write_table(unmatched_ids, SCRIPT_STEM, "unmatched_ids")
markdown_table(unmatched_ids)
````

```@raw html
</details>
```

| **relationship** | **unmatched\_side** | **id** |
|--:|--:|--:|
| generator schedule to static generator | Generator.id\_gen | 1 |
| generator schedule to static generator | Generator.id\_gen | 2 |
| generator schedule to static generator | Generator.id\_gen | 3 |
| generator schedule to static generator | Generator.id\_gen | 4 |
| generator schedule to static generator | Generator.id\_gen | 5 |
| generator schedule to static generator | Generator.id\_gen | 6 |
| generator schedule to static generator | Generator.id\_gen | 7 |
| generator schedule to static generator | Generator.id\_gen | 8 |
| generator schedule to static generator | Generator.id\_gen | 9 |
| generator schedule to static generator | Generator.id\_gen | 10 |
| generator schedule to static generator | Generator.id\_gen | 11 |
| generator schedule to static generator | Generator.id\_gen | 12 |
| generator schedule to static generator | Generator.id\_gen | 13 |
| generator schedule to static generator | Generator.id\_gen | 14 |
| generator schedule to static generator | Generator.id\_gen | 15 |
| generator schedule to static generator | Generator.id\_gen | 16 |
| generator schedule to static generator | Generator.id\_gen | 17 |
| generator schedule to static generator | Generator.id\_gen | 18 |
| generator schedule to static generator | Generator.id\_gen | 19 |
| generator schedule to static generator | Generator.id\_gen | 20 |
| generator schedule to static generator | Generator.id\_gen | 21 |
| generator schedule to static generator | Generator.id\_gen | 22 |
| generator schedule to static generator | Generator.id\_gen | 23 |
| generator schedule to static generator | Generator.id\_gen | 24 |
| generator schedule to static generator | Generator.id\_gen | 25 |
| generator schedule to static generator | Generator.id\_gen | 26 |
| generator schedule to static generator | Generator.id\_gen | 27 |
| generator schedule to static generator | Generator.id\_gen | 28 |
| generator schedule to static generator | Generator.id\_gen | 29 |
| generator schedule to static generator | Generator.id\_gen | 30 |
| generator schedule to static generator | Generator.id\_gen | 31 |
| generator schedule to static generator | Generator.id\_gen | 32 |
| generator schedule to static generator | Generator.id\_gen | 33 |
| generator schedule to static generator | Generator.id\_gen | 34 |
| generator schedule to static generator | Generator.id\_gen | 35 |
| generator schedule to static generator | Generator.id\_gen | 36 |
| generator schedule to static generator | Generator.id\_gen | 37 |
| generator schedule to static generator | Generator.id\_gen | 38 |
| generator schedule to static generator | Generator.id\_gen | 39 |
| generator schedule to static generator | Generator.id\_gen | 40 |
| generator schedule to static generator | Generator.id\_gen | 41 |
| generator schedule to static generator | Generator.id\_gen | 42 |
| generator schedule to static generator | Generator.id\_gen | 43 |
| generator schedule to static generator | Generator.id\_gen | 44 |
| generator schedule to static generator | Generator.id\_gen | 45 |
| generator schedule to static generator | Generator.id\_gen | 46 |
| generator schedule to static generator | Generator.id\_gen | 47 |
| generator schedule to static generator | Generator.id\_gen | 48 |
| generator schedule to static generator | Generator.id\_gen | 49 |
| generator schedule to static generator | Generator.id\_gen | 50 |
| generator schedule to static generator | Generator.id\_gen | 51 |
| generator schedule to static generator | Generator.id\_gen | 52 |
| generator schedule to static generator | Generator.id\_gen | 53 |
| generator schedule to static generator | Generator.id\_gen | 54 |
| generator schedule to static generator | Generator.id\_gen | 55 |
| generator schedule to static generator | Generator.id\_gen | 56 |
| generator schedule to static generator | Generator.id\_gen | 57 |
| generator schedule to static generator | Generator.id\_gen | 58 |
| generator schedule to static generator | Generator.id\_gen | 59 |
| generator schedule to static generator | Generator.id\_gen | 60 |
| generator schedule to static generator | Generator.id\_gen | 61 |
| generator schedule to static generator | Generator.id\_gen | 62 |
| generator schedule to static generator | Generator.id\_gen | 63 |
| generator schedule to static generator | Generator.id\_gen | 64 |
| generator schedule to static generator | Generator.id\_gen | 65 |
| generator schedule to static generator | Generator.id\_gen | 66 |
| generator schedule to static generator | Generator.id\_gen | 67 |
| generator schedule to static generator | Generator.id\_gen | 68 |
| generator schedule to static generator | Generator.id\_gen | 69 |
| generator schedule to static generator | Generator.id\_gen | 70 |
| generator schedule to static generator | Generator.id\_gen | 71 |
| generator schedule to static generator | Generator.id\_gen | 72 |
| generator schedule to static generator | Generator.id\_gen | 73 |
| generator schedule to static generator | Generator.id\_gen | 74 |
| generator schedule to static generator | Generator.id\_gen | 75 |
| generator schedule to static generator | Generator.id\_gen | 76 |
| generator schedule to static generator | Generator.id\_gen | 77 |
| generator schedule to static generator | Generator.id\_gen | 79 |
| generator schedule to static generator | Generator.id\_gen | 80 |
| generator schedule to static generator | Generator.id\_gen | 81 |
| generator schedule to static generator | Generator.id\_gen | 82 |
| generator schedule to static generator | Generator.id\_gen | 83 |
| generator schedule to static generator | Generator.id\_gen | 84 |
| generator schedule to static generator | Generator.id\_gen | 85 |
| generator schedule to static generator | Generator.id\_gen | 86 |
| generator schedule to static generator | Generator.id\_gen | 87 |
| generator schedule to static generator | Generator.id\_gen | 88 |
| generator schedule to static generator | Generator.id\_gen | 89 |
| generator schedule to static generator | Generator.id\_gen | 90 |
| generator schedule to static generator | Generator.id\_gen | 91 |


## Step 6 — identify the solar and wind generators

Solar and wind generators are identified from `Generator.tech` using the same case-insensitive pattern match used throughout this page.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
solar_gens = gen_df[is_solar_tech.(gen_df.tech), :]
wind_gens = gen_df[is_wind_tech.(gen_df.tech), :]
println("\nSolar generators: ", nrow(solar_gens))
println("Wind generators: ", nrow(wind_gens))

solar_wind_generator_counts = DataFrame([
    (category = "solar", n_generators = nrow(solar_gens)),
    (category = "wind", n_generators = nrow(wind_gens)),
])
write_table(solar_wind_generator_counts, SCRIPT_STEM, "solar_wind_generator_counts")
markdown_table(solar_wind_generator_counts)
````

```@raw html
</details>
```

| **category** | **n\_generators** |
|--:|--:|
| solar | 22 |
| wind | 11 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
solar_wind_tech_counts_solar = combine(groupby(solar_gens, :tech), nrow => :count)
solar_wind_tech_counts_solar.category .= "solar"
solar_wind_tech_counts_wind = combine(groupby(wind_gens, :tech), nrow => :count)
solar_wind_tech_counts_wind.category .= "wind"
solar_wind_tech_counts = vcat(solar_wind_tech_counts_solar, solar_wind_tech_counts_wind)[:, [:category, :tech, :count]]
write_table(solar_wind_tech_counts, SCRIPT_STEM, "solar_wind_tech_counts")
markdown_table(solar_wind_tech_counts)
````

```@raw html
</details>
```

| **category** | **tech** | **count** |
|--:|--:|--:|
| solar | RoofPV | 12 |
| solar | LargePV | 10 |
| wind | Wind | 11 |


## Step 7 — annual mean pmax per generator

This is a plain per-generator annual mean of the scheduled pmax series, unrelated to the capacity-factor denominator question addressed next.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
solar_ids = Set(solar_gens.id_gen)
wind_ids = Set(wind_gens.id_gen)

sol_sched = gen_pmax[in.(gen_pmax.id_gen, Ref(solar_ids)), :]
wind_sched = gen_pmax[in.(gen_pmax.id_gen, Ref(wind_ids)), :]

sol_annual = combine(groupby(sol_sched, :id_gen), :value => mean => :mean_pmax)
sol_annual.tech .= "solar"
wind_annual = combine(groupby(wind_sched, :id_gen), :value => mean => :mean_pmax)
wind_annual.tech .= "wind"

annual_mean_pmax = vcat(sol_annual, wind_annual)[:, [:tech, :id_gen, :mean_pmax]]
write_table(annual_mean_pmax, SCRIPT_STEM, "annual_mean_pmax")
markdown_table(annual_mean_pmax)
````

```@raw html
</details>
```

| **tech** | **id\_gen** | **mean\_pmax** |
|--:|--:|--:|
| solar | 92 | 159.446 |
| solar | 93 | 169.054 |
| solar | 94 | 15.7744 |
| solar | 95 | 1111.96 |
| solar | 96 | 235.189 |
| solar | 97 | 145.689 |
| solar | 98 | 1082.05 |
| solar | 99 | 252.6 |
| solar | 100 | 1203.47 |
| solar | 101 | 73.5825 |
| solar | 102 | 544.861 |
| solar | 103 | 22.2591 |
| solar | 104 | 523.28 |
| solar | 105 | 486.528 |
| solar | 106 | 812.664 |
| solar | 107 | 607.632 |
| solar | 108 | 345.791 |
| solar | 109 | 268.053 |
| solar | 110 | 973.302 |
| solar | 111 | 1277.55 |
| solar | 112 | 0.0 |
| solar | 113 | 9.7209 |
| wind | 114 | 1577.5 |
| wind | 115 | 4159.16 |
| wind | 116 | 1777.17 |
| wind | 117 | 2105.6 |
| wind | 118 | 1394.33 |
| wind | 119 | 1542.34 |
| wind | 120 | 1149.62 |
| wind | 121 | 2745.85 |
| wind | 122 | 1138.2 |
| wind | 123 | 106.432 |
| wind | 124 | 0.0 |


## Step 8 — capacity factor duration curve

Each generator's capacity factor is its scheduled mean output divided by its own scheduled maximum (see the caveat documented on `capacity_factor_duration_frame` above); generators are then ranked in descending capacity-factor order within each technology.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
capacity_factor_duration = vcat(
    capacity_factor_duration_frame(gen_pmax, solar_gens, "solar"),
    capacity_factor_duration_frame(gen_pmax, wind_gens, "wind"),
)
write_table(capacity_factor_duration, SCRIPT_STEM, "capacity_factor_duration")
markdown_table(capacity_factor_duration)
````

```@raw html
</details>
```

| **tech** | **rank** | **capacity\_factor** |
|--:|--:|--:|
| solar | 1 | 0.265706 |
| solar | 2 | 0.254766 |
| solar | 3 | 0.25395 |
| solar | 4 | 0.250557 |
| solar | 5 | 0.243088 |
| solar | 6 | 0.23701 |
| solar | 7 | 0.236894 |
| solar | 8 | 0.226594 |
| solar | 9 | 0.1944 |
| solar | 10 | 0.194388 |
| solar | 11 | 0.194188 |
| solar | 12 | 0.194148 |
| solar | 13 | 0.194083 |
| solar | 14 | 0.194016 |
| solar | 15 | 0.193491 |
| solar | 16 | 0.193455 |
| solar | 17 | 0.191882 |
| solar | 18 | 0.184806 |
| solar | 19 | 0.183818 |
| solar | 20 | 0.165217 |
| solar | 21 | 0.164012 |
| wind | 1 | 0.469006 |
| wind | 2 | 0.467413 |
| wind | 3 | 0.411739 |
| wind | 4 | 0.400556 |
| wind | 5 | 0.380414 |
| wind | 6 | 0.376079 |
| wind | 7 | 0.374036 |
| wind | 8 | 0.370776 |
| wind | 9 | 0.36448 |
| wind | 10 | 0.311522 |


## Step 9 — demand by area

The demand schedule is joined to the static `Demand` table to obtain each demand node's bus, then to `Bus` to obtain its NEM area, before summing to a daily total per area. The full daily series (1825 rows: 5 NEM areas x 365 days) is written to `demand_by_area_daily.csv`; the table below summarises it per area.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
dem_load_full = build_dem_load_full(dem_load, dem_df, bus_df)

dem_load_full.date_only = Date.(dem_load_full.datetime)
demand_by_area_daily = combine(groupby(dem_load_full, [:date_only, :area_name]), :value => sum => :total_demand_mw)
rename!(demand_by_area_daily, :date_only => :date)
write_table(demand_by_area_daily, SCRIPT_STEM, "demand_by_area_daily")

demand_by_area_summary = combine(
    groupby(demand_by_area_daily, :area_name),
    :total_demand_mw => mean => :mean_daily_mw,
    :total_demand_mw => minimum => :min_daily_mw,
    :total_demand_mw => maximum => :max_daily_mw,
)
markdown_table(demand_by_area_summary)
````

```@raw html
</details>
```

| **area\_name** | **mean\_daily\_mw** | **min\_daily\_mw** | **max\_daily\_mw** |
|--:|--:|--:|--:|
| QLD | 1.89295e5 | 1.65127e5 | 2.49773e5 |
| NSW | 2.34183e5 | 1.96257e5 | 3.38706e5 |
| VIC | 1.51096e5 | 1.1346e5 | 2.34937e5 |
| TAS | 32043.8 | 26777.0 | 39019.7 |
| SA | 49865.2 | 39497.2 | 79666.7 |


## Step 10 — daily solar, wind, and demand aggregates in GW

Generator schedules are joined to generator technology before summing solar and wind pmax separately by day; the demand schedule's daily total, already joined above, is combined alongside them and converted from MW to GW. The full daily series (one row per calendar date) is written to `daily_solar_wind_demand_gw.csv`; the page displays only the first 10 rows as a representative sample.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
gen_pmax_ts = build_gen_pmax_ts(gen_pmax, gen_df)

sol_daily = daily_tech_sum(gen_pmax_ts, is_solar_tech)
wind_daily = daily_tech_sum(gen_pmax_ts, is_wind_tech)
dem_daily_ts = combine(groupby(dem_load_full, :date_only), :value => sum => :total_demand)

daily_joined = innerjoin(
    innerjoin(sol_daily, wind_daily, on = :date_only, makeunique = true, renamecols = "_solar" => "_wind"),
    dem_daily_ts,
    on = :date_only,
)
sort!(daily_joined, :date_only)
daily_gw = DataFrame(
    date = daily_joined.date_only,
    solar_gw = daily_joined.total_solar ./ 1000,
    wind_gw = daily_joined.total_wind ./ 1000,
    demand_gw = daily_joined.total_demand ./ 1000,
)
write_table(daily_gw, SCRIPT_STEM, "daily_solar_wind_demand_gw")
markdown_table(first(daily_gw, 10))
````

```@raw html
</details>
```

| **date** | **solar\_gw** | **wind\_gw** | **demand\_gw** |
|--:|--:|--:|--:|
| 2030-01-01 | 374.067 | 276.858 | 614.026 |
| 2030-01-02 | 339.376 | 452.67 | 776.411 |
| 2030-01-03 | 290.948 | 350.491 | 681.55 |
| 2030-01-04 | 324.67 | 368.159 | 685.118 |
| 2030-01-05 | 330.252 | 479.69 | 669.052 |
| 2030-01-06 | 296.22 | 341.457 | 615.867 |
| 2030-01-07 | 249.297 | 328.978 | 643.931 |
| 2030-01-08 | 342.392 | 440.671 | 677.834 |
| 2030-01-09 | 339.525 | 455.946 | 776.754 |
| 2030-01-10 | 291.068 | 349.769 | 682.724 |


## Step 11 — hourly pmax profile for the first 30 days

Restricting to the first 30 scheduled days and grouping scheduled pmax by hour of day gives a representative diurnal shape for solar and wind generators. The full per-generator profile (792 rows) is written to `hourly_pmax_profile.csv`; the table below averages across generators within each technology to show the fleet-level diurnal shape, and Step 15 plots the per-generator profile for up to 5 generators of each technology.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
cutoff30 = minimum(Date.(gen_pmax_ts.datetime)) + Day(29)
subset30 = gen_pmax_ts[Date.(gen_pmax_ts.datetime) .<= cutoff30, :]

sol_subset = subset30[is_solar_tech.(subset30.tech), :]
sol_subset = transform(sol_subset, :datetime => ByRow(hour) => :hour)
sol_profile = combine(groupby(sol_subset, [:id_gen, :hour]), :value => mean => :mean_pmax)
sol_profile.tech .= "solar"

wind_subset = subset30[is_wind_tech.(subset30.tech), :]
wind_subset = transform(wind_subset, :datetime => ByRow(hour) => :hour)
wind_profile = combine(groupby(wind_subset, [:id_gen, :hour]), :value => mean => :mean_pmax)
wind_profile.tech .= "wind"

hourly_pmax_profile = vcat(sol_profile, wind_profile)[:, [:tech, :id_gen, :hour, :mean_pmax]]
write_table(hourly_pmax_profile, SCRIPT_STEM, "hourly_pmax_profile")

hourly_pmax_profile_fleet_mean = combine(
    groupby(hourly_pmax_profile, [:tech, :hour]),
    :mean_pmax => mean => :fleet_mean_pmax,
)
markdown_table(hourly_pmax_profile_fleet_mean)
````

```@raw html
</details>
```

| **tech** | **hour** | **fleet\_mean\_pmax** |
|--:|--:|--:|
| solar | 0 | 0.0 |
| solar | 1 | 0.0 |
| solar | 2 | 0.0 |
| solar | 3 | 0.0 |
| solar | 4 | 0.212135 |
| solar | 5 | 45.4364 |
| solar | 6 | 365.847 |
| solar | 7 | 848.022 |
| solar | 8 | 1121.09 |
| solar | 9 | 1311.59 |
| solar | 10 | 1422.01 |
| solar | 11 | 1467.55 |
| solar | 12 | 1468.83 |
| solar | 13 | 1409.75 |
| solar | 14 | 1276.29 |
| solar | 15 | 1112.31 |
| solar | 16 | 893.467 |
| solar | 17 | 567.117 |
| solar | 18 | 183.948 |
| solar | 19 | 14.3567 |
| solar | 20 | 0.0 |
| solar | 21 | 0.0 |
| solar | 22 | 0.0 |
| solar | 23 | 0.0 |
| wind | 0 | 1719.26 |
| wind | 1 | 1674.4 |
| wind | 2 | 1618.63 |
| wind | 3 | 1550.45 |
| wind | 4 | 1500.63 |
| wind | 5 | 1480.07 |
| wind | 6 | 1424.57 |
| wind | 7 | 1349.23 |
| wind | 8 | 1329.08 |
| wind | 9 | 1299.15 |
| wind | 10 | 1264.67 |
| wind | 11 | 1248.19 |
| wind | 12 | 1262.51 |
| wind | 13 | 1314.86 |
| wind | 14 | 1379.0 |
| wind | 15 | 1472.59 |
| wind | 16 | 1572.74 |
| wind | 17 | 1647.76 |
| wind | 18 | 1725.35 |
| wind | 19 | 1789.71 |
| wind | 20 | 1838.75 |
| wind | 21 | 1838.02 |
| wind | 22 | 1821.89 |
| wind | 23 | 1789.54 |


## Step 12 — VRE-vs-demand and demand-distribution summaries

The first summary describes the scale and correlation of daily VRE (solar + wind) generation against daily demand; the second describes the distribution of daily demand alone.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vre_daily = daily_gw.solar_gw .+ daily_gw.wind_gw
demand_daily = daily_gw.demand_gw
vre_vs_demand_summary = DataFrame([(
    n_days = nrow(daily_gw),
    mean_demand_gw = mean(demand_daily),
    mean_vre_gw = mean(vre_daily),
    min_demand_gw = minimum(demand_daily),
    max_demand_gw = maximum(demand_daily),
    min_vre_gw = minimum(vre_daily),
    max_vre_gw = maximum(vre_daily),
    corr_demand_vre = cor(demand_daily, vre_daily),
)])
write_table(vre_vs_demand_summary, SCRIPT_STEM, "vre_vs_demand_summary")
markdown_table(vre_vs_demand_summary)
````

```@raw html
</details>
```

| **n\_days** | **mean\_demand\_gw** | **mean\_vre\_gw** | **min\_demand\_gw** | **max\_demand\_gw** | **min\_vre\_gw** | **max\_vre\_gw** | **corr\_demand\_vre** |
|--:|--:|--:|--:|--:|--:|--:|--:|
| 365 | 656.483 | 672.4 | 547.968 | 776.754 | 223.515 | 1189.63 | -0.0447203 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_distribution_summary = DataFrame([(
    n = length(dem_daily_ts.total_demand),
    mean_mw = mean(dem_daily_ts.total_demand),
    std_mw = std(dem_daily_ts.total_demand),
    min_mw = minimum(dem_daily_ts.total_demand),
    max_mw = maximum(dem_daily_ts.total_demand),
    median_mw = median(dem_daily_ts.total_demand),
)])
write_table(demand_distribution_summary, SCRIPT_STEM, "demand_distribution_summary")
markdown_table(demand_distribution_summary)
````

```@raw html
</details>
```

| **n** | **mean\_mw** | **std\_mw** | **min\_mw** | **max\_mw** | **median\_mw** |
|--:|--:|--:|--:|--:|--:|
| 365 | 6.56483e5 | 40810.3 | 5.47968e5 | 7.76754e5 | 6.54805e5 |


## Step 13 — figure: PISP outputs overview

A 2x2 overview: annual mean pmax per solar generator, annual mean pmax per wind generator, daily total demand by NEM area, and the capacity-factor duration curve for solar and wind. The per-generator pmax panels use horizontal-line scatter plots rather than `Plots.jl` bar charts, a plotting-library workaround with no effect on the underlying values.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
sol_annual_sorted = sort(combine(groupby(sol_sched, :id_gen), :value => mean => :mean_pmax), :mean_pmax)
wind_annual_sorted = sort(combine(groupby(wind_sched, :id_gen), :value => mean => :mean_pmax), :mean_pmax)

p_sol_bar = scatter(sol_annual_sorted.mean_pmax, 1:nrow(sol_annual_sorted),
                    title="Solar Generators — Annual Mean pmax (MW)", xlabel="PMax (MW)", ylabel="",
                    legend=false, grid=true, gridalpha=0.3, markersize=0,
                    yticks=(1:nrow(sol_annual_sorted), string.(sol_annual_sorted.id_gen)))
for i in 1:nrow(sol_annual_sorted)
    plot!(p_sol_bar, [0, sol_annual_sorted.mean_pmax[i]], [i, i], color=:orange, alpha=0.7, label="")
end

p_wind_bar = scatter(wind_annual_sorted.mean_pmax, 1:nrow(wind_annual_sorted),
                     title="Wind Generators — Annual Mean pmax (MW)", xlabel="PMax (MW)", ylabel="",
                     legend=false, grid=true, gridalpha=0.3, markersize=0,
                     yticks=(1:nrow(wind_annual_sorted), string.(wind_annual_sorted.id_gen)))
for i in 1:nrow(wind_annual_sorted)
    plot!(p_wind_bar, [0, wind_annual_sorted.mean_pmax[i]], [i, i], color=:steelblue, alpha=0.7, label="")
end

area_map_plot = Dict(row.id_bus => row.id_area for row in eachrow(bus_df))
dem_load_full_plot = innerjoin(dem_load, dem_df[:, [:id_dem, :id_bus]], on = :id_dem)
dem_load_full_plot.datetime = parse_schedule_datetime.(dem_load_full_plot.date)
dem_load_full_plot.area = [area_map_plot[b] for b in dem_load_full_plot.id_bus]
dem_load_full_plot.area_name = [AREA_NAMES[a] for a in dem_load_full_plot.area]
dem_load_full_plot.date_only = Date.(dem_load_full_plot.datetime)
dem_daily_area = combine(groupby(dem_load_full_plot, [:date_only, :area_name]), :value => sum => :total_demand_mw)

p_demand = plot(title="Daily Total Demand (MW) by NEM Area", xlabel="Date", ylabel="Demand (MW)",
                legend=:topright, grid=true, gridalpha=0.3)
for area in sort(unique(dem_daily_area.area_name))
    area_data = filter(row -> row.area_name == area, dem_daily_area)
    plot!(p_demand, area_data.date_only, area_data.total_demand_mw, label=area, linewidth=1, alpha=0.7)
end

sol_cf_grouped = combine(groupby(sol_sched, :id_gen), :value => mean => :mean_val, :value => maximum => :max_val)
wind_cf_grouped = combine(groupby(wind_sched, :id_gen), :value => mean => :mean_val, :value => maximum => :max_val)

sol_cf_vals = Float64[]
for row in eachrow(sol_cf_grouped)
    cf = row.mean_val / row.max_val
    isnan(cf) || push!(sol_cf_vals, cf)
end
sol_cf_sorted = sort(sol_cf_vals; rev=true)

wind_cf_vals = Float64[]
for row in eachrow(wind_cf_grouped)
    cf = row.mean_val / row.max_val
    isnan(cf) || push!(wind_cf_vals, cf)
end
wind_cf_sorted = sort(wind_cf_vals; rev=true)

p_cf = plot(sol_cf_sorted, label="Solar CF", color=:orange, linewidth=1.5, alpha=0.7,
            title="Capacity Factor Duration Curve (2030)", xlabel="Generator Rank", ylabel="Capacity Factor",
            legend=:topright, grid=true, gridalpha=0.3)
plot!(p_cf, wind_cf_sorted, label="Wind CF", color=:steelblue, linewidth=1.5, alpha=0.7)

p_overview = plot(p_sol_bar, p_wind_bar, p_demand, p_cf, layout=(2,2), size=(1200, 1000), left_margin=8Plots.mm, top_margin=8Plots.mm)

savefig(p_overview, figure_path(SCRIPT_STEM, "06_pisp_outputs_overview.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "06_pisp_outputs_overview.png"), "06_pisp_outputs_overview.png")
````

```@raw html
</details>
```

![PISP outputs overview: annual mean pmax by generator for solar and wind, daily demand by NEM area, and the solar/wind capacity-factor duration curve](06_pisp_outputs_overview.png)

## Step 14 — figure: solar and wind PMax versus total demand over time

Daily solar PMax, wind PMax, and total demand, each summed across generators/nodes and expressed in GW, plotted over the full scheduled horizon.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
gen_pmax_ts_plot = innerjoin(gen_pmax, gen_df[:, [:id_gen, :tech]], on = :id_gen)
gen_pmax_ts_plot.datetime = parse_schedule_datetime.(gen_pmax_ts_plot.date)
gen_pmax_ts_plot.date_only = Date.(gen_pmax_ts_plot.datetime)

sol_daily_ts = combine(groupby(gen_pmax_ts_plot[is_solar_tech.(gen_pmax_ts_plot.tech), :], :date_only), :value => sum => :total)
wind_daily_ts = combine(groupby(gen_pmax_ts_plot[is_wind_tech.(gen_pmax_ts_plot.tech), :], :date_only), :value => sum => :total)
dem_daily_ts_plot = combine(groupby(dem_load_full_plot, :date_only), :value => sum => :total_demand)

p_ts = plot(size=(1200, 600), title="2030 — Daily Aggregate: Solar PMax, Wind PMax, Total Demand",
           xlabel="Date", ylabel="GW", legend=:topright, grid=true, gridalpha=0.3, left_margin=8Plots.mm)
plot!(p_ts, sol_daily_ts.date_only, sol_daily_ts.total ./ 1000, label="Solar PMax (GW)", color=:orange, linewidth=1, alpha=0.7)
plot!(p_ts, wind_daily_ts.date_only, wind_daily_ts.total ./ 1000, label="Wind PMax (GW)", color=:steelblue, linewidth=1, alpha=0.7)
plot!(p_ts, dem_daily_ts_plot.date_only, dem_daily_ts_plot.total_demand ./ 1000, label="Total Demand (GW)", color=:grey, linewidth=1, alpha=0.7)

savefig(p_ts, figure_path(SCRIPT_STEM, "06_solar_wind_vs_demand_ts.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "06_solar_wind_vs_demand_ts.png"), "06_solar_wind_vs_demand_ts.png")
````

```@raw html
</details>
```

![Daily solar PMax, wind PMax, and total demand over the scheduled horizon, each in GW](06_solar_wind_vs_demand_ts.png)

## Step 15 — figure: PISP detailed

A second 2x2 detail view: hourly pmax profile (first 30 days) for up to 5 solar generators, the same for up to 5 wind generators, a VRE-vs-demand scatter with a 1:1 reference line, and the daily demand distribution histogram.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
cutoff = minimum(Date.(gen_pmax_ts_plot.datetime)) + Day(29)
subset30_plot = filter(row -> Date(row.datetime) <= cutoff, gen_pmax_ts_plot)

sol_subset_plot = subset30_plot[is_solar_tech.(subset30_plot.tech), :]
sol_subset_plot = transform(sol_subset_plot, :datetime => ByRow(hour) => :hour)
sol_profile_plot = combine(groupby(sol_subset_plot, [:id_gen, :hour]), :value => mean => :mean_pmax)
sort!(sol_profile_plot, :id_gen)

wind_subset_plot = subset30_plot[is_wind_tech.(subset30_plot.tech), :]
wind_subset_plot = transform(wind_subset_plot, :datetime => ByRow(hour) => :hour)
wind_profile_plot = combine(groupby(wind_subset_plot, [:id_gen, :hour]), :value => mean => :mean_pmax)
sort!(wind_profile_plot, :id_gen)

p_detailed = plot(layout=(2,2), size=(1200, 1000), left_margin=8Plots.mm, top_margin=8Plots.mm)

top_sol_gens = unique(sol_profile_plot.id_gen)[1:min(5, length(unique(sol_profile_plot.id_gen)))]
for gid in top_sol_gens
    gdata = filter(row -> row.id_gen == gid, sol_profile_plot)
    plot!(p_detailed[1], gdata.hour, gdata.mean_pmax, label="Solar Gen $gid", linewidth=1.5)
end
plot!(p_detailed[1], title="Solar PMax: Hourly Profile (mean of first 30 days)", xlabel="Hour", ylabel="PMax (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

top_wind_gens = unique(wind_profile_plot.id_gen)[1:min(5, length(unique(wind_profile_plot.id_gen)))]
for gid in top_wind_gens
    gdata = filter(row -> row.id_gen == gid, wind_profile_plot)
    plot!(p_detailed[2], gdata.hour, gdata.mean_pmax, label="Wind Gen $gid", linewidth=1.5)
end
plot!(p_detailed[2], title="Wind PMax: Hourly Profile (mean of first 30 days)", xlabel="Hour", ylabel="PMax (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

vre_scatter = daily_gw.solar_gw .+ daily_gw.wind_gw
scatter!(p_detailed[3], daily_gw.demand_gw, vre_scatter, markersize=2, alpha=0.3, color=:purple, label="", legend=false)
plot!(p_detailed[3], [0, maximum(daily_gw.demand_gw)], [0, maximum(daily_gw.demand_gw)],
      label="1:1", color=:black, linestyle=:dash, alpha=0.3, linewidth=1)
plot!(p_detailed[3], title="VRE Generation vs Total Demand (2030)", xlabel="Demand (GW)", ylabel="VRE Solar+Wind (GW)",
      grid=true, gridalpha=0.3, legend=false)

histogram!(p_detailed[4], dem_daily_ts_plot.total_demand, bins=50, alpha=0.6, color=:grey, legend=false)
plot!(p_detailed[4], title="Daily Total Demand Distribution (2030)", xlabel="Demand (MW)", ylabel="",
      grid=true, gridalpha=0.3, legend=false)

savefig(p_detailed, figure_path(SCRIPT_STEM, "06_pisp_detailed.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "06_pisp_detailed.png"), "06_pisp_detailed.png")
````

```@raw html
</details>
```

![PISP detailed view: hourly pmax profiles for solar and wind generators, VRE-vs-demand scatter, and daily demand distribution](06_pisp_detailed.png)

## Summary

- Static asset tables and 2030 schedule outputs join cleanly for this generated build, with identifier coverage and schedule time coverage recorded above and any unmatched identifiers listed in `unmatched_ids`.
- Solar and wind generator classification, annual mean pmax, and capacity-factor duration curves are all computed live above, following the capacity-factor denominator convention documented on `capacity_factor_duration_frame`.
- The three figures — outputs overview, solar/wind-vs-demand time series, and the detailed 2x2 view — are all built on this page from the same joined tables shown above.
- This page writes its full evidence tables to `eda/tables/julia/06_pisp_outputs/*.csv`; four of them — `build_metadata`, `join_coverage`, `schedule_time_coverage`, and `unmatched_ids` — are this page's own diagnostics with no prior baseline to compare against.

