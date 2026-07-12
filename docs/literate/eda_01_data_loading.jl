# # Trace data availability and structure
#
# PISP uses historical demand, solar, and wind traces with different directory layouts and table schemas. This page summarises the available reference years, sampled table structures, date coverage, value ranges, and one demand-trace example.

using CSV
using DataFrames

const EDA01_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "01_data_loading",
)

function read_eda01(table_name)
    path = joinpath(EDA01_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end


# ## Available reference years

available_year_checks = read_eda01("available_year_checks")
available_year_checks

# ## Solar and wind table structure

trace_shape_columns = read_eda01("trace_shape_columns")
trace_shape_columns

# The date ranges identify the period represented by each sampled trace.

trace_date_ranges = read_eda01("trace_date_ranges")
trace_date_ranges

# ## Trace value ranges
#
# The minimum and maximum values describe the numeric range in each sampled trace.

trace_value_ranges = read_eda01("trace_value_ranges")
trace_value_ranges

# The solar low-output summary includes the threshold and half-hourly window used for the count.

solar_midday_low_days = read_eda01("solar_midday_low_days")
solar_midday_low_days

# ## Demand trace example
#
# Demand traces use a different file family and schema from solar and wind traces. The metadata table records the file count, sample shape, and value-column span.

demand_sample_metadata = read_eda01("demand_sample_metadata")
demand_sample_metadata
