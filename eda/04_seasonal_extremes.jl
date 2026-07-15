#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using Printf
using Statistics
using Plots

const SCRIPT_STEM = "04_seasonal_extremes"
const TRACES = joinpath("data", "2024", "pisp-downloads", "Traces")
const TABLE_ROOT = joinpath(@__DIR__, "tables")
const FIGURE_ROOT = joinpath(@__DIR__, "figures")

function table_dir(script_stem; producer = "julia", root = TABLE_ROOT)
    path = joinpath(root, producer, script_stem)
    mkpath(path)
    return path
end

function table_path(script_stem, table_name; producer = "julia", root = TABLE_ROOT)
    filename = endswith(table_name, ".csv") ? table_name : "$(table_name).csv"
    return joinpath(table_dir(script_stem; producer = producer, root = root), filename)
end

function write_table(frame::DataFrame, script_stem, table_name; producer = "julia", root = TABLE_ROOT)
    path = table_path(script_stem, table_name; producer = producer, root = root)
    CSV.write(path, frame; missingstring = "")
    println("Saved table: ", path)
    return path
end

function figure_dir(script_stem; producer = "julia", root = FIGURE_ROOT)
    path = joinpath(root, producer, script_stem)
    mkpath(path)
    return path
end

function figure_path(script_stem, figure_name; producer = "julia", root = FIGURE_ROOT)
    filename = endswith(figure_name, ".png") ? figure_name : "$(figure_name).png"
    return joinpath(figure_dir(script_stem; producer = producer, root = root), filename)
end

const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]

# Known hot vs cool (La Nina) Australian historical summers.
const HOT_SUMMERS = [2019, 2013, 2017, 2015, 2023]
const COOL_SUMMERS = [2011, 2016, 2020, 2022]

const SOLAR_LOC = "Bannerton_SAT"
const WIND_LOC = "DUNDWF1"

function add_datetime!(df::DataFrame)
    df.datetime = Date.(df.Year, df.Month, df.Day)
    return df
end

function load_trace(tech, yr, loc)
    file = joinpath(TRACES, "$(tech)_$(yr)", "$(loc)_RefYear$(yr).csv")
    isfile(file) || return nothing
    df = CSV.read(file, DataFrame)
    add_datetime!(df)
    return df
end

row_mean(df::DataFrame, cols) = [mean(row[col] for col in cols) for row in eachrow(df)]

# Rolling mean matching pandas' `Series.rolling(window).mean()` default
# `min_periods == window`: the first `window - 1` entries are missing.
function rolling_mean(values, window)
    n = length(values)
    result = Vector{Union{Missing, Float64}}(missing, n)
    for i in window:n
        result[i] = mean(values[(i - window + 1):i])
    end
    return result
end

# ====== Table 1: Hot vs cool summer solar profile summary ======
function write_hot_cool_summary_table()
    rows = NamedTuple[]
    for (season_type, year_list) in (("Hot Summers", HOT_SUMMERS), ("Cool Summers", COOL_SUMMERS))
        for yr in year_list
            df = load_trace("solar", yr, SOLAR_LOC)
            df === nothing && continue
            summer_mask = in.(df.Month, Ref((12, 1, 2)))
            any(summer_mask) || continue
            vals = row_mean(df[summer_mask, :], HH_COLS_SOL)
            push!(
                rows,
                (
                    season_type = season_type,
                    year = yr,
                    n_days = length(vals),
                    mean_daily_cf = mean(vals),
                    std_daily_cf = std(vals),
                    min_daily_cf = minimum(vals),
                    max_daily_cf = maximum(vals),
                ),
            )
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "hot_cool_summer_solar_summary")
end

# ====== Table 2: Multi-day (3+) low-output events across all years ======
#
# Mirrors pandas' `below.diff()` + `starts = diff[diff==1].index` /
# `ends = diff[diff==-1].index` + `zip(starts, ends)` exactly, including its
# quirks:
#   - `.diff()` is positional (state transitions in filtered-row order), but
#     `starts`/`ends` capture the ORIGINAL (unfiltered) row position labels,
#     which are not contiguous once rows are filtered to Dec/Jan/Feb only.
#   - `duration = (e - s) + 1` is then computed from those labels directly,
#     not from an actual count of matched rows, so an event whose state runs
#     from the tail of a Dec/Jan/Feb block into the next one (across the
#     excluded Mar-Nov gap) gets a hugely inflated (but faithfully
#     reproduced) duration.
#   - `zip(starts, ends)` pairs the two lists purely by position; if their
#     lengths differ (e.g. a run already active at the first row leaves an
#     unmatched trailing "end"), every subsequent pair is shifted and the
#     resulting durations can even go negative. This is replicated verbatim.
#   - `daily.loc[s:e]` is a label-based range select: all filtered rows whose
#     original position falls within [s, e], which is what `mask_range` below
#     reproduces.
function low_output_events_for(tech, loc, hh_cols, threshold, yr)
    df = load_trace(tech, yr, loc)
    df === nothing && return NamedTuple[]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    any(summer_mask) || return NamedTuple[]

    full_idx = findall(summer_mask)  # original row positions, in file order
    dates = df.datetime[full_idx]
    daily = row_mean(df[full_idx, :], hh_cols)
    below = daily .< threshold
    n = length(below)

    starts = Int[]
    ends = Int[]
    for i in 2:n
        delta = Int(below[i]) - Int(below[i - 1])
        if delta == 1
            push!(starts, full_idx[i])
        elseif delta == -1
            push!(ends, full_idx[i])
        end
    end

    rows = NamedTuple[]
    for k in 1:min(length(starts), length(ends))
        s = starts[k]
        e = ends[k]
        duration = (e - s) + 1
        duration >= 3 || continue
        mask_range = (full_idx .>= s) .& (full_idx .<= e)
        vals = daily[mask_range]
        s_pos = findfirst(==(s), full_idx)
        e_pos = findfirst(==(e), full_idx)
        push!(
            rows,
            NamedTuple{(:year, :start, :end, :duration, :min_cf, :mean_cf, :tech)}(
                (
                    yr,
                    Dates.format(dates[s_pos], "yyyy-mm-dd"),
                    Dates.format(dates[e_pos], "yyyy-mm-dd"),
                    duration,
                    minimum(vals),
                    mean(vals),
                    tech,
                ),
            ),
        )
    end
    return rows
end

function write_low_output_events_table()
    rows = NamedTuple[]
    for (tech, loc, hh_cols, threshold) in (
        ("solar", SOLAR_LOC, HH_COLS_SOL, 0.1),
        ("wind", WIND_LOC, HH_COLS_WIND, 0.15),
    )
        for yr in 2011:2023
            append!(rows, low_output_events_for(tech, loc, hh_cols, threshold, yr))
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "low_output_events")
end

# ====== Table 3: Worst summer day by year (all years, solar) ======
function write_worst_solar_day_table()
    rows = NamedTuple[]
    for yr in 2011:2023
        df = load_trace("solar", yr, SOLAR_LOC)
        df === nothing && continue
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        daily = row_mean(summer, HH_COLS_SOL)
        worst_pos = argmin(daily)  # first occurrence on ties, matching pandas idxmin
        push!(
            rows,
            (
                year = yr,
                date = Dates.format(summer.datetime[worst_pos], "yyyy-mm-dd"),
                cf = daily[worst_pos],
                is_hot_summer = yr in HOT_SUMMERS ? 1 : 0,
            ),
        )
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "worst_solar_day_summary")
    return rows
end

# ====== Table 4: Half-hourly profile of the single worst solar day (all years) ======
function write_worst_solar_day_profile_table(worst_rows)
    rows = NamedTuple[]
    if !isempty(worst_rows)
        best_idx = argmin([r.cf for r in worst_rows])
        worst = worst_rows[best_idx]
        yr = worst.year
        worst_date = Date(worst.date, "yyyy-mm-dd")
        df = load_trace("solar", yr, SOLAR_LOC)
        if df !== nothing
            mask = df.datetime .== worst_date
            if any(mask)
                row_idx = findfirst(mask)
                half_hours = collect(0.5:0.5:24.0)
                for (hh, col) in zip(half_hours, HH_COLS_SOL)
                    push!(rows, (year = yr, date = worst.date, half_hour = hh, cf = df[row_idx, col]))
                end
            end
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "worst_solar_day_profile")
end

# ====== Table 5: Monthly CF summary for 2019 ======
#
# Replicates the (corrected) two-stage aggregation: per half-hourly column,
# compute that column's mean/std across the days in the month, then average
# those 48 per-column values into one monthly figure. Matches the fixed
# Python `monthly_stats.loc[m].xs('mean'|'std', level=1).mean()` expression
# (the original `.loc[m, ('mean',)]` / `('mean', std)` lookups raised
# KeyError/NameError and were fixed as part of this port).
function write_monthly_cf_2019_table()
    df = load_trace("solar", 2019, SOLAR_LOC)
    rows = NamedTuple[]
    if df !== nothing
        for m in 1:12
            mask = df.Month .== m
            if any(mask)
                sub = df[mask, :]
                col_means = [mean(sub[!, col]) for col in HH_COLS_SOL]
                col_stds = [std(sub[!, col]) for col in HH_COLS_SOL]
                push!(rows, (month = m, mean_cf = mean(col_means), std_cf = mean(col_stds)))
            else
                push!(rows, (month = m, mean_cf = 0.0, std_cf = 0.0))
            end
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "monthly_cf_2019_summary")
end

# ====== Table 6: Black Summer 2019 detailed daily trace ======
function write_black_summer_table()
    df = load_trace("solar", 2019, SOLAR_LOC)
    rows = NamedTuple[]
    if df !== nothing
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        summer = df[summer_mask, :]
        daily = row_mean(summer, HH_COLS_SOL)
        rolling3 = rolling_mean(daily, 3)
        for (i, d) in enumerate(summer.datetime)
            push!(rows, (date = Dates.format(d, "yyyy-mm-dd"), daily_mean_cf = daily[i], rolling3_cf = rolling3[i]))
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "black_summer_2019_daily_cf")
end

function main()
    gr()  # Select GR backend for static PNG output

    write_hot_cool_summary_table()
    write_low_output_events_table()
    worst_rows = write_worst_solar_day_table()
    write_worst_solar_day_profile_table(worst_rows)
    write_monthly_cf_2019_table()
    write_black_summer_table()

    # ====== Figure 1: Hot vs Cool summer solar profiles ======
    plots_hot_cool = []
    for (season_type, year_list, color) in [("Hot Summers", HOT_SUMMERS, :darkred), ("Cool Summers", COOL_SUMMERS, :steelblue)]
        p = plot(legend=false, size=(1400, 400))
        for yr in year_list
            df = load_trace("solar", yr, SOLAR_LOC)
            df === nothing && continue
            summer_mask = in.(df.Month, Ref((12, 1, 2)))
            any(summer_mask) || continue
            summer = df[summer_mask, :]
            daily = [mean(skipmissing(Vector(summer[i, HH_COLS_SOL]))) for i in 1:nrow(summer)]
            rolling3 = rolling_mean(daily, 3)
            plot!(p, summer.datetime, daily, linewidth=0.5, alpha=0.6, color=color, label="$yr")
            plot!(p, summer.datetime, rolling3, linewidth=1.5, color=:black, alpha=0.8, label="")
        end
        plot!(p, title="Solar $(SOLAR_LOC) — $(season_type) Daily Mean CF", ylabel="Daily Mean CF",
              ylim=(0, 0.5), grid=true, gridalpha=0.3)
        push!(plots_hot_cool, p)
    end
    p_hc = plot(plots_hot_cool..., layout=(2,1), size=(1400, 800),
                left_margin=5Plots.mm, bottom_margin=5Plots.mm)
    savefig(p_hc, figure_path(SCRIPT_STEM, "04_hot_vs_cool_summer_solar.png"))
    println("Saved: 04_hot_vs_cool_summer_solar.png")

    # ====== Figure 2: Low output events (2x2 grid) ======
    # Histogram of solar low events
    solar_low_events = []
    wind_low_events = []
    worst_solar_days_data = Dict()
    worst_day_profile_data = Dict()

    for yr in 2011:2023
        df = load_trace("solar", yr, SOLAR_LOC)
        df === nothing && continue
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        daily = [mean(skipmissing(Vector(summer[i, HH_COLS_SOL]))) for i in 1:nrow(summer)]

        # Find consecutive low output events (< 0.1 for 3+ days)
        rows = low_output_events_for("solar", SOLAR_LOC, HH_COLS_SOL, 0.1, yr)
        for row in rows
            push!(solar_low_events, row.duration)
        end

        # Find worst day for this year
        worst_pos = argmin(daily)
        worst_solar_days_data[yr] = (date = summer.datetime[worst_pos], cf = daily[worst_pos])
    end

    for yr in 2011:2023
        df = load_trace("wind", yr, WIND_LOC)
        df === nothing && continue
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        daily = [mean(skipmissing(Vector(summer[i, HH_COLS_WIND]))) for i in 1:nrow(summer)]

        # Find consecutive low output events (< 0.15 for 3+ days)
        rows = low_output_events_for("wind", WIND_LOC, HH_COLS_WIND, 0.15, yr)
        for row in rows
            push!(wind_low_events, row.duration)
        end
    end

    # Plots for the 2x2 grid
    p_sol_hist = histogram(solar_low_events, bins=1:maximum(solar_low_events)+1, color=:darkorange, alpha=0.7,
                           legend=false, title="Solar $(SOLAR_LOC) — Duration of Low-Output Events (≥3 days)",
                           xlabel="Consecutive Days Below Threshold", ylabel="Count", grid=true, gridalpha=0.3)

    p_wind_hist = histogram(wind_low_events, bins=1:maximum(wind_low_events)+1, color=:steelblue, alpha=0.7,
                            legend=false, title="Wind $(WIND_LOC) — Duration of Low-Output Events (≥3 days)",
                            xlabel="Consecutive Days Below Threshold", ylabel="Count", grid=true, gridalpha=0.3)

    # Worst days bar chart - sort by CF value, not by year
    worst_yrs = collect(keys(worst_solar_days_data))
    sort!(worst_yrs, by = yr -> worst_solar_days_data[yr].cf)
    worst_cfs = [worst_solar_days_data[yr].cf for yr in worst_yrs]
    p_worst_days = bar(string.(worst_yrs), worst_cfs, color=:darkorange, alpha=0.7, legend=false,
                       title="Solar $(SOLAR_LOC) — Worst Summer Day by Year (sorted by CF)",
                       ylabel="Daily Mean CF", grid=true, gridalpha=0.3)

    # Worst day profile
    if !isempty(worst_rows)
        best_idx = argmin([r.cf for r in worst_rows])
        worst = worst_rows[best_idx]
        yr = worst.year
        worst_date = Date(worst.date, "yyyy-mm-dd")
        df = load_trace("solar", yr, SOLAR_LOC)
        if df !== nothing
            mask = df.datetime .== worst_date
            if any(mask)
                row_idx = findfirst(mask)
                half_hours = collect(0.5:0.5:24.0)
                hh_vals = Vector(df[row_idx, HH_COLS_SOL])
                p_worst_profile = plot(half_hours, hh_vals, linewidth=2, marker=:circle, markersize=3,
                                      color=:darkred, legend=false,
                                      title="Worst Solar Day: $(worst.date) (CF=$(round(worst.cf, digits=3)))",
                                      xlabel="Hour", ylabel="Capacity Factor", ylim=(0, 1),
                                      grid=true, gridalpha=0.3)
            else
                p_worst_profile = plot(legend=false)
            end
        else
            p_worst_profile = plot(legend=false)
        end
    else
        p_worst_profile = plot(legend=false)
    end

    p_low_out = plot(p_sol_hist, p_wind_hist, p_worst_days, p_worst_profile, layout=(2,2), size=(1400, 1000),
                     left_margin=5Plots.mm, bottom_margin=5Plots.mm)
    savefig(p_low_out, figure_path(SCRIPT_STEM, "04_low_output_events.png"))
    println("Saved: 04_low_output_events.png")

    # ====== Figure 3: Monthly CF 2019 ======
    # Read the monthly summary table already written by write_monthly_cf_2019_table()
    # This ensures the plot uses exactly the same aggregation as the table
    monthly_table_path = table_path(SCRIPT_STEM, "monthly_cf_2019_summary")
    if isfile(monthly_table_path)
        monthly_df = CSV.read(monthly_table_path, DataFrame)
        month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        p_monthly = bar(month_labels, monthly_df.mean_cf, yerror=monthly_df.std_cf, color=:darkorange, alpha=0.6,
                        edgecolor=:black, legend=false,
                        title="Solar $(SOLAR_LOC) 2019 — Monthly Mean CF ± Std",
                        xlabel="Month", ylabel="Mean Capacity Factor", grid=true, gridalpha=0.3, size=(1200, 500),
                        left_margin=5Plots.mm, bottom_margin=5Plots.mm)
        savefig(p_monthly, figure_path(SCRIPT_STEM, "04_monthly_cf_2019.png"))
        println("Saved: 04_monthly_cf_2019.png")
    end

    # ====== Figure 4: Summer 2019 Black Summer ======
    df_2019 = load_trace("solar", 2019, SOLAR_LOC)
    if df_2019 !== nothing
        summer_2019 = df_2019[in.(df_2019.Month, Ref((12, 1, 2))), :]
        daily = [mean(skipmissing(Vector(summer_2019[i, HH_COLS_SOL]))) for i in 1:nrow(summer_2019)]
        rolling3 = rolling_mean(daily, 3)
        p_black = plot(summer_2019.datetime, daily, linewidth=0.5, color=:darkorange, alpha=0.7, legend=false)
        plot!(p_black, summer_2019.datetime, rolling3, linewidth=2, color=:darkred, label="")
        plot!(p_black, title="Solar $(SOLAR_LOC) — Summer 2019 (Black Summer)", ylabel="Daily Mean CF",
              ylim=(0, 0.5), grid=true, gridalpha=0.3, size=(1600, 500),
              left_margin=5Plots.mm, bottom_margin=5Plots.mm)
        savefig(p_black, figure_path(SCRIPT_STEM, "04_summer_2019_black_summer.png"))
        println("Saved: 04_summer_2019_black_summer.png")
    end

    println("\nDone.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
