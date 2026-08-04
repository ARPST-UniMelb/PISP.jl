# # Hydro inflows and energy constraints
#
# Hydro source material spans bounded workbook assumptions and model CSVs.
# The workbook gives historical reference-year inflows for named schemes, while the model archive supplies daily natural inflows and annual energy limits used by the current ISP 2024 parser.
# The [2023 IASR, pp. 97–98](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=97) identifies the assumptions workbook as the source of monthly, annual, and seasonal inflow information for the represented hydro schemes.

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const HYDRO_INFLOWS_2024 = PISP.source_spec(:hydro_scheme_inflows, 2024)
const HYDRO_NATURAL_INFLOW_2024 = PISP.source_spec(:hydro_natural_inflow_trace, 2024)
const HYDRO_ANNUAL_ENERGY_2024 = PISP.source_spec(:hydro_annual_energy_limit_trace, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, HYDRO_INFLOWS_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
const MODEL2024 = joinpath(ISP2024.download_root, "2024 ISP Model")
nothing #hide

# ## Workbook reference-year tables
#
# The 2024 PISP source selection combines public-domain interpretations for Blowering, Eucumbene, and Guthega and reads the monthly values used by the current parser.
# The 2026 workbook separates named schemes into their own blocks; the sample below begins with Blowering, labels the values in GL, and includes the published annual total.

hydro_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, HYDRO_INFLOWS_2024)
hydro_2024 = DataFrame(
    hydro_source_2024[2:7, 1:13],
    Symbol.([
        "Reference year", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan",
        "Feb", "Mar", "Apr", "May", "Jun",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(hydro_2024)
#-

hydro_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Hydro Scheme Inflows", "B11:O16"),
    Symbol.([
        "Reference year", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan",
        "Feb", "Mar", "Apr", "May", "Jun", "Annual total",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(hydro_2026)
#-

# ## Daily natural inflow CSV
#
# A representative model file contains one daily inflow value keyed by year, month, and day.
# Although its filename begins with `MonthlyNaturalInflow`, the records shown here are daily observations.
# The parser groups files to hydro generators through package mappings and aggregates the daily records into the required temporal representation.

natural_inflow_path = PISP.source_path(
    MODEL2024,
    HYDRO_NATURAL_INFLOW_2024;
    scenario = "Step Change",
    file_name = "MonthlyNaturalInflow_Anthony_Pieman_RefYear4006",
    hydro_scenario = "StepChange",
)
natural_inflow = PISP.read_csv_source(natural_inflow_path, HYDRO_NATURAL_INFLOW_2024)
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

annual_energy_path = PISP.source_path(
    MODEL2024,
    HYDRO_ANNUAL_ENERGY_2024;
    scenario = "Step Change",
    file_name = "MaxEnergyYear_LT_RefYear4006",
    hydro_scenario = "StepChange",
)
annual_energy = PISP.read_csv_source(annual_energy_path, HYDRO_ANNUAL_ENERGY_2024)
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

# These selections cover the bounded hydro inputs used by the parser; bulk
# renewable and demand traces are described under trace coverage.
# The ISP 2026 workbook reorganises scheme inflows and must be read with its
# edition-specific row groups and reference-year columns.
