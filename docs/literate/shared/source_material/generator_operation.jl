# # Generator operating assumptions
#
# AEMO provides minimum stable levels, minimum up/down times, and ramp limits for time-sequential modelling.
# These fields constrain how quickly thermal units can move and how low they can operate when committed.
# The [2023 IASR, pp. 88–89](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=88) describes the earlier operating assumptions, while the [2025 IASR, pp. 121–122](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=121) explains the later coal minimum-stable-level bands.

using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const WORKBOOK2019 = joinpath(ISP2024.download_root, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## Worksheet organisation changed
#
# ISP 2024 has a general `Generation limits` sheet and a separate minimum-up/down sheet.
# ISP 2026 replaces the coal section with `Coal Min Stable Level` and does not contain a worksheet named `Min Up&Down Times`.

sheet_names_2024 = Set(PISPDocUtils.sheet_names(WORKBOOK2024))
sheet_names_2026 = Set(PISPDocUtils.sheet_names(WORKBOOK2026))
operating_sheet_presence = DataFrame([
    (edition = "2024", worksheet = name, present = name in sheet_names_2024)
    for name in ("Generation limits", "Coal Min Stable Level", "GPG Min Stable Level", "Min Up&Down Times", "Max Ramp Rates")
])
append!(
    operating_sheet_presence,
    DataFrame([
        (edition = "2026", worksheet = name, present = name in sheet_names_2026)
        for name in ("Generation limits", "Coal Min Stable Level", "GPG Min Stable Level", "Min Up&Down Times", "Max Ramp Rates")
    ]),
)
PISPDocUtils.markdown_table(operating_sheet_presence)
#-

# ## Minimum stable levels
#
# The 2024 coal table uses station and unit identifiers with a single minimum-stable-level value.
# The 2026 coal table retains a backcast value and adds a typical lowest band, exposing a distinction that is absent from the earlier source table.

coal_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Generation limits",
    "B9:D14",
    ["Station", "Generating unit", "Minimum stable level (MW)"],
)
PISPDocUtils.markdown_table(coal_2024)
#-

coal_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Coal Min Stable Level",
    "B14:F20",
    ["IASR ID", "Station", "Technology", "IASR 2023 backcast (MW)", "Typical lowest band (MW)"],
)
PISPDocUtils.markdown_table(coal_2026)
#-

# Gas-powered generation remains a unit-level table in both editions, but ISP 2026 uses IASR IDs and revised technology labels.

gpg_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "GPG Min Stable Level",
    "B10:E15",
    ["Station", "Generating unit", "Technology", "Minimum stable level (MW)"],
)
PISPDocUtils.markdown_table(gpg_2024)
#-

gpg_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "GPG Min Stable Level",
    "B12:E18",
    ["IASR ID", "Station", "Technology", "Minimum stable level (MW)"],
)
PISPDocUtils.markdown_table(gpg_2026)
#-

# ## Minimum up/down times
#
# The current PISP parser uses the 2024 sheet and supplements it with unit values from the 2019 workbook.
# Because ISP 2026 does not contain a directly corresponding worksheet, an updated implementation would require manual source and semantic review rather than a sheet-name substitution.

minimum_up_down_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Min Up&Down Times",
    "B9:E15",
    ["Station", "Generating unit", "Technology", "Minimum up/down time (h)"],
)
PISPDocUtils.markdown_table(minimum_up_down_2024)
#-

minimum_up_2019 = PISPDocUtils.cells_table(
    WORKBOOK2019,
    "Generation limits",
    "O10:Q16",
    ["Station", "Generating unit", "Minimum up time (h)"],
)
PISPDocUtils.markdown_table(minimum_up_2019)
#-

# ## Ramp rates
#
# ISP 2026 retains separate maximum ramp-up and ramp-down values and explicitly marks some reciprocating-engine records as sufficiently high rather than assigning a numeric limit.

ramp_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Max Ramp Rates",
    "B9:F15",
    ["Station", "Generating unit", "Technology", "Ramp up (MW/min)", "Ramp down (MW/min)"],
)
PISPDocUtils.markdown_table(ramp_2024)
#-

ramp_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Max Ramp Rates",
    "B9:F15",
    ["IASR ID", "Station", "Technology", "Ramp up (MW/min)", "Ramp down (MW/min)"],
)
PISPDocUtils.markdown_table(ramp_2026)
#-
