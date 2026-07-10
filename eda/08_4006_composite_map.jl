#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using Printf
using Statistics

const SCRIPT_STEM = "08_4006_composite_map"
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

const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]

const SOLAR_LOC = "Bannerton_SAT"
const WIND_LOC = "DUNDWF1"

const NEAR_YEARS = [2025, 2026, 2027, 2028, 2029]
const FAR_YEARS = [2045, 2046, 2047, 2048, 2049]

# The hardcoded DATE_RANGES_REFYEARS mapping from PISP.jl
const DATE_RANGES_REFYEARS = [
    ("2024-07-01", "2025-06-30", 2019),
    ("2025-07-01", "2026-06-30", 2020),
    ("2026-07-01", "2027-06-30", 2021),
    ("2027-07-01", "2028-06-30", 2022),
    ("2028-07-01", "2029-06-30", 2023),
    ("2029-07-01", "2030-06-30", 2015),
    ("2030-07-01", "2031-06-30", 2011),
    ("2031-07-01", "2032-06-30", 2012),
    ("2032-07-01", "2033-06-30", 2013),
    ("2033-07-01", "2034-06-30", 2014),
    ("2034-07-01", "2035-06-30", 2015),
    ("2035-07-01", "2036-06-30", 2016),
    ("2036-07-01", "2037-06-30", 2017),
    ("2037-07-01", "2038-06-30", 2018),
    ("2038-07-01", "2039-06-30", 2019),
    ("2039-07-01", "2040-06-30", 2020),
    ("2040-07-01", "2041-06-30", 2021),
    ("2041-07-01", "2042-06-30", 2022),
    ("2042-07-01", "2043-06-30", 2023),
    ("2043-07-01", "2044-06-30", 2015),
    ("2044-07-01", "2045-06-30", 2011),
    ("2045-07-01", "2046-06-30", 2012),
    ("2046-07-01", "2047-06-30", 2013),
    ("2047-07-01", "2048-06-30", 2014),
    ("2048-07-01", "2049-06-30", 2015),
    ("2049-07-01", "2050-06-30", 2016),
    ("2050-07-01", "2051-06-30", 2017),
    ("2051-07-01", "2052-06-30", 2018),
]

function build_mapping_table()
    fy_start = [t[1] for t in DATE_RANGES_REFYEARS]
    fy_end = [t[2] for t in DATE_RANGES_REFYEARS]
    ref_year = [t[3] for t in DATE_RANGES_REFYEARS]
    fy_label = ["FY$(e[1:4])" for e in fy_end]
    ref_label = string.(ref_year)
    return DataFrame(
        fy_start = fy_start,
        fy_end = fy_end,
        ref_year = ref_year,
        fy_label = fy_label,
        ref_label = ref_label,
    )
end

read_trace(path) = CSV.read(path, DataFrame)

trace_path(tech, yr, loc) = joinpath(TRACES, "$(tech)_$(yr)", "$(loc)_RefYear$(yr).csv")

daily_cf(df::DataFrame, hh_cols) = [mean(row[col] for col in hh_cols) for row in eachrow(df)]

# Mirrors `mapping_df[mapping_df['fy_end'].str.startswith(str(yr))]['ref_year'].values[0]`:
# `yr` is a financial-year-END year (e.g. 2025, 2045), not a historical/ref year, and must
# be translated through the mapping table before loading a trace file.
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
        isfile(path) || continue
        push!(all_cfs, daily_cf(read_trace(path), hh_cols))
    end
    isempty(all_cfs) && return nothing
    n = length(all_cfs[1])
    return [mean(cfs[i] for cfs in all_cfs) for i in 1:n]
end

function write_historical_year_vre_stats_table(mapping::DataFrame)
    rows = NamedTuple[]
    for yr in sort(unique(mapping.ref_year))
        for (tech, loc, hh_cols) in (("solar", SOLAR_LOC, HH_COLS_SOL), ("wind", WIND_LOC, HH_COLS_WIND))
            path = trace_path(tech, yr, loc)
            isfile(path) || continue
            df = read_trace(path)
            summer = df[in.(df.Month, Ref((12, 1, 2))), :]
            nrow(summer) == 0 && continue
            summer_cf = daily_cf(summer, hh_cols)
            push!(
                rows,
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
    write_table(DataFrame(rows), SCRIPT_STEM, "historical_year_vre_stats")
end

function write_near_vs_far_term_table()
    rows = NamedTuple[]
    for (tech, loc, hh_cols) in (("solar", SOLAR_LOC, HH_COLS_SOL), ("wind", WIND_LOC, HH_COLS_WIND))
        near_cf = load_year_cf(NEAR_YEARS, tech, loc, hh_cols)
        far_cf = load_year_cf(FAR_YEARS, tech, loc, hh_cols)
        if near_cf !== nothing
            for (day, cf) in enumerate(near_cf)
                push!(rows, (tech = tech, term = "near", day_of_year = day, daily_cf = cf))
            end
        end
        if far_cf !== nothing
            for (day, cf) in enumerate(far_cf)
                push!(rows, (tech = tech, term = "far", day_of_year = day, daily_cf = cf))
            end
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "near_vs_far_term_daily_cf")
end

function write_vre_heatmap_table(mapping::DataFrame)
    years_unique = sort(unique(mapping.ref_year))
    rows = NamedTuple[]
    for (tech, loc, hh_cols) in (("solar", SOLAR_LOC, HH_COLS_SOL), ("wind", WIND_LOC, HH_COLS_WIND))
        for yr in years_unique
            path = trace_path(tech, yr, loc)
            val = isfile(path) ? mean(daily_cf(read_trace(path), hh_cols)) : missing
            push!(rows, (tech = tech, ref_year = yr, annual_mean_cf = val))
        end
    end
    write_table(DataFrame(rows), SCRIPT_STEM, "vre_heatmap")
end

function write_ref_year_counts_table(mapping::DataFrame)
    counts = combine(groupby(mapping, :ref_year), nrow => :count)
    sort!(counts, :ref_year)
    write_table(counts, SCRIPT_STEM, "ref_year_counts")
end

function main()
    mapping = build_mapping_table()
    write_table(mapping, SCRIPT_STEM, "mapping_table")

    println("=== 4006 Composite Mapping ===")
    for row in eachrow(mapping)
        println("  ", row.fy_start[1:4], " → ref ", row.ref_year)
    end

    write_historical_year_vre_stats_table(mapping)
    write_near_vs_far_term_table()
    write_vre_heatmap_table(mapping)

    println("\n=== 4006 COMPOSITE STATS ===")
    println("Total years: ", nrow(mapping))
    println("Unique historical years used: ", sort(unique(mapping.ref_year)))
    write_ref_year_counts_table(mapping)

    println("\nDone.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
