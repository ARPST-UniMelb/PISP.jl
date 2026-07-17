# # ISP 2024: Trace data availability and structure
#
# PISP uses historical demand, solar, and wind traces with different directory layouts and table schemas. AEMO's [2024 ISP PLEXOS Model Instructions, physical p. 7](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=7) describes the demand, hydro, load-subtracter, solar, timeslice, and wind trace families. In the local downloads inspected here, solar and wind are grouped by technology and reference year, while demand is grouped by state/scenario and node. This page loads those raw trace files directly and shows their shape, date coverage, value ranges, and one demand-trace example.

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

const SCRIPT_STEM = "isp2024_01_data_loading"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const TRACES = relpath(joinpath(ISP2024_PROFILE.download_root, "Traces"), REPO_ROOT)  # kept relative: this is the path form recorded in the tables below
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a TRACES-relative path to an absolute file location for reading

function column_preview(df::DataFrame, n = 10)
    cols = names(df)
    return cols[1:min(n, length(cols))]
end

function first_three_text(df::DataFrame, row)
    cols = names(df)[1:3]
    parts = ["$(col): $(df[row, col])" for col in cols]
    return "{" * join(parts, ", ") * "}"
end

function value_minmax(df::DataFrame)
    value_cols = names(df)[4:end]
    min_value = minimum(minimum(skipmissing(df[!, col])) for col in value_cols)
    max_value = maximum(maximum(skipmissing(df[!, col])) for col in value_cols)
    return min_value, max_value
end

function trace_shape_row(label, path, df::DataFrame)
    cols = names(df)
    preview = cols[1:min(10, length(cols))]
    return (
        trace_type = label,
        file = path,
        file_name = basename(path),
        rows = nrow(df),
        columns = ncol(df),
        metadata_columns = join(cols[1:3], ","),
        value_columns = max(length(cols) - 3, 0),
        first_value_column = length(cols) > 3 ? cols[4] : "",
        last_value_column = length(cols) > 3 ? cols[end] : "",
        columns_preview = join(preview, "|"),
    )
end

function trace_date_range_row(label, path, df::DataFrame)
    first_row = df[1, :]
    last_row = df[end, :]
    return (
        trace_type = label,
        file_name = basename(path),
        first_year = Int(first_row["Year"]),
        first_month = Int(first_row["Month"]),
        first_day = Int(first_row["Day"]),
        last_year = Int(last_row["Year"]),
        last_month = Int(last_row["Month"]),
        last_day = Int(last_row["Day"]),
    )
end

function trace_value_range_row(label, path, df::DataFrame)
    min_value, max_value = value_minmax(df)
    return (trace_type = label, file_name = basename(path), min_value = min_value, max_value = max_value)
end
nothing #hide

# ## Step 1 — load the solar and wind reference traces for trace year 4006
#
# `Bannerton_SAT` (solar) and `ARWF1` (wind) are the same representative locations used throughout the EDA 02-08 pages.

sol_file = joinpath(TRACES, "solar_4006", "Bannerton_SAT_RefYear4006.csv")
df_sol = CSV.read(abs_path(sol_file), DataFrame)

println("Solar trace: ", sol_file)
println("Shape: ", (nrow(df_sol), ncol(df_sol)))
println("Columns (preview): ", column_preview(df_sol))
println("Date range: ", first_three_text(df_sol, 1), " to ", first_three_text(df_sol, nrow(df_sol)))

wind_file = joinpath(TRACES, "wind_4006", "ARWF1_RefYear4006.csv")
df_wind = CSV.read(abs_path(wind_file), DataFrame)

println("\nWind trace: ", wind_file)
println("Shape: ", (nrow(df_wind), ncol(df_wind)))
println("Date range: ", first_three_text(df_wind, 1), " to ", first_three_text(df_wind, nrow(df_wind)))

# ## Step 2 — table structure and date coverage
#
# Both traces share the same layout: three metadata columns (`Year`, `Month`, `Day`) followed by half-hourly value columns.

traces = [("solar", sol_file, df_sol), ("wind", wind_file, df_wind)]
trace_shape_columns = DataFrame([trace_shape_row(t...) for t in traces])
write_table(trace_shape_columns, SCRIPT_STEM, "trace_shape_columns")
markdown_table(trace_shape_columns)

#-

trace_date_ranges = DataFrame([trace_date_range_row(t...) for t in traces])
write_table(trace_date_ranges, SCRIPT_STEM, "trace_date_ranges")
markdown_table(trace_date_ranges)

# ## Step 3 — value ranges and the solar low-output threshold
#
# The minimum and maximum values describe the numeric range in each sampled trace. The solar low-output summary counts days at Bannerton_SAT whose midday half-hourly maximum, across columns `24:35`, falls below the fixed capacity-factor threshold `0.1`.

trace_value_ranges = DataFrame([trace_value_range_row(t...) for t in traces])
write_table(trace_value_ranges, SCRIPT_STEM, "trace_value_ranges")
markdown_table(trace_value_ranges)

#-

midday_cols = string.(24:35)
daily_max = [maximum(row[col] for col in midday_cols) for row in eachrow(df_sol)]
n_low = count(<(0.1), daily_max)
n_total = nrow(df_sol)
println(@sprintf("Days with midday max < 0.1: %d/%d (%.6f%%)", n_low, n_total, 100 * n_low / n_total))

solar_midday_low_days = DataFrame([
    (
        trace_type = "solar",
        file_name = basename(sol_file),
        midday_columns = join(midday_cols, "|"),
        low_threshold = 0.1,
        low_days = Int(n_low),
        total_days = Int(n_total),
        low_percent = 100 * n_low / n_total,
    ),
])
write_table(solar_midday_low_days, SCRIPT_STEM, "solar_midday_low_days")
markdown_table(solar_midday_low_days)

# ## Step 4 — a demand-trace example
#
# Demand traces use a different file family and schema from solar and wind traces: one file per demand node under a state/scenario directory, rather than one file per reference year.

demand_dir = joinpath(TRACES, "demand_VIC_Step Change")
dem_files = isdir(abs_path(demand_dir)) ? sort(filter(name -> endswith(name, "_PV_TOT.csv"), readdir(abs_path(demand_dir)))) : String[]

demand_sample_metadata = if !isempty(dem_files)
    df_dem = CSV.read(abs_path(joinpath(demand_dir, dem_files[1])), DataFrame)
    println("Demand file: ", dem_files[1])
    println("Shape: ", (nrow(df_dem), ncol(df_dem)))
    cols = names(df_dem)
    DataFrame([
        (
            demand_dir = demand_dir,
            file_count = length(dem_files),
            sample_file = dem_files[1],
            sample_rows = nrow(df_dem),
            sample_columns = ncol(df_dem),
            metadata_columns = join(cols[1:3], ","),
            value_columns = max(length(cols) - 3, 0),
            first_value_column = length(cols) > 3 ? cols[4] : "",
            last_value_column = length(cols) > 3 ? cols[end] : "",
            columns_list = join(cols, "|"),
        ),
    ])
else
    DataFrame([
        (
            demand_dir = demand_dir,
            file_count = 0,
            sample_file = "",
            sample_rows = missing,
            sample_columns = missing,
            metadata_columns = "",
            value_columns = missing,
            first_value_column = "",
            last_value_column = "",
            columns_list = "",
        ),
    ])
end
write_table(demand_sample_metadata, SCRIPT_STEM, "demand_sample_metadata")
markdown_table(demand_sample_metadata)

# ## Step 5 — which reference years are available
#
# PISP's reference-trace convention spans several historical weather years plus the composite `4006` trace; not every year is present in every local download.

available_year_rows = NamedTuple[]
for yr in [2011, 2015, 2019, 2023]
    test_file = joinpath(TRACES, "solar_$(yr)", "Bannerton_SAT_RefYear$(yr).csv")
    exists = isfile(abs_path(test_file))
    first_year = missing
    first_month = missing
    first_day = missing
    if exists
        df_check = CSV.read(abs_path(test_file), DataFrame; limit = 1)
        first_year = Int(df_check[1, "Year"])
        first_month = Int(df_check[1, "Month"])
        first_day = Int(df_check[1, "Day"])
    end
    push!(available_year_rows, (year = yr, solar_file = test_file, exists = exists ? 1 : 0, first_year = first_year, first_month = first_month, first_day = first_day))
end

available_year_checks = DataFrame(available_year_rows)
write_table(available_year_checks, SCRIPT_STEM, "available_year_checks")
markdown_table(available_year_checks)

# ## Step 6 — plot the first 30 days of each trace
#
# The two panels compare the shape of a representative solar half-hourly capacity-factor series against a representative wind series over the same window.

sol_sub = df_sol[1:30, :]
sol_datetime = Date.(sol_sub.Year, sol_sub.Month, sol_sub.Day)
sol_hourly = vec(mean(Matrix(sol_sub[!, 4:51]), dims = 2))

wind_sub = df_wind[1:30, :]
wind_datetime = Date.(wind_sub.Year, wind_sub.Month, wind_sub.Day)
wind_hourly = vec(mean(Matrix(wind_sub[!, 4:51]), dims = 2))

p1 = plot(sol_datetime, sol_hourly, linewidth = 0.8, color = :orange, label = "", title = "Solar 4006 — Bannerton_SAT (first 30 days)", ylabel = "Mean half-hourly CF", legend = false)
p2 = plot(wind_datetime, wind_hourly, linewidth = 0.8, color = :steelblue, label = "", title = "Wind 4006 — ARWF1 (first 30 days)", ylabel = "Mean half-hourly CF", legend = false)
fig = plot(p1, p2, layout = (2, 1), size = (1600, 900), left_margin = 5Plots.mm, bottom_margin = 4Plots.mm, top_margin = 4Plots.mm)

const CANONICAL_FIGURE_PATH = figure_path(SCRIPT_STEM, "01_sample_traces.png")
savefig(fig, CANONICAL_FIGURE_PATH)

EdaSupport.embed_figure(CANONICAL_FIGURE_PATH, "01_sample_traces.png")
nothing #hide

# ![First 30 days of the solar and wind 4006 reference traces](01_sample_traces.png)

# ## Summary
#
# - The executed 4006 samples for solar site Bannerton_SAT and wind site ARWF1 each contain 10,227 rows and 51 columns, spanning 2024-07-01 through 2052-06-30.
# - For the solar 4006 sample at Bannerton_SAT, 67 of 10,227 days (0.655129%) have a midday maximum below the threshold `0.1` across columns `24:35`.
# - Solar and wind traces share one schema (three metadata columns plus half-hourly value columns); demand traces use a different, per-node file family.
