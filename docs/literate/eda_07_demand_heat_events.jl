# # Demand stress and low-solar coincidence
#
# High demand can coincide with low renewable availability, but that relationship depends on aligned dates, explicit thresholds, and the event definition. This page presents Victorian demand distributions, demand-defined stress days, hourly demand profiles, and solar availability on selected high-demand dates.
#
# Here, `heat event` is an operational label for days at or above the 95th percentile of demand.
# It does not use air temperature, an excess-heat factor, or a meteorological heatwave definition.

using CSV
using DataFrames

const EDA07_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "07_demand_heat_events",
)

function read_eda07(table_name)
    path = joinpath(EDA07_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda07(table; rows = 16) = first(table, min(rows, nrow(table)))

# ## Demand and trace coverage
#
# The trace inventory and area-level daily demand table establish the available inputs before the Victorian subset is analysed.

demand_trace_inventory = read_eda07("demand_trace_inventory")
preview_eda07(demand_trace_inventory; rows = 12)

demand_by_area_daily = read_eda07("demand_by_area_daily")
preview_eda07(demand_by_area_daily; rows = 20)

# ## Victorian demand and solar alignment
#
# The merged table contains only dates present in both the PISP demand schedule and the selected Victorian solar trace.
# Any missing-date pattern should be reviewed before interpreting coincidence statistics.

vic_demand_solar_merged = read_eda07("vic_demand_solar_merged")
preview_eda07(vic_demand_solar_merged; rows = 20)

# ## High-demand and low-solar threshold screen
#
# The screen uses the 90th demand percentile and 10th solar-capacity-factor percentile within the merged sample.
# These are relative thresholds, so the resulting count depends on the selected period and is not an absolute adequacy criterion.

high_demand_low_solar_summary = read_eda07("high_demand_low_solar_summary")
high_demand_low_solar_summary

# ## Demand-defined stress days
#
# The summary records the P90 and P95 demand thresholds, event counts, and peak-demand date.
# The hourly profile then compares demand on P95 stress days with days below P90.

demand_heat_event_summary = read_eda07("demand_heat_event_summary")
demand_heat_event_summary

heat_normal_hourly_profile = read_eda07("heat_normal_hourly_profile")
heat_normal_hourly_profile

# ## Demand duration and normalised coincidence
#
# Duration-curve and normalised tables preserve ranking information but discard chronology.
# They can describe distributional alignment, not event persistence or sequential operational stress.

demand_duration_curve = read_eda07("demand_duration_curve")
preview_eda07(demand_duration_curve; rows = 20)

normalized_vre_demand_summary = read_eda07("normalized_vre_demand_summary")
preview_eda07(normalized_vre_demand_summary; rows = 20)

# ## Solar availability on the highest-demand days
#
# The detail table reports solar capacity factor for the selected top-demand dates that could be matched to the trace.
# It should be read with the representative-site and date-alignment limitations above.

hot_day_solar_cf_detail = read_eda07("hot_day_solar_cf_detail")
hot_day_solar_cf_detail
