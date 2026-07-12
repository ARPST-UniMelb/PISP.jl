# # Comparing historical solar and wind reference years
#
# A single reference year can conceal substantial interannual variation in renewable availability. This page compares annual and seasonal capacity factors, low-output days, and the most adverse summer solar day across the available historical traces.
#
# The comparison is location-specific: solar uses `Bannerton_SAT` and wind uses `DUNDWF1`.
# Results should not be generalised to all Victorian renewable resources without additional spatial analysis.

using CSV
using DataFrames

const EDA03_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "03_year_comparison",
)

function read_eda03(table_name)
    path = joinpath(EDA03_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda03(table; rows = 16) = first(table, min(rows, nrow(table)))

# ## Annual variation
#
# Annual means establish the scale of year-to-year variation before seasonal or extreme-event metrics are considered.

annual_cf_by_year = read_eda03("annual_cf_by_year")
annual_cf_by_year

annual_cf_variability_summary = read_eda03("annual_cf_variability_summary")
annual_cf_variability_summary

# ## Seasonal variation
#
# Seasonal summaries separate summer and winter behaviour for each historical year. Variation between seasons and variation between years within the same season are different effects and should be read separately.

seasonal_cf_by_year = read_eda03("seasonal_cf_by_year")
preview_eda03(seasonal_cf_by_year; rows = 20)

# ## Low-output frequency
#
# Solar and wind use different low-output metrics: solar counts days whose midday maximum is below the threshold, while wind uses daily mean capacity factor.
# Their percentages are therefore not directly interchangeable without retaining the metric definition.

low_output_days_by_year = read_eda03("low_output_days_by_year")
preview_eda03(low_output_days_by_year; rows = 20)

# ## Worst summer solar day in each year
#
# This table identifies the minimum midday-maximum solar day within each sampled summer.
# It is an event-screening metric rather than a complete adequacy or energy-shortfall measure.

worst_summer_day_by_year = read_eda03("worst_summer_day_by_year")
worst_summer_day_by_year
