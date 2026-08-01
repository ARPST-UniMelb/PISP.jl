# # Hydro inflows and energy constraints
#
# Hydro source material spans bounded workbook assumptions and model CSVs.
# The workbook gives historical reference-year inflows for named schemes, while the model archive supplies daily natural inflows and annual energy limits used by the current ISP 2024 parser.
# The [2023 IASR, pp. 97–98](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=97) identifies the assumptions workbook as the source of monthly, annual, and seasonal inflow information for the represented hydro schemes.

using PISP
using CSV
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
const MODEL2024 = joinpath(ISP2024.download_root, "2024 ISP Model")
nothing #hide

# ## Workbook reference-year tables
#
# The 2024 sample combines public-domain interpretations for Blowering, Eucumbene, and Guthega and reports monthly values plus an annual total without restating a unit in the immediate table block.
# The 2026 workbook separates named schemes into their own blocks; the sample below begins with Blowering and labels the values in GL.

hydro_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Hydro Scheme Inflows",
    "B35:O40",
    [
        "Reference year", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan",
        "Feb", "Mar", "Apr", "May", "Jun", "Annual total",
    ],
)
PISPDocUtils.markdown_table(hydro_2024)
#-

hydro_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Hydro Scheme Inflows",
    "B11:O16",
    [
        "Reference year", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan",
        "Feb", "Mar", "Apr", "May", "Jun", "Annual total",
    ],
)
PISPDocUtils.markdown_table(hydro_2026)
#-

# ## Daily natural inflow CSV
#
# A representative model file contains one daily inflow value keyed by year, month, and day.
# Although its filename begins with `MonthlyNaturalInflow`, the records shown here are daily observations.
# The parser groups files to hydro generators through package mappings and aggregates the daily records into the required temporal representation.

natural_inflow_path = PISPDocUtils.first_matching_file(MODEL2024, r"^MonthlyNaturalInflow_Anthony_Pieman_.*\.csv$"i)
natural_inflow = CSV.read(natural_inflow_path, DataFrame)
natural_inflow_preview = first(natural_inflow, 5)
PISPDocUtils.markdown_table(natural_inflow_preview)
#-

natural_inflow_profile = DataFrame([
    (property = "Source file", value = PISPDocUtils.compact_path(natural_inflow_path, MODEL2024)),
    (property = "Rows", value = string(nrow(natural_inflow))),
    (property = "Columns", value = join(names(natural_inflow), ", ")),
])
PISPDocUtils.markdown_table(natural_inflow_profile)
#-

# ## Annual energy-limit CSV
#
# The annual file uses one year key followed by named hydro constraints.
# These limits are distinct from the daily inflow series and are joined to generators through maintained hydro-constraint mappings.

annual_energy_path = PISPDocUtils.first_matching_file(MODEL2024, r"^MaxEnergyYear_.*\.csv$"i)
annual_energy = CSV.read(annual_energy_path, DataFrame)
annual_energy_preview = first(select(annual_energy, 1:6), 5)
PISPDocUtils.markdown_table(annual_energy_preview)
#-

annual_energy_profile = DataFrame([
    (property = "Source file", value = PISPDocUtils.compact_path(annual_energy_path, MODEL2024)),
    (property = "Rows", value = string(nrow(annual_energy))),
    (property = "Columns", value = string(ncol(annual_energy))),
])
PISPDocUtils.markdown_table(annual_energy_profile)
#-

# ## Package hydro conventions
#
# PISP maintains file assignments, energy-constraint assignments, scenario mappings, dam shares, and scheme groups for ISP 2024.
# These objects encode package decisions and relationships that are not supplied as one ready-made AEMO table.

hydro_conventions = DataFrame([
    (object = "PISP.HYDRO2FILE", role = "Generator-to-natural-inflow file assignments", entries = length(PISP.HYDRO2FILE)),
    (object = "PISP.HYDRO2CNS", role = "Generator-to-energy-constraint assignments", entries = length(PISP.HYDRO2CNS)),
    (object = "PISP.HYDROSCE", role = "PISP scenario to model hydro scenario", entries = length(PISP.HYDROSCE)),
    (object = "PISP.SNOWY_HYDRO_GROUPS", role = "Grouped Snowy scheme units", entries = length(PISP.SNOWY_HYDRO_GROUPS)),
])
PISPDocUtils.markdown_table(hydro_conventions)
#-

# This page covers bounded hydro inputs required by the parser, not the bulk renewable or demand trace payloads.
# ISP 2026 workbook inflows are observed source evidence and are not presented as an integrated PISP 2026 hydro workflow.
