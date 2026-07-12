# # Assessing temperature-related information and climate-zone variation
#
# Temperature can affect demand, renewable output, thermal ratings, and equipment reliability, but those effects are not automatically represented by a planning dataset. This page presents temperature- or reliability-related workbook material, fields exported by PISP, and summer solar summaries for selected climate-zone proxies.
#
# No observed temperature time series is loaded, and no causal temperature-response model is estimated.
# Climate-zone comparisons are descriptive solar-trace comparisons, not direct measurements of thermal derating.

using CSV
using DataFrames

const EDA05_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "05_temperature_analysis",
)

function read_eda05(table_name)
    path = joinpath(EDA05_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda05(table; rows = 16) = first(table, min(rows, nrow(table)))

# ## What relevant workbook material exists?
#
# The sheet inventory records keyword matches and the shapes of potentially relevant worksheets.
# A keyword match identifies material for review; it does not prove that the sheet contains a usable temperature dependency.

workbook_sheet_inventory = read_eda05("workbook_sheet_inventory")
preview_eda05(workbook_sheet_inventory; rows = 24)

workbook_relevant_sheet_shapes = read_eda05("workbook_relevant_sheet_shapes")
workbook_relevant_sheet_shapes

workbook_rooftop_sheet_summary = read_eda05("workbook_rooftop_sheet_summary")
workbook_rooftop_sheet_summary

workbook_reliability_sheet_shapes = read_eda05("workbook_reliability_sheet_shapes")
workbook_reliability_sheet_shapes

# ## What temperature-related fields reach the output dataset?
#
# The output inventory and generator-column table distinguish information present in the downloaded workbook from fields exported by PISP.

pisp_output_inventory = read_eda05("pisp_output_inventory")
pisp_output_inventory

generator_temperature_columns = read_eda05("generator_temperature_columns")
generator_temperature_columns

# Solar and wind generator details provide the static reliability and capacity fields available for later modelling.
# Their presence should not be interpreted as a temperature-dependent outage or derating process.

generator_solar_wind_details = read_eda05("generator_solar_wind_details")
preview_eda05(generator_solar_wind_details; rows = 20)

# ## How do selected climate-zone solar traces differ?
#
# The zone labels are analytical groupings attached to representative sites.
# The summary describes summer solar capacity-factor distributions and does not isolate temperature from cloud, season, geography, or trace construction.

climate_zone_summer_cf_summary = read_eda05("climate_zone_summer_cf_summary")
climate_zone_summer_cf_summary
