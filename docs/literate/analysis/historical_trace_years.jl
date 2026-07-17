# # Comparing historical solar and wind reference years
#
# A single reference year can conceal substantial interannual variation in renewable availability. This page loads the full historical solar and wind trace archive directly, computes annual and seasonal capacity factors, low-output-day frequencies, and the most adverse summer solar day across the available historical years, and builds the comparison figures.
#
# The comparison is location-specific: solar uses `Bannerton_SAT` and wind uses `DUNDWF1`. Results should not be generalised to all Victorian renewable resources without additional spatial analysis.

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Statistics
using Plots
using StatsPlots

gr();

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

EdaSupport.snapshot_metadata_line(REPO_ROOT; context = "2024 ISP raw trace downloads, historical years 2011-2023")

const SCRIPT_STEM = "03_year_comparison"
const TRACES = joinpath("data", "2024", "pisp-downloads", "Traces")  # kept relative: this is the path form recorded in the output tables
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
nothing #hide

# ## Step 1 — load solar and wind traces across all historical reference years
#
# `Bannerton_SAT` (solar) and `DUNDWF1` (wind) are loaded for every historical reference year in `YEARS` that has a local trace file available.

sol_years = load_location_all_years("solar", SOLAR_LOC, YEARS)
wind_years = load_location_all_years("wind", WIND_LOC, YEARS)

println("Loaded solar $(SOLAR_LOC): $(length(sol_years)) years")
println("Loaded wind $(WIND_LOC): $(length(wind_years)) years")

# ## Step 2 — seasonal capacity factor by year
#
# For each loaded year, the summer (Dec/Jan/Feb) and winter (Jun/Jul/Aug) daily mean capacity factors are summarised separately, since variation between seasons and variation between years within the same season are different effects.

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

# ## Step 3 — annual capacity factor by year
#
# Averaging across the whole year (rather than by season) establishes the scale of year-to-year variation before seasonal or extreme-event metrics are considered.

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

# ## Step 4 — worst summer solar day per year
#
# For each year, this finds the summer day with the lowest midday (hour 12-18) maximum capacity factor — an event-screening metric rather than a complete adequacy or energy-shortfall measure. Ties resolve to the first occurrence.

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

# ## Step 5 — low-output day frequency
#
# Solar and wind use different low-output metrics: solar counts summer days whose midday maximum falls below the threshold, while wind uses the summer daily mean capacity factor. Their percentages are therefore not directly interchangeable without retaining the metric definition.

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

# ## Step 6 — annual CF variability summary
#
# This summarises the spread of annual mean capacity factor across all loaded years for each technology, using the population standard deviation (dividing by n, not n-1) — a different convention from the sample standard deviation used for `std_cf` in the seasonal summary above (Step 2), which divides by n-1.

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

# ## Step 7 — figure: year-over-year boxplot of summer and winter daily mean CF
#
# Each panel shows the distribution of daily mean capacity factor across all days in one season for one technology, one box per historical reference year.

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
nothing #hide

# ![Summer and winter daily mean capacity factor distributions for solar and wind, one boxplot per historical reference year](03_year_comparison_boxplot.png)

# ## Step 8 — figure: annual mean CF trend across years
#
# This plots one point per historical reference year for each technology, showing the overall trend in annual mean capacity factor across the sampled years.

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
nothing #hide

# ![Annual mean capacity factor trend across historical reference years for solar and wind](03_annual_cf_trend.png)

# ## Step 9 — figure: worst summer solar day per year
#
# This bar chart visualises the same worst-summer-day metric computed in Step 4, one bar per year, annotated with its midday max capacity factor.

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
nothing #hide

# ![Worst (lowest midday-max capacity factor) summer solar day identified in each historical reference year](03_worst_summer_day.png)

# ## Step 10 — figure: near-zero-output day frequency
#
# This two-panel bar chart visualises the same low-output-day metric computed in Step 5 as a percentage of summer days per year, annotated with the underlying day count, one panel per technology.

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
nothing #hide

# ![Percentage of summer days each year with near-zero solar midday-max or wind daily-mean capacity factor, annotated with the underlying day count](03_zero_output_days.png)

# ## Summary
#
# - Solar (`Bannerton_SAT`) and wind (`DUNDWF1`) show materially different year-to-year and season-to-season capacity factor variability across the 2011-2023 historical reference years.
# - The worst-summer-day and near-zero-output-day tables and figures identify specific adverse years rather than a single averaged risk figure, and the two technologies use different low-output metrics that are not directly interchangeable.
