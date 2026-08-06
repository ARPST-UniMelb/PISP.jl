# # Electric vehicles
#
# The IASR electric-vehicle workbooks provide vehicle numbers, energy consumption, charging-mode shares, and weekday and weekend charging profiles.
# ParseISP combines the 2023 IASR workbook with ISP 2024 subregional demand allocation when it constructs the current EV demand representation.
# The [2023 IASR, p. 59](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=59) explains the earlier charging-profile categories, while the [2025 IASR, p. 94](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=94) defines the revised static and dynamic charging categories.

using ParseISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const EV_NUMBERS_2024 = ParseISP.source_spec(:ev_vehicle_numbers, 2024)
const EV_CHARGE_TYPES_2024 = ParseISP.source_spec(:ev_bev_phev_charge_type, 2024)
const EV2023 = ParseISP.source_path(ISP2024.download_root, EV_NUMBERS_2024)
const EV2025 = joinpath(ISP2026.download_root, "aemo-2025-iasr-ev-workbook.xlsx")
nothing #hide

# ## Workbook subjects
#
# Both workbooks retain BEV/PHEV consumption, charging shares, and static weekday and weekend profiles.
# The 2025 workbook adds a hybrid-vehicle numbers worksheet and revises the charging-mode taxonomy.

ev_sheets = [
    "BEV_Numbers", "PHEV_Numbers", "FCEV_Numbers", "ICE_Numbers", "Hybrid_Numbers",
    "BEV_PHEV_Consumption (GWh)", "BEV_PHEV_Charge_Type (%)",
    "BEV_PHEV_Profile_kW (Weekday)", "BEV_PHEV_Profile_kW (Weekend)",
]
ev_sheet_names = [
    ("2023 IASR", XLSX.openxlsx(EV2023) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
    ("2025 IASR", XLSX.openxlsx(EV2025) do workbook
        Set(XLSX.sheetnames(workbook))
    end),
]
ev_sheet_presence = DataFrame([
    (edition = edition, worksheet = sheet, present = sheet in available)
    for (edition, available) in ev_sheet_names
    for sheet in ev_sheets
])
ParseISPDocUtils.markdown_table(ev_sheet_presence)
#-

# ## Battery-electric vehicle numbers
#
# The samples use the first scenario and New South Wales block in each workbook.
# The planning years and scenario names shift between publications, so the values are not a like-for-like revision series without additional scenario interpretation.

bev_numbers_source_2024 = ParseISP.read_xlsx_rows(
    EV2023,
    EV_NUMBERS_2024;
    worksheet = "BEV_Numbers",
)
bev_2023 = DataFrame(
    bev_numbers_source_2024[8:14, 1:9],
    Symbol.(["Vehicle type", "2022-23", "2023-24", "2024-25", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(bev_2023)
#-

bev_2025 = DataFrame(
    XLSX.readdata(EV2025, "BEV_Numbers", "B8:J14"),
    Symbol.(["Vehicle type", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(bev_2025)
#-

# ## Hybrid vehicles in the later workbook
#
# The 2025 IASR publication adds projected hybrid stocks as a separate source family.
# The current ISP 2024 EV parser has no maintained output-field mapping for this worksheet.

hybrid_2025 = DataFrame(
    XLSX.readdata(EV2025, "Hybrid_Numbers", "B8:J14"),
    Symbol.(["Vehicle type", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(hybrid_2025)
#-

# ## Charging-mode changes
#
# The earlier source uses labels such as convenience, daytime, highway-fast, and nighttime charging.
# The later source uses unscheduled, public, off-peak-and-solar, and time-of-use categories, which changes the source vocabulary even where the workbook subject remains recognisable.

charge_type_source_2024 = ParseISP.read_xlsx_rows(EV2023, EV_CHARGE_TYPES_2024)
charge_type_2023 = DataFrame(
    charge_type_source_2024[11:14, 1:9],
    Symbol.(["Charging mode", "2022-23", "2023-24", "2024-25", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(charge_type_2023)
#-

charge_type_2025 = DataFrame(
    XLSX.readdata(EV2025, "BEV_PHEV_Charge_Type (%)", "B9:J14"),
    Symbol.(["Charging mode", "2025-26", "2026-27", "2027-28", "2028-29", "2029-30", "2030-31", "2031-32", "2032-33"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(charge_type_2025)
#-

# ## ParseISP output-field ownership
#
# The maintained mapping assigns four 2023 number worksheets to parsed output fields.
# Charging profiles, vehicle categories, state names, scenario names, bus IDs, and demand relationships use the additional package mappings listed in [AEMO ISP source coverage and ownership](coverage-and-ownership.md).

vehicle_number_mapping = getfield(ParseISP, :EV_2024_VEHICLE_NUMBER_VALUE_COLUMN_BY_SHEET)
ev_output_fields = DataFrame(
    source_worksheet = collect(keys(vehicle_number_mapping)),
    parsed_field = string.(collect(values(vehicle_number_mapping))),
)
ParseISPDocUtils.markdown_table(ev_output_fields)
#-

# The 2025 IASR workbook adds FCEV and hybrid vehicle families, annual
# consumption, and revised charging categories to the EV source structure.
