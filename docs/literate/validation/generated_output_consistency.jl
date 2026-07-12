# # Generated-output consistency
#
# PISP writes static asset tables and time-varying schedules as one connected dataset. This page describes identifier coverage, schedule coverage, generator classifications, and daily series alignment for one generated build.

using CSV
using DataFrames

const EDA06_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", ".."))),
    "eda", "tables", "julia", "06_pisp_outputs",
)

function read_eda06(table_name)
    path = joinpath(EDA06_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame; missingstring = nothing)
end

# ## Build snapshot

build_metadata = read_eda06("build_metadata")
build_metadata

# ## Schedule coverage
#
# The schedule tables record the row and column counts and the represented time interval for generator PMax and demand load.

schedule_shapes = read_eda06("schedule_shapes")
schedule_shapes

#-

schedule_time_coverage = read_eda06("schedule_time_coverage")
schedule_time_coverage

# ## Join coverage
#
# The join-coverage table compares schedule identifiers with their static-table identifiers and compares generator and demand bus references with `Bus.csv`. `left_unmatched_ids` identifies schedule or asset rows without a corresponding referenced record. `right_unmatched_ids` identifies static records without a corresponding row in the compared table.

join_coverage = read_eda06("join_coverage")
join_coverage

#-

unmatched_ids = read_eda06("unmatched_ids")
unmatched_ids

# ## Generator classification
#
# Generator fuel and technology counts show which static classifications are available for schedule joins and technology-specific aggregation.

generator_fuel_counts = read_eda06("generator_fuel_counts")
generator_fuel_counts

#-

generator_tech_counts = read_eda06("generator_tech_counts")
generator_tech_counts

#-

solar_wind_generator_counts = read_eda06("solar_wind_generator_counts")
solar_wind_generator_counts

# ## Daily schedule alignment
#
# Generator schedules are joined to generator identities and demand schedules to demand identities before aggregating solar PMax, wind PMax, and demand.

daily_series = read_eda06("daily_solar_wind_demand_gw")

daily_coverage = DataFrame([
    (
        first_date = minimum(daily_series.date),
        last_date = maximum(daily_series.date),
        n_days = nrow(daily_series),
        missing_solar = count(ismissing, daily_series.solar_gw),
        missing_wind = count(ismissing, daily_series.wind_gw),
        missing_demand = count(ismissing, daily_series.demand_gw),
    ),
])
daily_coverage

# ## VRE and demand summary
#
# The summary reports the scale and correlation of the joined daily series for the selected build.

vre_vs_demand_summary = read_eda06("vre_vs_demand_summary")
vre_vs_demand_summary