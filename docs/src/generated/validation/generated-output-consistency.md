```@meta
EditURL = "../../../literate/validation/generated_output_consistency.jl"
```

# PISP generated-output consistency

PISP writes a static asset dataset (`Generator.csv`, `Demand.csv`, `Bus.csv`) alongside time-varying schedules (`Generator_pmax_sched.csv`, `Demand_load_sched.csv`) for one generated build. This page loads one such build, joins the static and schedule tables, and checks identifier coverage, schedule coverage, generator classification, and daily solar/wind/demand alignment, computed live on this page and written to `eda/tables/julia/06_pisp_outputs/` as evidence. It also builds the three PISP-output figures shown in the generated docs site.

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

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))

include(joinpath(REPO_ROOT, "eda", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "06_pisp_outputs"
const OUT = normpath(get(
    ENV,
    "PISP_OUTPUT_ROOT",
    joinpath(REPO_ROOT, "data", "2024", "pisp-datasets", "out-ref4006-poe10", "csv"),
))
const SCHEDULE_TAG = get(ENV, "PISP_SCHEDULE_TAG", "schedule-2030")
const SCHEDULE_DIR = joinpath(OUT, SCHEDULE_TAG)

snapshot_metadata_line(REPO_ROOT; context = "$(SCHEDULE_TAG) generated PISP output (out-ref4006-poe10 build)")

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # no-op here since OUT/SCHEDULE_DIR are already absolute; kept for consistency with the other EDA pages

const AREA_NAMES = Dict(1 => "QLD", 2 => "NSW", 3 => "VIC", 4 => "TAS", 5 => "SA")
````

```@raw html
</details>
```

````
Snapshot: PISP.jl commit a429ab9+dirty, generated 2026-07-17 — schedule-2030 generated PISP output (out-ref4006-poe10 build)

````

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

Generator schedules are joined to generator technology before summing solar and wind pmax separately by day; the demand schedule's daily total, already joined above, is combined alongside them and converted from MW to GW.

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
markdown_table(daily_gw)
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
| 2030-01-11 | 236.658 | 363.813 | 741.129 |
| 2030-01-12 | 181.532 | 390.47 | 613.234 |
| 2030-01-13 | 174.057 | 406.003 | 593.869 |
| 2030-01-14 | 239.328 | 415.704 | 661.345 |
| 2030-01-15 | 174.458 | 471.475 | 664.623 |
| 2030-01-16 | 242.238 | 637.522 | 753.264 |
| 2030-01-17 | 364.555 | 337.071 | 707.878 |
| 2030-01-18 | 416.063 | 340.797 | 716.008 |
| 2030-01-19 | 408.296 | 405.196 | 646.971 |
| 2030-01-20 | 391.012 | 296.747 | 630.655 |
| 2030-01-21 | 333.157 | 393.718 | 660.424 |
| 2030-01-22 | 237.358 | 622.682 | 659.62 |
| 2030-01-23 | 275.506 | 439.234 | 687.056 |
| 2030-01-24 | 291.241 | 361.398 | 759.915 |
| 2030-01-25 | 287.961 | 285.766 | 768.369 |
| 2030-01-26 | 326.41 | 192.688 | 640.565 |
| 2030-01-27 | 383.733 | 425.75 | 634.263 |
| 2030-01-28 | 294.346 | 372.751 | 605.335 |
| 2030-01-29 | 231.391 | 529.072 | 653.073 |
| 2030-01-30 | 248.042 | 648.093 | 641.086 |
| 2030-01-31 | 378.057 | 436.449 | 643.227 |
| 2030-02-01 | 378.225 | 324.08 | 643.178 |
| 2030-02-02 | 383.145 | 331.329 | 607.556 |
| 2030-02-03 | 349.573 | 330.426 | 603.701 |
| 2030-02-04 | 341.695 | 538.32 | 652.674 |
| 2030-02-05 | 347.07 | 469.014 | 646.59 |
| 2030-02-06 | 334.641 | 395.077 | 638.984 |
| 2030-02-07 | 355.947 | 549.619 | 651.266 |
| 2030-02-08 | 370.222 | 490.037 | 673.602 |
| 2030-02-09 | 327.34 | 405.917 | 642.735 |
| 2030-02-10 | 365.517 | 330.747 | 631.68 |
| 2030-02-11 | 370.761 | 486.485 | 675.052 |
| 2030-02-12 | 360.698 | 515.213 | 696.902 |
| 2030-02-13 | 333.962 | 470.783 | 758.474 |
| 2030-02-14 | 307.941 | 461.222 | 690.012 |
| 2030-02-15 | 264.059 | 557.692 | 679.425 |
| 2030-02-16 | 272.5 | 416.481 | 636.393 |
| 2030-02-17 | 339.272 | 368.618 | 639.69 |
| 2030-02-18 | 346.442 | 406.916 | 677.357 |
| 2030-02-19 | 318.091 | 458.15 | 668.292 |
| 2030-02-20 | 298.156 | 489.677 | 666.651 |
| 2030-02-21 | 263.447 | 466.855 | 684.276 |
| 2030-02-22 | 242.41 | 425.915 | 683.215 |
| 2030-02-23 | 290.074 | 456.75 | 658.898 |
| 2030-02-24 | 273.286 | 396.305 | 670.559 |
| 2030-02-25 | 303.595 | 432.764 | 690.308 |
| 2030-02-26 | 317.608 | 411.69 | 664.206 |
| 2030-02-27 | 308.499 | 350.171 | 660.805 |
| 2030-02-28 | 281.071 | 179.238 | 665.319 |
| 2030-03-01 | 321.374 | 174.744 | 676.725 |
| 2030-03-02 | 283.307 | 313.325 | 641.256 |
| 2030-03-03 | 337.877 | 395.571 | 623.614 |
| 2030-03-04 | 312.794 | 353.763 | 656.243 |
| 2030-03-05 | 343.709 | 269.334 | 668.487 |
| 2030-03-06 | 358.202 | 401.195 | 676.151 |
| 2030-03-07 | 385.206 | 633.744 | 708.446 |
| 2030-03-08 | 316.27 | 441.261 | 654.453 |
| 2030-03-09 | 307.221 | 242.557 | 614.397 |
| 2030-03-10 | 330.476 | 178.518 | 610.461 |
| 2030-03-11 | 346.231 | 243.176 | 655.479 |
| 2030-03-12 | 320.859 | 249.285 | 674.103 |
| 2030-03-13 | 314.856 | 287.09 | 674.245 |
| 2030-03-14 | 302.556 | 361.948 | 663.661 |
| 2030-03-15 | 287.862 | 468.515 | 646.838 |
| 2030-03-16 | 353.092 | 408.455 | 606.75 |
| 2030-03-17 | 330.245 | 391.21 | 598.006 |
| 2030-03-18 | 310.051 | 382.695 | 642.451 |
| 2030-03-19 | 179.89 | 482.239 | 653.112 |
| 2030-03-20 | 285.813 | 476.541 | 660.605 |
| 2030-03-21 | 348.491 | 479.022 | 693.081 |
| 2030-03-22 | 322.071 | 428.882 | 706.569 |
| 2030-03-23 | 267.17 | 548.79 | 614.673 |
| 2030-03-24 | 261.964 | 456.824 | 601.155 |
| 2030-03-25 | 234.015 | 452.131 | 659.808 |
| 2030-03-26 | 230.624 | 334.172 | 661.151 |
| 2030-03-27 | 308.248 | 244.249 | 657.265 |
| 2030-03-28 | 305.209 | 445.237 | 671.083 |
| 2030-03-29 | 297.756 | 371.32 | 652.492 |
| 2030-03-30 | 308.495 | 176.515 | 602.644 |
| 2030-03-31 | 283.932 | 242.309 | 592.456 |
| 2030-04-01 | 226.913 | 211.385 | 639.913 |
| 2030-04-02 | 240.06 | 282.614 | 642.291 |
| 2030-04-03 | 210.085 | 543.805 | 645.683 |
| 2030-04-04 | 226.44 | 462.913 | 640.566 |
| 2030-04-05 | 293.995 | 324.241 | 629.067 |
| 2030-04-06 | 268.755 | 231.317 | 590.558 |
| 2030-04-07 | 231.782 | 214.833 | 584.597 |
| 2030-04-08 | 281.238 | 270.818 | 635.467 |
| 2030-04-09 | 178.569 | 593.377 | 645.699 |
| 2030-04-10 | 251.282 | 618.299 | 638.983 |
| 2030-04-11 | 307.628 | 286.671 | 636.771 |
| 2030-04-12 | 294.153 | 323.466 | 629.354 |
| 2030-04-13 | 268.899 | 231.317 | 590.94 |
| 2030-04-14 | 231.918 | 214.833 | 584.598 |
| 2030-04-15 | 281.393 | 271.291 | 635.945 |
| 2030-04-16 | 225.806 | 348.588 | 638.859 |
| 2030-04-17 | 258.699 | 315.671 | 638.704 |
| 2030-04-18 | 242.224 | 340.091 | 644.657 |
| 2030-04-19 | 203.836 | 413.91 | 580.169 |
| 2030-04-20 | 143.845 | 281.841 | 581.758 |
| 2030-04-21 | 214.71 | 179.686 | 568.076 |
| 2030-04-22 | 219.757 | 254.232 | 586.397 |
| 2030-04-23 | 206.306 | 561.561 | 657.209 |
| 2030-04-24 | 221.204 | 435.588 | 650.682 |
| 2030-04-25 | 260.705 | 323.375 | 655.333 |
| 2030-04-26 | 194.328 | 247.31 | 638.138 |
| 2030-04-27 | 217.129 | 346.985 | 602.428 |
| 2030-04-28 | 190.858 | 677.726 | 608.256 |
| 2030-04-29 | 237.066 | 306.755 | 643.959 |
| 2030-04-30 | 257.752 | 293.018 | 658.569 |
| 2030-05-01 | 228.32 | 410.532 | 659.49 |
| 2030-05-02 | 185.703 | 510.764 | 662.474 |
| 2030-05-03 | 162.946 | 491.338 | 654.148 |
| 2030-05-04 | 182.128 | 445.993 | 606.647 |
| 2030-05-05 | 205.984 | 169.416 | 593.67 |
| 2030-05-06 | 237.334 | 302.654 | 645.652 |
| 2030-05-07 | 238.057 | 605.427 | 656.479 |
| 2030-05-08 | 260.171 | 594.669 | 665.182 |
| 2030-05-09 | 241.489 | 642.979 | 673.23 |
| 2030-05-10 | 239.298 | 509.129 | 669.108 |
| 2030-05-11 | 225.961 | 575.432 | 623.437 |
| 2030-05-12 | 211.7 | 755.646 | 614.771 |
| 2030-05-13 | 211.766 | 754.737 | 661.216 |
| 2030-05-14 | 203.142 | 637.021 | 674.998 |
| 2030-05-15 | 227.812 | 717.154 | 698.504 |
| 2030-05-16 | 249.128 | 656.044 | 698.046 |
| 2030-05-17 | 229.339 | 422.24 | 678.018 |
| 2030-05-18 | 222.671 | 489.787 | 623.761 |
| 2030-05-19 | 204.353 | 467.363 | 613.089 |
| 2030-05-20 | 173.623 | 403.02 | 667.944 |
| 2030-05-21 | 122.885 | 457.86 | 673.609 |
| 2030-05-22 | 191.767 | 421.592 | 669.271 |
| 2030-05-23 | 141.776 | 232.843 | 679.741 |
| 2030-05-24 | 187.543 | 550.282 | 682.731 |
| 2030-05-25 | 247.588 | 375.982 | 639.626 |
| 2030-05-26 | 225.357 | 307.775 | 637.188 |
| 2030-05-27 | 203.425 | 257.817 | 690.006 |
| 2030-05-28 | 170.132 | 187.957 | 693.334 |
| 2030-05-29 | 185.039 | 281.009 | 677.378 |
| 2030-05-30 | 168.126 | 388.031 | 670.719 |
| 2030-05-31 | 150.837 | 363.469 | 669.769 |
| 2030-06-01 | 140.87 | 369.354 | 630.854 |
| 2030-06-02 | 102.435 | 513.677 | 632.194 |
| 2030-06-03 | 182.36 | 574.891 | 733.276 |
| 2030-06-04 | 231.852 | 226.949 | 753.61 |
| 2030-06-05 | 208.572 | 98.7518 | 725.513 |
| 2030-06-06 | 215.415 | 306.886 | 766.164 |
| 2030-06-07 | 182.914 | 299.88 | 734.539 |
| 2030-06-08 | 220.501 | 413.081 | 644.698 |
| 2030-06-09 | 200.311 | 595.943 | 626.264 |
| 2030-06-10 | 202.367 | 633.684 | 621.66 |
| 2030-06-11 | 177.762 | 532.982 | 685.281 |
| 2030-06-12 | 182.763 | 423.428 | 707.714 |
| 2030-06-13 | 177.659 | 559.488 | 703.546 |
| 2030-06-14 | 164.264 | 449.73 | 697.64 |
| 2030-06-15 | 157.947 | 379.734 | 642.587 |
| 2030-06-16 | 163.152 | 283.721 | 631.755 |
| 2030-06-17 | 112.064 | 385.498 | 685.886 |
| 2030-06-18 | 56.26 | 367.485 | 686.407 |
| 2030-06-19 | 65.2192 | 393.941 | 687.173 |
| 2030-06-20 | 128.914 | 348.144 | 703.257 |
| 2030-06-21 | 169.202 | 327.319 | 714.666 |
| 2030-06-22 | 209.897 | 205.044 | 675.644 |
| 2030-06-23 | 235.598 | 330.836 | 668.319 |
| 2030-06-24 | 189.275 | 544.28 | 719.585 |
| 2030-06-25 | 180.676 | 485.943 | 700.514 |
| 2030-06-26 | 138.422 | 321.622 | 687.824 |
| 2030-06-27 | 150.756 | 274.819 | 693.293 |
| 2030-06-28 | 205.888 | 419.152 | 686.384 |
| 2030-06-29 | 196.451 | 374.718 | 655.824 |
| 2030-06-30 | 187.611 | 285.959 | 642.026 |
| 2030-07-01 | 211.383 | 331.143 | 687.654 |
| 2030-07-02 | 140.118 | 356.114 | 717.213 |
| 2030-07-03 | 111.079 | 229.146 | 736.079 |
| 2030-07-04 | 156.153 | 140.88 | 761.187 |
| 2030-07-05 | 55.7251 | 167.79 | 761.71 |
| 2030-07-06 | 200.217 | 521.223 | 677.24 |
| 2030-07-07 | 199.118 | 270.317 | 660.9 |
| 2030-07-08 | 155.662 | 244.34 | 721.894 |
| 2030-07-09 | 140.202 | 352.927 | 717.395 |
| 2030-07-10 | 111.138 | 228.528 | 735.829 |
| 2030-07-11 | 151.548 | 283.848 | 716.733 |
| 2030-07-12 | 193.122 | 521.339 | 708.152 |
| 2030-07-13 | 138.444 | 709.461 | 654.606 |
| 2030-07-14 | 137.829 | 511.203 | 627.959 |
| 2030-07-15 | 185.261 | 358.558 | 687.302 |
| 2030-07-16 | 126.386 | 659.727 | 684.851 |
| 2030-07-17 | 149.317 | 875.271 | 690.882 |
| 2030-07-18 | 221.694 | 592.102 | 703.091 |
| 2030-07-19 | 217.835 | 191.409 | 698.305 |
| 2030-07-20 | 231.499 | 336.016 | 658.515 |
| 2030-07-21 | 204.927 | 430.862 | 649.463 |
| 2030-07-22 | 149.096 | 224.217 | 710.828 |
| 2030-07-23 | 198.858 | 264.416 | 718.199 |
| 2030-07-24 | 213.435 | 251.886 | 748.596 |
| 2030-07-25 | 222.982 | 326.638 | 718.284 |
| 2030-07-26 | 205.629 | 343.752 | 700.302 |
| 2030-07-27 | 164.193 | 273.712 | 654.805 |
| 2030-07-28 | 171.194 | 272.556 | 640.809 |
| 2030-07-29 | 194.85 | 398.639 | 699.159 |
| 2030-07-30 | 185.697 | 495.378 | 706.937 |
| 2030-07-31 | 79.2072 | 453.319 | 702.832 |
| 2030-08-01 | 90.6447 | 345.344 | 690.611 |
| 2030-08-02 | 164.256 | 480.808 | 673.137 |
| 2030-08-03 | 152.606 | 731.126 | 630.699 |
| 2030-08-04 | 220.308 | 688.756 | 636.877 |
| 2030-08-05 | 224.355 | 835.327 | 703.702 |
| 2030-08-06 | 215.193 | 556.634 | 709.365 |
| 2030-08-07 | 213.618 | 336.041 | 709.892 |
| 2030-08-08 | 185.133 | 403.743 | 714.797 |
| 2030-08-09 | 259.931 | 338.88 | 713.042 |
| 2030-08-10 | 279.069 | 267.27 | 678.488 |
| 2030-08-11 | 280.881 | 336.876 | 656.914 |
| 2030-08-12 | 243.649 | 465.966 | 699.162 |
| 2030-08-13 | 55.8472 | 661.734 | 714.354 |
| 2030-08-14 | 125.565 | 683.487 | 703.804 |
| 2030-08-15 | 201.988 | 873.999 | 710.922 |
| 2030-08-16 | 258.691 | 399.048 | 695.864 |
| 2030-08-17 | 249.581 | 569.719 | 653.44 |
| 2030-08-18 | 206.633 | 795.694 | 635.4 |
| 2030-08-19 | 259.121 | 686.652 | 700.496 |
| 2030-08-20 | 306.037 | 390.901 | 710.937 |
| 2030-08-21 | 196.806 | 736.843 | 726.647 |
| 2030-08-22 | 203.173 | 802.897 | 682.912 |
| 2030-08-23 | 191.523 | 699.08 | 693.246 |
| 2030-08-24 | 261.908 | 565.15 | 653.463 |
| 2030-08-25 | 271.854 | 410.081 | 638.819 |
| 2030-08-26 | 106.488 | 569.465 | 693.464 |
| 2030-08-27 | 189.624 | 748.627 | 703.232 |
| 2030-08-28 | 168.661 | 820.287 | 716.833 |
| 2030-08-29 | 173.726 | 821.603 | 706.672 |
| 2030-08-30 | 239.987 | 666.676 | 691.573 |
| 2030-08-31 | 266.508 | 201.213 | 651.298 |
| 2030-09-01 | 251.587 | 172.908 | 628.949 |
| 2030-09-02 | 270.892 | 267.872 | 675.834 |
| 2030-09-03 | 242.865 | 525.073 | 678.018 |
| 2030-09-04 | 177.041 | 505.691 | 671.947 |
| 2030-09-05 | 231.433 | 391.496 | 673.591 |
| 2030-09-06 | 159.681 | 594.754 | 677.371 |
| 2030-09-07 | 84.3612 | 898.926 | 624.806 |
| 2030-09-08 | 182.183 | 642.993 | 610.164 |
| 2030-09-09 | 246.742 | 313.746 | 672.776 |
| 2030-09-10 | 296.465 | 228.271 | 682.598 |
| 2030-09-11 | 287.663 | 426.828 | 674.633 |
| 2030-09-12 | 179.404 | 504.876 | 665.729 |
| 2030-09-13 | 187.112 | 727.335 | 665.132 |
| 2030-09-14 | 321.424 | 389.628 | 628.983 |
| 2030-09-15 | 275.024 | 344.054 | 605.288 |
| 2030-09-16 | 236.683 | 393.375 | 657.648 |
| 2030-09-17 | 199.68 | 335.303 | 669.439 |
| 2030-09-18 | 290.949 | 729.46 | 670.787 |
| 2030-09-19 | 239.735 | 695.448 | 672.239 |
| 2030-09-20 | 232.812 | 505.333 | 669.952 |
| 2030-09-21 | 240.841 | 394.363 | 624.521 |
| 2030-09-22 | 146.784 | 337.839 | 610.159 |
| 2030-09-23 | 178.038 | 334.146 | 659.771 |
| 2030-09-24 | 230.347 | 287.417 | 661.836 |
| 2030-09-25 | 247.634 | 387.179 | 656.28 |
| 2030-09-26 | 243.208 | 262.442 | 656.545 |
| 2030-09-27 | 288.934 | 292.046 | 652.572 |
| 2030-09-28 | 239.277 | 406.198 | 601.095 |
| 2030-09-29 | 323.085 | 224.118 | 593.536 |
| 2030-09-30 | 260.991 | 530.425 | 644.606 |
| 2030-10-01 | 274.93 | 432.996 | 667.44 |
| 2030-10-02 | 331.619 | 417.449 | 672.837 |
| 2030-10-03 | 332.821 | 295.044 | 670.442 |
| 2030-10-04 | 243.736 | 417.3 | 649.822 |
| 2030-10-05 | 237.082 | 461.865 | 609.212 |
| 2030-10-06 | 228.715 | 634.073 | 584.473 |
| 2030-10-07 | 268.019 | 545.4 | 610.138 |
| 2030-10-08 | 334.603 | 298.342 | 639.919 |
| 2030-10-09 | 274.05 | 417.847 | 642.319 |
| 2030-10-10 | 259.091 | 483.138 | 656.595 |
| 2030-10-11 | 186.418 | 350.381 | 645.456 |
| 2030-10-12 | 205.829 | 433.915 | 602.755 |
| 2030-10-13 | 233.163 | 711.715 | 590.039 |
| 2030-10-14 | 214.445 | 834.215 | 636.004 |
| 2030-10-15 | 179.121 | 579.709 | 639.153 |
| 2030-10-16 | 132.244 | 346.591 | 643.447 |
| 2030-10-17 | 185.002 | 451.485 | 639.616 |
| 2030-10-18 | 57.0936 | 898.405 | 656.451 |
| 2030-10-19 | 303.352 | 886.283 | 633.732 |
| 2030-10-20 | 328.513 | 486.301 | 607.556 |
| 2030-10-21 | 369.517 | 336.943 | 652.818 |
| 2030-10-22 | 381.325 | 255.986 | 652.207 |
| 2030-10-23 | 355.264 | 361.925 | 636.733 |
| 2030-10-24 | 292.241 | 286.958 | 630.647 |
| 2030-10-25 | 315.099 | 379.636 | 628.639 |
| 2030-10-26 | 279.476 | 337.463 | 594.573 |
| 2030-10-27 | 285.851 | 273.998 | 601.176 |
| 2030-10-28 | 326.962 | 183.626 | 637.247 |
| 2030-10-29 | 328.584 | 233.408 | 636.34 |
| 2030-10-30 | 369.413 | 200.527 | 637.781 |
| 2030-10-31 | 347.63 | 460.74 | 637.076 |
| 2030-11-01 | 321.715 | 534.656 | 630.462 |
| 2030-11-02 | 223.36 | 516.457 | 591.036 |
| 2030-11-03 | 242.579 | 491.037 | 585.225 |
| 2030-11-04 | 178.341 | 228.134 | 629.296 |
| 2030-11-05 | 317.021 | 403.42 | 620.477 |
| 2030-11-06 | 326.318 | 229.825 | 639.348 |
| 2030-11-07 | 199.679 | 349.613 | 639.226 |
| 2030-11-08 | 289.556 | 493.983 | 632.239 |
| 2030-11-09 | 335.424 | 488.204 | 596.231 |
| 2030-11-10 | 336.964 | 492.867 | 578.121 |
| 2030-11-11 | 303.25 | 418.776 | 632.004 |
| 2030-11-12 | 316.398 | 334.439 | 640.178 |
| 2030-11-13 | 254.86 | 376.626 | 640.953 |
| 2030-11-14 | 309.047 | 220.549 | 652.607 |
| 2030-11-15 | 284.767 | 434.196 | 658.009 |
| 2030-11-16 | 200.583 | 439.039 | 614.139 |
| 2030-11-17 | 217.622 | 351.2 | 601.095 |
| 2030-11-18 | 207.285 | 240.924 | 645.452 |
| 2030-11-19 | 268.747 | 178.065 | 644.461 |
| 2030-11-20 | 307.361 | 263.927 | 641.422 |
| 2030-11-21 | 228.141 | 256.82 | 640.606 |
| 2030-11-22 | 317.046 | 370.236 | 636.937 |
| 2030-11-23 | 339.103 | 464.404 | 596.283 |
| 2030-11-24 | 324.156 | 436.319 | 587.272 |
| 2030-11-25 | 354.773 | 563.261 | 655.565 |
| 2030-11-26 | 345.644 | 674.201 | 672.628 |
| 2030-11-27 | 295.385 | 554.252 | 665.925 |
| 2030-11-28 | 284.036 | 350.134 | 654.673 |
| 2030-11-29 | 273.126 | 306.676 | 649.896 |
| 2030-11-30 | 237.03 | 514.894 | 603.586 |
| 2030-12-01 | 128.989 | 549.636 | 581.714 |
| 2030-12-02 | 206.9 | 466.941 | 635.456 |
| 2030-12-03 | 153.25 | 593.922 | 637.296 |
| 2030-12-04 | 150.786 | 517.886 | 634.037 |
| 2030-12-05 | 224.43 | 423.637 | 643.129 |
| 2030-12-06 | 200.794 | 378.982 | 645.783 |
| 2030-12-07 | 235.708 | 315.782 | 617.462 |
| 2030-12-08 | 262.271 | 310.923 | 601.167 |
| 2030-12-09 | 251.74 | 476.321 | 665.811 |
| 2030-12-10 | 297.164 | 683.12 | 671.891 |
| 2030-12-11 | 248.864 | 592.404 | 669.04 |
| 2030-12-12 | 298.833 | 444.519 | 671.212 |
| 2030-12-13 | 287.266 | 513.74 | 657.369 |
| 2030-12-14 | 306.107 | 467.247 | 605.658 |
| 2030-12-15 | 332.61 | 393.51 | 589.58 |
| 2030-12-16 | 432.51 | 190.174 | 650.745 |
| 2030-12-17 | 371.368 | 316.86 | 661.017 |
| 2030-12-18 | 360.006 | 391.004 | 664.938 |
| 2030-12-19 | 334.637 | 251.083 | 650.562 |
| 2030-12-20 | 232.947 | 466.108 | 643.822 |
| 2030-12-21 | 205.887 | 478.589 | 599.306 |
| 2030-12-22 | 132.542 | 561.502 | 580.484 |
| 2030-12-23 | 337.351 | 721.552 | 626.709 |
| 2030-12-24 | 400.335 | 358.334 | 632.643 |
| 2030-12-25 | 267.627 | 591.623 | 566.683 |
| 2030-12-26 | 318.677 | 462.118 | 567.91 |
| 2030-12-27 | 297.2 | 592.055 | 602.475 |
| 2030-12-28 | 221.883 | 354.374 | 547.968 |
| 2030-12-29 | 195.442 | 469.682 | 550.678 |
| 2030-12-30 | 337.543 | 717.433 | 626.568 |
| 2030-12-31 | 400.559 | 353.064 | 632.767 |


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

