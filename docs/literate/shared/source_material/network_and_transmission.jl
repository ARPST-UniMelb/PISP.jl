# # Network and transmission assumptions
#
# AEMO publishes seasonal flow-path capability, transmission reliability, and candidate augmentation options as related but distinct source subjects.
# The capability tables describe transfer approximations under system conditions; the reliability tables describe outage behaviour; the augmentation tables describe possible future changes.

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

include(joinpath(REPO_ROOT, "docs", "source_material_support.jl"))
using .PISPDocsSourceMaterialSupport

const ISP2024 = edition_profile(REPO_ROOT, "2024")
const ISP2026 = edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## Seasonal flow-path capability
#
# Both editions publish forward and reverse capability approximations for peak demand, summer typical, and winter reference conditions.
# ISP 2026 also places a notes field beside the dominant constraints and revises several sampled limits, so an implementation cannot substitute the later sheet solely by matching flow-path names.

capability_2024 = cells_table(
    WORKBOOK2024,
    "Network Capability",
    "B8:J12",
    [
        "Flow path", "Forward peak (MW)", "Forward summer (MW)", "Forward winter (MW)",
        "Reverse peak (MW)", "Reverse summer (MW)", "Reverse winter (MW)",
        "Forward constraint", "Reverse constraint",
    ],
)
markdown_table(capability_2024)
#-

capability_2026 = cells_table(
    WORKBOOK2026,
    "Network capability",
    "B8:K12",
    [
        "Flow path", "Forward peak (MW)", "Forward summer (MW)", "Forward winter (MW)",
        "Reverse peak (MW)", "Reverse summer (MW)", "Reverse winter (MW)",
        "Forward constraint", "Reverse constraint", "Notes",
    ],
)
capability_2026.Notes = coalesce.(capability_2026.Notes, "Not reported")
markdown_table(capability_2026)
#-

# ## Transmission reliability
#
# ISP 2024 represents credible-contingency and reclassification outage rates in separate columns.
# ISP 2026 instead uses separate rows for those event types and one unplanned-outage-rate field, with mean time to repair beside it.

transmission_reliability_2024 = cells_table(
    WORKBOOK2024,
    "Transmission Reliability",
    "B8:G11",
    [
        "Line or flow path", "Implementation", "Credible-contingency outage rate",
        "Reclassification outage rate", "Credible-contingency MTTR", "Reclassification MTTR",
    ],
)
markdown_table(transmission_reliability_2024)
#-

transmission_reliability_2026 = cells_table(
    WORKBOOK2026,
    "Transmission Reliability",
    "B8:E13",
    ["Line or flow path and event", "Implementation", "Unplanned outage rate (%)", "Mean time to repair"],
)
markdown_table(transmission_reliability_2026)
#-

# ## Candidate augmentation options
#
# The augmentation workbooks retain option names, directional transfer increases, costs, easement length, and lead time.
# The cost basis changes from 2023 dollars to 2025 dollars, and ISP 2026 adds prerequisite and notes fields around the option record.

augmentation_2024 = cells_table(
    WORKBOOK2024,
    "Flow Path Augmentation options",
    "B13:N14",
    [
        "Flow path", "Option", "Power-flow direction", "Forward increase (MW)",
        "Reverse increase (MW)", "Indicative cost (\$2023 million)", "Easement (km)", "Lead time",
    ];
    columns = [1, 4, 6, 7, 8, 9, 12, 13],
)
fill_down!(augmentation_2024, [Symbol("Flow path"), Symbol("Power-flow direction")])
markdown_table(augmentation_2024)
#-

augmentation_2026 = cells_table(
    WORKBOOK2026,
    "Flow path augmentation options",
    "B14:Q15",
    [
        "Flow path", "Option", "Power-flow direction", "Forward increase (MW)",
        "Reverse increase (MW)", "Indicative cost (\$2025 million)", "Easement (km)",
        "Lead time", "Additional REZ capacity", "Notes",
    ];
    columns = [1, 4, 7, 8, 9, 10, 13, 14, 15, 16],
)
fill_down!(augmentation_2026, [Symbol("Flow path"), Symbol("Power-flow direction")])
augmentation_2026.Notes = coalesce.(augmentation_2026.Notes, "Not reported")
markdown_table(augmentation_2026)
#-

# Flow-path and direction labels are merged across option rows in the source workbooks.
# The displayed samples fill those identifiers down for readability and show blank notes as `Not reported`.
#

# ## PISP network geography
#
# PISP applies maintained subregion names and subregion-to-NEM-region mappings when it builds the ISP 2024 network model.
# These dictionaries are package conventions rather than extra AEMO workbook rows.

network_geography = DataFrame(
    isp_subregion = collect(keys(PISP.NEMBUSNAME)),
    pisp_name = collect(values(PISP.NEMBUSNAME)),
    nem_region = [PISP.BUS2AREA[key] for key in keys(PISP.NEMBUSNAME)],
)
markdown_table(network_geography)
#-

# PISP currently implements these selections for ISP 2024.
# The ISP 2026 evidence above identifies source changes that require a reviewed parser design before they can define a 2026 dataset.
