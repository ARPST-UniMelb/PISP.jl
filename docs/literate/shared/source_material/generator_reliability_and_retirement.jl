# # Generator reliability and retirement
#
# Reliability assumptions describe the frequency, duration, and partial effect of outages.
# Retirement tables identify expected closure years, while PISP applies additional package-defined scenario schedules when generating ISP 2024 datasets.
# AEMO documents the earlier unplanned-outage assumptions in the [2023 IASR, pp. 90–93](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=90) and the revised long-duration and other unplanned-outage treatment in the [2025 IASR, pp. 122–125](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=122).

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const RELIABILITY_2024 = PISP.source_spec(:existing_generator_reliability, 2024)
const RETIREMENTS_2024 = PISP.source_spec(:generator_retirements, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, RELIABILITY_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## ISP 2024 reliability structure
#
# The 2024 table places full and partial outage rates, mean time to repair, and partial-outage derating in one technology-level block.
# PISP reads the existing and new-entrant blocks separately and maps them into generator and storage fields.

reliability_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, RELIABILITY_2024)
reliability_2024 = DataFrame(
    reliability_source_2024[2:9, 1:6],
    Symbol.([
        "Fuel or technology", "Full outage fraction", "Partial outage fraction",
        "Full-outage MTTR (h)", "Partial-outage MTTR (h)", "Partial derating factor",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(reliability_2024)
#-

# ## ISP 2026 reliability structure
#
# ISP 2026 separates long-duration outages from other unplanned outages and reports annual values across the planning horizon.
# That change is more than a renamed sheet: the source is now a property-by-year table.

long_duration_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Generator Reliability Settings", "B11:E16"),
    Symbol.(["Fuel or technology", "Property", "2025-26", "2026-27"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(long_duration_2026)
#-

other_outages_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Generator Reliability Settings", "B23:E29"),
    Symbol.(["Fuel or technology", "Property", "2025-26", "2026-27"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(other_outages_2026)
#-

# ## Expected closure years
#
# Both editions use unit identifiers, but ISP 2026 adds technology and status fields and revises some expected closure years.
# For example, the sampled Callide B records move from 2028 in the 2024 source to 2031 in the 2026 source.

retirement_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, RETIREMENTS_2024)
retirement_2024 = DataFrame(
    retirement_source_2024[2:10, 1:3],
    Symbol.(["Station", "DUID", "Expected closure year"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(retirement_2024)
#-

retirement_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Retirement", "B13:F20"),
    Symbol.(["IASR ID", "Station", "Technology", "Status", "Expected closure year"]);
    makeunique = true,
)
PISPDocUtils.markdown_table(retirement_2026)
#-

# ## Package-defined ISP 2024 schedules
#
# `Retirements2024` and `Reduction2024` are package conventions rather than AEMO workbook rows.
# They provide scenario-specific schedules used by the current dataset builder and are documented as transformations, not raw source facts.

retirement_conventions = DataFrame([
    (
        scenario_id = scenario_id,
        scenario = PISP.ID2SCE[scenario_id],
        retirement_stations = length(PISP.Retirements2024[scenario_id]),
        capacity_reduction_stations = length(PISP.Reduction2024[scenario_id]),
    )
    for scenario_id in sort(collect(keys(PISP.ID2SCE)))
])
PISPDocUtils.markdown_table(retirement_conventions)
#-
