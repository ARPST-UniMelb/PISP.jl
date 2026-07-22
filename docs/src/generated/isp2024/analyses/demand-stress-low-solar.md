```@meta
EditURL = "../../../../literate/isp2024/analysis/demand_stress_low_solar.jl"
```

# ISP 2024: Demand stress and low-solar coincidence

High demand can coincide with low renewable availability, but that relationship depends on aligned dates, explicit thresholds, and a precise event definition.
The analysis combines the Victorian demand schedule from the selected `schedule-2030` PISP output with the Bannerton reference-trace `4006` solar series.

## Definitions and data

| Item | Definition |
|---|---|
| ISP edition | ISP 2024 |
| Demand evidence | Generated PISP demand schedule, POE10 premise, Victorian area `3` |
| Solar evidence | Raw `4006` trace for `Bannerton_SAT` |
| Time aggregation | Half-hourly inputs reduced to daily mean demand and daily mean solar capacity factor |
| Coincidence screen | Demand above P90 and solar capacity factor below P10 within the matched sample |
| Demand-stress group | Demand at or above P95 |
| Normal group | Demand below P90; P90-P95 days are excluded from both groups |
| Date alignment | Inner match on exact calendar date |

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

const SCRIPT_STEM = "isp2024_07_demand_heat_events"
````

```@raw html
</details>
```

````
"isp2024_07_demand_heat_events"
````

The historical evidence and figure basenames retain `heat` for compatibility.
Reader-facing terminology and executable variables use `demand_stress` because no meteorological heatwave criterion is applied.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const TRACES = relpath(joinpath(ISP2024_PROFILE.download_root, "Traces"), REPO_ROOT)  # kept relative: this is the path form recorded in the tables below
const OUTPUT_ROOT = ISP2024_PROFILE.output_root
OUTPUT_ROOT === nothing && error(
    "ISP 2024 profile does not define output_root; set PISP_DOCS_ISP2024_OUTPUT_ROOT to select a local output build.",
)
const OUT = relpath(OUTPUT_ROOT, REPO_ROOT)  # kept relative, same reason
const SCHEDULE_TAG = ISP2024_PROFILE.schedule_tag
SCHEDULE_TAG === nothing && error(
    "ISP 2024 profile does not define schedule_tag; set PISP_DOCS_ISP2024_SCHEDULE_TAG to select a local schedule.",
)

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a TRACES/OUT-relative path to an absolute file location for reading

const HH_COLS_SOL = string.(1:48)

function daily_cf(df::DataFrame, half_hour_cols)
    return [mean(Float64(row[col]) for col in half_hour_cols) for row in eachrow(df)]
end

function load_solar_4006(loc)
    file = joinpath(TRACES, "solar_4006", "$(loc)_RefYear4006.csv")
    isfile(abs_path(file)) || return nothing
    df = CSV.read(abs_path(file), DataFrame)
    df.datetime = Date.(df.Year, df.Month, df.Day)
    return df
end

"""
    solar_cf_by_date(df)

Maps each exact calendar date in a composite RefYear4006 trace to its half-hourly-mean solar capacity factor for that date.
"""
function solar_cf_by_date(df::DataFrame)
    cfs = daily_cf(df, HH_COLS_SOL)
    return Dict(zip(df.datetime, cfs))
end
````

```@raw html
</details>
```

## Demand input inventory

The demand trace family stores one POE10 operational-schedule file per network node under a state/scenario directory; this step lists every such file as the input inventory.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
dem_dir = joinpath(TRACES, "demand_VIC_Step Change")
dem_files = sort(filter(name -> endswith(name, "_POE10_OPSO_MODELLING.csv"), readdir(abs_path(dem_dir))))
println("Found $(length(dem_files)) demand trace files")

demand_trace_inventory = DataFrame(file = dem_files)
write_table(demand_trace_inventory, SCRIPT_STEM, "demand_trace_inventory")
markdown_table(demand_trace_inventory)
````

```@raw html
</details>
```

| **file** |
|:--|
| VIC\_RefYear\_2011\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2012\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2013\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2014\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2015\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2016\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2017\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2018\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2019\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2020\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2021\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2022\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |
| VIC\_RefYear\_2023\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING.csv |


## Regional demand construction

The PISP model output records each network node's half-hourly demand schedule and its bus, and each bus's NEM area; joining these mappings supports daily mean demand by area. The complete daily-by-area table is written to `demand_by_area_daily.csv`, and the table below summarises each area.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
dem_load = CSV.read(abs_path(joinpath(OUT, SCHEDULE_TAG, "Demand_load_sched.csv")), DataFrame)
dem_df = CSV.read(abs_path(joinpath(OUT, "Demand.csv")), DataFrame)
bus_df = CSV.read(abs_path(joinpath(OUT, "Bus.csv")), DataFrame)

area_map = Dict(row.id_bus => row.id_area for row in eachrow(bus_df))
bus_of_dem = Dict(row.id_dem => row.id_bus for row in eachrow(dem_df))

dem_load.area = [area_map[bus_of_dem[d]] for d in dem_load.id_dem]
dem_load.date_only = Date.(dem_load.date)

dem_daily = combine(groupby(dem_load, [:date_only, :area]), :value => mean => :demand_mw)
rename!(dem_daily, :date_only => :date)
write_table(dem_daily, SCRIPT_STEM, "demand_by_area_daily")

area_demand_summary = combine(
    groupby(dem_daily, :area),
    :demand_mw => mean => :mean_demand_mw,
    :demand_mw => minimum => :min_demand_mw,
    :demand_mw => maximum => :max_demand_mw,
    nrow => :n_days,
)
sort!(area_demand_summary, :area)
markdown_table(area_demand_summary)
````

```@raw html
</details>
```

| **area** | **mean\_demand\_mw** | **min\_demand\_mw** | **max\_demand\_mw** | **n\_days** |
|--:|--:|--:|--:|--:|
| 1 | 1866.12 | 1626.77 | 2507.94 | 365 |
| 2 | 2350.35 | 1965.23 | 3448.83 | 365 |
| 3 | 6486.5 | 4943.57 | 10002.6 | 365 |
| 4 | 1290.81 | 1083.71 | 1586.97 | 365 |
| 5 | 1055.96 | 835.589 | 1670.46 | 365 |


## Representative Victorian solar input

`Bannerton_SAT` is the representative VIC solar site used throughout this analysis; `Darlington_Point_SAT` is also checked as a candidate even though only Bannerton is used downstream.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
locations = ["Bannerton_SAT", "Darlington_Point_SAT"]
sol_4006 = Dict{String, DataFrame}()
for loc in locations
    df = load_solar_4006(loc)
    df === nothing || (sol_4006[loc] = df)
end
println("Loaded $(length(sol_4006)) solar locations for 4006")
````

```@raw html
</details>
```

````
Loaded 2 solar locations for 4006

````

## Victorian daily demand series

Area `3` is the Victorian NEM region in this bus-to-area mapping; the half-hourly schedule for that area is averaged to one daily mean demand value per calendar date.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vic_dem = dem_load[dem_load.area .== 3, :]
vic_daily = combine(groupby(vic_dem, :date_only), :value => mean => :demand)
sort!(vic_daily, :date_only)
````

```@raw html
</details>
```

## Daily alignment and matched coverage

Only calendar dates present in both the VIC demand schedule and the Bannerton 4006 solar trace are retained, so the merged sample can be smaller than either input series. The complete merged series is written to `vic_demand_solar_merged.csv`; the metric summary below reports its coverage and range.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
merged = DataFrame(date = Date[], demand = Float64[], solar_cf = Float64[])
if haskey(sol_4006, "Bannerton_SAT")
    cf_of_date = solar_cf_by_date(sol_4006["Bannerton_SAT"])
    for row in eachrow(vic_daily)
        haskey(cf_of_date, row.date_only) || continue
        push!(merged, (date = row.date_only, demand = row.demand, solar_cf = cf_of_date[row.date_only]))
    end
    write_table(merged, SCRIPT_STEM, "vic_demand_solar_merged")
end

merged_summary = DataFrame(
    matched_days = nrow(merged),
    date_min = isempty(merged.date) ? missing : minimum(merged.date),
    date_max = isempty(merged.date) ? missing : maximum(merged.date),
    demand_mean_mw = isempty(merged.demand) ? missing : mean(merged.demand),
    demand_min_mw = isempty(merged.demand) ? missing : minimum(merged.demand),
    demand_max_mw = isempty(merged.demand) ? missing : maximum(merged.demand),
    solar_cf_mean = isempty(merged.solar_cf) ? missing : mean(merged.solar_cf),
    solar_cf_min = isempty(merged.solar_cf) ? missing : minimum(merged.solar_cf),
    solar_cf_max = isempty(merged.solar_cf) ? missing : maximum(merged.solar_cf),
)
metric_value_table([
    "Matched days" => merged_summary.matched_days[1],
    "First date" => merged_summary.date_min[1],
    "Last date" => merged_summary.date_max[1],
    "Mean demand (MW)" => merged_summary.demand_mean_mw[1],
    "Minimum demand (MW)" => merged_summary.demand_min_mw[1],
    "Maximum demand (MW)" => merged_summary.demand_max_mw[1],
    "Mean solar capacity factor" => merged_summary.solar_cf_mean[1],
    "Minimum solar capacity factor" => merged_summary.solar_cf_min[1],
    "Maximum solar capacity factor" => merged_summary.solar_cf_max[1],
])
````

```@raw html
</details>
```

| **Metric** | **Value** |
|:--|:--|
| Matched days | 365 |
| First date | 2030-01-01 |
| Last date | 2030-12-31 |
| Mean demand (MW) | 6486.5 |
| Minimum demand (MW) | 4943.57 |
| Maximum demand (MW) | 10002.6 |
| Mean solar capacity factor | 0.26346 |
| Minimum solar capacity factor | 0.0095789 |
| Maximum solar capacity factor | 0.499403 |


## Coincidence results

The screen flags days above the 90th demand percentile that also fall below the 10th solar-capacity-factor percentile, within the merged sample above.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
if haskey(sol_4006, "Bannerton_SAT")
    threshold_demand = quantile(merged.demand, 0.9)
    threshold_solar = quantile(merged.solar_cf, 0.1)
    bad_days = merged[(merged.demand .> threshold_demand) .& (merged.solar_cf .< threshold_solar), :]
    @printf("\nHigh-demand + Low-solar days: %d\n", nrow(bad_days))
    @printf("  Threshold: demand > %.0f MW, solar CF < %.3f\n", threshold_demand, threshold_solar)

    high_demand_low_solar_summary = DataFrame(
        demand_quantile = 0.9,
        solar_quantile = 0.1,
        threshold_demand_mw = threshold_demand,
        threshold_solar_cf = threshold_solar,
        bad_day_count = nrow(bad_days),
        total_day_count = nrow(merged),
    )
    write_table(high_demand_low_solar_summary, SCRIPT_STEM, "high_demand_low_solar_summary")
    metric_value_table([
        "Demand quantile" => high_demand_low_solar_summary.demand_quantile[1],
        "Solar quantile" => high_demand_low_solar_summary.solar_quantile[1],
        "Demand threshold (MW)" => high_demand_low_solar_summary.threshold_demand_mw[1],
        "Solar threshold (capacity factor)" => high_demand_low_solar_summary.threshold_solar_cf[1],
        "Coincident days" => high_demand_low_solar_summary.bad_day_count[1],
        "Days checked" => high_demand_low_solar_summary.total_day_count[1],
    ])
end
````

```@raw html
</details>
```

| **Metric** | **Value** |
|:--|:--|
| Demand quantile | 0.9 |
| Solar quantile | 0.1 |
| Demand threshold (MW) | 7313.93 |
| Solar threshold (capacity factor) | 0.0912422 |
| Coincident days | 3.0 |
| Days checked | 365.0 |


## Demand-stress and normal-day groups

Demand-stress days sit at or above the 95th demand percentile; normal days sit below the 90th percentile. Days between P90 and P95 are excluded from both groups.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_p90 = quantile(vic_daily.demand, 0.9)
demand_p95 = quantile(vic_daily.demand, 0.95)

demand_stress_days = vic_daily[vic_daily.demand .>= demand_p95, :date_only]
normal_days = Set(vic_daily[vic_daily.demand .< demand_p90, :date_only])
demand_stress_days_set = Set(demand_stress_days)

@printf("\nDemand thresholds: P90=%.0f MW, P95=%.0f MW\n", demand_p90, demand_p95)
println("Demand-stress days (>P95): ", length(demand_stress_days))
println("Normal days (<P90): ", length(normal_days))
````

```@raw html
</details>
```

````

Demand thresholds: P90=7314 MW, P95=7443 MW
Demand-stress days (>P95): 19
Normal days (<P90): 328

````

## Intraday demand shape on stress and normal days

Half-hourly demand observations on demand-stress days and normal days are each averaged by hour of day, allowing the intraday profile shape of the two groups to be compared.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_stress_df = vic_dem[in.(vic_dem.date_only, Ref(demand_stress_days_set)), :]
normal_df = vic_dem[in.(vic_dem.date_only, Ref(normal_days)), :]
demand_stress_df = transform(demand_stress_df, :date => ByRow(hour) => :hour)
normal_df = transform(normal_df, :date => ByRow(hour) => :hour)

demand_stress_hourly = Dict(row.hour => row.value_mean for row in eachrow(combine(groupby(demand_stress_df, :hour), :value => mean => :value_mean)))
normal_hourly = Dict(row.hour => row.value_mean for row in eachrow(combine(groupby(normal_df, :hour), :value => mean => :value_mean)))

stress_normal_hourly_profile = DataFrame(
    hour = 0:23,
    demand_stress_mean_demand_mw = [get(demand_stress_hourly, h, missing) for h in 0:23],
    normal_mean_demand_mw = [get(normal_hourly, h, missing) for h in 0:23],
)
write_table(stress_normal_hourly_profile, SCRIPT_STEM, "heat_normal_hourly_profile")
markdown_table(stress_normal_hourly_profile)
````

```@raw html
</details>
```

| **hour** | **demand\_stress\_mean\_demand\_mw** | **normal\_mean\_demand\_mw** |
|--:|--:|--:|
| 0 | 6621.06 | 5633.84 |
| 1 | 6510.36 | 5442.19 |
| 2 | 6143.05 | 5094.39 |
| 3 | 5909.05 | 4909.51 |
| 4 | 5907.5 | 4931.7 |
| 5 | 6282.61 | 5264.24 |
| 6 | 7259.85 | 5930.72 |
| 7 | 8231.84 | 6415.63 |
| 8 | 8876.57 | 6825.24 |
| 9 | 9197.01 | 7053.38 |
| 10 | 9308.45 | 7163.66 |
| 11 | 9368.55 | 7197.25 |
| 12 | 9397.89 | 7167.64 |
| 13 | 9412.28 | 7107.42 |
| 14 | 9264.0 | 6976.0 |
| 15 | 9160.84 | 6897.39 |
| 16 | 9241.6 | 6885.78 |
| 17 | 9407.82 | 6923.68 |
| 18 | 9288.72 | 6916.95 |
| 19 | 8905.59 | 6798.69 |
| 20 | 8550.83 | 6597.54 |
| 21 | 8006.59 | 6217.22 |
| 22 | 7394.43 | 5886.7 |
| 23 | 7132.91 | 5994.54 |


## Demand duration evidence

Sorting daily Victorian demand from highest to lowest gives the demand duration curve, independent of chronology. The complete 365-day curve is written to `demand_duration_curve.csv` and shown in the demand-stress overview; the table below reports selected quantile marks.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
sorted_demand = sort(vic_daily.demand; rev = true)
demand_duration_curve = DataFrame(day_rank = 1:length(sorted_demand), demand_mw = sorted_demand)
write_table(demand_duration_curve, SCRIPT_STEM, "demand_duration_curve")

duration_curve_quantile_marks = DataFrame(
    quantile_label = ["max", "p95", "p90", "p75", "median", "p25", "min"],
    demand_mw = [
        maximum(vic_daily.demand),
        demand_p95,
        demand_p90,
        quantile(vic_daily.demand, 0.75),
        quantile(vic_daily.demand, 0.5),
        quantile(vic_daily.demand, 0.25),
        minimum(vic_daily.demand),
    ],
)
markdown_table(duration_curve_quantile_marks)
````

```@raw html
</details>
```

| **quantile\_label** | **demand\_mw** |
|:--|--:|
| max | 10002.6 |
| p95 | 7443.21 |
| p90 | 7313.93 |
| p75 | 6939.36 |
| median | 6391.19 |
| p25 | 6100.47 |
| min | 4943.57 |


## Normalised demand and solar comparison

Demand and Bannerton solar capacity factor from the merged sample are normalised by their own maxima and ranked by ascending demand, so their relative shapes can be compared on the same 0-to-1 scale. The complete 365-day series is written to `normalized_vre_demand_summary.csv` and shown in the demand-stress overview; the correlation is reported separately.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
if nrow(merged) > 0
    merged_sorted = sort(merged, :demand)
    normalized_vre_demand_summary = DataFrame(
        day_rank = 1:nrow(merged_sorted),
        demand_norm = merged_sorted.demand ./ maximum(merged_sorted.demand),
        solar_norm = merged_sorted.solar_cf ./ maximum(merged_sorted.solar_cf),
    )
    write_table(normalized_vre_demand_summary, SCRIPT_STEM, "normalized_vre_demand_summary")

    normalized_demand_solar_correlation = DataFrame(
        day_count = nrow(normalized_vre_demand_summary),
        demand_solar_correlation = cor(normalized_vre_demand_summary.demand_norm, normalized_vre_demand_summary.solar_norm),
    )
    markdown_table(normalized_demand_solar_correlation)
end
````

```@raw html
</details>
```

| **day\_count** | **demand\_solar\_correlation** |
|--:|--:|
| 365 | -0.254149 |


## Key demand statistics

A short console summary reports the total day count, the demand-stress share, the peak-demand day, and the mean demand across the full period.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
total_days = nrow(vic_daily)
peak_row = vic_daily[argmax(vic_daily.demand), :]
println("\n=== DEMAND-STRESS ANALYSIS ===")
println("Total days: ", total_days)
@printf("Demand-stress days (>P95): %d (%.1f%%)\n", length(demand_stress_days), 100 * length(demand_stress_days) / total_days)
@printf("Peak demand: %.0f MW on %s\n", peak_row.demand, peak_row.date_only)
@printf("Mean demand: %.0f MW\n", mean(vic_daily.demand))
````

```@raw html
</details>
```

````

=== DEMAND-STRESS ANALYSIS ===
Total days: 365
Demand-stress days (>P95): 19 (5.2%)
Peak demand: 10003 MW on 2030-01-09
Mean demand: 6486 MW

````

## Solar availability on the highest-demand days

For the ten highest-demand stress days, this looks up the matching Bannerton solar capacity factor where the exact date exists in the trace.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
if haskey(sol_4006, "Bannerton_SAT")
    cf_of_date = solar_cf_by_date(sol_4006["Bannerton_SAT"])
    top10_days = demand_stress_days[1:min(10, length(demand_stress_days))]
    stress_day_cfs = Float64[]
    for hd in top10_days
        haskey(cf_of_date, hd) || continue
        push!(stress_day_cfs, cf_of_date[hd])
    end
    mean_cf = mean(stress_day_cfs)
    @printf("\nSolar CF on top 10 demand-stress days: mean=%.4f\n", mean_cf)
    println("  Individual CFs: ", [@sprintf("%.4f", c) for c in stress_day_cfs])

    stress_day_solar_cf_detail = DataFrame(
        rank = 1:length(stress_day_cfs),
        date = top10_days[1:length(stress_day_cfs)],
        solar_cf = stress_day_cfs,
        mean_solar_cf_top10 = fill(mean_cf, length(stress_day_cfs)),
    )
    write_table(stress_day_solar_cf_detail, SCRIPT_STEM, "hot_day_solar_cf_detail")
    markdown_table(stress_day_solar_cf_detail)
end
````

```@raw html
</details>
```

| **rank** | **date** | **solar\_cf** | **mean\_solar\_cf\_top10** |
|--:|:--|--:|--:|
| 1 | 2030-01-02 | 0.483717 | 0.294279 |
| 2 | 2030-01-09 | 0.483717 | 0.294279 |
| 3 | 2030-01-24 | 0.47003 | 0.294279 |
| 4 | 2030-02-13 | 0.42786 | 0.294279 |
| 5 | 2030-05-15 | 0.217938 | 0.294279 |
| 6 | 2030-06-03 | 0.211081 | 0.294279 |
| 7 | 2030-06-04 | 0.148711 | 0.294279 |
| 8 | 2030-06-05 | 0.186725 | 0.294279 |
| 9 | 2030-06-06 | 0.140501 | 0.294279 |
| 10 | 2030-06-14 | 0.172506 | 0.294279 |


## Threshold and event-count summary

This collects the thresholds, counts, and peak/mean statistics computed above into a single summary row.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_stress_event_summary = DataFrame(
    total_days = total_days,
    demand_p90_mw = demand_p90,
    demand_p95_mw = demand_p95,
    demand_stress_day_count = length(demand_stress_days),
    normal_day_count = length(normal_days),
    demand_stress_event_pct = 100 * length(demand_stress_days) / total_days,
    peak_demand_mw = peak_row.demand,
    peak_date = peak_row.date_only,
    mean_demand_mw = mean(vic_daily.demand),
)
write_table(demand_stress_event_summary, SCRIPT_STEM, "demand_heat_event_summary")
metric_value_table([
    "Total days" => demand_stress_event_summary.total_days[1],
    "Demand P90 (MW)" => demand_stress_event_summary.demand_p90_mw[1],
    "Demand P95 (MW)" => demand_stress_event_summary.demand_p95_mw[1],
    "Demand-stress days" => demand_stress_event_summary.demand_stress_day_count[1],
    "Normal days" => demand_stress_event_summary.normal_day_count[1],
    "Demand-stress share (%)" => demand_stress_event_summary.demand_stress_event_pct[1],
    "Peak demand (MW)" => demand_stress_event_summary.peak_demand_mw[1],
    "Peak date" => demand_stress_event_summary.peak_date[1],
    "Mean demand (MW)" => demand_stress_event_summary.mean_demand_mw[1],
])
````

```@raw html
</details>
```

| **Metric** | **Value** |
|:--|:--|
| Total days | 365 |
| Demand P90 (MW) | 7313.93 |
| Demand P95 (MW) | 7443.21 |
| Demand-stress days | 19 |
| Normal days | 328 |
| Demand-stress share (%) | 5.20548 |
| Peak demand (MW) | 10002.6 |
| Peak date | 2030-01-09 |
| Mean demand (MW) | 6486.5 |


## Time-series evidence

The top panel shows the Bannerton solar capacity factor over the full period with a 7-day rolling average; the bottom panel shows VIC daily mean demand with its own 7-day rolling average.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p1 = plot(layout=(2,1), size=(1400, 900), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=4Plots.mm)

if haskey(sol_4006, "Bannerton_SAT")
    sol_vic = sol_4006["Bannerton_SAT"]
    sol_vic_daily = daily_cf(sol_vic, HH_COLS_SOL)
    sol_vic_dates = sol_vic.datetime
    sol_rolling = [i < 7 ? NaN : mean(sol_vic_daily[max(1,i-6):i]) for i in 1:length(sol_vic_daily)]

    plot!(p1[1], sol_vic_dates, sol_vic_daily, color=:orange, linewidth=0.5, alpha=0.7, label="Solar CF (Bannerton)")
    plot!(p1[1], sol_vic_dates, sol_rolling, color=:darkred, linewidth=2, label="7-day avg")
    plot!(p1[1], title="4006 Solar CF — Bannerton VIC (Full Period)", ylabel="Daily Mean CF",
          ylim=(0, 0.4), legend=:topright, grid=true, gridalpha=0.3)
end

vic_dem_dates = vic_daily.date_only
vic_dem_values = vic_daily.demand
vic_rolling = [i < 7 ? NaN : mean(vic_dem_values[max(1,i-6):i]) for i in 1:length(vic_dem_values)]

plot!(p1[2], vic_dem_dates, vic_dem_values, color=:grey, linewidth=0.5, alpha=0.7, label="VIC Demand")
plot!(p1[2], vic_dem_dates, vic_rolling, color=:black, linewidth=2, label="7-day avg")
plot!(p1[2], title="2030 VIC Daily Mean Demand (MW)", xlabel="Date", ylabel="Demand (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

savefig(p1, figure_path(SCRIPT_STEM, "07_vic_demand_solar_4006.png"))
println("Saved: 07_vic_demand_solar_4006.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "07_vic_demand_solar_4006.png"), "07_vic_demand_solar_4006.png")
````

```@raw html
</details>
```

````
Saved: 07_vic_demand_solar_4006.png

````

![VIC daily solar capacity factor and daily mean demand over the full period, each with a 7-day rolling average](07_vic_demand_solar_4006.png)

## Coincidence scatter

Each point is one matched calendar day's demand against its Bannerton solar capacity factor; the P90-demand/P10-solar coincidence days are highlighted in red.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p2 = plot(size=(800, 600), title="VIC Demand vs Solar CF (2030, Bannerton)",
         xlabel="Daily Mean Solar CF", ylabel="Daily Mean Demand (MW)",
         legend=:bottomright, grid=true, gridalpha=0.3)

if nrow(merged) > 0
    scatter!(p2, merged.solar_cf, merged.demand, markersize=2, alpha=0.3, color=:purple, label="")

    threshold_demand = quantile(merged.demand, 0.9)
    threshold_solar = quantile(merged.solar_cf, 0.1)
    bad_days = merged[(merged.demand .> threshold_demand) .& (merged.solar_cf .< threshold_solar), :]

    scatter!(p2, bad_days.solar_cf, bad_days.demand, markersize=4, color=:red,
            label="High demand (>$(round(Int, threshold_demand)) MW) + Low solar (<$(round(threshold_solar, digits=3)) CF)")
end

savefig(p2, figure_path(SCRIPT_STEM, "07_demand_vs_solar_scatter.png"))
println("Saved: 07_demand_vs_solar_scatter.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "07_demand_vs_solar_scatter.png"), "07_demand_vs_solar_scatter.png")
````

```@raw html
</details>
```

````
Saved: 07_demand_vs_solar_scatter.png

````

![VIC daily demand plotted against Bannerton solar capacity factor, with high-demand/low-solar days highlighted](07_demand_vs_solar_scatter.png)

## Demand-stress overview

A 2x2 panel combines the hourly stress-vs-normal profile, the demand duration curve with P90/P95 reference lines, a month-by-hour demand heatmap, and the normalised demand/solar comparison.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
p3 = plot(layout=(2,2), size=(1200, 1000), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=5Plots.mm)

hours = 0:23
demand_stress_vals = [get(demand_stress_hourly, h, NaN) for h in hours]
normal_vals = [get(normal_hourly, h, NaN) for h in hours]

plot!(p3[1], hours, demand_stress_vals, color=:red, linewidth=2, marker=:o, markersize=3,
      label="Demand-stress days (>$(round(Int, demand_p95)) MW, n=$(length(demand_stress_days)))")
plot!(p3[1], hours, normal_vals, color=:blue, linewidth=2, marker=:s, markersize=3,
      label="Normal days (<$(round(Int, demand_p90)) MW, n=$(length(normal_days)))")
plot!(p3[1], title="VIC Demand: Stress Days vs Normal Days", xlabel="Hour", ylabel="Demand (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

sorted_demand = sort(vic_daily.demand; rev=true)
plot!(p3[2], sorted_demand, color=:grey, linewidth=1.5, label="", legend=false)
hline!(p3[2], [demand_p90], color=:blue, linestyle=:dash, label="P90=$(round(Int, demand_p90))")
hline!(p3[2], [demand_p95], color=:red, linestyle=:dash, label="P95=$(round(Int, demand_p95))")
plot!(p3[2], title="VIC Demand Duration Curve (2030)", xlabel="Day Rank", ylabel="Demand (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

dem_load_heat = deepcopy(vic_dem)
dem_load_heat = transform(dem_load_heat, :date => ByRow(x -> month(x)) => :month_int)
dem_load_heat = transform(dem_load_heat, :date => ByRow(x -> hour(x)) => :hour)
heatmap_data = zeros(12, 24)
counts = zeros(12, 24)
for row in eachrow(dem_load_heat)
    m = row.month_int
    h = row.hour + 1
    if 1 <= m <= 12 && 1 <= h <= 24
        heatmap_data[m, h] += row.value
        counts[m, h] += 1
    end
end
heatmap_data = heatmap_data ./ max.(counts, 1)

heatmap!(p3[3], 0:23, 1:12, heatmap_data, c=:YlOrRd, title="VIC Demand Profile: Month vs Hour",
        xlabel="Hour", ylabel="Month", yticks=(1:12, month_labels), legend=false)

if nrow(merged) > 0
    merged_sorted = sort(merged, :demand)
    day_ranks = 1:nrow(merged_sorted)
    demand_norm = merged_sorted.demand ./ maximum(merged_sorted.demand)
    solar_norm = merged_sorted.solar_cf ./ maximum(merged_sorted.solar_cf)

    bar!(p3[4], day_ranks, demand_norm, alpha=0.5, color=:grey, label="VIC Demand (norm)", legend=:topright)
    plot!(p3[4], day_ranks, solar_norm, color=:orange, linewidth=1, label="Solar CF (norm)")
    plot!(p3[4], title="Normalized Demand & Solar CF (sorted by demand)", xlabel="Day Rank",
          grid=true, gridalpha=0.3)
end

savefig(p3, figure_path(SCRIPT_STEM, "07_demand_heat_events.png"))
println("Saved: 07_demand_heat_events.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "07_demand_heat_events.png"), "07_demand_heat_events.png")
````

```@raw html
</details>
```

````
Saved: 07_demand_heat_events.png

````

![Hourly demand-stress versus normal-day profile, demand duration curve, month-by-hour demand heatmap, and normalised demand-solar comparison](07_demand_heat_events.png)

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
println("\nDone.")
````

```@raw html
</details>
```

````

Done.

````

## Key coincidence findings

- The committed execution contains 365 exact-date matches between Victorian daily mean demand and Bannerton daily mean solar capacity factor.
- Their Pearson correlation is `-0.257949`, an inverse association within this sample.
- Nineteen matched days, or approximately 5.2% of the sample, meet the demand-stress threshold at or above P95.
- Peak daily mean demand is `9789.05 MW` on `2030-01-09`; mean daily demand is `6295.69 MW`.
- The coincidence screen and the P95 stress-day group answer different questions and therefore retain separate thresholds.

## Interpretation

The demand schedule uses the 10% probability-of-exceedance demand-profile premise for capacity outlooks ([ISP Methodology, p. 39](../../../../../data/2024/pisp-reports/2023-isp-methodology.pdf#page=39)).
The negative correlation indicates that higher-demand days tend to have lower Bannerton solar capacity factor in this matched sample, but it does not establish causation or a system-wide renewable shortfall.

## Limitations

- Demand stress is defined only by the demand distribution; it is not a meteorological heatwave classification.
- Solar availability is represented by one site, so the analysis does not measure portfolio-level spatial diversity.
- Daily means can hide intraday coincidence between the demand peak and solar availability.
- The page does not model dispatch, storage, transmission constraints, imports, or adequacy outcomes.

## Modelling implications

Use the aligned demand and renewable traces as a screening workflow rather than an adequacy result.
A heatwave study should add meteorological criteria, while an adequacy study should test multiple renewable locations, trace years, and operational constraints in an appropriate system model.

