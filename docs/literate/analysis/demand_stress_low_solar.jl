# # Demand stress and low-solar coincidence
#
# High demand can coincide with low renewable availability, but that relationship depends on aligned dates, explicit thresholds, and the event definition. This page loads the Victorian demand schedule and the Bannerton 4006 solar trace directly, then builds the demand distributions, demand-defined stress days, hourly demand profiles, and solar-availability-on-stress-days summaries live.
#
# Here, `heat event` is an operational label for days at or above the 95th percentile of demand. It does not use air temperature, an excess-heat factor, or a meteorological heatwave definition.

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

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

EdaSupport.snapshot_metadata_line(REPO_ROOT; context = "VIC demand schedule from the schedule-2030 generated PISP output; Bannerton 4006 solar reference trace from the 2024 ISP raw trace downloads")

const SCRIPT_STEM = "07_demand_heat_events"
const TRACES = joinpath("data", "2024", "pisp-downloads", "Traces")  # kept relative: this is the path form recorded in the tables below
const OUT = joinpath("data", "2024", "pisp-datasets", "out-ref4006-poe10", "csv")  # kept relative, same reason

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
nothing #hide

# ## Step 1 — demand trace inventory
#
# The demand trace family stores one POE10 operational-schedule file per network node under a state/scenario directory; this step lists every such file as the input inventory.

dem_dir = joinpath(TRACES, "demand_VIC_Step Change")
dem_files = sort(filter(name -> endswith(name, "_POE10_OPSO_MODELLING.csv"), readdir(abs_path(dem_dir))))
println("Found $(length(dem_files)) demand trace files")

demand_trace_inventory = DataFrame(file = dem_files)
write_table(demand_trace_inventory, SCRIPT_STEM, "demand_trace_inventory")
markdown_table(demand_trace_inventory)

# ## Step 2 — load the demand schedule and aggregate daily demand by area
#
# The PISP model output records each network node's half-hourly demand schedule and its bus, and each bus's NEM area; joining these mappings lets the schedule be aggregated to a daily mean demand per area. The full daily-by-area table (one row per area per calendar date) is written to `demand_by_area_daily.csv`; the page displays one summary row per area instead of every row.

dem_load = CSV.read(abs_path(joinpath(OUT, "schedule-2030", "Demand_load_sched.csv")), DataFrame)
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

# ## Step 3 — load the solar 4006 reference traces for candidate VIC solar sites
#
# `Bannerton_SAT` is the representative VIC solar site used throughout this analysis; `Darlington_Point_SAT` is also checked as a candidate even though only Bannerton is used downstream.

locations = ["Bannerton_SAT", "Darlington_Point_SAT"]
sol_4006 = Dict{String, DataFrame}()
for loc in locations
    df = load_solar_4006(loc)
    df === nothing || (sol_4006[loc] = df)
end
println("Loaded $(length(sol_4006)) solar locations for 4006")

# ## Step 4 — aggregate Victorian daily demand from the raw schedule
#
# Area `3` is the Victorian NEM region in this bus-to-area mapping; the half-hourly schedule for that area is averaged to one daily mean demand value per calendar date.

vic_dem = dem_load[dem_load.area .== 3, :]
vic_daily = combine(groupby(vic_dem, :date_only), :value => mean => :demand)
sort!(vic_daily, :date_only)
nothing #hide

# ## Step 5 — merge VIC demand with the Bannerton solar capacity factor by date
#
# Only calendar dates present in both the VIC demand schedule and the Bannerton 4006 solar trace are kept, so the merged sample can be smaller than either input series. The full merged series is written to `vic_demand_solar_merged.csv`; the page displays a single summary row describing its coverage and range instead of every day.

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
markdown_table(merged_summary)

# ## Step 6 — high-demand and low-solar threshold screen
#
# The screen flags days above the 90th demand percentile that also fall below the 10th solar-capacity-factor percentile, within the merged sample above.

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
    markdown_table(high_demand_low_solar_summary)
end

# ## Step 7 — heat-event and normal-day demand thresholds
#
# `Heat event` days sit at or above the 95th demand percentile; `normal` days sit below the 90th percentile. Days between P90 and P95 are excluded from both groups.

demand_p90 = quantile(vic_daily.demand, 0.9)
demand_p95 = quantile(vic_daily.demand, 0.95)

heat_days = vic_daily[vic_daily.demand .>= demand_p95, :date_only]
normal_days = Set(vic_daily[vic_daily.demand .< demand_p90, :date_only])
heat_days_set = Set(heat_days)

@printf("\nDemand thresholds: P90=%.0f MW, P95=%.0f MW\n", demand_p90, demand_p95)
println("Heat event days (>P95): ", length(heat_days))
println("Normal days (<P90): ", length(normal_days))

# ## Step 8 — hourly demand profile for heat days vs normal days
#
# Half-hourly demand observations on heat-event days and on normal days are each averaged by hour of day, to compare the shape of the demand profile between the two groups.

heat_df = vic_dem[in.(vic_dem.date_only, Ref(heat_days_set)), :]
normal_df = vic_dem[in.(vic_dem.date_only, Ref(normal_days)), :]
heat_df = transform(heat_df, :date => ByRow(hour) => :hour)
normal_df = transform(normal_df, :date => ByRow(hour) => :hour)

heat_hourly = Dict(row.hour => row.value_mean for row in eachrow(combine(groupby(heat_df, :hour), :value => mean => :value_mean)))
normal_hourly = Dict(row.hour => row.value_mean for row in eachrow(combine(groupby(normal_df, :hour), :value => mean => :value_mean)))

heat_normal_hourly_profile = DataFrame(
    hour = 0:23,
    heat_mean_demand_mw = [get(heat_hourly, h, missing) for h in 0:23],
    normal_mean_demand_mw = [get(normal_hourly, h, missing) for h in 0:23],
)
write_table(heat_normal_hourly_profile, SCRIPT_STEM, "heat_normal_hourly_profile")
markdown_table(heat_normal_hourly_profile)

# ## Step 9 — demand duration curve
#
# Sorting daily VIC demand from highest to lowest gives the demand duration curve, independent of chronology. The full 365-day curve is written to `demand_duration_curve.csv` and shown as a figure in Step 16; the page displays the curve's value at a handful of quantile marks instead.

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

# ## Step 10 — normalized VRE vs demand summary, sorted by demand
#
# Demand and Bannerton solar capacity factor from the merged sample are each normalized by their own maximum and ranked by ascending demand, so their relative shapes can be compared on the same 0-to-1 scale. The full 365-day normalized series is written to `normalized_vre_demand_summary.csv` and shown as a figure in Step 16; the page instead reports how closely the two normalized series track each other.

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

# ## Step 11 — key summary statistics
#
# A short console summary reports the total day count, the heat-event share, the peak demand day, and the mean demand across the full period.

total_days = nrow(vic_daily)
peak_row = vic_daily[argmax(vic_daily.demand), :]
println("\n=== DEMAND HEAT EVENT ANALYSIS ===")
println("Total days: ", total_days)
@printf("Heat event days (>P95): %d (%.1f%%)\n", length(heat_days), 100 * length(heat_days) / total_days)
@printf("Peak demand: %.0f MW on %s\n", peak_row.demand, peak_row.date_only)
@printf("Mean demand: %.0f MW\n", mean(vic_daily.demand))

# ## Step 12 — solar CF on the hottest demand days
#
# For the top 10 heat-event days (by demand), this looks up the matching Bannerton solar capacity factor, where a matching date exists in the trace.

if haskey(sol_4006, "Bannerton_SAT")
    cf_of_date = solar_cf_by_date(sol_4006["Bannerton_SAT"])
    top10_days = heat_days[1:min(10, length(heat_days))]
    hot_day_cfs = Float64[]
    for hd in top10_days
        haskey(cf_of_date, hd) || continue
        push!(hot_day_cfs, cf_of_date[hd])
    end
    mean_cf = mean(hot_day_cfs)
    @printf("\nSolar CF on top 10 heat event days: mean=%.4f\n", mean_cf)
    println("  Individual CFs: ", [@sprintf("%.4f", c) for c in hot_day_cfs])

    hot_day_solar_cf_detail = DataFrame(
        rank = 1:length(hot_day_cfs),
        date = top10_days[1:length(hot_day_cfs)],
        solar_cf = hot_day_cfs,
        mean_solar_cf_top10 = fill(mean_cf, length(hot_day_cfs)),
    )
    write_table(hot_day_solar_cf_detail, SCRIPT_STEM, "hot_day_solar_cf_detail")
    markdown_table(hot_day_solar_cf_detail)
end

# ## Step 13 — demand heat event summary
#
# This collects the thresholds, counts, and peak/mean statistics computed above into a single summary row.

demand_heat_event_summary = DataFrame(
    total_days = total_days,
    demand_p90_mw = demand_p90,
    demand_p95_mw = demand_p95,
    heat_day_count = length(heat_days),
    normal_day_count = length(normal_days),
    heat_event_pct = 100 * length(heat_days) / total_days,
    peak_demand_mw = peak_row.demand,
    peak_date = peak_row.date_only,
    mean_demand_mw = mean(vic_daily.demand),
)
write_table(demand_heat_event_summary, SCRIPT_STEM, "demand_heat_event_summary")
markdown_table(demand_heat_event_summary)

# ## Step 14 — figure: VIC demand and solar CF time series
#
# The top panel shows the Bannerton solar capacity factor over the full period with a 7-day rolling average; the bottom panel shows VIC daily mean demand with its own 7-day rolling average.

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
nothing #hide

# ![VIC daily solar capacity factor and daily mean demand over the full period, each with a 7-day rolling average](07_vic_demand_solar_4006.png)

# ## Step 15 — figure: demand vs solar CF scatter
#
# Each point is one calendar day's demand against its Bannerton solar capacity factor; the high-demand, low-solar days identified in Step 6 are highlighted in red.

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
nothing #hide

# ![VIC daily demand plotted against Bannerton solar capacity factor, with high-demand/low-solar days highlighted](07_demand_vs_solar_scatter.png)

# ## Step 16 — figure: demand heat events overview
#
# A 2x2 panel combines the hourly heat-vs-normal profile, the demand duration curve with P90/P95 reference lines, a month-by-hour demand heatmap, and the normalized demand/solar comparison from Step 10.

month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
p3 = plot(layout=(2,2), size=(1200, 1000), left_margin=6Plots.mm, right_margin=3Plots.mm, top_margin=5Plots.mm, bottom_margin=5Plots.mm)

hours = 0:23
heat_vals = [get(heat_hourly, h, NaN) for h in hours]
normal_vals = [get(normal_hourly, h, NaN) for h in hours]

plot!(p3[1], hours, heat_vals, color=:red, linewidth=2, marker=:o, markersize=3,
      label="Heat days (>$(round(Int, demand_p95)) MW, n=$(length(heat_days)))")
plot!(p3[1], hours, normal_vals, color=:blue, linewidth=2, marker=:s, markersize=3,
      label="Normal days (<$(round(Int, demand_p90)) MW, n=$(length(normal_days)))")
plot!(p3[1], title="VIC Demand: Heat Event Days vs Normal Days", xlabel="Hour", ylabel="Demand (MW)",
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

heatmap!(p3[3], 0:23, 1:12, heatmap_data, c=:YlOrRd, title="VIC Demand Heatmap: Month vs Hour",
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
nothing #hide

# ![Hourly heat-vs-normal demand profile, demand duration curve, month-by-hour demand heatmap, and normalized demand/solar comparison](07_demand_heat_events.png)

println("\nDone.")

# ## Summary
#
# - VIC daily demand and the Bannerton 4006 solar capacity factor are merged by date, then used to define demand-defined heat-event days (>=P95) and normal days (<P90) and to screen for high-demand, low-solar coincidence days.
# - Three figures are built live on this page: the demand/solar time series, the demand-vs-solar scatter, and the combined heat-event overview panel.
