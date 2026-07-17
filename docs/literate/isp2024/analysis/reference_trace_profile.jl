# # ISP 2024: Reference trace 4006 profiles
#
# Reference trace `4006` combines location-specific solar and wind profiles with a planning-horizon weather-year mapping. This page loads the raw solar and wind traces (2024 ISP raw trace downloads) for one representative location per state, computes daily and seasonal capacity-factor structure, and builds each figure directly on the page.
#
# Reference trace `4006` is not a climate projection. Its planning-year behaviour depends on the historical-year composition documented in [ISP 2024: Parameters and mappings](@ref).

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
nothing #hide

# ## Step 1 — load the solar and wind reference traces for trace year 4006
#
# One representative solar and one representative wind location per state are loaded for trace year `4006`.

sol_4006 = load_traces("solar", 4006, last.(SOLAR_LOCATIONS))
wind_4006 = load_traces("wind", 4006, last.(WIND_LOCATIONS))

println("Loaded $(length(sol_4006)) solar locations, $(length(wind_4006)) wind locations for trace 4006")

# ## Step 2 — which representative locations loaded successfully
#
# The loaded-location inventory records, for every representative solar and wind site, whether its trace file was found and its shape if so.

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

# ## Step 3 — daily capacity-factor summary
#
# For each loaded location, the daily summary reports descriptive statistics of the daily mean capacity factor, including the mean of a 7-day rolling average.

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

# ## Step 4 — solar diurnal profile at the Victorian representative location
#
# The half-hourly diurnal profile at `Bannerton_SAT` is split into summer (Dec-Feb) and winter (Jun-Aug) days, reporting the mean, 10th and 90th percentile capacity factor at each half hour.

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

# ## Step 5 — wind monthly diurnal profile at the Victorian representative location
#
# The half-hourly diurnal profile at `DUNDWF1` is reported separately for each calendar month present in the trace — 12 months of 48 half-hourly points each, visualised together in Step 11's figure. The full table is written to the evidence CSV; the page displays only the first complete month as a representative sample.

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

# ## Step 6 — wind monthly mean capacity factor
#
# The daily capacity factor at `DUNDWF1` is grouped by calendar month start to give a compact monthly mean series spanning the full trace. The full series is written to the evidence CSV and plotted in Step 11's figure; the page displays only the first two years as a representative sample.

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

# ## Step 7 — annual capacity factor by financial year
#
# Daily capacity factor for the Victorian solar and wind representative locations is grouped into Australian financial years (ending June) for a compact annual comparison.

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

# ## Step 8 — figure: solar daily capacity factor by state
#
# One panel per state shows the daily mean capacity factor for the representative solar location, with a 7-day rolling average overlaid.

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
nothing #hide

# ![Daily mean capacity factor for the representative solar location in each state, with a 7-day rolling average](02_solar_4006_daily_cf.png)

# ## Step 9 — figure: wind daily capacity factor by state
#
# The same daily-mean-plus-rolling-average layout as Step 8, for the representative wind location in each state.

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
nothing #hide

# ![Daily mean capacity factor for the representative wind location in each state, with a 7-day rolling average](02_wind_4006_daily_cf.png)

# ## Step 10 — figure: solar diurnal profile, summer vs winter
#
# Individual daily half-hourly profiles (up to 200 per season), the mean profile, and the P10-P90 band, for `Bannerton_SAT` summer and winter days.

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
nothing #hide

# ![Solar diurnal profile at Bannerton_SAT: individual days, mean, and P10-P90 band, summer vs winter](02_solar_4006_diurnal.png)

# ## Step 11 — figure: wind seasonal analysis
#
# The top panel shows the mean diurnal profile by calendar month at `DUNDWF1`; the bottom panel shows the daily capacity factor overlaid with the monthly mean.

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
nothing #hide

# ![Wind seasonal analysis at DUNDWF1: mean diurnal profile by month, and daily capacity factor with monthly mean overlaid](02_wind_4006_seasonal.png)

# ## Step 12 — figure: annual capacity factor by financial year
#
# The Victorian solar and wind representative locations' annual mean capacity factor, grouped by financial year, on one comparison chart.

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
nothing #hide

# ![Annual mean capacity factor by financial year, solar and wind trace 4006](02_4006_annual_cf.png)

println("\nDone.")

# ## Summary
#
# - Solar and wind capacity-factor structure for reference trace 4006 is loaded, transformed, and plotted directly on this page.
# - Five figures cover daily capacity factor by state, diurnal structure at the Victorian representative locations, wind seasonal structure, and the annual financial-year comparison.
