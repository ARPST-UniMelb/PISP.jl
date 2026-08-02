# # Demand-side participation
#
# Demand-side participation assumptions quantify response at price bands and at reliability-response conditions.
# The two editions publish the same broad subject through different table organisations.

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const DSP_2024 = PISP.source_spec(:dsp_green_energy_exports_nsw_summer, 2024)
const WORKBOOK2024 = PISP.source_path(ISP2024.download_root, DSP_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## ISP 2024 repeated blocks
#
# ISP 2024 arranges each scenario, NEM region, and season as a separate matrix block.
# The sampled block shows the New South Wales summer assumptions for the opening scenario section.

dsp_source_2024 = PISP.read_xlsx_rows(WORKBOOK2024, DSP_2024)
dsp_2024 = DataFrame(
    dsp_source_2024[2:6, 1:9],
    Symbol.([
        "Price band or response", "2023-24", "2024-25", "2025-26", "2026-27",
        "2027-28", "2028-29", "2029-30", "2030-31",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(dsp_2024)
#-

# ## ISP 2026 normalised rows
#
# ISP 2026 places region, price band, scenario, and season on every row.
# This removes the need to infer those dimensions from a matrix block's location, but it also changes the schema consumed by a parser.

dsp_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "DSP", "B10:L18"),
    Symbol.([
        "Region", "Price band or response", "Scenario", "Season", "2025-26", "2026-27",
        "2027-28", "2028-29", "2029-30", "2030-31", "2031-32",
    ]);
    makeunique = true,
)
PISPDocUtils.markdown_table(dsp_2026)
#-

# ## Active ISP 2024 source coverage
#
# The current parser names every combination of three scenarios, five NEM regions, and two seasons.
# The coverage ledger expands those selections into 30 active ranges so that no workbook block remains implicit.

coverage = PISPDocUtils.coverage_document(REPO_ROOT)
source_reads = PISPDocUtils.coverage_table(coverage, "source_read")
dsp_ranges = filter(:owner => ==("shared-source-demand-side-participation"), source_reads)

dsp_coverage = DataFrame([
    (dimension = "Scenario", values = length(PISP.ID2SCE), interpretation = join(values(PISP.ID2SCE), ", ")),
    (dimension = "NEM region", values = 5, interpretation = "NSW, QLD, SA, TAS, and VIC"),
    (dimension = "Season", values = 2, interpretation = "Summer and Winter"),
    (dimension = "Explicit source ranges", values = nrow(dsp_ranges), interpretation = "3 × 5 × 2 active blocks"),
])
PISPDocUtils.markdown_table(dsp_coverage)
#-

# ## Package mappings
#
# PISP maps workbook price-band labels to package values and maps the maintained scenario IDs to the 2024 scenario names.
# These lookups are package conventions that sit between the raw matrices and the generated demand-response records.

scenario_mapping = DataFrame(
    scenario_id = collect(keys(PISP.ID2SCE)),
    scenario_name = collect(values(PISP.ID2SCE)),
)
PISPDocUtils.markdown_table(scenario_mapping)
#-

# A future ISP 2026 implementation needs a reviewed mapping for the new row schema and scenario set.
# The visible similarity of price-band labels does not establish complete semantic equivalence.
