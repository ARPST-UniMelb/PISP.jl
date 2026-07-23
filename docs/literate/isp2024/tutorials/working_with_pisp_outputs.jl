# # ISP 2024: Working with PISP-generated outputs
#
# This tutorial loads one local PISP output build and shows how the static tables relate to the time-varying schedules.
# By default it reads `data/2024/pisp-datasets/out-ref4006-poe10/csv/` and `schedule-2030/`; set `PISP_DOCS_ISP2024_OUTPUT_ROOT` or `PISP_DOCS_ISP2024_SCHEDULE_TAG` to select another local generated build.
#
# ## Prerequisites and selected build
#
# The selected ISP 2024 documentation profile must provide an output root and schedule tag containing the five files checked below.
# Missing inputs fail before any aggregation or plotting begins.
#
# | Evidence | Role in this tutorial |
# |---|---|
# | `Generator.csv` | Static generator identity, technology, and bus assignment |
# | `Demand.csv` | Static demand identity and bus assignment |
# | `Bus.csv` | Bus-to-NEM-area mapping |
# | `Generator_pmax_sched.csv` | Time-varying maximum available generator output |
# | `Demand_load_sched.csv` | Time-varying demand load |
#
# ## Output relationships
#
# The workflow joins generator and demand schedules back to their static definitions, then aggregates daily solar PMax, wind PMax, and total demand series.
# `Generator_pmax_sched.csv` is an availability or maximum-output schedule; it is not realised dispatch or observed generation.

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Plots

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const OUTPUT_ROOT = ISP2024_PROFILE.output_root
OUTPUT_ROOT === nothing && error(
    "ISP 2024 profile does not define output_root; set PISP_DOCS_ISP2024_OUTPUT_ROOT to select a local output build.",
)
const DATA_ROOT = normpath(OUTPUT_ROOT)
const SCHEDULE_TAG = ISP2024_PROFILE.schedule_tag
SCHEDULE_TAG === nothing && error(
    "ISP 2024 profile does not define schedule_tag; set PISP_DOCS_ISP2024_SCHEDULE_TAG to select a local schedule.",
)
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

# ## Load static tables
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

# ## Load schedules
#
# `Generator_pmax_sched.csv` and `Demand_load_sched.csv` are time-varying companion tables for generator maximum available output and demand load.
# Maximum available output is a technical limit, not a record of dispatch.

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

# ## Area and technology context
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

# ## Join identifiers
#
# The demand schedule is filtered to demand IDs present in `Demand.csv`. The generator PMax schedule is joined to `Generator.csv` so solar and wind schedules can be separated by technology.

dem_load_full = filter(:id_dem => in(Set(dem_df.id_dem)), dem_load)
dem_load_full.day = Date.(dem_load_full.date)

gen_pmax_ts = innerjoin(gen_pmax, select(gen_df, [:id_gen, :tech]); on = :id_gen)
gen_pmax_ts.day = Date.(gen_pmax_ts.date)

sol_pmax_ts = filter(:tech => is_solar, gen_pmax_ts)
wind_pmax_ts = filter(:tech => is_wind, gen_pmax_ts)
nothing #hide

# ## Aggregate daily series
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

# ## Selected schedule profiles
#
# The figure compares the daily aggregate schedules in GW.
# It should not be read as a supply-demand balance: it omits dispatch decisions, curtailment, storage operation, network constraints, and interchange.

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

const SCRIPT_STEM = "isp2024_working_with_pisp_outputs"
const FIGURE_PATH = figure_path(SCRIPT_STEM, "isp2024_working_with_pisp_outputs-timeseries.png")
savefig(fig, FIGURE_PATH)
embed_figure(FIGURE_PATH, "isp2024_working_with_pisp_outputs-timeseries.png")
nothing #hide

# ![Daily aggregate solar PMax, wind PMax, and total demand](isp2024_working_with_pisp_outputs-timeseries.png)

# ## Validation
#
# - The required-file preflight verifies the selected build before any table is read.
# - The printed shapes and first rows expose the static and schedule schemas used by the joins.
# - The generator counts verify which records are classified as solar and wind.
# - The reported daily-series lengths verify the overlapping date coverage used by the figure.
#
# ## Interpret the result
#
# The static-table joins attach technology and bus-area context to otherwise identifier-only schedule rows.
# The resulting solar and wind series describe aggregate PMax availability, while the demand series describes aggregate load.
# Their co-plotting is useful for coverage and shape checks, but it does not establish dispatch feasibility, adequacy, or energy balance.
#
# ## Next use
#
# The same joins can be extended by filtering a scenario, NEM area, technology, or date window before aggregation.
# Analyses that require realised operation must use an appropriate dispatch or power-system model rather than treating PMax as generation.
