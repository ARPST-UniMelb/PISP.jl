# # Network and transmission assumptions
#
# AEMO publishes seasonal flow-path capability, transmission reliability, and candidate augmentation options as related but distinct source subjects.
# The capability tables describe transfer approximations under system conditions; the reliability tables describe outage behaviour; the augmentation tables describe possible future changes.

using ParseISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const NETWORK_CAPABILITY_2024 = ParseISP.source_spec(:network_capability, 2024)
const TRANSMISSION_RELIABILITY_2024 = ParseISP.source_spec(:transmission_reliability, 2024)
const AUGMENTATION_OPTIONS_2024 = ParseISP.source_spec(:flow_path_augmentation_options, 2024)
const WORKBOOK2024 = ParseISP.source_path(ISP2024.download_root, NETWORK_CAPABILITY_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## Seasonal flow-path capability
#
# Both editions publish forward and reverse capability approximations for peak demand, summer typical, and winter reference conditions.
# The ParseISP 2024 source selection contains the flow-path identifier and six capability fields.
# ISP 2026 also places dominant constraints and a notes field beside those values and revises several sampled limits, so an implementation cannot substitute the later sheet solely by matching flow-path names.
# The 2024 workbook's flow-path column embeds a stray soft-hyphen character in one row, which the sample below strips before display.

capability_source_2024 = ParseISP.read_xlsx_rows(WORKBOOK2024, NETWORK_CAPABILITY_2024)
capability_2024 = DataFrame(
    capability_source_2024[3:7, 1:7],
    Symbol.([
        "Flow path", "Forward peak (MW)", "Forward summer (MW)", "Forward winter (MW)",
        "Reverse peak (MW)", "Reverse summer (MW)", "Reverse winter (MW)",
    ]);
    makeunique = true,
)
capability_2024[!, Symbol("Flow path")] = replace.(capability_2024[!, Symbol("Flow path")], "\\uad" => "", Char(0x00ad) => "")
ParseISPDocUtils.markdown_table(capability_2024)
#-

capability_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Network capability", "B8:K12"),
    Symbol.([
        "Flow path", "Forward peak (MW)", "Forward summer (MW)", "Forward winter (MW)",
        "Reverse peak (MW)", "Reverse summer (MW)", "Reverse winter (MW)",
        "Forward constraint", "Reverse constraint", "Notes",
    ]);
    makeunique = true,
)
capability_2026.Notes = coalesce.(capability_2026.Notes, "Not reported")
ParseISPDocUtils.markdown_table(capability_2026)
#-

# ## Transmission reliability
#
# ISP 2024 represents credible-contingency and reclassification outage rates in separate columns.
# ISP 2026 instead uses separate rows for those event types and one unplanned-outage-rate field, with mean time to repair beside it.

transmission_reliability_source_2024 = ParseISP.read_xlsx_rows(
    WORKBOOK2024,
    TRANSMISSION_RELIABILITY_2024,
)
transmission_reliability_2024 = DataFrame(
    transmission_reliability_source_2024[2:5, 1:6],
    Symbol.([
        "Line or flow path", "Implementation", "Credible-contingency outage rate",
        "Reclassification outage rate", "Credible-contingency MTTR", "Reclassification MTTR",
    ]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(transmission_reliability_2024)
#-

transmission_reliability_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Transmission Reliability", "B8:E13"),
    Symbol.(["Line or flow path and event", "Implementation", "Unplanned outage rate (%)", "Mean time to repair"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(transmission_reliability_2026)
#-

# ## Candidate augmentation options
#
# The augmentation workbooks retain option names, directional transfer increases, costs, easement length, and lead time.
# The cost basis changes from 2023 dollars to 2025 dollars, and ISP 2026 adds prerequisite and notes fields around the option record.

augmentation_source_2024 = ParseISP.read_xlsx_rows(WORKBOOK2024, AUGMENTATION_OPTIONS_2024)
augmentation_2024 = DataFrame(
    augmentation_source_2024[3:4, [1, 4, 6, 7, 8, 9, 12, 13]],
    Symbol.([
        "Flow path", "Option", "Power-flow direction", "Forward increase (MW)",
        "Reverse increase (MW)", "Indicative cost (\$2023 million)", "Easement (km)", "Lead time",
    ]);
    makeunique = true,
)
ParseISPDocUtils.fill_down!(augmentation_2024, [Symbol("Flow path"), Symbol("Power-flow direction")])
ParseISPDocUtils.markdown_table(augmentation_2024)
#-

augmentation_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Flow path augmentation options", "B14:Q15")[:, [1, 4, 7, 8, 9, 10, 13, 14, 15, 16]],
    Symbol.([
        "Flow path", "Option", "Power-flow direction", "Forward increase (MW)",
        "Reverse increase (MW)", "Indicative cost (\$2025 million)", "Easement (km)",
        "Lead time", "Additional REZ capacity", "Notes",
    ]);
    makeunique = true,
)
ParseISPDocUtils.fill_down!(augmentation_2026, [Symbol("Flow path"), Symbol("Power-flow direction")])
augmentation_2026.Notes = coalesce.(augmentation_2026.Notes, "Not reported")
ParseISPDocUtils.markdown_table(augmentation_2026)
#-

# Flow-path and direction labels are merged across option rows in the source workbooks.
# The displayed samples fill those identifiers down for readability and show blank notes as `Not reported`.
#

# ## ParseISP network geography
#
# ParseISP applies maintained subregion names and subregion-to-NEM-region mappings when it builds the ISP 2024 network model.
# These dictionaries are package conventions rather than extra AEMO workbook rows.

network_geography = DataFrame(
    isp_subregion = collect(keys(ParseISP.NEMBUSNAME)),
    pisp_name = collect(values(ParseISP.NEMBUSNAME)),
    nem_region = [ParseISP.BUS2AREA[key] for key in keys(ParseISP.NEMBUSNAME)],
)
ParseISPDocUtils.markdown_table(network_geography)
#-

# ParseISP currently implements these selections for ISP 2024.
# The ISP 2026 evidence above identifies source changes that require a reviewed parser design before they can define a 2026 dataset.
