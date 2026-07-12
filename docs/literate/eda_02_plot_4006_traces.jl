# # Reference trace 4006 profiles
#
# Reference trace `4006` combines location-specific solar and wind profiles with a planning-horizon weather-year mapping. This page presents the selected locations, daily capacity-factor distributions, diurnal profiles, monthly structure, and financial-year aggregates.
#
# Reference trace `4006` is not a climate projection.
# Its planning-year behaviour depends on the historical-year composition documented in [Parameters and mappings](@ref).

using CSV
using DataFrames

const EDA02_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "02_plot_4006_traces",
)

function read_eda02(table_name)
    path = joinpath(EDA02_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda02(table; rows = 12) = first(table, min(rows, nrow(table)))

# ## Representative locations
#
# The location inventory identifies the solar and wind sites represented below.

loaded_locations = read_eda02("loaded_locations")
loaded_locations

# ## Daily capacity-factor distribution
#
# The daily summary provides comparable descriptive statistics for the selected solar and wind locations.

daily_cf_summary = read_eda02("daily_cf_summary")
daily_cf_summary

# ## Solar diurnal structure
#
# The solar profile summarises half-hourly behaviour at the selected Victorian location.
# Percentile bands should be interpreted as variation within the trace, not as forecast uncertainty unless the underlying construction supports that interpretation.

solar_diurnal_profile = read_eda02("solar_diurnal_profile")
preview_eda02(solar_diurnal_profile; rows = 16)

# ## Wind monthly and diurnal structure
#
# Wind is represented by both a monthly diurnal profile and a monthly mean series.
# These tables support different questions and should not be collapsed into one statistic.

wind_monthly_diurnal_profile = read_eda02("wind_monthly_diurnal_profile")
preview_eda02(wind_monthly_diurnal_profile; rows = 16)

wind_monthly_mean_cf = read_eda02("wind_monthly_mean_cf")
preview_eda02(wind_monthly_mean_cf; rows = 12)

# ## Financial-year aggregation
#
# The financial-year table links the profile statistics to the July-June convention used by the build pipeline.

annual_cf_by_fy = read_eda02("annual_cf_by_fy")
annual_cf_by_fy
