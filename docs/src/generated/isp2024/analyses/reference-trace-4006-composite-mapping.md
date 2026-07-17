```@meta
EditURL = "../../../../literate/isp2024/analysis/reference_trace_4006_mapping.jl"
```

# ISP 2024: Reference trace 4006 composite mapping

Reference trace `4006` assigns a historical weather year to each financial year across the planning horizon, so a "near-term" or "far-term" renewable profile is really a reuse of a specific historical solar and wind year (the 2024 ISP raw trace downloads), not an independent forecast. This page builds the financial-year-to-historical-year mapping, the per-historical-year and near/far renewable statistics derived from it, and the four figures that visualise the mapping and its consequences.

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
using PISP

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_08_4006_composite_map"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const TRACES = relpath(joinpath(ISP2024_PROFILE.download_root, "Traces"), REPO_ROOT)
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a TRACES-relative path to an absolute file location for reading

const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]

const SOLAR_LOC = "Bannerton_SAT"
const WIND_LOC = "DUNDWF1"

const NEAR_YEARS = [2025, 2026, 2027, 2028, 2029]
const FAR_YEARS = [2045, 2046, 2047, 2048, 2049]
````

```@raw html
</details>
```

The financial-year-to-historical-year mapping is read directly from `PISP.WEATHER_YEARS_ISP` rather than restated here, so this page cannot drift from the package's own mapping. An invariant check confirms every financial-year range is contiguous.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
const DATE_RANGES_REFYEARS = [
    (fy_range[1], fy_range[2], parse(Int, ref_year))
    for (fy_range, ref_year) in sort(collect(PISP.WEATHER_YEARS_ISP); by = first)
]

for i in 1:(length(DATE_RANGES_REFYEARS) - 1)
    this_fy_end = Date(DATE_RANGES_REFYEARS[i][2])
    next_fy_start = Date(DATE_RANGES_REFYEARS[i + 1][1])
    @assert next_fy_start == this_fy_end + Day(1) "PISP.WEATHER_YEARS_ISP financial-year ranges are not contiguous between row $i and $(i + 1)"
end
````

```@raw html
</details>
```

`read_trace`, `trace_path`, `daily_cf`, `ref_year_for_fy_end`, and `load_year_cf` are shared by several steps below: they resolve a technology/reference-year/location combination to a trace file, load it, and reduce it to one daily capacity-factor value per row. `ref_year_for_fy_end`'s argument (`yr`) is always a financial-year-END year (e.g. 2025, 2045), not a historical/ref year, and must be translated through the mapping table before a trace file can be loaded for it.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
read_trace(path) = CSV.read(abs_path(path), DataFrame)

trace_path(tech, yr, loc) = joinpath(TRACES, "$(tech)_$(yr)", "$(loc)_RefYear$(yr).csv")

daily_cf(df::DataFrame, hh_cols) = [mean(row[col] for col in hh_cols) for row in eachrow(df)]

function ref_year_for_fy_end(yr::Int)
    idx = findfirst(t -> startswith(t[2], string(yr)), DATE_RANGES_REFYEARS)
    idx === nothing && return nothing
    return DATE_RANGES_REFYEARS[idx][3]
end

function load_year_cf(years, tech, loc, hh_cols)
    all_cfs = Vector{Float64}[]
    for yr in years
        ref = ref_year_for_fy_end(yr)
        ref === nothing && continue
        path = trace_path(tech, ref, loc)
        isfile(abs_path(path)) || continue
        push!(all_cfs, daily_cf(read_trace(path), hh_cols))
    end
    isempty(all_cfs) && return nothing
    n = length(all_cfs[1])
    return [mean(cfs[i] for cfs in all_cfs) for i in 1:n]
end
````

```@raw html
</details>
```

## Step 1 — build the financial-year to historical-year mapping table

Each row assigns one financial year in the planning horizon to the historical weather year whose trace is reused for it.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
fy_start = [t[1] for t in DATE_RANGES_REFYEARS]
fy_end = [t[2] for t in DATE_RANGES_REFYEARS]
ref_year = [t[3] for t in DATE_RANGES_REFYEARS]
fy_label = ["FY$(e[1:4])" for e in fy_end]
ref_label = string.(ref_year)

mapping_table = DataFrame(
    fy_start = fy_start,
    fy_end = fy_end,
    ref_year = ref_year,
    fy_label = fy_label,
    ref_label = ref_label,
)
write_table(mapping_table, SCRIPT_STEM, "mapping_table")
markdown_table(mapping_table)
````

```@raw html
</details>
```

| **fy\_start** | **fy\_end** | **ref\_year** | **fy\_label** | **ref\_label** |
|--:|--:|--:|--:|--:|
| 2024-07-01 | 2025-06-30 | 2019 | FY2025 | 2019 |
| 2025-07-01 | 2026-06-30 | 2020 | FY2026 | 2020 |
| 2026-07-01 | 2027-06-30 | 2021 | FY2027 | 2021 |
| 2027-07-01 | 2028-06-30 | 2022 | FY2028 | 2022 |
| 2028-07-01 | 2029-06-30 | 2023 | FY2029 | 2023 |
| 2029-07-01 | 2030-06-30 | 2015 | FY2030 | 2015 |
| 2030-07-01 | 2031-06-30 | 2011 | FY2031 | 2011 |
| 2031-07-01 | 2032-06-30 | 2012 | FY2032 | 2012 |
| 2032-07-01 | 2033-06-30 | 2013 | FY2033 | 2013 |
| 2033-07-01 | 2034-06-30 | 2014 | FY2034 | 2014 |
| 2034-07-01 | 2035-06-30 | 2015 | FY2035 | 2015 |
| 2035-07-01 | 2036-06-30 | 2016 | FY2036 | 2016 |
| 2036-07-01 | 2037-06-30 | 2017 | FY2037 | 2017 |
| 2037-07-01 | 2038-06-30 | 2018 | FY2038 | 2018 |
| 2038-07-01 | 2039-06-30 | 2019 | FY2039 | 2019 |
| 2039-07-01 | 2040-06-30 | 2020 | FY2040 | 2020 |
| 2040-07-01 | 2041-06-30 | 2021 | FY2041 | 2021 |
| 2041-07-01 | 2042-06-30 | 2022 | FY2042 | 2022 |
| 2042-07-01 | 2043-06-30 | 2023 | FY2043 | 2023 |
| 2043-07-01 | 2044-06-30 | 2015 | FY2044 | 2015 |
| 2044-07-01 | 2045-06-30 | 2011 | FY2045 | 2011 |
| 2045-07-01 | 2046-06-30 | 2012 | FY2046 | 2012 |
| 2046-07-01 | 2047-06-30 | 2013 | FY2047 | 2013 |
| 2047-07-01 | 2048-06-30 | 2014 | FY2048 | 2014 |
| 2048-07-01 | 2049-06-30 | 2015 | FY2049 | 2015 |
| 2049-07-01 | 2050-06-30 | 2016 | FY2050 | 2016 |
| 2050-07-01 | 2051-06-30 | 2017 | FY2051 | 2017 |
| 2051-07-01 | 2052-06-30 | 2018 | FY2052 | 2018 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
println("=== 4006 Composite Mapping ===")
for row in eachrow(mapping_table)
    println("  ", row.fy_start[1:4], " → ref ", row.ref_year)
end
````

```@raw html
</details>
```

````
=== 4006 Composite Mapping ===
  2024 → ref 2019
  2025 → ref 2020
  2026 → ref 2021
  2027 → ref 2022
  2028 → ref 2023
  2029 → ref 2015
  2030 → ref 2011
  2031 → ref 2012
  2032 → ref 2013
  2033 → ref 2014
  2034 → ref 2015
  2035 → ref 2016
  2036 → ref 2017
  2037 → ref 2018
  2038 → ref 2019
  2039 → ref 2020
  2040 → ref 2021
  2041 → ref 2022
  2042 → ref 2023
  2043 → ref 2015
  2044 → ref 2011
  2045 → ref 2012
  2046 → ref 2013
  2047 → ref 2014
  2048 → ref 2015
  2049 → ref 2016
  2050 → ref 2017
  2051 → ref 2018

````

## Step 2 — renewable statistics by historical year

For every historical year actually used by the mapping, this computes the annual mean capacity factor and the summer (Dec/Jan/Feb) mean, minimum, and 5th-percentile capacity factor for the representative solar and wind locations.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
historical_year_vre_stats_rows = NamedTuple[]
for yr in sort(unique(mapping_table.ref_year))
    for (tech, loc, hh_cols) in (("solar", SOLAR_LOC, HH_COLS_SOL), ("wind", WIND_LOC, HH_COLS_WIND))
        path = trace_path(tech, yr, loc)
        isfile(abs_path(path)) || continue
        df = read_trace(path)
        summer = df[in.(df.Month, Ref((12, 1, 2))), :]
        nrow(summer) == 0 && continue
        summer_cf = daily_cf(summer, hh_cols)
        push!(
            historical_year_vre_stats_rows,
            (
                ref_year = yr,
                tech = tech,
                annual_mean_cf = mean(daily_cf(df, hh_cols)),
                summer_mean_cf = mean(summer_cf),
                summer_min_cf = minimum(summer_cf),
                summer_p5_cf = quantile(summer_cf, 0.05),
            ),
        )
    end
end
historical_year_vre_stats = DataFrame(historical_year_vre_stats_rows)
write_table(historical_year_vre_stats, SCRIPT_STEM, "historical_year_vre_stats")
markdown_table(historical_year_vre_stats)
````

```@raw html
</details>
```

| **ref\_year** | **tech** | **annual\_mean\_cf** | **summer\_mean\_cf** | **summer\_min\_cf** | **summer\_p5\_cf** |
|--:|--:|--:|--:|--:|--:|
| 2011 | solar | 0.257362 | 0.361699 | 0.0145063 | 0.0377352 |
| 2011 | wind | 0.361648 | 0.307114 | 0.020218 | 0.0412972 |
| 2012 | solar | 0.274037 | 0.38577 | 0.0311683 | 0.102937 |
| 2012 | wind | 0.390979 | 0.34782 | 0.0419995 | 0.120625 |
| 2013 | solar | 0.287337 | 0.404471 | 0.0175779 | 0.149914 |
| 2013 | wind | 0.374104 | 0.323963 | 0.0140656 | 0.0776668 |
| 2014 | solar | 0.274026 | 0.395343 | 0.0167056 | 0.119831 |
| 2014 | wind | 0.421323 | 0.337852 | 0.0472683 | 0.0970499 |
| 2015 | solar | 0.29051 | 0.394685 | 0.0329821 | 0.109433 |
| 2015 | wind | 0.363536 | 0.305119 | 0.0250786 | 0.0803984 |
| 2016 | solar | 0.28018 | 0.393496 | 0.110095 | 0.152268 |
| 2016 | wind | 0.362167 | 0.28348 | 0.0494088 | 0.0812237 |
| 2017 | solar | 0.280107 | 0.382376 | 0.0515059 | 0.120608 |
| 2017 | wind | 0.375569 | 0.296865 | 0.0357853 | 0.0484888 |
| 2018 | solar | 0.289739 | 0.385712 | 0.0689566 | 0.170206 |
| 2018 | wind | 0.395895 | 0.305462 | 0.0543059 | 0.0746259 |
| 2019 | solar | 0.296915 | 0.404872 | 0.0890162 | 0.204355 |
| 2019 | wind | 0.394096 | 0.26196 | 0.0309094 | 0.0619373 |
| 2020 | solar | 0.297859 | 0.403192 | 0.0773021 | 0.182836 |
| 2020 | wind | 0.412785 | 0.344116 | 0.0156713 | 0.0933679 |
| 2021 | solar | 0.284485 | 0.409647 | 0.0689535 | 0.174614 |
| 2021 | wind | 0.401134 | 0.368448 | 0.0474335 | 0.0892812 |
| 2022 | solar | 0.281107 | 0.410353 | 0.158083 | 0.229602 |
| 2022 | wind | 0.404672 | 0.355404 | 0.0125 | 0.105401 |
| 2023 | solar | 0.276166 | 0.426174 | 0.0907033 | 0.168359 |
| 2023 | wind | 0.369846 | 0.321152 | 0.0375621 | 0.094468 |


## Step 3 — near-term vs far-term daily capacity factor

The near-term group (financial years ending 2025-2029) and far-term group (financial years ending 2045-2049) are each translated through the mapping to their historical reference years, then averaged day-by-day across the group's traces. Each historical reference trace covers many years of half-hourly data reduced to one capacity-factor value per day, so the resulting near/far series run to tens of thousands of rows per technology; the full daily series is written to file as complete evidence, and the table below summarises it by technology and term.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
near_vs_far_term_rows = NamedTuple[]
for (tech, loc, hh_cols) in (("solar", SOLAR_LOC, HH_COLS_SOL), ("wind", WIND_LOC, HH_COLS_WIND))
    near_cf = load_year_cf(NEAR_YEARS, tech, loc, hh_cols)
    far_cf = load_year_cf(FAR_YEARS, tech, loc, hh_cols)
    if near_cf !== nothing
        for (day, cf) in enumerate(near_cf)
            push!(near_vs_far_term_rows, (tech = tech, term = "near", day_of_year = day, daily_cf = cf))
        end
    end
    if far_cf !== nothing
        for (day, cf) in enumerate(far_cf)
            push!(near_vs_far_term_rows, (tech = tech, term = "far", day_of_year = day, daily_cf = cf))
        end
    end
end
near_vs_far_term_daily_cf = DataFrame(near_vs_far_term_rows)
write_table(near_vs_far_term_daily_cf, SCRIPT_STEM, "near_vs_far_term_daily_cf")

near_vs_far_term_summary = combine(
    groupby(near_vs_far_term_daily_cf, [:tech, :term]),
    :daily_cf => mean => :mean_cf,
    :daily_cf => minimum => :min_cf,
    :daily_cf => maximum => :max_cf,
    nrow => :n_days,
)
sort!(near_vs_far_term_summary, [:tech, :term])
markdown_table(near_vs_far_term_summary)
````

```@raw html
</details>
```

| **tech** | **term** | **mean\_cf** | **min\_cf** | **max\_cf** | **n\_days** |
|--:|--:|--:|--:|--:|--:|
| solar | far | 0.276654 | 0.0462443 | 0.495946 | 12418 |
| solar | near | 0.287307 | 0.0886683 | 0.491964 | 12418 |
| wind | far | 0.382318 | 0.0602974 | 0.748947 | 12418 |
| wind | near | 0.396507 | 0.0745325 | 0.828956 | 12418 |


## Step 4 — year-by-year renewable matrix

One annual mean capacity factor per historical year and technology, feeding the heatmap figure below.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
heatmap_years = sort(unique(mapping_table.ref_year))
vre_heatmap_rows = NamedTuple[]
for (tech, loc, hh_cols) in (("solar", SOLAR_LOC, HH_COLS_SOL), ("wind", WIND_LOC, HH_COLS_WIND))
    for yr in heatmap_years
        path = trace_path(tech, yr, loc)
        val = isfile(abs_path(path)) ? mean(daily_cf(read_trace(path), hh_cols)) : missing
        push!(vre_heatmap_rows, (tech = tech, ref_year = yr, annual_mean_cf = val))
    end
end
vre_heatmap = DataFrame(vre_heatmap_rows)
write_table(vre_heatmap, SCRIPT_STEM, "vre_heatmap")
markdown_table(vre_heatmap)
````

```@raw html
</details>
```

| **tech** | **ref\_year** | **annual\_mean\_cf** |
|--:|--:|--:|
| solar | 2011 | 0.257362 |
| solar | 2012 | 0.274037 |
| solar | 2013 | 0.287337 |
| solar | 2014 | 0.274026 |
| solar | 2015 | 0.29051 |
| solar | 2016 | 0.28018 |
| solar | 2017 | 0.280107 |
| solar | 2018 | 0.289739 |
| solar | 2019 | 0.296915 |
| solar | 2020 | 0.297859 |
| solar | 2021 | 0.284485 |
| solar | 2022 | 0.281107 |
| solar | 2023 | 0.276166 |
| wind | 2011 | 0.361648 |
| wind | 2012 | 0.390979 |
| wind | 2013 | 0.374104 |
| wind | 2014 | 0.421323 |
| wind | 2015 | 0.363536 |
| wind | 2016 | 0.362167 |
| wind | 2017 | 0.375569 |
| wind | 2018 | 0.395895 |
| wind | 2019 | 0.394096 |
| wind | 2020 | 0.412785 |
| wind | 2021 | 0.401134 |
| wind | 2022 | 0.404672 |
| wind | 2023 | 0.369846 |


## Step 5 — how often each historical year is reused

Repeated reference years mean the planning horizon is not a monotonic sequence of new weather conditions; some historical years are reused several times.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
println("\n=== 4006 COMPOSITE STATS ===")
println("Total years: ", nrow(mapping_table))
println("Unique historical years used: ", sort(unique(mapping_table.ref_year)))

ref_year_counts = combine(groupby(mapping_table, :ref_year), nrow => :count)
sort!(ref_year_counts, :ref_year)
write_table(ref_year_counts, SCRIPT_STEM, "ref_year_counts")
markdown_table(ref_year_counts)
````

```@raw html
</details>
```

| **ref\_year** | **count** |
|--:|--:|
| 2011 | 2 |
| 2012 | 2 |
| 2013 | 2 |
| 2014 | 2 |
| 2015 | 4 |
| 2016 | 2 |
| 2017 | 2 |
| 2018 | 2 |
| 2019 | 2 |
| 2020 | 2 |
| 2021 | 2 |
| 2022 | 2 |
| 2023 | 2 |


## Step 6 — timeline of historical years across the planning horizon

Each bar is one financial year in the mapping, coloured by its source historical year, so repeated colours show reused historical years.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
unique_years = sort(unique(mapping_table.ref_year))
color_map = Dict(yr => palette(:tab20)[i % 20 + 1] for (i, yr) in enumerate(unique_years))

p1 = plot(xlim=(0, nrow(mapping_table)), ylim=(0.5, 1.5), legend=:none, title="4006 Reference Trace — Historical Year Mapping\n(Each bar = one financial year, color = source historical year)",
         xlabel="Financial Year", ylabel="", yticks=([1], ["4006 Trace"]), size=(1400, 400), grid=false)

for (idx, row) in enumerate(eachrow(mapping_table))
    color = color_map[row.ref_year]
    bar!(p1, [idx], [1.0], color=color, alpha=0.8, legend=false, width=1)
    if idx % 2 == 1
        annotate!(p1, idx, 1.1, text("$(row.ref_year)", 7, :center))
    end
end

fy_labels = [row.fy_start[1:4] for row in eachrow(mapping_table)]
plot!(p1, xticks=(1:nrow(mapping_table), fy_labels), xrotation=90)

savefig(p1, figure_path(SCRIPT_STEM, "08_4006_timeline_map.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "08_4006_timeline_map.png"), "08_4006_timeline_map.png")
````

```@raw html
</details>
```

![Timeline of the 4006 composite mapping, one bar per financial year coloured by source historical year](08_4006_timeline_map.png)

## Step 7 — summer capacity factor by historical year

Reads back the historical-year statistics table written in Step 2 and plots summer mean capacity factor per historical year for solar and wind, with downward error bars to the summer 5th-percentile value.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
stats = CSV.read(table_path(SCRIPT_STEM, "historical_year_vre_stats"), DataFrame)

p2 = plot(
    layout=(1,2), size=(1400, 650),
    left_margin=10Plots.mm, right_margin=10Plots.mm,
    top_margin=12Plots.mm, bottom_margin=16Plots.mm,
)

for (idx, tech) in enumerate(("solar", "wind"))
    tech_df = filter(row -> row.tech == tech, stats)
    sort!(tech_df, :ref_year)
    colors = [color_map[yr] for yr in tech_df.ref_year]

    years_labels = string.(tech_df.ref_year)
    for (i, (year, cf, p5_cf)) in enumerate(zip(tech_df.ref_year, tech_df.summer_mean_cf, tech_df.summer_p5_cf))
        bar!(p2[idx], [i], [cf], color=colors[i], alpha=0.8, legend=false, width=0.8)
    end

    errors = tech_df.summer_mean_cf .- tech_df.summer_p5_cf
    scatter!(p2[idx], 1:nrow(tech_df), tech_df.summer_mean_cf, yerror=(errors, zeros(length(errors))), color=:black, markersize=3, label="")

    loc = tech == "solar" ? SOLAR_LOC : WIND_LOC
    plot!(p2[idx], title="$(uppercase(tech)) $(loc)\n— Summer CF by Historical Year", titlefont=font(12),
          xlabel="Historical Year", ylabel="Summer Daily Mean CF", xticks=(1:nrow(tech_df), years_labels),
          xrotation=45, xtickfont=font(8), ylim=(0, 0.5), grid=true, gridalpha=0.3)
end

savefig(p2, figure_path(SCRIPT_STEM, "08_vre_by_historical_year.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "08_vre_by_historical_year.png"), "08_vre_by_historical_year.png")
````

```@raw html
</details>
```

![Summer mean capacity factor by historical year for solar and wind, with downward error bars to the summer 5th percentile](08_vre_by_historical_year.png)

## Step 8 — near-term vs far-term daily capacity factor

Overlays each group's raw daily capacity factor with its own 30-day rolling average, for solar and wind separately.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
p3 = plot(layout=(2,1), size=(1200, 800), left_margin=8Plots.mm, bottom_margin=8Plots.mm)

for (idx, (tech, loc, hh_cols, color)) in enumerate([("solar", SOLAR_LOC, HH_COLS_SOL, :orange), ("wind", WIND_LOC, HH_COLS_WIND, :steelblue)])
    near_cf = load_year_cf(NEAR_YEARS, tech, loc, hh_cols)
    far_cf = load_year_cf(FAR_YEARS, tech, loc, hh_cols)

    ax_idx = idx

    if near_cf !== nothing
        plot!(p3[ax_idx], near_cf, color=color, linewidth=0.5, alpha=0.5, label="Near-term 2025-2029")
        near_rolling = [i < 30 ? NaN : mean(near_cf[max(1,i-29):i]) for i in 1:length(near_cf)]
        plot!(p3[ax_idx], near_rolling, color=color, linewidth=2, label="Near-term 30d avg")
    end

    if far_cf !== nothing
        plot!(p3[ax_idx], far_cf, color=:grey, linewidth=0.5, alpha=0.5, label="Far-term 2045-2049")
        far_rolling = [i < 30 ? NaN : mean(far_cf[max(1,i-29):i]) for i in 1:length(far_cf)]
        plot!(p3[ax_idx], far_rolling, color=:black, linewidth=2, linestyle=:dash, label="Far-term 30d avg")
    end

    plot!(p3[ax_idx], title="$(uppercase(tech)) $(loc) — Near-term vs Far-term Daily CF",
          xlabel="Day of Year", ylabel="Daily Mean CF", ylim=(0, 0.6), legend=:topright, grid=true, gridalpha=0.3)
end

savefig(p3, figure_path(SCRIPT_STEM, "08_near_vs_far_term.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "08_near_vs_far_term.png"), "08_near_vs_far_term.png")
````

```@raw html
</details>
```

![Near-term versus far-term daily capacity factor for solar and wind, raw series and 30-day rolling averages](08_near_vs_far_term.png)

## Step 9 — year-by-year renewable heatmap

Reads back the year-by-year matrix written in Step 4 and renders it as a heatmap with per-cell annotations, deriving the colour range from the actual data rather than a fixed guess.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
heatmap_df = CSV.read(table_path(SCRIPT_STEM, "vre_heatmap"), DataFrame)

years_unique = sort(unique(heatmap_df.ref_year))
solar_data = filter(row -> row.tech == "solar", heatmap_df)
wind_data = filter(row -> row.tech == "wind", heatmap_df)

sort!(solar_data, :ref_year)
sort!(wind_data, :ref_year)

solar_vals = solar_data.annual_mean_cf
wind_vals = wind_data.annual_mean_cf

heatmap_matrix = [solar_vals'; wind_vals']

clim_vals = skipmissing(heatmap_matrix)
clim_min = minimum(clim_vals)
clim_max = maximum(clim_vals)
clim = (clim_min, clim_max)

p4 = heatmap(years_unique, ["Solar", "Wind"], heatmap_matrix, c=:YlOrRd,
            title="Annual Mean CF by Historical Year and Technology",
            xlabel="Historical Year", ylabel="", size=(1200, 400), clim=clim,
            colorbar_title="Annual Mean CF", xticks=(years_unique, string.(years_unique)), xrotation=45)

for (i, tech) in enumerate(["Solar", "Wind"])
    for (j, yr) in enumerate(years_unique)
        val = heatmap_matrix[i, j]
        if !ismissing(val) && !isnan(val)
            text_color = val > 0.25 ? :black : :white
            annotate!(p4, years_unique[j], i, text(@sprintf("%.3f", val), 7, text_color), legend=false)
        end
    end
end

savefig(p4, figure_path(SCRIPT_STEM, "08_vre_heatmap.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "08_vre_heatmap.png"), "08_vre_heatmap.png")
````

```@raw html
</details>
```

![Annual mean capacity factor by historical year and technology, coloured and annotated per cell](08_vre_heatmap.png)

## Summary

- Reference trace 4006 reuses a fixed set of historical solar and wind years across the planning horizon; several historical years are reused more than once, so later financial years are not new weather draws.

