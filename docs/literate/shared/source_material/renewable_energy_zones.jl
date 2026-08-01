# # Renewable energy zones
#
# Renewable energy zone records connect zone identifiers and names to NEM regions and ISP subregions.
# PISP uses the ISP 2024 table when allocating utility-scale solar and wind build-out from the generation and storage outlook material.

using PISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const WORKBOOK2024 = joinpath(ISP2024.download_root, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## ISP 2024 zone records
#
# The 2024 source includes the NTNDP zone, ISP subregion, and regional cost zone beside each REZ identifier.

rez_2024 = PISPDocUtils.cells_table(
    WORKBOOK2024,
    "Renewable Energy Zones",
    "B8:G15",
    ["ID", "Name", "NEM region", "NTNDP zone", "ISP subregion", "Regional cost zone"],
)
PISPDocUtils.markdown_table(rez_2024)
#-

# ## ISP 2026 zone records
#
# The corresponding 2026 table is narrower in its leading columns and no longer places the NTNDP and regional cost-zone fields in this block.

rez_2026 = PISPDocUtils.cells_table(
    WORKBOOK2026,
    "Renewable energy zones",
    "B7:E15",
    ["ID", "Name", "NEM region", "ISP subregion"],
)
PISPDocUtils.markdown_table(rez_2026)
#-

# ## Name changes under retained identifiers
#
# A retained REZ identifier does not guarantee an unchanged name or planning definition.
# In the sampled Queensland records, Q2 changes from North Qld Clean Energy Hub to Hughenden Hub.

rez_names = innerjoin(
    select(rez_2024, :ID, :Name => :name_2024),
    select(rez_2026, :ID, :Name => :name_2026),
    on = :ID,
)
renamed_rez = filter(row -> row.name_2024 != row.name_2026, rez_names)
PISPDocUtils.markdown_table(renamed_rez)
#-

# ## Transformation boundary
#
# The current solar and wind builders read the ISP 2024 REZ table, select the relevant zone IDs for each PISP subregion, and combine them with scenario outlook capacity.
# Both builders currently apply the package-defined cost-development path `CDP14` across the maintained scenario IDs.

rez_conventions = DataFrame([
    (subject = "Solar outlook cost-development path", convention = "CDP14 for each current PISP scenario"),
    (subject = "Wind outlook cost-development path", convention = "CDP14 for each current PISP scenario"),
    (subject = "Subregion geography", convention = "PISP.NEMBUSNAME and PISP.BUS2AREA"),
])
PISPDocUtils.markdown_table(rez_conventions)
#-

# The cost-development-path choices are package conventions, not values read from the REZ worksheet.
# ISP 2026 zone names and fields require semantic review before reuse in a future transformation.
