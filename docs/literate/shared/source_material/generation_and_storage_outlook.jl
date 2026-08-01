# # Generation and storage outlook
#
# AEMO publishes one generation and storage outlook workbook for each core scenario and sensitivity.
# The workbooks contain capacity, storage energy, storage power, REZ build, retirement, and other result tables across financial years.

using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const CORE2024 = joinpath(ISP2024.download_root, "Core")
const SENS2024 = joinpath(ISP2024.download_root, "Sensitivities")
const CORE2026 = joinpath(ISP2026.download_root, "Core scenarios")
const SENS2026 = joinpath(ISP2026.download_root, "Sensitivities")
const SAMPLE2024 = joinpath(CORE2024, "2024 ISP - Green Energy Exports - Core.xlsx")
const SAMPLE2026 = joinpath(CORE2026, "2026 ISP - Accelerated Transition - Core.xlsx")
nothing #hide

# ## Publication inventory
#
# The two editions retain the core-plus-sensitivity packaging pattern, but the case names and workbook counts differ.

outlook_inventory = vcat(
    PISPDocUtils.directory_workbook_inventory(CORE2024, "2024"),
    PISPDocUtils.directory_workbook_inventory(SENS2024, "2024"),
    PISPDocUtils.directory_workbook_inventory(CORE2026, "2026"),
    PISPDocUtils.directory_workbook_inventory(SENS2026, "2026"),
)
outlook_summary = combine(
    groupby(outlook_inventory, [:edition, :group]),
    nrow => :workbooks,
    :worksheet_count => minimum => :minimum_worksheets,
    :worksheet_count => maximum => :maximum_worksheets,
)
sort!(outlook_summary, [:edition, :group])
PISPDocUtils.markdown_table(outlook_summary)
#-

# ## Shared result subjects
#
# Representative core workbooks in both editions contain the main capacity, storage, REZ, and retirement subjects.
# Worksheet presence does not guarantee identical fields or interpretation.

outlook_sheet_presence = PISPDocUtils.worksheet_presence(
    ["ISP 2024" => SAMPLE2024, "ISP 2026" => SAMPLE2026],
    ["Capacity", "Storage Capacity", "Storage Energy", "REZ Generation Capacity", "Retirements"],
)
PISPDocUtils.markdown_table(outlook_sheet_presence)
#-

# ## Capacity table structure
#
# The capacity worksheet is a long table keyed by cost-development path, region, subregion, and technology, followed by financial-year values.
# The later sample starts in 2025-26 and retains the same leading keys before its financial-year values.

capacity_2024 = PISPDocUtils.cells_table(
    SAMPLE2024,
    "Capacity",
    "A4:H8",
    ["CDP", "Region", "Subregion", "Technology", "2023-24", "2024-25", "2025-26", "2026-27"],
)
PISPDocUtils.markdown_table(capacity_2024)
#-

capacity_2026 = PISPDocUtils.cells_table(
    SAMPLE2026,
    "Capacity",
    "A4:H8",
    ["CDP", "Region", "Subregion", "Technology", "2025-26", "2026-27", "2027-28", "2028-29"],
)
PISPDocUtils.markdown_table(capacity_2026)
#-

# ## Storage table structure
#
# Storage power remains in MW and storage energy remains in GWh.
# Category labels changed: ISP 2026 distinguishes utility-scale storage depths explicitly and updates the planning-year window.

storage_capacity_2024 = PISPDocUtils.cells_table(
    SAMPLE2024,
    "Storage Capacity",
    "A4:H8",
    ["CDP", "Region", "Subregion", "Storage category", "2024-25", "2025-26", "2026-27", "2027-28"],
)
PISPDocUtils.markdown_table(storage_capacity_2024)
#-

storage_capacity_2026 = PISPDocUtils.cells_table(
    SAMPLE2026,
    "Storage Capacity",
    "A4:H8",
    ["CDP", "Region", "Subregion", "Storage category", "2026-27", "2027-28", "2028-29", "2029-30"],
)
PISPDocUtils.markdown_table(storage_capacity_2026)
#-

# ## PISP transformation status
#
# The current scraper reads the 2024 capacity, storage, and REZ worksheets and writes condensed `Auxiliary/` workbooks used by the ISP 2024 parser.
# Those intermediates are PISP-generated material, not AEMO source publications.
# No corresponding integrated ISP 2026 scraper-to-dataset workflow is claimed here.
