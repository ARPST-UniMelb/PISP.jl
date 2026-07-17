```@meta
EditURL = "../../../../literate/isp2024/analysis/reference_trace_profile.jl"
```

# ISP 2024: Reference trace 4006 profiles

Reference trace `4006` combines location-specific solar and wind profiles with a planning-horizon weather-year mapping. This page loads the raw solar and wind traces (2024 ISP raw trace downloads) for one representative location per state, computes daily and seasonal capacity-factor structure, and builds each figure directly on the page.

Reference trace `4006` is not a climate projection. Its planning-year behaviour depends on the historical-year composition documented in [ISP 2024: Parameters and mappings](@ref).

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

const SCRIPT_STEM = "isp2024_02_plot_4006_traces"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const TRACES = relpath(joinpath(ISP2024_PROFILE.download_root, "Traces"), REPO_ROOT)  # kept relative: this is the path form recorded in the tables below
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a TRACES-relative path to an absolute file location for reading

const SOLAR_LOCATIONS = [
    ("VIC", "Bannerton_SAT"),
    ("NSW", "Darlington_Point_SAT"),
    ("QLD", "Banksia_SAT"),
    ("SA", "Bungala_One_SAT"),
    ("TAS", "Derby_SAT"),
]

const WIND_LOCATIONS = [
    ("VIC", "DUNDWF1"),
    ("NSW", "GULLRWF1"),
    ("QLD", "KABANWF1"),
    ("SA", "CLEMGPWF"),
    ("TAS", "MUSSELR1"),
]

const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]
const HALF_HOURS = collect(0.5:0.5:24.0)

function read_trace(path)
    return CSV.read(path, DataFrame)
end

function add_datetime!(df::DataFrame)
    df.datetime = Date.(df.Year, df.Month, df.Day)
    return df
end

function daily_cf(df::DataFrame, half_hour_cols)
    return [mean(row[col] for col in half_hour_cols) for row in eachrow(df)]
end

function load_traces(tech, trace_year, locations)
    dfs = Dict{String, DataFrame}()
    base = joinpath(TRACES, "$(tech)_$(trace_year)")
    for loc in locations
        file = joinpath(base, "$(loc)_RefYear$(trace_year).csv")
        if isfile(abs_path(file))
            df = read_trace(abs_path(file))
            add_datetime!(df)
            dfs[loc] = df
        end
    end
    return dfs
end

"""
    rolling_mean(values, window)

Rolling mean with a `window`-sized minimum period: the first `window - 1`
entries of the result are `missing` because no full window of prior values
exists yet.
"""
function rolling_mean(values, window)
    n = length(values)
    result = Vector{Union{Missing, Float64}}(missing, n)
    for i in window:n
        result[i] = mean(values[(i - window + 1):i])
    end
    return result
end

"""
    fy_year(date, n = 6)

Buckets a day into an Australian financial year (ending June), returned as the ending year. A date that already falls on the last day of its month
advances `n` month-ends forward; any other date first rolls forward to its
own month's end (consuming one step), then advances `n - 1` more
month-ends. The bucket year is the year of that final month-end.
"""
function fy_year(date::Date, n::Int = 6)
    absolute_month = year(date) * 12 + (month(date) - 1)
    on_offset = day(date) == daysinmonth(date)
    shifted = absolute_month + n - (on_offset ? 0 : 1)
    return fld(shifted, 12)
end

function daily_cf_row(tech, state, loc, df::DataFrame, hh_cols)
    daily = daily_cf(df, hh_cols)
    rolling7 = rolling_mean(daily, 7)
    return (
        tech = tech,
        state = state,
        location = loc,
        n_days = length(daily),
        mean_daily_cf = mean(daily),
        std_daily_cf = std(daily),
        min_daily_cf = minimum(daily),
        max_daily_cf = maximum(daily),
        mean_rolling7_cf = mean(skipmissing(rolling7)),
    )
end
````

```@raw html
</details>
```

## Step 1 — load the solar and wind reference traces for trace year 4006

One representative solar and one representative wind location per state are loaded for trace year `4006`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
sol_4006 = load_traces("solar", 4006, last.(SOLAR_LOCATIONS))
wind_4006 = load_traces("wind", 4006, last.(WIND_LOCATIONS))

println("Loaded $(length(sol_4006)) solar locations, $(length(wind_4006)) wind locations for trace 4006")
````

```@raw html
</details>
```

````
Loaded 5 solar locations, 5 wind locations for trace 4006

````

## Step 2 — which representative locations loaded successfully

The loaded-location inventory records, for every representative solar and wind site, whether its trace file was found and its shape if so.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
loaded_location_rows = NamedTuple[]
for (state, loc) in SOLAR_LOCATIONS
    df = get(sol_4006, loc, nothing)
    push!(loaded_location_rows, (
        tech = "solar",
        state = state,
        location = loc,
        file_name = "$(loc)_RefYear4006.csv",
        loaded = df === nothing ? 0 : 1,
        rows = df === nothing ? missing : nrow(df),
        columns = df === nothing ? missing : ncol(df),
    ))
end
for (state, loc) in WIND_LOCATIONS
    df = get(wind_4006, loc, nothing)
    push!(loaded_location_rows, (
        tech = "wind",
        state = state,
        location = loc,
        file_name = "$(loc)_RefYear4006.csv",
        loaded = df === nothing ? 0 : 1,
        rows = df === nothing ? missing : nrow(df),
        columns = df === nothing ? missing : ncol(df),
    ))
end

loaded_locations = DataFrame(loaded_location_rows)
write_table(loaded_locations, SCRIPT_STEM, "loaded_locations")
markdown_table(loaded_locations)
````

```@raw html
</details>
```

| **tech** | **state** | **location** | **file\_name** | **loaded** | **rows** | **columns** |
|--:|--:|--:|--:|--:|--:|--:|
| solar | VIC | Bannerton\_SAT | Bannerton\_SAT\_RefYear4006.csv | 1 | 10227 | 52 |
| solar | NSW | Darlington\_Point\_SAT | Darlington\_Point\_SAT\_RefYear4006.csv | 1 | 10227 | 52 |
| solar | QLD | Banksia\_SAT | Banksia\_SAT\_RefYear4006.csv | 1 | 10227 | 52 |
| solar | SA | Bungala\_One\_SAT | Bungala\_One\_SAT\_RefYear4006.csv | 1 | 10227 | 52 |
| solar | TAS | Derby\_SAT | Derby\_SAT\_RefYear4006.csv | 1 | 10227 | 52 |
| wind | VIC | DUNDWF1 | DUNDWF1\_RefYear4006.csv | 1 | 10227 | 52 |
| wind | NSW | GULLRWF1 | GULLRWF1\_RefYear4006.csv | 1 | 10227 | 52 |
| wind | QLD | KABANWF1 | KABANWF1\_RefYear4006.csv | 1 | 10227 | 52 |
| wind | SA | CLEMGPWF | CLEMGPWF\_RefYear4006.csv | 1 | 10227 | 52 |
| wind | TAS | MUSSELR1 | MUSSELR1\_RefYear4006.csv | 1 | 10227 | 52 |


## Step 3 — daily capacity-factor summary

For each loaded location, the daily summary reports descriptive statistics of the daily mean capacity factor, including the mean of a 7-day rolling average.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
daily_cf_summary_rows = NamedTuple[]
for (state, loc) in SOLAR_LOCATIONS
    df = get(sol_4006, loc, nothing)
    df === nothing && continue
    push!(daily_cf_summary_rows, daily_cf_row("solar", state, loc, df, HH_COLS_SOL))
end
for (state, loc) in WIND_LOCATIONS
    df = get(wind_4006, loc, nothing)
    df === nothing && continue
    push!(daily_cf_summary_rows, daily_cf_row("wind", state, loc, df, HH_COLS_WIND))
end

daily_cf_summary = DataFrame(daily_cf_summary_rows)
write_table(daily_cf_summary, SCRIPT_STEM, "daily_cf_summary")
markdown_table(daily_cf_summary)
````

```@raw html
</details>
```

| **tech** | **state** | **location** | **n\_days** | **mean\_daily\_cf** | **std\_daily\_cf** | **min\_daily\_cf** | **max\_daily\_cf** | **mean\_rolling7\_cf** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| solar | VIC | Bannerton\_SAT | 10227 | 0.282755 | 0.131951 | 0.0095789 | 0.500514 | 0.282823 |
| solar | NSW | Darlington\_Point\_SAT | 10227 | 0.275729 | 0.130218 | 0.00911927 | 0.495879 | 0.2758 |
| solar | QLD | Banksia\_SAT | 10227 | 0.262995 | 0.106228 | 0.00712346 | 0.46654 | 0.26304 |
| solar | SA | Bungala\_One\_SAT | 10227 | 0.295472 | 0.126436 | 0.0122899 | 0.492928 | 0.295525 |
| solar | TAS | Derby\_SAT | 10227 | 0.256992 | 0.137548 | 0.00850535 | 0.500684 | 0.257065 |
| wind | VIC | DUNDWF1 | 10227 | 0.38563 | 0.265356 | 0.000649813 | 0.96303 | 0.385482 |
| wind | NSW | GULLRWF1 | 10227 | 0.326027 | 0.234427 | 0.0 | 0.9737 | 0.326075 |
| wind | QLD | KABANWF1 | 10227 | 0.340004 | 0.226991 | 0.00196787 | 0.864389 | 0.339832 |
| wind | SA | CLEMGPWF | 10227 | 0.352498 | 0.211693 | 0.0 | 0.948054 | 0.352411 |
| wind | TAS | MUSSELR1 | 10227 | 0.377225 | 0.286636 | 0.0 | 0.987126 | 0.377288 |


## Step 4 — solar diurnal profile at the Victorian representative location

The half-hourly diurnal profile at `Bannerton_SAT` is split into summer (Dec-Feb) and winter (Jun-Aug) days, reporting the mean, 10th and 90th percentile capacity factor at each half hour.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
df_prof = sol_4006["Bannerton_SAT"]
summer_mask = in.(df_prof.Month, Ref((12, 1, 2)))
winter_mask = in.(df_prof.Month, Ref((6, 7, 8)))

solar_diurnal_profile_rows = NamedTuple[]
for (season, mask) in (("Summer", summer_mask), ("Winter", winter_mask))
    df_season = df_prof[mask, :]
    n_days_season = nrow(df_season)
    for (hh, hh_col) in zip(HALF_HOURS, HH_COLS_SOL)
        vals = df_season[!, hh_col]
        push!(solar_diurnal_profile_rows, (
            location = "Bannerton_SAT",
            season = season,
            half_hour = hh,
            n_days = n_days_season,
            mean_cf = mean(vals),
            p10_cf = quantile(vals, 0.1),
            p90_cf = quantile(vals, 0.9),
        ))
    end
end

solar_diurnal_profile = DataFrame(solar_diurnal_profile_rows)
write_table(solar_diurnal_profile, SCRIPT_STEM, "solar_diurnal_profile")
markdown_table(solar_diurnal_profile)
````

```@raw html
</details>
```

| **location** | **season** | **half\_hour** | **n\_days** | **mean\_cf** | **p10\_cf** | **p90\_cf** |
|--:|--:|--:|--:|--:|--:|--:|
| Bannerton\_SAT | Summer | 0.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 1.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 1.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 2.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 2.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 3.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 3.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 4.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 4.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 5.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 5.5 | 2527 | 0.00112645 | 0.0 | 0.00225437 |
| Bannerton\_SAT | Summer | 6.0 | 2527 | 0.0338495 | 0.0 | 0.101698 |
| Bannerton\_SAT | Summer | 6.5 | 2527 | 0.158414 | 0.00515178 | 0.405485 |
| Bannerton\_SAT | Summer | 7.0 | 2527 | 0.293433 | 0.0506821 | 0.506098 |
| Bannerton\_SAT | Summer | 7.5 | 2527 | 0.551065 | 0.0791632 | 0.989672 |
| Bannerton\_SAT | Summer | 8.0 | 2527 | 0.724201 | 0.119949 | 1.0 |
| Bannerton\_SAT | Summer | 8.5 | 2527 | 0.808047 | 0.186438 | 1.0 |
| Bannerton\_SAT | Summer | 9.0 | 2527 | 0.835295 | 0.240157 | 1.0 |
| Bannerton\_SAT | Summer | 9.5 | 2527 | 0.852269 | 0.310091 | 1.0 |
| Bannerton\_SAT | Summer | 10.0 | 2527 | 0.859632 | 0.333368 | 1.0 |
| Bannerton\_SAT | Summer | 10.5 | 2527 | 0.869157 | 0.366343 | 1.0 |
| Bannerton\_SAT | Summer | 11.0 | 2527 | 0.878689 | 0.455965 | 1.0 |
| Bannerton\_SAT | Summer | 11.5 | 2527 | 0.880964 | 0.456015 | 1.0 |
| Bannerton\_SAT | Summer | 12.0 | 2527 | 0.878934 | 0.482956 | 1.0 |
| Bannerton\_SAT | Summer | 12.5 | 2527 | 0.880215 | 0.497711 | 1.0 |
| Bannerton\_SAT | Summer | 13.0 | 2527 | 0.878858 | 0.487522 | 1.0 |
| Bannerton\_SAT | Summer | 13.5 | 2527 | 0.88244 | 0.515594 | 1.0 |
| Bannerton\_SAT | Summer | 14.0 | 2527 | 0.878134 | 0.481139 | 1.0 |
| Bannerton\_SAT | Summer | 14.5 | 2527 | 0.865373 | 0.447599 | 1.0 |
| Bannerton\_SAT | Summer | 15.0 | 2527 | 0.848161 | 0.348466 | 1.0 |
| Bannerton\_SAT | Summer | 15.5 | 2527 | 0.837886 | 0.308027 | 1.0 |
| Bannerton\_SAT | Summer | 16.0 | 2527 | 0.823186 | 0.238623 | 1.0 |
| Bannerton\_SAT | Summer | 16.5 | 2527 | 0.800563 | 0.169806 | 1.0 |
| Bannerton\_SAT | Summer | 17.0 | 2527 | 0.771118 | 0.131601 | 1.0 |
| Bannerton\_SAT | Summer | 17.5 | 2527 | 0.737642 | 0.105189 | 1.0 |
| Bannerton\_SAT | Summer | 18.0 | 2527 | 0.597066 | 0.0795343 | 0.95063 |
| Bannerton\_SAT | Summer | 18.5 | 2527 | 0.345505 | 0.0567868 | 0.484176 |
| Bannerton\_SAT | Summer | 19.0 | 2527 | 0.189567 | 0.034255 | 0.379718 |
| Bannerton\_SAT | Summer | 19.5 | 2527 | 0.0412864 | 0.0 | 0.0969854 |
| Bannerton\_SAT | Summer | 20.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 20.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 21.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 21.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 22.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 22.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 23.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 23.5 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Summer | 24.0 | 2527 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 0.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 1.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 1.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 2.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 2.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 3.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 3.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 4.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 4.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 5.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 5.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 6.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 6.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 7.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 7.5 | 2576 | 0.00464521 | 0.0 | 0.0135734 |
| Bannerton\_SAT | Winter | 8.0 | 2576 | 0.041447 | 0.00302342 | 0.10273 |
| Bannerton\_SAT | Winter | 8.5 | 2576 | 0.165315 | 0.0435124 | 0.395085 |
| Bannerton\_SAT | Winter | 9.0 | 2576 | 0.331962 | 0.0751844 | 0.748802 |
| Bannerton\_SAT | Winter | 9.5 | 2576 | 0.520152 | 0.0887947 | 0.823594 |
| Bannerton\_SAT | Winter | 10.0 | 2576 | 0.534694 | 0.0998846 | 0.832588 |
| Bannerton\_SAT | Winter | 10.5 | 2576 | 0.532482 | 0.114233 | 0.811134 |
| Bannerton\_SAT | Winter | 11.0 | 2576 | 0.533879 | 0.141766 | 0.791824 |
| Bannerton\_SAT | Winter | 11.5 | 2576 | 0.521858 | 0.166427 | 0.760644 |
| Bannerton\_SAT | Winter | 12.0 | 2576 | 0.503675 | 0.185524 | 0.728361 |
| Bannerton\_SAT | Winter | 12.5 | 2576 | 0.481561 | 0.190961 | 0.693301 |
| Bannerton\_SAT | Winter | 13.0 | 2576 | 0.464815 | 0.185816 | 0.682444 |
| Bannerton\_SAT | Winter | 13.5 | 2576 | 0.463837 | 0.171167 | 0.685816 |
| Bannerton\_SAT | Winter | 14.0 | 2576 | 0.469031 | 0.146434 | 0.713409 |
| Bannerton\_SAT | Winter | 14.5 | 2576 | 0.46738 | 0.125491 | 0.732354 |
| Bannerton\_SAT | Winter | 15.0 | 2576 | 0.465009 | 0.0931319 | 0.776375 |
| Bannerton\_SAT | Winter | 15.5 | 2576 | 0.461251 | 0.0815028 | 0.781373 |
| Bannerton\_SAT | Winter | 16.0 | 2576 | 0.467479 | 0.0769725 | 0.792466 |
| Bannerton\_SAT | Winter | 16.5 | 2576 | 0.328269 | 0.0646505 | 0.75967 |
| Bannerton\_SAT | Winter | 17.0 | 2576 | 0.179456 | 0.0419698 | 0.393809 |
| Bannerton\_SAT | Winter | 17.5 | 2576 | 0.0579395 | 0.00310549 | 0.124155 |
| Bannerton\_SAT | Winter | 18.0 | 2576 | 0.00543513 | 0.0 | 0.0223187 |
| Bannerton\_SAT | Winter | 18.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 19.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 19.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 20.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 20.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 21.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 21.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 22.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 22.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 23.0 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 23.5 | 2576 | 0.0 | 0.0 | 0.0 |
| Bannerton\_SAT | Winter | 24.0 | 2576 | 0.0 | 0.0 | 0.0 |


## Step 5 — wind monthly diurnal profile at the Victorian representative location

The half-hourly diurnal profile at `DUNDWF1` is reported separately for each calendar month present in the trace — 12 months of 48 half-hourly points each, visualised together in Step 11's figure. The full table is written to the evidence CSV; the page displays only the first complete month as a representative sample.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
df_wind_prof = wind_4006["DUNDWF1"]

wind_monthly_diurnal_profile_rows = NamedTuple[]
for m in 1:12
    mask = df_wind_prof.Month .== m
    any(mask) || continue
    df_month = df_wind_prof[mask, :]
    for (hh, hh_col) in zip(HALF_HOURS, HH_COLS_WIND)
        push!(wind_monthly_diurnal_profile_rows, (
            location = "DUNDWF1",
            month = m,
            half_hour = hh,
            mean_cf = mean(df_month[!, hh_col]),
        ))
    end
end

wind_monthly_diurnal_profile = DataFrame(wind_monthly_diurnal_profile_rows)
write_table(wind_monthly_diurnal_profile, SCRIPT_STEM, "wind_monthly_diurnal_profile")
markdown_table(first(wind_monthly_diurnal_profile, 48))
````

```@raw html
</details>
```

| **location** | **month** | **half\_hour** | **mean\_cf** |
|--:|--:|--:|--:|
| DUNDWF1 | 1 | 0.5 | 0.310919 |
| DUNDWF1 | 1 | 1.0 | 0.309558 |
| DUNDWF1 | 1 | 1.5 | 0.309992 |
| DUNDWF1 | 1 | 2.0 | 0.308409 |
| DUNDWF1 | 1 | 2.5 | 0.305366 |
| DUNDWF1 | 1 | 3.0 | 0.305224 |
| DUNDWF1 | 1 | 3.5 | 0.305995 |
| DUNDWF1 | 1 | 4.0 | 0.308799 |
| DUNDWF1 | 1 | 4.5 | 0.312317 |
| DUNDWF1 | 1 | 5.0 | 0.310048 |
| DUNDWF1 | 1 | 5.5 | 0.303957 |
| DUNDWF1 | 1 | 6.0 | 0.299077 |
| DUNDWF1 | 1 | 6.5 | 0.286254 |
| DUNDWF1 | 1 | 7.0 | 0.273518 |
| DUNDWF1 | 1 | 7.5 | 0.273388 |
| DUNDWF1 | 1 | 8.0 | 0.283653 |
| DUNDWF1 | 1 | 8.5 | 0.283428 |
| DUNDWF1 | 1 | 9.0 | 0.282451 |
| DUNDWF1 | 1 | 9.5 | 0.283205 |
| DUNDWF1 | 1 | 10.0 | 0.284297 |
| DUNDWF1 | 1 | 10.5 | 0.28504 |
| DUNDWF1 | 1 | 11.0 | 0.282411 |
| DUNDWF1 | 1 | 11.5 | 0.283309 |
| DUNDWF1 | 1 | 12.0 | 0.28339 |
| DUNDWF1 | 1 | 12.5 | 0.287288 |
| DUNDWF1 | 1 | 13.0 | 0.293583 |
| DUNDWF1 | 1 | 13.5 | 0.300178 |
| DUNDWF1 | 1 | 14.0 | 0.305076 |
| DUNDWF1 | 1 | 14.5 | 0.309665 |
| DUNDWF1 | 1 | 15.0 | 0.314961 |
| DUNDWF1 | 1 | 15.5 | 0.325784 |
| DUNDWF1 | 1 | 16.0 | 0.343967 |
| DUNDWF1 | 1 | 16.5 | 0.357296 |
| DUNDWF1 | 1 | 17.0 | 0.371007 |
| DUNDWF1 | 1 | 17.5 | 0.3846 |
| DUNDWF1 | 1 | 18.0 | 0.401118 |
| DUNDWF1 | 1 | 18.5 | 0.406242 |
| DUNDWF1 | 1 | 19.0 | 0.41736 |
| DUNDWF1 | 1 | 19.5 | 0.414948 |
| DUNDWF1 | 1 | 20.0 | 0.41257 |
| DUNDWF1 | 1 | 20.5 | 0.399103 |
| DUNDWF1 | 1 | 21.0 | 0.391666 |
| DUNDWF1 | 1 | 21.5 | 0.369269 |
| DUNDWF1 | 1 | 22.0 | 0.355134 |
| DUNDWF1 | 1 | 22.5 | 0.34204 |
| DUNDWF1 | 1 | 23.0 | 0.331154 |
| DUNDWF1 | 1 | 23.5 | 0.320918 |
| DUNDWF1 | 1 | 24.0 | 0.316191 |


## Step 6 — wind monthly mean capacity factor

The daily capacity factor at `DUNDWF1` is grouped by calendar month start to give a compact monthly mean series spanning the full trace. The full series is written to the evidence CSV and plotted in Step 11's figure; the page displays only the first two years as a representative sample.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
df_wind_prof = wind_4006["DUNDWF1"]
daily_wind = daily_cf(df_wind_prof, HH_COLS_WIND)
wind_month_starts = [Date(year(d), month(d), 1) for d in df_wind_prof.datetime]

wind_month_grouped = DataFrame(month_start = wind_month_starts, cf = daily_wind)
wind_month_summary = combine(groupby(wind_month_grouped, :month_start), :cf => mean => :mean_cf)

wind_monthly_mean_cf_rows = [
    (location = "DUNDWF1", month_start = Dates.format(row.month_start, "yyyy-mm-dd"), mean_cf = row.mean_cf)
    for row in eachrow(wind_month_summary)
]
wind_monthly_mean_cf = DataFrame(wind_monthly_mean_cf_rows)
write_table(wind_monthly_mean_cf, SCRIPT_STEM, "wind_monthly_mean_cf")
markdown_table(first(wind_monthly_mean_cf, 24))
````

```@raw html
</details>
```

| **location** | **month\_start** | **mean\_cf** |
|--:|--:|--:|
| DUNDWF1 | 2024-07-01 | 0.632757 |
| DUNDWF1 | 2024-08-01 | 0.582657 |
| DUNDWF1 | 2024-09-01 | 0.427451 |
| DUNDWF1 | 2024-10-01 | 0.390287 |
| DUNDWF1 | 2024-11-01 | 0.333989 |
| DUNDWF1 | 2024-12-01 | 0.256684 |
| DUNDWF1 | 2025-01-01 | 0.238217 |
| DUNDWF1 | 2025-02-01 | 0.310401 |
| DUNDWF1 | 2025-03-01 | 0.300776 |
| DUNDWF1 | 2025-04-01 | 0.355824 |
| DUNDWF1 | 2025-05-01 | 0.459771 |
| DUNDWF1 | 2025-06-01 | 0.419685 |
| DUNDWF1 | 2025-07-01 | 0.530267 |
| DUNDWF1 | 2025-08-01 | 0.516709 |
| DUNDWF1 | 2025-09-01 | 0.37134 |
| DUNDWF1 | 2025-10-01 | 0.416739 |
| DUNDWF1 | 2025-11-01 | 0.440677 |
| DUNDWF1 | 2025-12-01 | 0.361783 |
| DUNDWF1 | 2026-01-01 | 0.318526 |
| DUNDWF1 | 2026-02-01 | 0.361456 |
| DUNDWF1 | 2026-03-01 | 0.374958 |
| DUNDWF1 | 2026-04-01 | 0.425556 |
| DUNDWF1 | 2026-05-01 | 0.45991 |
| DUNDWF1 | 2026-06-01 | 0.393556 |


## Step 7 — annual capacity factor by financial year

Daily capacity factor for the Victorian solar and wind representative locations is grouped into Australian financial years (ending June) for a compact annual comparison.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
annual_cf_by_fy_rows = NamedTuple[]

df_s = get(sol_4006, "Bannerton_SAT", nothing)
if df_s !== nothing
    fy_solar = fy_year.(df_s.datetime)
    cf_solar_annual = daily_cf(df_s, HH_COLS_SOL)
    grouped_fy_solar = DataFrame(fy = fy_solar, cf = cf_solar_annual)
    summary_fy_solar = combine(groupby(grouped_fy_solar, :fy), :cf => mean => :mean_cf)
    for row in eachrow(summary_fy_solar)
        push!(annual_cf_by_fy_rows, (tech = "solar", location = "Bannerton_SAT", financial_year = row.fy, mean_cf = row.mean_cf))
    end
end

df_w = get(wind_4006, "DUNDWF1", nothing)
if df_w !== nothing
    fy_wind = fy_year.(df_w.datetime)
    cf_wind_annual = daily_cf(df_w, HH_COLS_WIND)
    grouped_fy_wind = DataFrame(fy = fy_wind, cf = cf_wind_annual)
    summary_fy_wind = combine(groupby(grouped_fy_wind, :fy), :cf => mean => :mean_cf)
    for row in eachrow(summary_fy_wind)
        push!(annual_cf_by_fy_rows, (tech = "wind", location = "DUNDWF1", financial_year = row.fy, mean_cf = row.mean_cf))
    end
end

annual_cf_by_fy = DataFrame(annual_cf_by_fy_rows)
write_table(annual_cf_by_fy, SCRIPT_STEM, "annual_cf_by_fy")
markdown_table(annual_cf_by_fy)
````

```@raw html
</details>
```

| **tech** | **location** | **financial\_year** | **mean\_cf** |
|--:|--:|--:|--:|
| solar | Bannerton\_SAT | 2024 | 0.171319 |
| solar | Bannerton\_SAT | 2025 | 0.297388 |
| solar | Bannerton\_SAT | 2026 | 0.297733 |
| solar | Bannerton\_SAT | 2027 | 0.283699 |
| solar | Bannerton\_SAT | 2028 | 0.282057 |
| solar | Bannerton\_SAT | 2029 | 0.274396 |
| solar | Bannerton\_SAT | 2030 | 0.289975 |
| solar | Bannerton\_SAT | 2031 | 0.255611 |
| solar | Bannerton\_SAT | 2032 | 0.274199 |
| solar | Bannerton\_SAT | 2033 | 0.287621 |
| solar | Bannerton\_SAT | 2034 | 0.274723 |
| solar | Bannerton\_SAT | 2035 | 0.288487 |
| solar | Bannerton\_SAT | 2036 | 0.277431 |
| solar | Bannerton\_SAT | 2037 | 0.280485 |
| solar | Bannerton\_SAT | 2038 | 0.290456 |
| solar | Bannerton\_SAT | 2039 | 0.296414 |
| solar | Bannerton\_SAT | 2040 | 0.295149 |
| solar | Bannerton\_SAT | 2041 | 0.28462 |
| solar | Bannerton\_SAT | 2042 | 0.282282 |
| solar | Bannerton\_SAT | 2043 | 0.275654 |
| solar | Bannerton\_SAT | 2044 | 0.288563 |
| solar | Bannerton\_SAT | 2045 | 0.258824 |
| solar | Bannerton\_SAT | 2046 | 0.275159 |
| solar | Bannerton\_SAT | 2047 | 0.287679 |
| solar | Bannerton\_SAT | 2048 | 0.274937 |
| solar | Bannerton\_SAT | 2049 | 0.289397 |
| solar | Bannerton\_SAT | 2050 | 0.280143 |
| solar | Bannerton\_SAT | 2051 | 0.284045 |
| solar | Bannerton\_SAT | 2052 | 0.300592 |
| wind | DUNDWF1 | 2024 | 0.645226 |
| wind | DUNDWF1 | 2025 | 0.384884 |
| wind | DUNDWF1 | 2026 | 0.399409 |
| wind | DUNDWF1 | 2027 | 0.419673 |
| wind | DUNDWF1 | 2028 | 0.390497 |
| wind | DUNDWF1 | 2029 | 0.373 |
| wind | DUNDWF1 | 2030 | 0.345239 |
| wind | DUNDWF1 | 2031 | 0.379052 |
| wind | DUNDWF1 | 2032 | 0.382921 |
| wind | DUNDWF1 | 2033 | 0.38554 |
| wind | DUNDWF1 | 2034 | 0.424437 |
| wind | DUNDWF1 | 2035 | 0.363684 |
| wind | DUNDWF1 | 2036 | 0.369277 |
| wind | DUNDWF1 | 2037 | 0.374024 |
| wind | DUNDWF1 | 2038 | 0.406603 |
| wind | DUNDWF1 | 2039 | 0.394251 |
| wind | DUNDWF1 | 2040 | 0.392789 |
| wind | DUNDWF1 | 2041 | 0.411623 |
| wind | DUNDWF1 | 2042 | 0.393033 |
| wind | DUNDWF1 | 2043 | 0.390258 |
| wind | DUNDWF1 | 2044 | 0.343069 |
| wind | DUNDWF1 | 2045 | 0.375079 |
| wind | DUNDWF1 | 2046 | 0.378997 |
| wind | DUNDWF1 | 2047 | 0.384508 |
| wind | DUNDWF1 | 2048 | 0.424584 |
| wind | DUNDWF1 | 2049 | 0.357804 |
| wind | DUNDWF1 | 2050 | 0.367272 |
| wind | DUNDWF1 | 2051 | 0.380433 |
| wind | DUNDWF1 | 2052 | 0.384275 |


## Step 8 — figure: solar daily capacity factor by state

One panel per state shows the daily mean capacity factor for the representative solar location, with a 7-day rolling average overlaid.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
state_names = Dict(v => k for (k, v) in SOLAR_LOCATIONS)
plots_sol = []
for (loc, df) in sort(sol_4006)
    state = get(state_names, loc, loc)
    daily = daily_cf(df, HH_COLS_SOL)
    rolling7 = rolling_mean(daily, 7)
    p = plot(df.datetime, daily, linewidth=0.3, alpha=0.7, color=:darkorange, label="", legend=:topright, legendfontsize=8)
    plot!(p, df.datetime, rolling7, linewidth=1.5, color=:darkred, label="7-day avg")
    plot!(p, ylabel="$(state)\nCF", ylim=(0, 1), grid=true, gridalpha=0.3)
    push!(plots_sol, p)
end
p_sol = plot(plots_sol..., layout=(length(plots_sol), 1), size=(1800, 300*length(plots_sol)), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=4Plots.mm)
plot!(p_sol, plot_title="Solar 4006 — Daily Mean Capacity Factor by State")
savefig(p_sol, figure_path(SCRIPT_STEM, "02_solar_4006_daily_cf.png"))
println("Saved: 02_solar_4006_daily_cf.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "02_solar_4006_daily_cf.png"), "02_solar_4006_daily_cf.png")
````

```@raw html
</details>
```

````
Saved: 02_solar_4006_daily_cf.png

````

![Daily mean capacity factor for the representative solar location in each state, with a 7-day rolling average](02_solar_4006_daily_cf.png)

## Step 9 — figure: wind daily capacity factor by state

The same daily-mean-plus-rolling-average layout as Step 8, for the representative wind location in each state.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
state_names_w = Dict(v => k for (k, v) in WIND_LOCATIONS)
plots_wind = []
for (loc, df) in sort(wind_4006)
    state = get(state_names_w, loc, loc)
    daily = daily_cf(df, HH_COLS_WIND)
    rolling7 = rolling_mean(daily, 7)
    p = plot(df.datetime, daily, linewidth=0.3, alpha=0.7, color=:steelblue, label="", legend=:topright, legendfontsize=8)
    plot!(p, df.datetime, rolling7, linewidth=1.5, color=:darkblue, label="7-day avg")
    plot!(p, ylabel="$(state)\nCF", ylim=(0, 1), grid=true, gridalpha=0.3)
    push!(plots_wind, p)
end
p_wind = plot(plots_wind..., layout=(length(plots_wind), 1), size=(1800, 300*length(plots_wind)), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=4Plots.mm)
plot!(p_wind, plot_title="Wind 4006 — Daily Mean Capacity Factor by State")
savefig(p_wind, figure_path(SCRIPT_STEM, "02_wind_4006_daily_cf.png"))
println("Saved: 02_wind_4006_daily_cf.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "02_wind_4006_daily_cf.png"), "02_wind_4006_daily_cf.png")
````

```@raw html
</details>
```

````
Saved: 02_wind_4006_daily_cf.png

````

![Daily mean capacity factor for the representative wind location in each state, with a 7-day rolling average](02_wind_4006_daily_cf.png)

## Step 10 — figure: solar diurnal profile, summer vs winter

Individual daily half-hourly profiles (up to 200 per season), the mean profile, and the P10-P90 band, for `Bannerton_SAT` summer and winter days.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
df_prof = sol_4006["Bannerton_SAT"]
summer_mask = in.(df_prof.Month, Ref((12, 1, 2)))
winter_mask = in.(df_prof.Month, Ref((6, 7, 8)))

plots_diurnal = []
for (season, mask, color) in [("Summer", summer_mask, :darkorange), ("Winter", winter_mask, :steelblue)]
    df_season = df_prof[mask, :]
    hh_vals = Matrix(df_season[!, HH_COLS_SOL])

    p = plot(legend=:topright, legendfontsize=8)
    for i in 1:min(200, size(hh_vals, 1))
        plot!(p, HALF_HOURS, hh_vals[i, :], linewidth=0.3, alpha=0.15, color=color, label="")
    end

    mean_profile = vec(mean(hh_vals, dims=1))
    plot!(p, HALF_HOURS, mean_profile, linewidth=2.5, color=:black, label="Mean")

    p10 = [quantile(hh_vals[:, j], 0.1) for j in 1:size(hh_vals, 2)]
    p90 = [quantile(hh_vals[:, j], 0.9) for j in 1:size(hh_vals, 2)]
    plot!(p, HALF_HOURS, p10, fillrange=p90, alpha=0.3, color=color, label="P10-P90", linewidth=0)

    plot!(p, title="Bannerton_SAT $(season) ($(count(mask)) days)", ylabel="Capacity Factor",
          ylim=(0, 1.05), xlabel="Hour of day", grid=true, gridalpha=0.3)
    push!(plots_diurnal, p)
end
p_diu = plot(plots_diurnal..., layout=(2,1), size=(1600, 1000), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=4Plots.mm)
plot!(p_diu, plot_title="Solar 4006 — Diurnal Profiles: Summer vs Winter")
savefig(p_diu, figure_path(SCRIPT_STEM, "02_solar_4006_diurnal.png"))
println("Saved: 02_solar_4006_diurnal.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "02_solar_4006_diurnal.png"), "02_solar_4006_diurnal.png")
````

```@raw html
</details>
```

````
Saved: 02_solar_4006_diurnal.png

````

![Solar diurnal profile at Bannerton_SAT: individual days, mean, and P10-P90 band, summer vs winter](02_solar_4006_diurnal.png)

## Step 11 — figure: wind seasonal analysis

The top panel shows the mean diurnal profile by calendar month at `DUNDWF1`; the bottom panel shows the daily capacity factor overlaid with the monthly mean.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
df_wind_prof = get(wind_4006, "DUNDWF1", nothing)
if df_wind_prof !== nothing
    plots_wind_sea = []

    wind_hh_cols = [lpad(i, 2, '0') for i in 1:48]
    monthly_cf = combine(groupby(df_wind_prof, :Month), [col => mean => col for col in HH_COLS_WIND])

    p1 = plot(legend=false)
    for m in 1:12
        if m in monthly_cf.Month
            row_idx = findfirst(==(m), monthly_cf.Month)
            vals = Vector(monthly_cf[row_idx, 2:49])
            plot!(p1, HALF_HOURS, vals, linewidth=1, alpha=0.8, label="Month $m")
        end
    end
    plot!(p1, title="Wind 4006 — Mean Diurnal Profile by Month: DUNDWF1", ylabel="Capacity Factor",
          ylim=(0, 1), grid=true, gridalpha=0.3, legend=:topright, legendfontsize=7, ncol=4)
    push!(plots_wind_sea, p1)

    daily_wind = daily_cf(df_wind_prof, HH_COLS_WIND)
    p2 = plot(df_wind_prof.datetime, daily_wind, linewidth=0.3, alpha=0.5, color=:steelblue, label="", legend=false)

    month_dates = df_wind_prof.datetime
    month_periods = [Date(year(d), month(d), 1) for d in month_dates]
    grouped = DataFrame(month_start = month_periods, cf = daily_wind)
    monthly_summary = combine(groupby(grouped, :month_start), :cf => mean => :mean_cf)
    monthly_dates = monthly_summary.month_start
    plot!(p2, monthly_dates, monthly_summary.mean_cf, linewidth=1.5, color=:darkblue, label="")
    plot!(p2, title="Wind 4006 — Daily & Monthly Mean CF: DUNDWF1", ylabel="Capacity Factor",
          ylim=(0, 1), grid=true, gridalpha=0.3)
    push!(plots_wind_sea, p2)

    p_wind_sea = plot(plots_wind_sea..., layout=(2,1), size=(1600, 900), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=4Plots.mm)
    savefig(p_wind_sea, figure_path(SCRIPT_STEM, "02_wind_4006_seasonal.png"))
    println("Saved: 02_wind_4006_seasonal.png")
    EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "02_wind_4006_seasonal.png"), "02_wind_4006_seasonal.png")
end
````

```@raw html
</details>
```

````
Saved: 02_wind_4006_seasonal.png

````

![Wind seasonal analysis at DUNDWF1: mean diurnal profile by month, and daily capacity factor with monthly mean overlaid](02_wind_4006_seasonal.png)

## Step 12 — figure: annual capacity factor by financial year

The Victorian solar and wind representative locations' annual mean capacity factor, grouped by financial year, on one comparison chart.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p5 = plot(legend=true, size=(1800, 700), left_margin=6Plots.mm, right_margin=4Plots.mm, top_margin=5Plots.mm, bottom_margin=5Plots.mm)

df_s = get(sol_4006, "Bannerton_SAT", nothing)
if df_s !== nothing
    fy = fy_year.(df_s.datetime)
    cf_sol = daily_cf(df_s, HH_COLS_SOL)
    grouped_sol = DataFrame(fy = fy, cf = cf_sol)
    summary_sol = combine(groupby(grouped_sol, :fy), :cf => mean => :mean_cf)
    plot!(p5, summary_sol.fy, summary_sol.mean_cf, marker=:circle, color=:darkorange,
          linewidth=2, markersize=6, label="Solar CF (Bannerton VIC)")
end

df_w = get(wind_4006, "DUNDWF1", nothing)
if df_w !== nothing
    fy = fy_year.(df_w.datetime)
    cf_wind = daily_cf(df_w, HH_COLS_WIND)
    grouped_wind = DataFrame(fy = fy, cf = cf_wind)
    summary_wind = combine(groupby(grouped_wind, :fy), :cf => mean => :mean_cf)
    plot!(p5, summary_wind.fy, summary_wind.mean_cf, marker=:square, color=:darkblue,
          linewidth=2, markersize=6, label="Wind CF (DUNDWF1 VIC)")
end

plot!(p5, xlabel="Financial Year (ending)", ylabel="Annual Mean Capacity Factor",
      title="Trace 4006 — Annual Mean Capacity Factor by Financial Year", ylim=(0, 0.5),
      grid=true, gridalpha=0.3, left_margin=12Plots.mm)
savefig(p5, figure_path(SCRIPT_STEM, "02_4006_annual_cf.png"))
println("Saved: 02_4006_annual_cf.png")
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "02_4006_annual_cf.png"), "02_4006_annual_cf.png")
````

```@raw html
</details>
```

````
Saved: 02_4006_annual_cf.png

````

![Annual mean capacity factor by financial year, solar and wind trace 4006](02_4006_annual_cf.png)

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

## Summary

- Solar and wind capacity-factor structure for reference trace 4006 is loaded, transformed, and plotted directly on this page.
- Five figures cover daily capacity factor by state, diurnal structure at the Victorian representative locations, wind seasonal structure, and the annual financial-year comparison.

