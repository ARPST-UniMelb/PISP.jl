#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using Printf
using Statistics

const SCRIPT_STEM = "03_year_comparison"
const TRACES = joinpath("data", "pisp-downloads", "Traces")
const TABLE_ROOT = joinpath(@__DIR__, "tables")

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

const YEARS = 2011:2023
const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]
const MIDDAY_COLS = string.(24:35)  # hours 12-18

# Representative locations
const SOLAR_LOC = "Bannerton_SAT"  # VIC solar
const WIND_LOC = "DUNDWF1"         # VIC wind

function add_datetime!(df::DataFrame)
    df.datetime = Date.(df.Year, df.Month, df.Day)
    return df
end

# Load a single location's traces across all historical reference years.
function load_location_all_years(tech, location, years)
    dfs = Dict{Int, DataFrame}()
    for yr in years
        file = joinpath(TRACES, "$(tech)_$(yr)", "$(location)_RefYear$(yr).csv")
        if isfile(file)
            df = CSV.read(file, DataFrame)
            add_datetime!(df)
            dfs[yr] = df
        end
    end
    return dfs
end

row_mean(df::DataFrame, cols) = [mean(row[col] for col in cols) for row in eachrow(df)]
row_max(df::DataFrame, cols) = [maximum(row[col] for col in cols) for row in eachrow(df)]

function write_seasonal_cf_table(sol_years, wind_years)
    rows = NamedTuple[]
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
                    rows,
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
                    rows,
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
    write_table(DataFrame(rows), SCRIPT_STEM, "seasonal_cf_by_year")
end

function write_annual_cf_table(sol_years, wind_years)
    rows = NamedTuple[]
    for (tech, loc, hh_cols, data) in (
        ("solar", SOLAR_LOC, HH_COLS_SOL, sol_years),
        ("wind", WIND_LOC, HH_COLS_WIND, wind_years),
    )
        for yr in sort(collect(keys(data)))
            vals = row_mean(data[yr], hh_cols)
            push!(rows, (tech = tech, location = loc, year = yr, mean_cf = mean(vals)))
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "annual_cf_by_year")
end

# For each year, find the day with the lowest midday (hour 12-18) max CF.
function write_worst_summer_day_table(sol_years)
    rows = NamedTuple[]
    for yr in sort(collect(keys(sol_years)))
        df = sol_years[yr]
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        midday_max = row_max(summer, MIDDAY_COLS)
        worst_pos = argmin(midday_max)  # first occurrence on ties, matching pandas idxmin
        worst_cf = midday_max[worst_pos]
        worst_date = summer.datetime[worst_pos]
        push!(rows, (year = yr, date = Dates.format(worst_date, "yyyy-mm-dd"), midday_max_cf = worst_cf))
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "worst_summer_day_by_year")
end

# Days with near-zero midday solar output / near-zero wind daily CF.
function write_low_output_days_table(sol_years, wind_years)
    rows = NamedTuple[]
    for yr in sort(collect(keys(sol_years)))
        df = sol_years[yr]
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        midday_max = row_max(summer, MIDDAY_COLS)
        n_low = count(<(0.05), midday_max)
        n_total = length(midday_max)
        push!(
            rows,
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
            rows,
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
    write_table(DataFrame(rows), SCRIPT_STEM, "low_output_days_by_year")
end

# Matches Python's `np.std(vals)` (population std, ddof=0) — distinct from the
# sample std (ddof=1) used by pandas `Series.std()` in `seasonal_cf_by_year`.
function write_variability_summary_table(sol_years, wind_years)
    rows = NamedTuple[]
    for (tech, loc, hh_cols, data) in (
        ("solar", SOLAR_LOC, HH_COLS_SOL, sol_years),
        ("wind", WIND_LOC, HH_COLS_WIND, wind_years),
    )
        vals = [mean(row_mean(data[yr], hh_cols)) for yr in sort(collect(keys(data)))]
        push!(
            rows,
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
    write_table(DataFrame(rows), SCRIPT_STEM, "annual_cf_variability_summary")
end

function main()
    sol_years = load_location_all_years("solar", SOLAR_LOC, YEARS)
    wind_years = load_location_all_years("wind", WIND_LOC, YEARS)

    println("Loaded solar $(SOLAR_LOC): $(length(sol_years)) years")
    println("Loaded wind $(WIND_LOC): $(length(wind_years)) years")

    write_seasonal_cf_table(sol_years, wind_years)
    write_annual_cf_table(sol_years, wind_years)
    write_worst_summer_day_table(sol_years)
    write_low_output_days_table(sol_years, wind_years)
    write_variability_summary_table(sol_years, wind_years)

    println("\nDone.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
