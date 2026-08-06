# # ISP 2024 and ISP 2026 raw-source comparison
#
# The raw-source comparison tracks how AEMO's non-trace inputs changed before any ParseISP transformation.
# It is distinct from the model-archive comparison, which inventories archive packaging, and from ParseISP output-schema comparisons, which describe generated datasets.

using ParseISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const INPUTS_2024 = ParseISP.source_spec(:existing_generator_summary, 2024)
const EV_NUMBERS_2024 = ParseISP.source_spec(:ev_vehicle_numbers, 2024)
const WORKBOOK2024 = ParseISP.source_path(ISP2024.download_root, INPUTS_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
const EV2023 = ParseISP.source_path(ISP2024.download_root, EV_NUMBERS_2024)
const EV2025 = joinpath(ISP2026.download_root, "aemo-2025-iasr-ev-workbook.xlsx")
nothing #hide

# ## Publication scale
#
# The later inputs workbook is larger and contains more worksheets.
# The EV publication also gains one worksheet, while the outlook package keeps three core workbooks but reduces the supplied sensitivity count.

publication_inventory = ParseISPDocUtils.read_workbook_inventory([
    "ISP 2024 inputs and assumptions" => WORKBOOK2024,
    "ISP 2026 inputs and assumptions" => WORKBOOK2026,
    "2023 IASR EV" => EV2023,
    "2025 IASR EV" => EV2025,
])
ParseISPDocUtils.markdown_table(publication_inventory)
#-

outlook_inventory = vcat(
    ParseISPDocUtils.read_outlook_inventory(joinpath(ISP2024.download_root, "Core"), "2024"),
    ParseISPDocUtils.read_outlook_inventory(joinpath(ISP2024.download_root, "Sensitivities"), "2024"),
    ParseISPDocUtils.read_outlook_inventory(joinpath(ISP2026.download_root, "Core scenarios"), "2026"),
    ParseISPDocUtils.read_outlook_inventory(joinpath(ISP2026.download_root, "Sensitivities"), "2026"),
)
outlook_counts = combine(groupby(outlook_inventory, [:edition, :group]), nrow => :workbooks)
sort!(outlook_counts, [:edition, :group])
ParseISPDocUtils.markdown_table(outlook_counts)
#-

# ## Worksheet presence
#
# Some source subjects retain a recognisable worksheet, some move or change name, and some appear only in one edition.
# Presence alone is structural evidence; it does not prove that fields, units, or row meaning remain compatible.

comparison_sheets = [
    "Existing Gen Data Summary", "Generator Reliability Settings", "Retirement",
    "Network Capability", "Network capability", "Flow Path Augmentation options",
    "Flow path augmentation options", "Renewable Energy Zones", "Renewable energy zones",
    "Generation limits", "Coal Min Stable Level", "Min Up&Down Times", "DSP",
    "Hydro Scheme Inflows", "Data Centre Forecasts", "Distribution network", "Hybrid site limits",
]
comparison_sheet_names = [
    ("ISP 2024", XLSX.openxlsx(WORKBOOK2024) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
    ("ISP 2026", XLSX.openxlsx(WORKBOOK2026) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
]
worksheet_comparison = DataFrame([
    (edition = edition, worksheet = sheet, present = sheet in available)
    for (edition, available) in comparison_sheet_names
    for sheet in comparison_sheets
])
ParseISPDocUtils.markdown_table(worksheet_comparison)
#-

# ## Declared worksheet dimensions
#
# Workbook dimensions provide a bounded indication of source scale.
# They include stored cells and formatting, so they are useful for comparison but not a substitute for counting parsed records.

dimension_2024 = ParseISPDocUtils.read_sheet_dimensions(
    WORKBOOK2024,
    [
        "Scenarios", "Existing Gen Data Summary", "New Entrant Data Summary",
        "Generator Reliability Settings", "Retirement", "Network Capability",
        "Flow Path Augmentation options", "Renewable Energy Zones", "Maximum capacity",
        "Storage properties", "DSP", "Hydro Scheme Inflows",
    ],
)
dimension_2024.edition = fill("2024", nrow(dimension_2024))

dimension_2026 = ParseISPDocUtils.read_sheet_dimensions(
    WORKBOOK2026,
    [
        "Scenarios", "Existing Gen Data Summary", "New Entrant Data Summary",
        "Generator Reliability Settings", "Retirement", "Network capability",
        "Flow path augmentation options", "Renewable energy zones", "Maximum capacity",
        "Storage properties", "DSP", "Hydro Scheme Inflows",
    ],
)
dimension_2026.edition = fill("2026", nrow(dimension_2026))

source_dimensions = select(
    vcat(dimension_2024, dimension_2026),
    :edition,
    :worksheet,
    :workbook_declared_dimension,
)
ParseISPDocUtils.markdown_table(source_dimensions)
#-

# ## Semantic source-family changes
#
# The comparison below separates additions, removals, relocations, and schema
# changes. Parser work must follow the edition-specific keys, units, and table
# meanings rather than reuse a 2024 reader from the worksheet name alone.

source_family_changes = DataFrame([
    (
        family = "Scenarios and sensitivities",
        isp_2024 = "Green Energy Exports, Step Change, Progressive Change; 9 sensitivities",
        isp_2026 = "Accelerated Transition, Step Change, Slower Growth; 6 sensitivities",
        change = "Scenario set and sensitivity set changed",
    ),
    (
        family = "Existing generation",
        isp_2024 = "Station-level leading summary",
        isp_2026 = "Unit-level IASR IDs and status fields",
        change = "Keys and record granularity changed",
    ),
    (
        family = "Generator operation",
        isp_2024 = "Generation limits and Min Up&Down Times worksheets",
        isp_2026 = "Coal Min Stable Level; no directly named Min Up&Down Times sheet",
        change = "Source split or moved",
    ),
    (
        family = "Generator reliability",
        isp_2024 = "Technology rows with full and partial outage fields",
        isp_2026 = "Property-by-year rows with long-duration separation",
        change = "Schema and time dimension changed",
    ),
    (
        family = "Network and transmission",
        isp_2024 = "Seasonal limits, reliability columns, and 2023-dollar augmentation costs",
        isp_2026 = "Revised limits, reliability event rows, and 2025-dollar augmentation costs",
        change = "Fields, values, and cost basis changed",
    ),
    (
        family = "Renewable energy zones",
        isp_2024 = "REZ, NTNDP, subregion, and cost-zone fields",
        isp_2026 = "Narrower leading REZ table; some retained IDs have new names",
        change = "Fields moved or removed; names changed",
    ),
    (
        family = "Demand and distributed resources",
        isp_2024 = "Demand, DER, and subregional allocation material",
        isp_2026 = "Adds data-centre, distribution-network, and hybrid-site worksheets",
        change = "New source families added",
    ),
    (
        family = "Demand-side participation",
        isp_2024 = "Scenario-region-season matrix blocks",
        isp_2026 = "Normalised region-price-scenario-season rows",
        change = "Table shape and keys changed",
    ),
    (
        family = "Electric vehicles",
        isp_2024 = "2023 IASR numbers, consumption, charging shares, and profiles",
        isp_2026 = "2025 IASR revises charging categories and adds hybrids",
        change = "Scenario years, vocabulary, and vehicle families changed",
    ),
    (
        family = "Hydro",
        isp_2024 = "Workbook reference years plus model inflow and energy-limit CSVs",
        isp_2026 = "Reorganised workbook scheme blocks",
        change = "Workbook organisation changed",
    ),
])
ParseISPDocUtils.markdown_table(source_family_changes; alignment = [:l, :l, :l, :l])
#-

# Detailed evidence is organised by subject under [AEMO ISP source material](../../shared/source-material/coverage-and-ownership.md).
# The [model archive comparison](model-archive-comparison.md) remains the authority for archive packaging, and the existing ParseISP dataset pages remain the authority for generated output schemas.
