```@meta
EditURL = "../../../../literate/isp2024/analysis/historical_trace_years.jl"
```

# ISP 2024: Historical trace-year comparison

A single reference year can conceal substantial interannual variation in renewable availability. This page loads the full historical solar and wind trace archive (the 2024 ISP raw trace downloads, historical years 2011-2023) directly, computes annual and seasonal capacity factors, low-output-day frequencies, and the most adverse summer solar day across the available historical years, and builds the comparison figures.

The comparison is location-specific: solar uses `Bannerton_SAT` and wind uses `DUNDWF1`. Results should not be generalised to all Victorian renewable resources without additional spatial analysis.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Statistics
using Plots
using StatsPlots

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_03_year_comparison"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const TRACES = relpath(joinpath(ISP2024_PROFILE.download_root, "Traces"), REPO_ROOT)  # kept relative: this is the path form recorded in the output tables
const YEARS = 2011:2023
const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]
const MIDDAY_COLS = string.(24:35)  # hours 12-18
const SOLAR_LOC = "Bannerton_SAT"  # VIC solar
const WIND_LOC = "DUNDWF1"         # VIC wind
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a TRACES-relative path to an absolute file location for reading

function add_datetime!(df::DataFrame)
    df.datetime = Date.(df.Year, df.Month, df.Day)
    return df
end

function load_location_all_years(tech, location, years)
    dfs = Dict{Int, DataFrame}()
    for yr in years
        file = joinpath(TRACES, "$(tech)_$(yr)", "$(location)_RefYear$(yr).csv")
        if isfile(abs_path(file))
            df = CSV.read(abs_path(file), DataFrame)
            add_datetime!(df)
            dfs[yr] = df
        end
    end
    return dfs
end

row_mean(df::DataFrame, cols) = [mean(row[col] for col in cols) for row in eachrow(df)]
row_max(df::DataFrame, cols) = [maximum(row[col] for col in cols) for row in eachrow(df)]
````

```@raw html
</details>
```

## Step 1 — load solar and wind traces across all historical reference years

`Bannerton_SAT` (solar) and `DUNDWF1` (wind) are loaded for every historical reference year in `YEARS` that has a local trace file available.
AEMO describes this as a rolling reference-year approach: the traces combine a 14-year historical sequence that repeats across the planning horizon ([2024 ISP PLEXOS Model Instructions, p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5)).

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
sol_years = load_location_all_years("solar", SOLAR_LOC, YEARS)
wind_years = load_location_all_years("wind", WIND_LOC, YEARS)

println("Loaded solar $(SOLAR_LOC): $(length(sol_years)) years")
println("Loaded wind $(WIND_LOC): $(length(wind_years)) years")
````

```@raw html
</details>
```

````
Loaded solar Bannerton_SAT: 13 years
Loaded wind DUNDWF1: 13 years

````

## Step 2 — seasonal capacity factor by year

For each loaded year, the summer (Dec/Jan/Feb) and winter (Jun/Jul/Aug) daily mean capacity factors are summarised separately, since variation between seasons and variation between years within the same season are different effects.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
seasonal_cf_rows = NamedTuple[]
for (tech, loc, hh_cols, data) in (
    ("solar", SOLAR_LOC, HH_COLS_SOL, sol_years),
    ("wind", WIND_LOC, HH_COLS_WIND, wind_years),
)
    for yr in sort(collect(keys(data)))
        df = data[yr]
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        if any(summer_mask)
            vals = row_mean(df[summer_mask, :], hh_cols)
            push!(
                seasonal_cf_rows,
                (
                    tech = tech,
                    location = loc,
                    season = "Summer",
                    year = yr,
                    n_days = length(vals),
                    mean_cf = mean(vals),
                    std_cf = std(vals),
                    min_cf = minimum(vals),
                    max_cf = maximum(vals),
                ),
            )
        end
        winter_mask = in.(df.Month, Ref((6, 7, 8)))
        if any(winter_mask)
            vals = row_mean(df[winter_mask, :], hh_cols)
            push!(
                seasonal_cf_rows,
                (
                    tech = tech,
                    location = loc,
                    season = "Winter",
                    year = yr,
                    n_days = length(vals),
                    mean_cf = mean(vals),
                    std_cf = std(vals),
                    min_cf = minimum(vals),
                    max_cf = maximum(vals),
                ),
            )
        end
    end
end
seasonal_cf_by_year = DataFrame(seasonal_cf_rows)
write_table(seasonal_cf_by_year, SCRIPT_STEM, "seasonal_cf_by_year")
markdown_table(seasonal_cf_by_year)
````

```@raw html
</details>
```

| **tech** | **location** | **season** | **year** | **n\_days** | **mean\_cf** | **std\_cf** | **min\_cf** | **max\_cf** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| solar | Bannerton\_SAT | Summer | 2011 | 3068 | 0.361699 | 0.138521 | 0.0145063 | 0.499403 |
| solar | Bannerton\_SAT | Winter | 2011 | 3128 | 0.156857 | 0.0585027 | 0.0095789 | 0.320306 |
| solar | Bannerton\_SAT | Summer | 2012 | 3068 | 0.38577 | 0.113911 | 0.0311683 | 0.498795 |
| solar | Bannerton\_SAT | Winter | 2012 | 3128 | 0.161978 | 0.07666 | 0.0242685 | 0.323715 |
| solar | Bannerton\_SAT | Summer | 2013 | 3068 | 0.404471 | 0.114939 | 0.0175779 | 0.500016 |
| solar | Bannerton\_SAT | Winter | 2013 | 3128 | 0.164595 | 0.0668842 | 0.0145248 | 0.330601 |
| solar | Bannerton\_SAT | Summer | 2014 | 3068 | 0.395343 | 0.118064 | 0.0167056 | 0.499387 |
| solar | Bannerton\_SAT | Winter | 2014 | 3128 | 0.160146 | 0.0655081 | 0.0164728 | 0.317032 |
| solar | Bannerton\_SAT | Summer | 2015 | 3068 | 0.394685 | 0.118126 | 0.0329821 | 0.500514 |
| solar | Bannerton\_SAT | Winter | 2015 | 3128 | 0.182758 | 0.0753149 | 0.00962398 | 0.310632 |
| solar | Bannerton\_SAT | Summer | 2016 | 3068 | 0.393496 | 0.0995262 | 0.110095 | 0.494742 |
| solar | Bannerton\_SAT | Winter | 2016 | 3128 | 0.143875 | 0.071287 | 0.0195337 | 0.326874 |
| solar | Bannerton\_SAT | Summer | 2017 | 3068 | 0.382376 | 0.116568 | 0.0515059 | 0.496493 |
| solar | Bannerton\_SAT | Winter | 2017 | 3128 | 0.167887 | 0.0709157 | 0.00995626 | 0.307574 |
| solar | Bannerton\_SAT | Summer | 2018 | 3068 | 0.385712 | 0.109853 | 0.0689566 | 0.495107 |
| solar | Bannerton\_SAT | Winter | 2018 | 3128 | 0.17432 | 0.0696596 | 0.011263 | 0.329645 |
| solar | Bannerton\_SAT | Summer | 2019 | 3068 | 0.404872 | 0.089915 | 0.0890162 | 0.497658 |
| solar | Bannerton\_SAT | Winter | 2019 | 3128 | 0.185259 | 0.061902 | 0.0205672 | 0.312467 |
| solar | Bannerton\_SAT | Summer | 2020 | 3068 | 0.403192 | 0.0968427 | 0.0773021 | 0.492177 |
| solar | Bannerton\_SAT | Winter | 2020 | 3128 | 0.184591 | 0.0654046 | 0.0483061 | 0.330894 |
| solar | Bannerton\_SAT | Summer | 2021 | 3068 | 0.409647 | 0.104105 | 0.0689535 | 0.49997 |
| solar | Bannerton\_SAT | Winter | 2021 | 3128 | 0.16638 | 0.075526 | 0.0169242 | 0.337331 |
| solar | Bannerton\_SAT | Summer | 2022 | 3068 | 0.410353 | 0.0854116 | 0.158083 | 0.498602 |
| solar | Bannerton\_SAT | Winter | 2022 | 3128 | 0.161973 | 0.0652057 | 0.0323292 | 0.315824 |
| solar | Bannerton\_SAT | Summer | 2023 | 3068 | 0.426174 | 0.0863665 | 0.0907033 | 0.498261 |
| solar | Bannerton\_SAT | Winter | 2023 | 3128 | 0.156571 | 0.066205 | 0.0323292 | 0.335218 |
| wind | DUNDWF1 | Summer | 2011 | 3068 | 0.307114 | 0.218651 | 0.020218 | 0.906974 |
| wind | DUNDWF1 | Winter | 2011 | 3128 | 0.464632 | 0.316575 | 0.00478592 | 0.942749 |
| wind | DUNDWF1 | Summer | 2012 | 3068 | 0.34782 | 0.200946 | 0.0419995 | 0.882836 |
| wind | DUNDWF1 | Winter | 2012 | 3128 | 0.452188 | 0.298884 | 0.0172527 | 0.959405 |
| wind | DUNDWF1 | Summer | 2013 | 3068 | 0.323963 | 0.194375 | 0.0140656 | 0.905228 |
| wind | DUNDWF1 | Winter | 2013 | 3128 | 0.435014 | 0.277966 | 0.00430331 | 0.945294 |
| wind | DUNDWF1 | Summer | 2014 | 3068 | 0.337852 | 0.2068 | 0.0472683 | 0.884263 |
| wind | DUNDWF1 | Winter | 2014 | 3128 | 0.538876 | 0.309664 | 0.00746108 | 0.96303 |
| wind | DUNDWF1 | Summer | 2015 | 3068 | 0.305119 | 0.183961 | 0.0250786 | 0.769096 |
| wind | DUNDWF1 | Winter | 2015 | 3128 | 0.392061 | 0.312063 | 0.00216577 | 0.961626 |
| wind | DUNDWF1 | Summer | 2016 | 3068 | 0.28348 | 0.187852 | 0.0494088 | 0.773467 |
| wind | DUNDWF1 | Winter | 2016 | 3128 | 0.446856 | 0.279113 | 0.00287329 | 0.955865 |
| wind | DUNDWF1 | Summer | 2017 | 3068 | 0.296865 | 0.215863 | 0.0357853 | 0.922245 |
| wind | DUNDWF1 | Winter | 2017 | 3128 | 0.428238 | 0.305132 | 0.00105192 | 0.959308 |
| wind | DUNDWF1 | Summer | 2018 | 3068 | 0.305462 | 0.200279 | 0.0543059 | 0.825952 |
| wind | DUNDWF1 | Winter | 2018 | 3128 | 0.486458 | 0.312867 | 0.0184536 | 0.962257 |
| wind | DUNDWF1 | Summer | 2019 | 3068 | 0.26196 | 0.189033 | 0.0309094 | 0.91107 |
| wind | DUNDWF1 | Winter | 2019 | 3128 | 0.543819 | 0.320272 | 0.0214145 | 0.947504 |
| wind | DUNDWF1 | Summer | 2020 | 3068 | 0.344116 | 0.218582 | 0.0156713 | 0.917512 |
| wind | DUNDWF1 | Winter | 2020 | 3128 | 0.473608 | 0.324444 | 0.00307133 | 0.957016 |
| wind | DUNDWF1 | Summer | 2021 | 3068 | 0.368448 | 0.201206 | 0.0474335 | 0.952007 |
| wind | DUNDWF1 | Winter | 2021 | 3128 | 0.435217 | 0.292918 | 0.0109802 | 0.955952 |
| wind | DUNDWF1 | Summer | 2022 | 3068 | 0.355404 | 0.181833 | 0.0125 | 0.793673 |
| wind | DUNDWF1 | Winter | 2022 | 3128 | 0.543756 | 0.273844 | 0.00704862 | 0.955128 |
| wind | DUNDWF1 | Summer | 2023 | 3068 | 0.321152 | 0.192413 | 0.0375621 | 0.781754 |
| wind | DUNDWF1 | Winter | 2023 | 3128 | 0.465627 | 0.276335 | 0.00101313 | 0.960851 |


## Step 3 — annual capacity factor by year

Averaging across the whole year (rather than by season) establishes the scale of year-to-year variation before seasonal or extreme-event metrics are considered.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
annual_cf_rows = NamedTuple[]
for (tech, loc, hh_cols, data) in (
    ("solar", SOLAR_LOC, HH_COLS_SOL, sol_years),
    ("wind", WIND_LOC, HH_COLS_WIND, wind_years),
)
    for yr in sort(collect(keys(data)))
        vals = row_mean(data[yr], hh_cols)
        push!(annual_cf_rows, (tech = tech, location = loc, year = yr, mean_cf = mean(vals)))
    end
end
annual_cf_by_year = DataFrame(annual_cf_rows)
write_table(annual_cf_by_year, SCRIPT_STEM, "annual_cf_by_year")
markdown_table(annual_cf_by_year)
````

```@raw html
</details>
```

| **tech** | **location** | **year** | **mean\_cf** |
|--:|--:|--:|--:|
| solar | Bannerton\_SAT | 2011 | 0.257362 |
| solar | Bannerton\_SAT | 2012 | 0.274037 |
| solar | Bannerton\_SAT | 2013 | 0.287337 |
| solar | Bannerton\_SAT | 2014 | 0.274026 |
| solar | Bannerton\_SAT | 2015 | 0.29051 |
| solar | Bannerton\_SAT | 2016 | 0.28018 |
| solar | Bannerton\_SAT | 2017 | 0.280107 |
| solar | Bannerton\_SAT | 2018 | 0.289739 |
| solar | Bannerton\_SAT | 2019 | 0.296915 |
| solar | Bannerton\_SAT | 2020 | 0.297859 |
| solar | Bannerton\_SAT | 2021 | 0.284485 |
| solar | Bannerton\_SAT | 2022 | 0.281107 |
| solar | Bannerton\_SAT | 2023 | 0.276166 |
| wind | DUNDWF1 | 2011 | 0.361648 |
| wind | DUNDWF1 | 2012 | 0.390979 |
| wind | DUNDWF1 | 2013 | 0.374104 |
| wind | DUNDWF1 | 2014 | 0.421323 |
| wind | DUNDWF1 | 2015 | 0.363536 |
| wind | DUNDWF1 | 2016 | 0.362167 |
| wind | DUNDWF1 | 2017 | 0.375569 |
| wind | DUNDWF1 | 2018 | 0.395895 |
| wind | DUNDWF1 | 2019 | 0.394096 |
| wind | DUNDWF1 | 2020 | 0.412785 |
| wind | DUNDWF1 | 2021 | 0.401134 |
| wind | DUNDWF1 | 2022 | 0.404672 |
| wind | DUNDWF1 | 2023 | 0.369846 |


## Step 4 — worst summer solar day per year

For each year, this finds the summer day with the lowest midday (hour 12-18) maximum capacity factor — an event-screening metric rather than a complete adequacy or energy-shortfall measure. Ties resolve to the first occurrence.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
worst_summer_day_rows = NamedTuple[]
for yr in sort(collect(keys(sol_years)))
    df = sol_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    any(summer_mask) || continue
    summer = df[summer_mask, :]
    midday_max = row_max(summer, MIDDAY_COLS)
    worst_pos = argmin(midday_max)  # first occurrence on ties
    worst_cf = midday_max[worst_pos]
    worst_date = summer.datetime[worst_pos]
    push!(worst_summer_day_rows, (year = yr, date = Dates.format(worst_date, "yyyy-mm-dd"), midday_max_cf = worst_cf))
end
worst_summer_day_by_year = DataFrame(worst_summer_day_rows)
write_table(worst_summer_day_by_year, SCRIPT_STEM, "worst_summer_day_by_year")
markdown_table(worst_summer_day_by_year)
````

```@raw html
</details>
```

| **year** | **date** | **midday\_max\_cf** |
|--:|--:|--:|
| 2011 | 2022-01-09 | 0.0456214 |
| 2012 | 2022-01-30 | 0.135249 |
| 2013 | 2021-12-17 | 0.0892427 |
| 2014 | 2022-02-11 | 0.0779296 |
| 2015 | 2022-01-07 | 0.0631645 |
| 2016 | 2022-01-13 | 0.438618 |
| 2017 | 2022-02-07 | 0.290899 |
| 2018 | 2021-12-09 | 0.282819 |
| 2019 | 2044-02-29 | 0.455299 |
| 2020 | 2022-01-02 | 0.257957 |
| 2021 | 2021-12-20 | 0.308981 |
| 2022 | 2022-01-26 | 0.813782 |
| 2023 | 2021-12-22 | 0.315597 |


## Step 5 — low-output day frequency

Solar and wind use different low-output metrics: solar counts summer days whose midday maximum falls below the threshold, while wind uses the summer daily mean capacity factor. Their percentages are therefore not directly interchangeable without retaining the metric definition.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
low_output_days_rows = NamedTuple[]
for yr in sort(collect(keys(sol_years)))
    df = sol_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    any(summer_mask) || continue
    summer = df[summer_mask, :]
    midday_max = row_max(summer, MIDDAY_COLS)
    n_low = count(<(0.05), midday_max)
    n_total = length(midday_max)
    push!(
        low_output_days_rows,
        (
            tech = "solar",
            location = SOLAR_LOC,
            year = yr,
            metric = "midday_max_cf",
            threshold = 0.05,
            n_low = n_low,
            n_total = n_total,
            low_percent = 100 * n_low / n_total,
        ),
    )
end
for yr in sort(collect(keys(wind_years)))
    df = wind_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    any(summer_mask) || continue
    summer = df[summer_mask, :]
    daily = row_mean(summer, HH_COLS_WIND)
    n_low = count(<(0.05), daily)
    n_total = length(daily)
    push!(
        low_output_days_rows,
        (
            tech = "wind",
            location = WIND_LOC,
            year = yr,
            metric = "daily_mean_cf",
            threshold = 0.05,
            n_low = n_low,
            n_total = n_total,
            low_percent = 100 * n_low / n_total,
        ),
    )
end
low_output_days_by_year = DataFrame(low_output_days_rows)
write_table(low_output_days_by_year, SCRIPT_STEM, "low_output_days_by_year")
markdown_table(low_output_days_by_year)
````

```@raw html
</details>
```

| **tech** | **location** | **year** | **metric** | **threshold** | **n\_low** | **n\_total** | **low\_percent** |
|--:|--:|--:|--:|--:|--:|--:|--:|
| solar | Bannerton\_SAT | 2011 | midday\_max\_cf | 0.05 | 34 | 3068 | 1.10821 |
| solar | Bannerton\_SAT | 2012 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2013 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2014 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2015 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2016 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2017 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2018 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2019 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2020 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2021 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2022 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| solar | Bannerton\_SAT | 2023 | midday\_max\_cf | 0.05 | 0 | 3068 | 0.0 |
| wind | DUNDWF1 | 2011 | daily\_mean\_cf | 0.05 | 195 | 3068 | 6.35593 |
| wind | DUNDWF1 | 2012 | daily\_mean\_cf | 0.05 | 15 | 3068 | 0.488918 |
| wind | DUNDWF1 | 2013 | daily\_mean\_cf | 0.05 | 68 | 3068 | 2.21643 |
| wind | DUNDWF1 | 2014 | daily\_mean\_cf | 0.05 | 5 | 3068 | 0.162973 |
| wind | DUNDWF1 | 2015 | daily\_mean\_cf | 0.05 | 26 | 3068 | 0.847458 |
| wind | DUNDWF1 | 2016 | daily\_mean\_cf | 0.05 | 34 | 3068 | 1.10821 |
| wind | DUNDWF1 | 2017 | daily\_mean\_cf | 0.05 | 165 | 3068 | 5.3781 |
| wind | DUNDWF1 | 2018 | daily\_mean\_cf | 0.05 | 0 | 3068 | 0.0 |
| wind | DUNDWF1 | 2019 | daily\_mean\_cf | 0.05 | 112 | 3068 | 3.65059 |
| wind | DUNDWF1 | 2020 | daily\_mean\_cf | 0.05 | 50 | 3068 | 1.62973 |
| wind | DUNDWF1 | 2021 | daily\_mean\_cf | 0.05 | 26 | 3068 | 0.847458 |
| wind | DUNDWF1 | 2022 | daily\_mean\_cf | 0.05 | 23 | 3068 | 0.749674 |
| wind | DUNDWF1 | 2023 | daily\_mean\_cf | 0.05 | 25 | 3068 | 0.814863 |


## Step 6 — annual CF variability summary

This summarises the spread of annual mean capacity factor across all loaded years for each technology, using the population standard deviation (dividing by n, not n-1) — a different convention from the sample standard deviation used for `std_cf` in the seasonal summary above (Step 2), which divides by n-1.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
variability_rows = NamedTuple[]
for (tech, loc, hh_cols, data) in (
    ("solar", SOLAR_LOC, HH_COLS_SOL, sol_years),
    ("wind", WIND_LOC, HH_COLS_WIND, wind_years),
)
    vals = [mean(row_mean(data[yr], hh_cols)) for yr in sort(collect(keys(data)))]
    push!(
        variability_rows,
        (
            tech = tech,
            location = loc,
            mean_annual_cf = mean(vals),
            std_annual_cf = std(vals; corrected = false),
            min_annual_cf = minimum(vals),
            max_annual_cf = maximum(vals),
        ),
    )
end
annual_cf_variability_summary = DataFrame(variability_rows)
write_table(annual_cf_variability_summary, SCRIPT_STEM, "annual_cf_variability_summary")
markdown_table(annual_cf_variability_summary)
````

```@raw html
</details>
```

| **tech** | **location** | **mean\_annual\_cf** | **std\_annual\_cf** | **min\_annual\_cf** | **max\_annual\_cf** |
|--:|--:|--:|--:|--:|--:|
| solar | Bannerton\_SAT | 0.282295 | 0.0104352 | 0.257362 | 0.297859 |
| wind | DUNDWF1 | 0.38675 | 0.019416 | 0.361648 | 0.421323 |


Across the 13 loaded years, the computed annual mean capacity factor ranges from 0.257362 to 0.297859 at `Bannerton_SAT` and from 0.361648 to 0.421323 at `DUNDWF1`. These are local trace-summary ranges, not values established by the PLEXOS instructions. Solar and wind low-output percentages remain non-interchangeable because they use different low-output metrics.

## Step 7 — figure: year-over-year boxplot of summer and winter daily mean CF

Each panel shows the distribution of daily mean capacity factor across all days in one season for one technology, one box per historical reference year.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
summer_cfs_sol = Dict()
summer_cfs_wind = Dict()
winter_cfs_sol = Dict()
winter_cfs_wind = Dict()

for yr in sort(collect(keys(sol_years)))
    df = sol_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    winter_mask = in.(df.Month, Ref((6, 7, 8)))
    if any(summer_mask)
        summer_cfs_sol[yr] = [mean(skipmissing(Vector(df[i, HH_COLS_SOL]))) for i in findall(summer_mask)]
    end
    if any(winter_mask)
        winter_cfs_sol[yr] = [mean(skipmissing(Vector(df[i, HH_COLS_SOL]))) for i in findall(winter_mask)]
    end
end

for yr in sort(collect(keys(wind_years)))
    df = wind_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    winter_mask = in.(df.Month, Ref((6, 7, 8)))
    if any(summer_mask)
        summer_cfs_wind[yr] = [mean(skipmissing(Vector(df[i, HH_COLS_WIND]))) for i in findall(summer_mask)]
    end
    if any(winter_mask)
        winter_cfs_wind[yr] = [mean(skipmissing(Vector(df[i, HH_COLS_WIND]))) for i in findall(winter_mask)]
    end
end

yrs_sol_summer = sort(collect(keys(summer_cfs_sol)))
yrs_wind_summer = sort(collect(keys(summer_cfs_wind)))
yrs_sol_winter = sort(collect(keys(winter_cfs_sol)))
yrs_wind_winter = sort(collect(keys(winter_cfs_wind)))

function long_form(cf_dict, years)
    labels = String[]
    values = Float64[]
    for yr in years
        for v in cf_dict[yr]
            push!(labels, string(yr))
            push!(values, v)
        end
    end
    return DataFrame(labels = labels, values = values)
end

p1 = @df long_form(summer_cfs_sol, yrs_sol_summer) boxplot(:labels, :values, legend = false, fillalpha = 0.3, color = :darkorange, title = "Solar $(SOLAR_LOC) — Summer Daily Mean CF by Year", ylabel = "Daily Mean Capacity Factor", ylim = (0, 1))
p2 = @df long_form(summer_cfs_wind, yrs_wind_summer) boxplot(:labels, :values, legend = false, fillalpha = 0.3, color = :steelblue, title = "Wind $(WIND_LOC) — Summer Daily Mean CF by Year", ylabel = "Daily Mean Capacity Factor", ylim = (0, 1))
p3 = @df long_form(winter_cfs_sol, yrs_sol_winter) boxplot(:labels, :values, legend = false, fillalpha = 0.3, color = :darkorange, title = "Solar $(SOLAR_LOC) — Winter Daily Mean CF by Year", ylabel = "Daily Mean Capacity Factor", ylim = (0, 1))
p4 = @df long_form(winter_cfs_wind, yrs_wind_winter) boxplot(:labels, :values, legend = false, fillalpha = 0.3, color = :steelblue, title = "Wind $(WIND_LOC) — Winter Daily Mean CF by Year", ylabel = "Daily Mean Capacity Factor", ylim = (0, 1))

p_bp = plot(p1, p2, p3, p4, layout = (2, 2), size = (1400, 1000), left_margin = 8Plots.mm, bottom_margin = 8Plots.mm)
savefig(p_bp, figure_path(SCRIPT_STEM, "03_year_comparison_boxplot.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "03_year_comparison_boxplot.png"), "03_year_comparison_boxplot.png")
````

```@raw html
</details>
```

![Summer and winter daily mean capacity factor distributions for solar and wind, one boxplot per historical reference year](03_year_comparison_boxplot.png)

## Step 8 — figure: annual mean CF trend across years

This plots one point per historical reference year for each technology, showing the overall trend in annual mean capacity factor across the sampled years.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p_trend = plot(legend = true, size = (1200, 600), left_margin = 8Plots.mm, bottom_margin = 8Plots.mm)

annual_means_sol = []
yrs_list_sol = []
for yr in sort(collect(keys(sol_years)))
    df = sol_years[yr]
    daily = [mean(skipmissing(Vector(df[i, HH_COLS_SOL]))) for i in 1:nrow(df)]
    push!(annual_means_sol, mean(daily))
    push!(yrs_list_sol, yr)
end
plot!(p_trend, yrs_list_sol, annual_means_sol, marker = :circle, color = :darkorange, linewidth = 2, markersize = 8, label = "Solar $(SOLAR_LOC)")

annual_means_wind = []
yrs_list_wind = []
for yr in sort(collect(keys(wind_years)))
    df = wind_years[yr]
    daily = [mean(skipmissing(Vector(df[i, HH_COLS_WIND]))) for i in 1:nrow(df)]
    push!(annual_means_wind, mean(daily))
    push!(yrs_list_wind, yr)
end
plot!(p_trend, yrs_list_wind, annual_means_wind, marker = :square, color = :steelblue, linewidth = 2, markersize = 8, label = "Wind $(WIND_LOC)")

plot!(p_trend, xlabel = "Reference Year", ylabel = "Annual Mean Capacity Factor", title = "Annual Mean CF: Solar ($(SOLAR_LOC)) vs Wind ($(WIND_LOC))", grid = true, gridalpha = 0.3)
savefig(p_trend, figure_path(SCRIPT_STEM, "03_annual_cf_trend.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "03_annual_cf_trend.png"), "03_annual_cf_trend.png")
````

```@raw html
</details>
```

![Annual mean capacity factor trend across historical reference years for solar and wind](03_annual_cf_trend.png)

## Step 9 — figure: worst summer solar day per year

This bar chart visualises the same worst-summer-day metric computed in Step 4, one bar per year, annotated with its midday max capacity factor.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
midday_cols = string.(24:35)
worst_days = Dict()
for yr in sort(collect(keys(sol_years)))
    df = sol_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    if any(summer_mask)
        summer = df[summer_mask, :]
        midday_max = [maximum(skipmissing(Vector(summer[i, midday_cols]))) for i in 1:nrow(summer)]
        worst_pos = argmin(midday_max)
        worst_days[yr] = midday_max[worst_pos]
    end
end

yrs_worst = sort(collect(keys(worst_days)))
cfs_worst = [worst_days[yr] for yr in yrs_worst]

p_worst = bar(
    string.(yrs_worst), cfs_worst, color = :darkorange, alpha = 0.7, legend = false,
    title = "Solar $(SOLAR_LOC) — Worst Summer Day (Midday Max CF) by Year",
    ylabel = "Midday Max Capacity Factor", ylim = (0, 1), size = (1200, 600), left_margin = 8Plots.mm, bottom_margin = 8Plots.mm,
)
for (i, (yr, cf)) in enumerate(zip(yrs_worst, cfs_worst))
    annotate!(p_worst, i, cf + 0.02, text(string(round(cf, digits = 2)), 8, :center))
end
savefig(p_worst, figure_path(SCRIPT_STEM, "03_worst_summer_day.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "03_worst_summer_day.png"), "03_worst_summer_day.png")
````

```@raw html
</details>
```

![Worst (lowest midday-max capacity factor) summer solar day identified in each historical reference year](03_worst_summer_day.png)

## Step 10 — figure: near-zero-output day frequency

This two-panel bar chart visualises the same low-output-day metric computed in Step 5 as a percentage of summer days per year, annotated with the underlying day count, one panel per technology.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
sol_low = Dict()
wind_low = Dict()
sol_low_counts = Dict()
wind_low_counts = Dict()

for yr in sort(collect(keys(sol_years)))
    df = sol_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    if any(summer_mask)
        summer = df[summer_mask, :]
        midday_max = [maximum(skipmissing(Vector(summer[i, midday_cols]))) for i in 1:nrow(summer)]
        n_low = count(<(0.05), midday_max)
        n_total = length(midday_max)
        sol_low[yr] = 100 * n_low / n_total
        sol_low_counts[yr] = n_low
    end
end

for yr in sort(collect(keys(wind_years)))
    df = wind_years[yr]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    if any(summer_mask)
        summer = df[summer_mask, :]
        daily = [mean(skipmissing(Vector(summer[i, HH_COLS_WIND]))) for i in 1:nrow(summer)]
        n_low = count(<(0.05), daily)
        n_total = length(daily)
        wind_low[yr] = 100 * n_low / n_total
        wind_low_counts[yr] = n_low
    end
end

yrs_sol_low = sort(collect(keys(sol_low)))
yrs_wind_low = sort(collect(keys(wind_low)))
sol_low_values = [sol_low[yr] for yr in yrs_sol_low]
wind_low_values = [wind_low[yr] for yr in yrs_wind_low]
sol_label_offset = max(0.15, 0.025 * maximum(sol_low_values))
wind_label_offset = max(0.15, 0.025 * maximum(wind_low_values))

p_low1 = bar(
    string.(yrs_sol_low), sol_low_values, color = :darkorange, alpha = 0.7,
    legend = false, title = "Solar $(SOLAR_LOC) — % Summer Days with Midday Max CF < 0.05",
    ylabel = "% of Summer Days", ylim = (0, maximum(sol_low_values) + 2 * sol_label_offset),
)
p_low2 = bar(
    string.(yrs_wind_low), wind_low_values, color = :steelblue, alpha = 0.7,
    legend = false, title = "Wind $(WIND_LOC) — % Summer Days with Daily Mean CF < 0.05",
    ylabel = "% of Summer Days", ylim = (0, maximum(wind_low_values) + 2 * wind_label_offset),
)

for (idx, yr) in enumerate(yrs_sol_low)
    annotate!(p_low1, idx, sol_low_values[idx] + sol_label_offset, text(string(sol_low_counts[yr]), 8, :center))
end
for (idx, yr) in enumerate(yrs_wind_low)
    annotate!(p_low2, idx, wind_low_values[idx] + wind_label_offset, text(string(wind_low_counts[yr]), 8, :center))
end

p_zero = plot(p_low1, p_low2, layout = (1, 2), size = (1800, 600), left_margin = 10Plots.mm, bottom_margin = 10Plots.mm, top_margin = 20Plots.mm)
savefig(p_zero, figure_path(SCRIPT_STEM, "03_zero_output_days.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "03_zero_output_days.png"), "03_zero_output_days.png")
````

```@raw html
</details>
```

![Percentage of summer days each year with near-zero solar midday-max or wind daily-mean capacity factor, annotated with the underlying day count](03_zero_output_days.png)

## Summary

- Solar (`Bannerton_SAT`) and wind (`DUNDWF1`) show materially different year-to-year and season-to-season capacity factor variability across the 2011-2023 historical reference years.
- The worst-summer-day and near-zero-output-day tables and figures identify specific adverse years rather than a single averaged risk figure, and the two technologies use different low-output metrics that are not directly interchangeable.

