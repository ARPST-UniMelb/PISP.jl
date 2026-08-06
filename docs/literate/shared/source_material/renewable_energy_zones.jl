# # Renewable energy zones
#
# Renewable energy zone records connect zone identifiers and names to NEM regions and ISP subregions.
# ParseISP uses the ISP 2024 table when allocating utility-scale solar and wind build-out from the generation and storage outlook material.

using ParseISP
using DataFrames
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const RENEWABLE_ENERGY_ZONES_2024 = ParseISP.source_spec(:renewable_energy_zones, 2024)
const WORKBOOK2024 = ParseISP.source_path(ISP2024.download_root, RENEWABLE_ENERGY_ZONES_2024)
const WORKBOOK2026 = joinpath(ISP2026.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
nothing #hide

# ## ISP 2024 zone records
#
# The 2024 source includes the NTNDP zone, ISP subregion, and regional cost zone beside each REZ identifier.

rez_source_2024 = ParseISP.read_xlsx_rows(WORKBOOK2024, RENEWABLE_ENERGY_ZONES_2024)
rez_2024 = DataFrame(
    rez_source_2024[2:9, 1:6],
    Symbol.(["ID", "Name", "NEM region", "NTNDP zone", "ISP subregion", "Regional cost zone"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(rez_2024)
#-

# ## ISP 2026 zone records
#
# The corresponding 2026 table is narrower in its leading columns and no longer places the NTNDP and regional cost-zone fields in this block.

rez_2026 = DataFrame(
    XLSX.readdata(WORKBOOK2026, "Renewable energy zones", "B7:E15"),
    Symbol.(["ID", "Name", "NEM region", "ISP subregion"]);
    makeunique = true,
)
ParseISPDocUtils.markdown_table(rez_2026)
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
ParseISPDocUtils.markdown_table(renamed_rez)
#-

# ## Transformation boundary
#
# The current solar and wind builders read the ISP 2024 REZ table, select the relevant zone IDs for each ParseISP subregion, and combine them with scenario outlook capacity.
# Both builders currently apply the package-defined candidate development path `CDP14` across the maintained scenario IDs.

rez_conventions = DataFrame([
    (subject = "Solar outlook candidate development path", convention = "CDP14 for each current ParseISP scenario"),
    (subject = "Wind outlook candidate development path", convention = "CDP14 for each current ParseISP scenario"),
    (subject = "Subregion geography", convention = "ParseISP.NEMBUSNAME and ParseISP.BUS2AREA"),
])
ParseISPDocUtils.markdown_table(rez_conventions)
#-

# The candidate-development-path choices are package conventions, not values read from the REZ worksheet.
# The current solar and wind builders continue to use the ISP 2024 zone records.
#src # NOTE: Verify ISP 2026 zone semantics before any transformation reuses its names or fields.
