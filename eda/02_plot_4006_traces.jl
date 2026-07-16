#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using Printf
using Statistics
using Plots

const SCRIPT_STEM = "02_plot_4006_traces"
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
        if isfile(file)
            df = read_trace(file)
            add_datetime!(df)
            dfs[loc] = df
        end
    end
    return dfs
end

# State-representative solar locations
const SOLAR_LOCATIONS = [
    ("VIC", "Bannerton_SAT"),
    ("NSW", "Darlington_Point_SAT"),
    ("QLD", "Banksia_SAT"),
    ("SA", "Bungala_One_SAT"),
    ("TAS", "Derby_SAT"),
]

# State-representative wind locations
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

# Replicates `(date + pd.offsets.MonthEnd(n)).year`, used by the Python
# script to bucket each day into an Australian financial year (ending June).
# pandas MonthEnd rolls a non-month-end date forward to its month's end
# first (consuming one of the `n` steps), then advances `n - 1` more
# month-ends; a date already on a month end advances the full `n` steps.
function fy_year(date::Date, n::Int = 6)
    absolute_month = year(date) * 12 + (month(date) - 1)
    on_offset = day(date) == daysinmonth(date)
    shifted = absolute_month + n - (on_offset ? 0 : 1)
    return fld(shifted, 12)
end

function write_loaded_locations_table(sol_dict, wind_dict)
    rows = NamedTuple[]
    for (state, loc) in SOLAR_LOCATIONS
        df = get(sol_dict, loc, nothing)
        push!(rows, (
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
        df = get(wind_dict, loc, nothing)
        push!(rows, (
            tech = "wind",
            state = state,
            location = loc,
            file_name = "$(loc)_RefYear4006.csv",
            loaded = df === nothing ? 0 : 1,
            rows = df === nothing ? missing : nrow(df),
            columns = df === nothing ? missing : ncol(df),
        ))
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "loaded_locations")
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

function write_daily_cf_summary_table(sol_dict, wind_dict)
    rows = NamedTuple[]
    for (state, loc) in SOLAR_LOCATIONS
        df = get(sol_dict, loc, nothing)
        df === nothing && continue
        push!(rows, daily_cf_row("solar", state, loc, df, HH_COLS_SOL))
    end
    for (state, loc) in WIND_LOCATIONS
        df = get(wind_dict, loc, nothing)
        df === nothing && continue
        push!(rows, daily_cf_row("wind", state, loc, df, HH_COLS_WIND))
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "daily_cf_summary")
end

function write_solar_diurnal_profile_table(sol_dict, prof_loc)
    df_prof = sol_dict[prof_loc]
    summer_mask = in.(df_prof.Month, Ref((12, 1, 2)))
    winter_mask = in.(df_prof.Month, Ref((6, 7, 8)))

    rows = NamedTuple[]
    for (season, mask) in (("Summer", summer_mask), ("Winter", winter_mask))
        df_season = df_prof[mask, :]
        n_days_season = nrow(df_season)
        for (hh, hh_col) in zip(HALF_HOURS, HH_COLS_SOL)
            vals = df_season[!, hh_col]
            push!(rows, (
                location = prof_loc,
                season = season,
                half_hour = hh,
                n_days = n_days_season,
                mean_cf = mean(vals),
                p10_cf = quantile(vals, 0.1),
                p90_cf = quantile(vals, 0.9),
            ))
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "solar_diurnal_profile")
end

function write_wind_monthly_diurnal_profile_table(wind_dict, wind_loc)
    df_wind_prof = wind_dict[wind_loc]
    rows = NamedTuple[]
    for m in 1:12
        mask = df_wind_prof.Month .== m
        any(mask) || continue
        df_month = df_wind_prof[mask, :]
        for (hh, hh_col) in zip(HALF_HOURS, HH_COLS_WIND)
            push!(rows, (
                location = wind_loc,
                month = m,
                half_hour = hh,
                mean_cf = mean(df_month[!, hh_col]),
            ))
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "wind_monthly_diurnal_profile")
end

function write_wind_monthly_mean_cf_table(wind_dict, wind_loc)
    df_wind_prof = wind_dict[wind_loc]
    daily_wind = daily_cf(df_wind_prof, HH_COLS_WIND)
    month_starts = [Date(year(d), month(d), 1) for d in df_wind_prof.datetime]

    grouped = DataFrame(month_start = month_starts, cf = daily_wind)
    summary = combine(groupby(grouped, :month_start), :cf => mean => :mean_cf)

    rows = [
        (location = wind_loc, month_start = Dates.format(row.month_start, "yyyy-mm-dd"), mean_cf = row.mean_cf)
        for row in eachrow(summary)
    ]
    write_table(DataFrame(rows), SCRIPT_STEM, "wind_monthly_mean_cf")
end

function write_annual_cf_by_fy_table(sol_dict, wind_dict)
    rows = NamedTuple[]

    df_s = get(sol_dict, "Bannerton_SAT", nothing)
    if df_s !== nothing
        fy = fy_year.(df_s.datetime)
        cf = daily_cf(df_s, HH_COLS_SOL)
        grouped = DataFrame(fy = fy, cf = cf)
        summary = combine(groupby(grouped, :fy), :cf => mean => :mean_cf)
        for row in eachrow(summary)
            push!(rows, (tech = "solar", location = "Bannerton_SAT", financial_year = row.fy, mean_cf = row.mean_cf))
        end
    end

    df_w = get(wind_dict, "DUNDWF1", nothing)
    if df_w !== nothing
        fy = fy_year.(df_w.datetime)
        cf = daily_cf(df_w, HH_COLS_WIND)
        grouped = DataFrame(fy = fy, cf = cf)
        summary = combine(groupby(grouped, :fy), :cf => mean => :mean_cf)
        for row in eachrow(summary)
            push!(rows, (tech = "wind", location = "DUNDWF1", financial_year = row.fy, mean_cf = row.mean_cf))
        end
    end

    write_table(DataFrame(rows), SCRIPT_STEM, "annual_cf_by_fy")
end

function main()
    gr()  # Select GR backend for static PNG output

    sol_4006 = load_traces("solar", 4006, last.(SOLAR_LOCATIONS))
    wind_4006 = load_traces("wind", 4006, last.(WIND_LOCATIONS))

    println("Loaded $(length(sol_4006)) solar locations, $(length(wind_4006)) wind locations for trace 4006")

    write_loaded_locations_table(sol_4006, wind_4006)
    write_daily_cf_summary_table(sol_4006, wind_4006)
    write_solar_diurnal_profile_table(sol_4006, "Bannerton_SAT")
    write_wind_monthly_diurnal_profile_table(wind_4006, "DUNDWF1")
    write_wind_monthly_mean_cf_table(wind_4006, "DUNDWF1")
    write_annual_cf_by_fy_table(sol_4006, wind_4006)

    # ====== Figure 1: Solar 4006 daily CF ======
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

    # ====== Figure 2: Wind 4006 daily CF ======
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

    # ====== Figure 3: Solar diurnal (summer vs winter) ======
    df_prof = sol_4006["Bannerton_SAT"]
    summer_mask = in.(df_prof.Month, Ref((12, 1, 2)))
    winter_mask = in.(df_prof.Month, Ref((6, 7, 8)))

    plots_diurnal = []
    for (season, mask, color) in [("Summer", summer_mask, :darkorange), ("Winter", winter_mask, :steelblue)]
        df_season = df_prof[mask, :]
        hh_vals = Matrix(df_season[!, HH_COLS_SOL])

        # Plot all days (up to 200)
        p = plot(legend=:topright, legendfontsize=8)
        for i in 1:min(200, size(hh_vals, 1))
            plot!(p, HALF_HOURS, hh_vals[i, :], linewidth=0.3, alpha=0.15, color=color, label="")
        end

        # Mean profile
        mean_profile = vec(mean(hh_vals, dims=1))
        plot!(p, HALF_HOURS, mean_profile, linewidth=2.5, color=:black, label="Mean")

        # P10-P90
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

    # ====== Figure 4: Wind seasonal analysis ======
    df_wind_prof = get(wind_4006, "DUNDWF1", nothing)
    if df_wind_prof !== nothing
        plots_wind_sea = []

        # Monthly diurnal
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

        # Daily and monthly mean
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
    end

    # ====== Figure 5: Annual CF by FY ======
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

    println("\nDone.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
