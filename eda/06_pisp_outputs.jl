#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using Printf
using Statistics

const SCRIPT_STEM = "06_pisp_outputs"
const OUT = joinpath("data", "pisp-datasets", "out-ref4006-poe10", "csv")
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

const AREA_NAMES = Dict(1 => "QLD", 2 => "NSW", 3 => "VIC", 4 => "TAS", 5 => "SA")

# Schedule date strings look like "2030-01-01T00:00:00.0". CSV.jl's type
# inference already parses this column as DateTime directly (it tolerates the
# single-digit fractional seconds); this helper only has to handle the string
# fallback in case a future dataset stores the column as text instead.
parse_schedule_datetime(s::AbstractString) = DateTime(replace(s, r"\.\d+$" => ""))
parse_schedule_datetime(d::DateTime) = d

is_solar_tech(tech) = occursin(r"PV|SOLAR"i, tech)
is_wind_tech(tech) = occursin(r"WIND"i, tech)

function write_generator_count_tables(gen_df::DataFrame)
    fuel_counts = combine(groupby(gen_df, :fuel), nrow => :count)
    write_table(fuel_counts, SCRIPT_STEM, "generator_fuel_counts")

    tech_counts = combine(groupby(gen_df, :tech), nrow => :count)
    write_table(tech_counts, SCRIPT_STEM, "generator_tech_counts")
end

function write_schedule_shape_table(gen_pmax::DataFrame, dem_load::DataFrame)
    rows = [
        (schedule = "Generator_pmax_sched", n_rows = nrow(gen_pmax), n_cols = ncol(gen_pmax)),
        (schedule = "Demand_load_sched", n_rows = nrow(dem_load), n_cols = ncol(dem_load)),
    ]
    write_table(DataFrame(rows), SCRIPT_STEM, "schedule_shapes")
end

function write_solar_wind_count_tables(solar_gens::DataFrame, wind_gens::DataFrame)
    write_table(
        DataFrame([
            (category = "solar", n_generators = nrow(solar_gens)),
            (category = "wind", n_generators = nrow(wind_gens)),
        ]),
        SCRIPT_STEM,
        "solar_wind_generator_counts",
    )

    solar_tech = combine(groupby(solar_gens, :tech), nrow => :count)
    solar_tech.category .= "solar"
    wind_tech = combine(groupby(wind_gens, :tech), nrow => :count)
    wind_tech.category .= "wind"
    combined = vcat(solar_tech, wind_tech)[:, [:category, :tech, :count]]
    write_table(combined, SCRIPT_STEM, "solar_wind_tech_counts")
end

# Plain per-generator annual mean pmax — a straightforward grouped mean,
# unrelated to the capacity-factor denominator question addressed below.
function write_annual_mean_pmax_table(gen_pmax::DataFrame, solar_gens::DataFrame, wind_gens::DataFrame)
    solar_ids = Set(solar_gens.id_gen)
    wind_ids = Set(wind_gens.id_gen)

    sol_sched = gen_pmax[in.(gen_pmax.id_gen, Ref(solar_ids)), :]
    wind_sched = gen_pmax[in.(gen_pmax.id_gen, Ref(wind_ids)), :]

    sol_annual = combine(groupby(sol_sched, :id_gen), :value => mean => :mean_pmax)
    sol_annual.tech .= "solar"
    wind_annual = combine(groupby(wind_sched, :id_gen), :value => mean => :mean_pmax)
    wind_annual.tech .= "wind"

    combined = vcat(sol_annual, wind_annual)[:, [:tech, :id_gen, :mean_pmax]]
    write_table(combined, SCRIPT_STEM, "annual_mean_pmax")
end

# Capacity factor for solar and wind divides each generator's scheduled mean
# output by that generator's own scheduled maximum, not by the static `pmax`
# recorded in `Generator.csv`. The static field is not a reliable capacity
# reference for these generators: rooftop PV rows carry a fixed placeholder
# pmax (src/parsers/PISP-2024parser.jl:1070, `gen_pmax_distpv`), and
# utility-scale solar/wind rows record only currently operating capacity,
# which a future-year schedule can exceed once ISP-outlook build-out is
# reflected in the trace (`gen_pmax_wind`, ~1386 vs. ~1477 in the same
# file). SiennaNEM.jl, which builds unit-commitment models from this same
# PISP output, applies the same convention (src/read_data.jl:214-229,
# `update_system_data_bound!`) and calls the static pmax "dummy" for these
# generators (src/create_system.jl:342,368). See PISP.jl's own
# docs/src/parameters.md and docs/src/assumptions.md for the full caveat.
function capacity_factor_duration_frame(gen_pmax::DataFrame, gens::DataFrame, tech::AbstractString)
    ids = Set(gens.id_gen)

    sched = gen_pmax[in.(gen_pmax.id_gen, Ref(ids)), :]
    grouped = combine(groupby(sched, :id_gen), :value => mean => :mean_value, :value => maximum => :max_value)

    cf_values = Float64[]
    for row in eachrow(grouped)
        cf = row.mean_value / row.max_value
        isnan(cf) && continue
        push!(cf_values, cf)
    end
    sorted_desc = sort(cf_values; rev = true)
    return DataFrame(tech = tech, rank = 1:length(sorted_desc), capacity_factor = sorted_desc)
end

function write_capacity_factor_duration_table(gen_pmax::DataFrame, solar_gens::DataFrame, wind_gens::DataFrame)
    solar_frame = capacity_factor_duration_frame(gen_pmax, solar_gens, "solar")
    wind_frame = capacity_factor_duration_frame(gen_pmax, wind_gens, "wind")
    write_table(vcat(solar_frame, wind_frame), SCRIPT_STEM, "capacity_factor_duration")
end

function build_dem_load_full(dem_load::DataFrame, dem_df::DataFrame, bus_df::DataFrame)
    area_map = Dict(row.id_bus => row.id_area for row in eachrow(bus_df))
    dem_load_full = innerjoin(dem_load, dem_df[:, [:id_dem, :id_bus]], on = :id_dem)
    dem_load_full.datetime = parse_schedule_datetime.(dem_load_full.date)
    dem_load_full.area = [area_map[b] for b in dem_load_full.id_bus]
    dem_load_full.area_name = [AREA_NAMES[a] for a in dem_load_full.area]
    return dem_load_full
end

function write_demand_by_area_table(dem_load_full::DataFrame)
    dem_load_full.date_only = Date.(dem_load_full.datetime)
    daily = combine(groupby(dem_load_full, [:date_only, :area_name]), :value => sum => :total_demand_mw)
    rename!(daily, :date_only => :date)
    write_table(daily, SCRIPT_STEM, "demand_by_area_daily")
    return daily
end

function build_gen_pmax_ts(gen_pmax::DataFrame, gen_df::DataFrame)
    gen_pmax_ts = innerjoin(gen_pmax, gen_df[:, [:id_gen, :tech]], on = :id_gen)
    gen_pmax_ts.datetime = parse_schedule_datetime.(gen_pmax_ts.date)
    return gen_pmax_ts
end

function daily_tech_sum(gen_pmax_ts::DataFrame, tech_predicate)
    subset = gen_pmax_ts[tech_predicate.(gen_pmax_ts.tech), :]
    subset = transform(subset, :datetime => ByRow(Date) => :date_only)
    return combine(groupby(subset, :date_only), :value => sum => :total)
end

function write_daily_solar_wind_demand_table(gen_pmax_ts::DataFrame, dem_load_full::DataFrame)
    sol_daily = daily_tech_sum(gen_pmax_ts, is_solar_tech)
    wind_daily = daily_tech_sum(gen_pmax_ts, is_wind_tech)
    dem_daily_ts = combine(groupby(dem_load_full, :date_only), :value => sum => :total_demand)

    daily = innerjoin(
        innerjoin(sol_daily, wind_daily, on = :date_only, makeunique = true, renamecols = "_solar" => "_wind"),
        dem_daily_ts,
        on = :date_only,
    )
    sort!(daily, :date_only)
    result = DataFrame(
        date = daily.date_only,
        solar_gw = daily.total_solar ./ 1000,
        wind_gw = daily.total_wind ./ 1000,
        demand_gw = daily.total_demand ./ 1000,
    )
    write_table(result, SCRIPT_STEM, "daily_solar_wind_demand_gw")
    return result, dem_daily_ts
end

function write_hourly_pmax_profile_table(gen_pmax_ts::DataFrame)
    cutoff = Date(2030, 1, 30)
    subset30 = gen_pmax_ts[Date.(gen_pmax_ts.datetime) .<= cutoff, :]

    sol_subset = subset30[is_solar_tech.(subset30.tech), :]
    sol_subset = transform(sol_subset, :datetime => ByRow(hour) => :hour)
    sol_profile = combine(groupby(sol_subset, [:id_gen, :hour]), :value => mean => :mean_pmax)
    sol_profile.tech .= "solar"

    wind_subset = subset30[is_wind_tech.(subset30.tech), :]
    wind_subset = transform(wind_subset, :datetime => ByRow(hour) => :hour)
    wind_profile = combine(groupby(wind_subset, [:id_gen, :hour]), :value => mean => :mean_pmax)
    wind_profile.tech .= "wind"

    combined = vcat(sol_profile, wind_profile)[:, [:tech, :id_gen, :hour, :mean_pmax]]
    write_table(combined, SCRIPT_STEM, "hourly_pmax_profile")
end

function write_vre_vs_demand_summary_table(daily_gw::DataFrame)
    vre = daily_gw.solar_gw .+ daily_gw.wind_gw
    demand = daily_gw.demand_gw
    write_table(
        DataFrame([(
            n_days = nrow(daily_gw),
            mean_demand_gw = mean(demand),
            mean_vre_gw = mean(vre),
            min_demand_gw = minimum(demand),
            max_demand_gw = maximum(demand),
            min_vre_gw = minimum(vre),
            max_vre_gw = maximum(vre),
            corr_demand_vre = cor(demand, vre),
        )]),
        SCRIPT_STEM,
        "vre_vs_demand_summary",
    )
end

function write_demand_distribution_summary_table(dem_daily_ts::DataFrame)
    vals = dem_daily_ts.total_demand
    write_table(
        DataFrame([(
            n = length(vals),
            mean_mw = mean(vals),
            std_mw = std(vals),
            min_mw = minimum(vals),
            max_mw = maximum(vals),
            median_mw = median(vals),
        )]),
        SCRIPT_STEM,
        "demand_distribution_summary",
    )
end

function main()
    gen_df = CSV.read(joinpath(OUT, "Generator.csv"), DataFrame)
    dem_df = CSV.read(joinpath(OUT, "Demand.csv"), DataFrame)
    bus_df = CSV.read(joinpath(OUT, "Bus.csv"), DataFrame)

    gen_pmax = CSV.read(joinpath(OUT, "schedule-2030", "Generator_pmax_sched.csv"), DataFrame)
    dem_load = CSV.read(joinpath(OUT, "schedule-2030", "Demand_load_sched.csv"), DataFrame)

    println("=== Generator Table ===")
    println("Shape: ", (nrow(gen_df), ncol(gen_df)))
    write_generator_count_tables(gen_df)

    println("\n=== Generator_pmax_sched ===")
    println("Shape: ", (nrow(gen_pmax), ncol(gen_pmax)))
    println("\n=== Demand_load_sched ===")
    println("Shape: ", (nrow(dem_load), ncol(dem_load)))
    write_schedule_shape_table(gen_pmax, dem_load)

    solar_gens = gen_df[is_solar_tech.(gen_df.tech), :]
    wind_gens = gen_df[is_wind_tech.(gen_df.tech), :]
    println("\nSolar generators: ", nrow(solar_gens))
    println("Wind generators: ", nrow(wind_gens))
    write_solar_wind_count_tables(solar_gens, wind_gens)

    write_annual_mean_pmax_table(gen_pmax, solar_gens, wind_gens)
    write_capacity_factor_duration_table(gen_pmax, solar_gens, wind_gens)

    dem_load_full = build_dem_load_full(dem_load, dem_df, bus_df)
    write_demand_by_area_table(dem_load_full)

    gen_pmax_ts = build_gen_pmax_ts(gen_pmax, gen_df)
    daily_gw, dem_daily_ts = write_daily_solar_wind_demand_table(gen_pmax_ts, dem_load_full)
    write_hourly_pmax_profile_table(gen_pmax_ts)
    write_vre_vs_demand_summary_table(daily_gw)
    write_demand_distribution_summary_table(dem_daily_ts)

    println("\nDone.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
