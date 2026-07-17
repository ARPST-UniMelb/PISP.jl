# # Working with PISP-generated outputs
#
# This tutorial loads one local PISP output build and shows how the static tables relate to the time-varying schedules. By default it reads `data/2024/pisp-datasets/out-ref4006-poe10/csv/` and `schedule-2030/`; set `PISP_OUTPUT_ROOT` or `PISP_SCHEDULE_TAG` to use another generated build.
#
# The workflow joins generator and demand schedules back to `Generator.csv`, `Demand.csv`, and `Bus.csv`, then aggregates daily solar PMax, wind PMax, and total demand series.

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Plots

gr();

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))
const DATA_ROOT = normpath(get(
    ENV,
    "PISP_OUTPUT_ROOT",
    joinpath(REPO_ROOT, "data", "2024", "pisp-datasets", "out-ref4006-poe10", "csv"),
))
const SCHEDULE_TAG = get(ENV, "PISP_SCHEDULE_TAG", "schedule-2030")
const SCHEDULE_DIR = joinpath(DATA_ROOT, SCHEDULE_TAG)

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

required_files = [
    joinpath(DATA_ROOT, "Generator.csv"),
    joinpath(DATA_ROOT, "Demand.csv"),
    joinpath(DATA_ROOT, "Bus.csv"),
    joinpath(SCHEDULE_DIR, "Generator_pmax_sched.csv"),
    joinpath(SCHEDULE_DIR, "Demand_load_sched.csv"),
]
missing_files = filter(path -> !isfile(path), required_files)
isempty(missing_files) || error("missing PISP output files: $(join(missing_files, ", "))")

# ## Step 1 — load the static output tables
#
# `Generator.csv`, `Demand.csv`, and `Bus.csv` are static tables written once per PISP build.

gen_df = CSV.read(joinpath(DATA_ROOT, "Generator.csv"), DataFrame)
dem_df = CSV.read(joinpath(DATA_ROOT, "Demand.csv"), DataFrame)
bus_df = CSV.read(joinpath(DATA_ROOT, "Bus.csv"), DataFrame)

println("=== Generator Table ===")
println("Shape: ", size(gen_df))
println("Columns: ", names(gen_df))

# Fuel and technology counts show the asset mix represented in the generated output.

fuel_counts = sort(combine(groupby(gen_df, :fuel), nrow => :count), :count; rev = true)
markdown_table(fuel_counts)

#-

tech_counts = sort(combine(groupby(gen_df, :tech), nrow => :count), :count; rev = true)
markdown_table(tech_counts)

# ## Step 2 — load the schedule output
#
# `Generator_pmax_sched.csv` and `Demand_load_sched.csv` are time-varying companion tables for generator maximum output and demand load.

gen_pmax = CSV.read(joinpath(SCHEDULE_DIR, "Generator_pmax_sched.csv"), DataFrame)
dem_load = CSV.read(joinpath(SCHEDULE_DIR, "Demand_load_sched.csv"), DataFrame)

println("\n=== Generator_pmax_sched ===")
println("Shape: ", size(gen_pmax))
println("Columns: ", names(gen_pmax))

# The first rows make the schedule schema concrete.

#-

markdown_table(first(gen_pmax, 5))

#-

println("\n=== Demand_load_sched ===")
println("Shape: ", size(dem_load))

#-

markdown_table(first(dem_load, 5))

# ## Step 3 — map generators to buses and identify solar/wind generators
#
# `Bus.csv` carries `id_area`; joining that onto `Generator.csv` via `id_bus` assigns each generator to a NEM area. Solar and wind are identified from `tech` using case-insensitive substring matches.

area_map = Dict(zip(bus_df.id_bus, bus_df.id_area))
gen_df.area = [area_map[b] for b in gen_df.id_bus]
const AREA_NAMES = Dict(1 => "QLD", 2 => "NSW", 3 => "VIC", 4 => "TAS", 5 => "SA")
gen_df.area_name = [AREA_NAMES[a] for a in gen_df.area]

is_solar(tech) = occursin(r"pv|solar"i, tech)
is_wind(tech) = occursin(r"wind"i, tech)

solar_gens = filter(:tech => is_solar, gen_df)
wind_gens = filter(:tech => is_wind, gen_df)

println("\nSolar generators: ", nrow(solar_gens))
println("Wind generators: ", nrow(wind_gens))

#-

solar_tech_counts = sort(
    combine(groupby(solar_gens, :tech), nrow => :count), :count; rev = true,
)
markdown_table(solar_tech_counts)

#-

wind_tech_counts = sort(
    combine(groupby(wind_gens, :tech), nrow => :count), :count; rev = true,
)
markdown_table(wind_tech_counts)

# ## Step 4 — prepare daily aggregate series
#
# The demand schedule is filtered to demand IDs present in `Demand.csv`. The generator PMax schedule is joined to `Generator.csv` so solar and wind schedules can be separated by technology.

dem_load_full = filter(:id_dem => in(Set(dem_df.id_dem)), dem_load)
dem_load_full.day = Date.(dem_load_full.date)

gen_pmax_ts = innerjoin(gen_pmax, select(gen_df, [:id_gen, :tech]); on = :id_gen)
gen_pmax_ts.day = Date.(gen_pmax_ts.date)

sol_pmax_ts = filter(:tech => is_solar, gen_pmax_ts)
wind_pmax_ts = filter(:tech => is_wind, gen_pmax_ts)
nothing #hide

# ## Step 5 — daily aggregate solar PMax, wind PMax, and total demand
#
# Values are summed by day and converted from MW to GW for plotting.

sol_daily = sort(combine(groupby(sol_pmax_ts, :day), :value => sum => :value), :day)
wind_daily = sort(combine(groupby(wind_pmax_ts, :day), :value => sum => :value), :day)
dem_daily = sort(combine(groupby(dem_load_full, :day), :value => sum => :value), :day)

println(
    "\nDaily aggregate series length — solar: ", nrow(sol_daily),
    ", wind: ", nrow(wind_daily),
    ", demand: ", nrow(dem_daily),
)

# ## Step 6 — plot the comparison
#
# The figure compares the daily aggregate schedules in GW.

fig = plot(
    sol_daily.day, sol_daily.value ./ 1000;
    label = "Solar PMax (GW)", color = :darkorange, linewidth = 1, alpha = 0.8,
)
plot!(
    fig, wind_daily.day, wind_daily.value ./ 1000;
    label = "Wind PMax (GW)", color = :steelblue, linewidth = 1, alpha = 0.8,
)
plot!(
    fig, dem_daily.day, dem_daily.value ./ 1000;
    label = "Total Demand (GW)", color = :grey, linewidth = 1, alpha = 0.8,
)
xlabel!(fig, "Date")
ylabel!(fig, "GW")
title!(fig, "$(SCHEDULE_TAG) — Daily Aggregate: Solar PMax, Wind PMax, Total Demand")

const FIGURE_PATH = joinpath(
    normpath(get(ENV, "PISP_LITERATE_OUTPUT_DIR", @__DIR__)),
    "working_with_pisp_outputs-timeseries.png",
)
savefig(fig, FIGURE_PATH)
nothing #hide

# ![Daily aggregate solar PMax, wind PMax, and total demand](working_with_pisp_outputs-timeseries.png)

# ## Summary
#
# - `Generator_pmax_sched.csv` carries hourly PMax schedules for generators whose maximum output varies across the year in this build, chiefly solar and wind.
# - `Demand_load_sched.csv` carries hourly demand by demand node.
# - The daily aggregates expose the overlapping date coverage of the selected solar, wind, and demand schedules.
# - The static-table joins attach generator technology and bus-area information to the schedules before aggregation.
