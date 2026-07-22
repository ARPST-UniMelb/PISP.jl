```@meta
EditURL = "../../../../literate/isp2024/validation/generated_output_consistency.jl"
```

# ISP 2024: Generated-output consistency

This validation checks identifier coverage, schedule coverage, generator classification, and daily solar, wind, and demand alignment for one generated ISP 2024 build.
Supporting tables are saved under `eda/tables/julia/06_pisp_outputs/`, and the selected figures summarise the same computed evidence.

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
            checked_unique_ids = length(left_set) + length(right_set),
            matched_unique_ids = length(intersect(left_set, right_set)),
            unmatched_unique_ids = length(left_unmatched) + length(right_unmatched),
            unmatched_pct = isempty(left_set) && isempty(right_set) ? 0.0 :
                100 * (length(left_unmatched) + length(right_unmatched)) /
                (length(left_set) + length(right_set)),
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
The static field is not a reliable capacity reference for these generators: rooftop PV rows carry a fixed placeholder pmax ([`src/parsers/PISP-2024parser.jl`](https://github.com/ARPST-UniMelb/PISP.jl/blob/main/src/parsers/PISP-2024parser.jl):1070, `gen_pmax_distpv`), and utility-scale solar/wind rows record only currently operating capacity, which a future-year schedule can exceed once ISP-outlook build-out is reflected in the trace (`gen_pmax_wind`, ~1386 vs. ~1477 in the same file).
[SiennaNEM.jl](https://github.com/ARPST-UniMelb/SiennaNEM.jl), which builds unit-commitment models from this same PISP output, applies the same convention ([`src/read_data.jl`](https://github.com/ARPST-UniMelb/SiennaNEM.jl/blob/main/src/read_data.jl):214-229, `update_system_data_bound!`) and calls the static pmax "dummy" for these generators ([`src/create_system.jl`](https://github.com/ARPST-UniMelb/SiennaNEM.jl/blob/main/src/create_system.jl):342,368).
See the generated Parameters and mappings page and `docs/src/assumptions.md` for the full caveat.

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

## Selected build and inputs

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

## Build identity

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
|:--|:--|:--|
| data/2024/pisp-datasets/out-ref4006-poe10/csv | schedule-2030 | data/2024/pisp-datasets/out-ref4006-poe10/csv/schedule-2030 |


## Generator coverage

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
|:--|--:|
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
|:--|--:|
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


## Schedule coverage

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
|:--|--:|--:|
| Generator\_pmax\_sched | 867243 | 5 |
| Demand\_load\_sched | 315360 | 5 |


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
|:--|:--|:--|--:|--:|
| Generator\_pmax\_sched | 2030-01-01T00:00:00 | 2044-07-01T00:00:00 | 8761 | 366 |
| Demand\_load\_sched | 2030-01-01T00:00:00 | 2030-12-31T23:00:00 | 8760 | 365 |


## Static-to-schedule join coverage

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
join_coverage_display = select(
    join_coverage,
    :relationship => Symbol("Relationship"),
    :checked_unique_ids => Symbol("Unique IDs checked"),
    :matched_unique_ids => Symbol("Matched IDs"),
    :unmatched_unique_ids => Symbol("Unmatched IDs"),
    :unmatched_pct => Symbol("Unmatched (%)"),
)
markdown_table(join_coverage_display)
````

```@raw html
</details>
```

| **Relationship** | **Unique IDs checked** | **Matched IDs** | **Unmatched IDs** | **Unmatched (%)** |
|:--|--:|--:|--:|--:|
| generator schedule to static generator | 158 | 34 | 90 | 56.962 |
| demand schedule to static demand | 24 | 12 | 0 | 0.0 |
| generator bus to bus table | 24 | 12 | 0 | 0.0 |
| demand bus to bus table | 24 | 12 | 0 | 0.0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
unmatched_ids = isempty(join_detail_rows) ? DataFrame(relationship = String[], unmatched_side = String[], id = String[]) : DataFrame(join_detail_rows)
write_table(unmatched_ids, SCRIPT_STEM, "unmatched_ids")
if isempty(unmatched_ids)
    metric_value_table(["Unmatched identifiers" => 0])
else
    unmatched_summary = combine(
        groupby(unmatched_ids, [:relationship, :unmatched_side]),
        nrow => :unmatched_count,
    )
    markdown_table(unmatched_summary; column_labels = ["Relationship", "Unmatched side", "Count"])

    unmatched_examples = vcat(
        [first(group, min(5, nrow(group))) for group in groupby(unmatched_ids, :relationship)]...;
        cols = :union,
    )
    # At most five identifiers per relationship are shown; the complete list remains in `unmatched_ids.csv`.
    markdown_table(unmatched_examples; column_labels = ["Relationship", "Unmatched side", "Identifier"])
end
````

```@raw html
</details>
```

| **Relationship** | **Unmatched side** | **Identifier** |
|:--|:--|:--|
| generator schedule to static generator | Generator.id\_gen | 1 |
| generator schedule to static generator | Generator.id\_gen | 2 |
| generator schedule to static generator | Generator.id\_gen | 3 |
| generator schedule to static generator | Generator.id\_gen | 4 |
| generator schedule to static generator | Generator.id\_gen | 5 |


## Renewable classification

Solar and wind generators are identified from `Generator.tech` with one case-insensitive pattern match used consistently throughout the validation.

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
|:--|--:|
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
|:--|:--|--:|
| solar | RoofPV | 12 |
| solar | LargePV | 10 |
| wind | Wind | 11 |


## Annual mean available output

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
|:--|--:|--:|
| solar | 92 | 155.907 |
| solar | 93 | 165.396 |
| solar | 94 | 15.489 |
| solar | 95 | 1075.06 |
| solar | 96 | 220.029 |
| solar | 97 | 138.072 |
| solar | 98 | 1035.13 |
| solar | 99 | 239.17 |
| solar | 100 | 1176.94 |
| solar | 101 | 69.4871 |
| solar | 102 | 528.324 |
| solar | 103 | 21.952 |
| solar | 104 | 928.051 |
| solar | 105 | 927.829 |
| solar | 106 | 661.881 |
| solar | 107 | 907.72 |
| solar | 108 | 517.949 |
| solar | 109 | 777.506 |
| solar | 110 | 938.221 |
| solar | 111 | 1370.82 |
| solar | 112 | 21.184 |
| solar | 113 | 9.7209 |
| wind | 114 | 1857.69 |
| wind | 115 | 4846.46 |
| wind | 116 | 1725.65 |
| wind | 117 | 2240.35 |
| wind | 118 | 1609.93 |
| wind | 119 | 1944.25 |
| wind | 120 | 1444.67 |
| wind | 121 | 2704.88 |
| wind | 122 | 1768.3 |
| wind | 123 | 267.823 |
| wind | 124 | 0.0 |


## Capacity-factor duration

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
|:--|--:|--:|
| solar | 1 | 0.236929 |
| solar | 2 | 0.226594 |
| solar | 3 | 0.181941 |
| solar | 4 | 0.166754 |
| solar | 5 | 0.163866 |
| solar | 6 | 0.162742 |
| solar | 7 | 0.159858 |
| solar | 8 | 0.159474 |
| solar | 9 | 0.159196 |
| solar | 10 | 0.158282 |
| solar | 11 | 0.157504 |
| solar | 12 | 0.156229 |
| solar | 13 | 0.154617 |
| solar | 14 | 0.149317 |
| solar | 15 | 0.147794 |
| solar | 16 | 0.140268 |
| solar | 17 | 0.136418 |
| solar | 18 | 0.113766 |
| solar | 19 | 0.112869 |
| solar | 20 | 0.109473 |
| solar | 21 | 0.104435 |
| solar | 22 | 0.0655664 |
| wind | 1 | 0.344141 |
| wind | 2 | 0.306527 |
| wind | 3 | 0.294099 |
| wind | 4 | 0.292721 |
| wind | 5 | 0.27232 |
| wind | 6 | 0.268375 |
| wind | 7 | 0.242306 |
| wind | 8 | 0.240554 |
| wind | 9 | 0.216236 |
| wind | 10 | 0.204271 |


## Demand by area

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
|:--|--:|--:|--:|
| QLD | 5.37443e5 | 468511.0 | 7.22287e5 |
| NSW | 6.76902e5 | 565987.0 | 9.93262e5 |
| VIC | 4.67028e5 | 3.55937e5 | 7.20187e5 |
| TAS | 92938.2 | 78027.4 | 1.14262e5 |
| SA | 1.52058e5 | 1.20325e5 | 240546.0 |


## Daily aggregate profiles

Generator schedules are joined to generator technology before summing solar and wind pmax separately by day; the demand schedule's daily total is combined alongside them and converted from MW to GW. The complete daily series is written to `daily_solar_wind_demand_gw.csv`; the table below shows the first 10 dates.

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
|:--|--:|--:|--:|
| 2030-01-01 | 1246.71 | 949.769 | 1798.78 |
| 2030-01-02 | 1145.46 | 1557.08 | 2284.5 |
| 2030-01-03 | 989.282 | 1244.29 | 1997.75 |
| 2030-01-04 | 1152.08 | 1298.23 | 2007.67 |
| 2030-01-05 | 1087.16 | 1690.19 | 1961.72 |
| 2030-01-06 | 1022.48 | 1219.31 | 1804.34 |
| 2030-01-07 | 868.513 | 1129.14 | 1887.91 |
| 2030-01-08 | 1126.54 | 1512.55 | 1988.29 |
| 2030-01-09 | 1145.92 | 1568.4 | 2285.53 |
| 2030-01-10 | 989.648 | 1242.56 | 2001.33 |


## Hourly available-output profile

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
|:--|--:|--:|
| solar | 0 | 0.0 |
| solar | 1 | 0.0 |
| solar | 2 | 0.0 |
| solar | 3 | 0.0 |
| solar | 4 | 0.204708 |
| solar | 5 | 49.8679 |
| solar | 6 | 419.354 |
| solar | 7 | 984.439 |
| solar | 8 | 1296.43 |
| solar | 9 | 1504.42 |
| solar | 10 | 1618.38 |
| solar | 11 | 1663.9 |
| solar | 12 | 1659.36 |
| solar | 13 | 1600.8 |
| solar | 14 | 1460.96 |
| solar | 15 | 1285.84 |
| solar | 16 | 1051.72 |
| solar | 17 | 679.452 |
| solar | 18 | 220.837 |
| solar | 19 | 18.3051 |
| solar | 20 | 0.0 |
| solar | 21 | 0.0 |
| solar | 22 | 0.0 |
| solar | 23 | 0.0 |
| wind | 0 | 1956.45 |
| wind | 1 | 1908.84 |
| wind | 2 | 1849.24 |
| wind | 3 | 1776.48 |
| wind | 4 | 1722.91 |
| wind | 5 | 1701.01 |
| wind | 6 | 1641.53 |
| wind | 7 | 1558.17 |
| wind | 8 | 1534.13 |
| wind | 9 | 1500.53 |
| wind | 10 | 1464.37 |
| wind | 11 | 1448.04 |
| wind | 12 | 1466.72 |
| wind | 13 | 1523.24 |
| wind | 14 | 1591.95 |
| wind | 15 | 1692.36 |
| wind | 16 | 1799.88 |
| wind | 17 | 1884.56 |
| wind | 18 | 1968.9 |
| wind | 19 | 2035.49 |
| wind | 20 | 2088.87 |
| wind | 21 | 2089.55 |
| wind | 22 | 2071.23 |
| wind | 23 | 2035.35 |


## Renewable availability and demand summaries

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
metric_value_table([
    "Days" => vre_vs_demand_summary.n_days[1],
    "Mean demand (GW)" => vre_vs_demand_summary.mean_demand_gw[1],
    "Mean VRE (GW)" => vre_vs_demand_summary.mean_vre_gw[1],
    "Minimum demand (GW)" => vre_vs_demand_summary.min_demand_gw[1],
    "Maximum demand (GW)" => vre_vs_demand_summary.max_demand_gw[1],
    "Minimum VRE (GW)" => vre_vs_demand_summary.min_vre_gw[1],
    "Maximum VRE (GW)" => vre_vs_demand_summary.max_vre_gw[1],
    "Demand-VRE correlation" => vre_vs_demand_summary.corr_demand_vre[1],
])
````

```@raw html
</details>
```

| **Metric** | **Value** |
|:--|:--|
| Days | 365.0 |
| Mean demand (GW) | 1926.37 |
| Mean VRE (GW) | 2326.45 |
| Minimum demand (GW) | 1608.96 |
| Maximum demand (GW) | 2285.53 |
| Minimum VRE (GW) | 780.444 |
| Maximum VRE (GW) | 4103.23 |
| Demand-VRE correlation | -0.0554535 |


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
metric_value_table([
    "Days" => demand_distribution_summary.n[1],
    "Mean demand (MW)" => demand_distribution_summary.mean_mw[1],
    "Demand standard deviation (MW)" => demand_distribution_summary.std_mw[1],
    "Minimum demand (MW)" => demand_distribution_summary.min_mw[1],
    "Maximum demand (MW)" => demand_distribution_summary.max_mw[1],
    "Median demand (MW)" => demand_distribution_summary.median_mw[1],
])
````

```@raw html
</details>
```

| **Metric** | **Value** |
|:--|:--|
| Days | 365.0 |
| Mean demand (MW) | 1.92637e6 |
| Demand standard deviation (MW) | 1.20642e5 |
| Minimum demand (MW) | 1.60896e6 |
| Maximum demand (MW) | 2.28553e6 |
| Median demand (MW) | 1.92103e6 |


## Output overview

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

## Renewable availability and demand over time

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

## Detailed output diagnostics

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
- Solar and wind classification, annual mean available output, and capacity-factor duration follow the denominator convention documented on `capacity_factor_duration_frame`.
- The figures and tables use the same joined static and schedule inputs.
- Complete diagnostics are saved under `eda/tables/julia/06_pisp_outputs/`; no historical thresholds are applied.

