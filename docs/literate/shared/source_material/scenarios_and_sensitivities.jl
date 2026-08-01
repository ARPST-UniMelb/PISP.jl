# # Scenarios and sensitivities
#
# AEMO's scenario workbooks describe alternative planning futures, while the generation and storage outlook workbooks provide one core result set per scenario and additional sensitivity cases.
# Scenario names changed between ISP 2024 and ISP 2026, so names alone do not establish semantic equivalence.
# AEMO describes Step Change as a refinement of the 2023 scenario with the same name ([2025 IASR, p. 18](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=18)), Slower Growth as the successor to Progressive Change ([p. 19](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=19)), and Accelerated Transition as a refinement of Green Energy Exports ([p. 20](../../../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=20)); this lineage does not imply unchanged assumptions or model inputs.

using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
all(isfile, (WORKBOOK2024, WORKBOOK2026)) || error("both selected ISP inputs workbooks are required")
nothing #hide

# ## ISP 2024 scenario framing
#
# ISP 2024 uses Green Energy Exports, Step Change, and Progressive Change.
# The source distinguishes these futures through demand drivers, energy efficiency, consumer participation, and other assumptions rather than through a single scalar ranking.
# AEMO's scenario worksheet embeds zero-width-space and soft-hyphen escape artifacts in several cells, both as literal escape text (e.g. the six characters backslash-u-2-0-0-b) and as the actual Unicode characters; `strip_scenario_marker` removes both forms so they don't leak into the rendered table.

strip_scenario_marker(value) = value
strip_scenario_marker(value::AbstractString) = strip(replace(
    value,
    "\\u200b" => "",
    "\\u00ad" => "",
    "\\uad" => "",
    Char(0x200b) => "",
    Char(0x00ad) => "",
))

scenario_2024 = DataFrame(
    XLSX.readdata(WORKBOOK2024, "Scenarios", "B6:E12"),
    Symbol.(["Parameter", "Green Energy Exports", "Step Change", "Progressive Change"]);
    makeunique = true,
)
for column in names(scenario_2024)
    scenario_2024[!, column] = strip_scenario_marker.(scenario_2024[!, column])
end
filter!(row -> any(value -> !ismissing(value), Tuple(row)[2:end]), scenario_2024)
PISPDocUtils.markdown_table(scenario_2024)
#-

# ## ISP 2026 scenario framing
#
# ISP 2026 uses Slower Growth, Step Change, and Accelerated Transition.
# Step Change is the only retained scenario name; even there, the surrounding assumptions and publication year differ, so direct reuse still requires semantic review.

scenario_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Scenarios", "B6:E12"),
    Symbol.(["Parameter", "Slower Growth", "Step Change", "Accelerated Transition"]);
    makeunique = true,
)
for column in names(scenario_2026)
    scenario_2026[!, column] = strip_scenario_marker.(scenario_2026[!, column])
end
filter!(row -> any(value -> !ismissing(value), Tuple(row)[2:end]), scenario_2026)
PISPDocUtils.markdown_table(scenario_2026)
#-

# ## Outlook workbook families
#
# The directory names orient readers to the publication structure: ISP 2024 uses `Core`, ISP 2026 uses `Core scenarios`, and both editions provide `Sensitivities`.
# Each workbook is a result package with many worksheets rather than a single flat table.

outlook_inventory = vcat(
    PISPDocUtils.read_outlook_inventory(joinpath(ISP2024.download_root, "Core"), "2024"),
    PISPDocUtils.read_outlook_inventory(joinpath(ISP2024.download_root, "Sensitivities"), "2024"),
    PISPDocUtils.read_outlook_inventory(joinpath(ISP2026.download_root, "Core scenarios"), "2026"),
    PISPDocUtils.read_outlook_inventory(joinpath(ISP2026.download_root, "Sensitivities"), "2026"),
)
outlook_counts = combine(groupby(outlook_inventory, [:edition, :group]), nrow => :workbooks)
sort!(outlook_counts, [:edition, :group])
PISPDocUtils.markdown_table(outlook_counts)
#-

outlook_cases = select(outlook_inventory, :edition, :group, :scenario_or_sensitivity)
PISPDocUtils.markdown_table(outlook_cases)
#-

# The 2024 set contains three core workbooks and nine sensitivities.
# The 2026 set contains three core workbooks and six sensitivities.
# Additions, removals, and renamed cases should be interpreted from their published assumptions, not inferred mechanically from similar filenames.
