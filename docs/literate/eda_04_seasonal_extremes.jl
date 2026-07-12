# # Examining seasonal renewable extremes
#
# Mean capacity factors do not describe the persistence, timing, or profile of low-output conditions. This page presents grouped summer comparisons, candidate multi-day low-output events, and detailed solar profiles for adverse days.
#
# The analysis uses one Victorian solar location and one Victorian wind location.
# Its event definitions are exploratory and should not be treated as a system-wide adequacy criterion.

using CSV
using DataFrames

const EDA04_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "04_seasonal_extremes",
)

function read_eda04(table_name)
    path = joinpath(EDA04_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda04(table; rows = 16) = first(table, min(rows, nrow(table)))

# ## Hot and cool summer groups
#
# The grouped summary compares preselected historical summers.
# The labels encode an external classification used for the comparison; the table itself does not establish meteorological causality.

hot_cool_summer_solar_summary = read_eda04("hot_cool_summer_solar_summary")
hot_cool_summer_solar_summary

# ## Candidate multi-day low-output events
#
# The current event-duration calculation retains original row labels after summer filtering. Events crossing excluded months can therefore receive inflated or otherwise misleading durations, and positional pairing can shift when start and end counts differ. Do not use the reported durations as modelling inputs until this calculation is corrected.

low_output_events = read_eda04("low_output_events")
preview_eda04(low_output_events; rows = 20)

# ## Worst solar day and half-hourly profile
#
# The summary identifies the selected adverse day for each year, while the profile table retains the intraday shape needed to understand whether the low-output metric is broad or confined to a short interval.

worst_solar_day_summary = read_eda04("worst_solar_day_summary")
worst_solar_day_summary

worst_solar_day_profile = read_eda04("worst_solar_day_profile")
preview_eda04(worst_solar_day_profile; rows = 24)

# ## 2019 monthly and Black Summer detail
#
# The monthly table provides a calendar context for the detailed summer series.
# The three-day rolling value is descriptive and should not be interpreted as a dispatch or storage requirement without a separate system model.

monthly_cf_2019_summary = read_eda04("monthly_cf_2019_summary")
monthly_cf_2019_summary

black_summer_2019_daily_cf = read_eda04("black_summer_2019_daily_cf")
preview_eda04(black_summer_2019_daily_cf; rows = 20)
