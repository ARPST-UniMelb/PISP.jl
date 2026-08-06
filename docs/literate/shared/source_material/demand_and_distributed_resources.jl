# # Demand and distributed resources
#
# The ISP inputs workbooks contain regional demand forecasts and supporting material for distributed energy resources, subregional allocation, and emerging loads.
# ISP 2026 expands this source family with dedicated data-centre and distribution-network worksheets.

using ParseISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const SUBREGIONAL_ALLOCATION_2024 = ParseISP.source_spec(:ev_subregional_demand_allocation, 2024)
const WORKBOOK2024 = ParseISP.source_path(ISP2024.download_root, SUBREGIONAL_ALLOCATION_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## Source-family presence
#
# Both workbooks contain demand forecasts, rooftop and non-scheduled PV, and embedded or aggregated storage material.
# The later edition adds dedicated data-centre, distribution-network, distribution-cost, and hybrid-site-limit subjects, while the 2024 workbook contains the subregional allocation table used by the current EV transformation.

demand_sheets = [
    "Demand and Energy Forecasts", "Rooftop PV", "PVNSG",
    "Embedded energy storages", "Aggregated energy storages",
    "Sub-regional demand allocation", "Data Centre Forecasts", "Distribution network",
    "Distribution cost forecasts", "Hybrid site limits",
]
demand_sheet_names = [
    ("ISP 2024", XLSX.openxlsx(WORKBOOK2024) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
    ("ISP 2026", XLSX.openxlsx(WORKBOOK2026) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
]
demand_sheet_presence = DataFrame([
    (edition = edition, worksheet = sheet, present = sheet in available)
    for (edition, available) in demand_sheet_names
    for sheet in demand_sheets
])
ParseISPDocUtils.markdown_table(demand_sheet_presence)
#-

# ## ISP 2024 subregional allocation
#
# The allocation table expresses a regional total as shares assigned to ISP subregions over time.
# ParseISP uses a later block of this worksheet to distribute EV demand to buses; the rows below illustrate the same source structure without reproducing the full transformation.

subregional_allocation_source_2024 = ParseISP.read_xlsx_rows(
    WORKBOOK2024,
    SUBREGIONAL_ALLOCATION_2024,
)
subregional_allocation_2024 = DataFrame(
    subregional_allocation_source_2024[6:10, 1:9],
    Symbol.([
        "Region or subregion", "2023-24", "2024-25", "2025-26", "2026-27",
        "2027-28", "2028-29", "2029-30", "2030-31",
    ]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(subregional_allocation_2024)
#-

# ## ISP 2026 data-centre demand
#
# The dedicated data-centre worksheet reports annual energy in TWh by NEM region and scenario.
# The sampled rows are from the Slower Growth scenario block.
# It separates an emerging load category that was not published as its own worksheet in the 2024 source set.

data_centres_2026 = DataFrame(
    XLSX.readdata(
        WORKBOOK2026,
        "Data Centre Forecasts",
        "B12:J16",
    ),
    Symbol.(["Region", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(data_centres_2026)
#-

# ## ISP 2026 distribution-network hosting material
#
# The distribution-network table reports provider coverage, solar-PV hosting capacity, battery-storage hosting capacity, and the near-term connection pipeline by ISP subregion.

distribution_network_2026 = DataFrame(
    XLSX.readdata(
        WORKBOOK2026,
        "Distribution network",
        "B20:G25",
    ),
    Symbol.([
        "ISP subregion", "Distribution network service provider", "Solar PV hosting (MW)",
        "Battery storage hosting (MW)", "Solar PV pipeline to 2029-30 (MW)",
        "Battery pipeline to 2029-30 (MW)",
    ]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(distribution_network_2026)
#-

# ## How the source material differs
#
# The ISP 2024 dataset builder derives demand-by-bus relationships from its generated demand table and separately applies the EV allocation workflow.
# ISP 2026 adds data-centre forecasts, distribution-network limits, rooftop-PV
# tables, and hybrid-site limits that require new source selections and mappings.
