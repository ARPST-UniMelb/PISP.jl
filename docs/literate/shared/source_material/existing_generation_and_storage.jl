# # Existing generation and storage
#
# The inputs workbooks describe existing generation, committed and anticipated projects, storage technology properties, and source identifiers used elsewhere in the ISP material.
# ISP 2024 presents the main generation summary at station level, whereas ISP 2026 exposes unit-level IASR identifiers in the corresponding summary.

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const EXISTING_GENERATORS_2024 = PISP.source_spec(:existing_generator_summary, 2024)
const STORAGE_PROPERTIES_2024 = PISP.source_spec(:bess_storage_properties, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, EXISTING_GENERATORS_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## ISP 2024 station-level summary
#
# Each row below represents a station and combines location, technology, maximum capacity, and seasonal ratings.
# PISP uses this source with `Summary Mapping`, maximum-capacity, emissions, reliability, and package mappings to construct unit-level generator records.

existing_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, EXISTING_GENERATORS_2024)
existing_2024 = DataFrame(
    existing_source_2024[4:9, 1:10],
    Symbol.([
        "Station", "Generator type", "Region", "ISP sub-region", "REZ", "Fuel/technology",
        "Maximum capacity (MW)", "Summer peak (MW)", "Summer typical (MW)", "Winter (MW)",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(existing_2024)
#-

# ## ISP 2026 unit-level summary
#
# The later workbook places IASR IDs and project status directly beside station and technology fields.
# Bayswater therefore appears as four records rather than one station aggregate.

existing_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Existing Gen Data Summary", "B13:Q18"),
    Symbol.([
        "IASR ID", "Station", "Technology", "Fuel", "Region", "ISP sub-region", "REZ", "Cost zone",
        "Status", "Storage capacity", "Maximum capacity (MW)", "Minimum load", "Summer peak (MW)",
        "Summer typical (MW)", "Winter (MW)", "Minimum stable level (MW)",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(existing_2026)
#-

# ## Storage technology properties
#
# ISP 2024 organises battery durations as columns and properties as rows.
# ISP 2026 uses one row per technology, adds compressed air and separate coordinated-CER categories, and reports energy capacity as hours for a 1 MW reference power.
# A blank ISP 2024 source cell is shown as `Not reported` rather than as a Julia missing-value marker.

storage_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, STORAGE_PROPERTIES_2024)
storage_2024 = DataFrame(
    storage_source_2024[2:10, 1:7],
    Symbol.(["Property", "Battery 1 h", "Battery 2 h", "Battery 4 h", "Battery 8 h", "VPP", "Units"]);
    makeunique = true,
)
for column in names(storage_2024)
    storage_2024[!, column] = coalesce.(storage_2024[!, column], "Not reported")
end
PISPDocUtils.markdown_table(storage_2024)
#-

storage_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Storage properties", "B6:I13"),
    Symbol.([
        "Technology", "Maximum power (MW)", "Energy capacity (h)", "Charge efficiency (%)",
        "Discharge efficiency (%)", "Maximum state of charge (%)", "Minimum state of charge (%)",
        "Round-trip efficiency (%)",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(storage_2026)
#-

# ## PISP conventions applied after source reading
#
# The current package includes maintained generator, battery, and pumped-hydro dictionaries.
# These objects are package conventions and supplements; they are not additional AEMO source rows.

package_collections = DataFrame([
    (collection = "Generator unit mappings", object = "PISP.units", entries = length(PISP.units)),
    (collection = "Battery defaults", object = "PISP.databess", entries = length(PISP.databess)),
    (collection = "Pumped-hydro defaults", object = "PISP.dataps", entries = length(PISP.dataps)),
])
PISPDocUtils.markdown_table(package_collections)
#-

# PISP currently implements the ISP 2024 transformation path.
# The ISP 2026 tables above are observed source evidence and do not imply an integrated 2026 PISP dataset builder.
