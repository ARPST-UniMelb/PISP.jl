# # Existing generation and storage
#
# The inputs workbooks describe existing generation, committed and anticipated projects, storage technology properties, and source identifiers used elsewhere in the ISP material.
# ISP 2024 presents the main generation summary at station level, whereas ISP 2026 exposes unit-level IASR identifiers in the corresponding summary.

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

include(joinpath(REPO_ROOT, "docs", "source_material_support.jl"))
using .PISPDocsSourceMaterialSupport

const ISP2024 = edition_profile(REPO_ROOT, "2024")
const ISP2026 = edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## ISP 2024 station-level summary
#
# Each row below represents a station and combines location, technology, maximum capacity, and seasonal ratings.
# PISP uses this source with `Summary Mapping`, maximum-capacity, emissions, reliability, and package mappings to construct unit-level generator records.

existing_2024 = cells_table(
    WORKBOOK2024,
    "Existing Gen Data Summary",
    "B13:K18",
    [
        "Station", "Generator type", "Region", "ISP sub-region", "REZ", "Fuel/technology",
        "Maximum capacity (MW)", "Summer peak (MW)", "Summer typical (MW)", "Winter (MW)",
    ],
)
markdown_table(existing_2024)
#-

# ## ISP 2026 unit-level summary
#
# The later workbook places IASR IDs and project status directly beside station and technology fields.
# Bayswater therefore appears as four records rather than one station aggregate.

existing_2026 = cells_table(
    WORKBOOK2026,
    "Existing Gen Data Summary",
    "B13:Q18",
    [
        "IASR ID", "Station", "Technology", "Fuel", "Region", "ISP sub-region", "REZ", "Cost zone",
        "Status", "Storage capacity", "Maximum capacity (MW)", "Minimum load", "Summer peak (MW)",
        "Summer typical (MW)", "Winter (MW)", "Minimum stable level (MW)",
    ];
    columns = collect(1:16),
)
markdown_table(existing_2026)
#-

# ## Storage technology properties
#
# ISP 2024 organises battery durations as columns and properties as rows.
# ISP 2026 uses one row per technology, adds compressed air and separate coordinated-CER categories, and reports energy capacity as hours for a 1 MW reference power.
# A blank ISP 2024 source cell is shown as `Not reported` rather than as a Julia missing-value marker.

storage_2024 = cells_table(
    WORKBOOK2024,
    "Storage properties",
    "B5:H13",
    ["Property", "Battery 1 h", "Battery 2 h", "Battery 4 h", "Battery 8 h", "VPP", "Units"],
)
for column in names(storage_2024)
    storage_2024[!, column] = coalesce.(storage_2024[!, column], "Not reported")
end
markdown_table(storage_2024)
#-

storage_2026 = cells_table(
    WORKBOOK2026,
    "Storage properties",
    "B6:I13",
    [
        "Technology", "Maximum power (MW)", "Energy capacity (h)", "Charge efficiency (%)",
        "Discharge efficiency (%)", "Maximum state of charge (%)", "Minimum state of charge (%)",
        "Round-trip efficiency (%)",
    ],
)
markdown_table(storage_2026)
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
markdown_table(package_collections)
#-

# PISP currently implements the ISP 2024 transformation path.
# The ISP 2026 tables above are observed source evidence and do not imply an integrated 2026 PISP dataset builder.
