# # ISP 2026: Raw-source reader map
#
# ISP 2026 workbooks, outlook files, and model traces contain structured inputs.
# This reference maps the observed source selections to their keys, fields,
# units, and candidate PISP consumers.

using PISP
using DataFrames
using TOML
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const INVENTORY_PATH = joinpath(REPO_ROOT, "docs", "config", "isp2026-source-specs.toml")
const INVENTORY = TOML.parsefile(INVENTORY_PATH)
const PROFILE = PISPDocUtils.edition_profile(REPO_ROOT, "2026")

lineage_ids = reduce(vcat, values(INVENTORY["lineage"]))
length(lineage_ids) == 80 || error("the ISP 2024 lineage must contain 80 entries")
length(unique(lineage_ids)) == 80 || error("the ISP 2024 lineage IDs must be unique")

source_rows = DataFrame(map(INVENTORY["source"]) do source
    (
        id = source["id"],
        group = source["group"],
        status = source["status"],
        format = source["format"],
        path = source["path"],
        selection = source["selection"],
        keys = source["keys"],
        fields_units = source["fields_units"],
        lineage_count = length(source["lineage_2024"]),
        possible_reader = source["possible_reader"],
    )
end)

length(unique(source_rows.id)) == nrow(source_rows) || error("ISP 2026 source IDs must be unique")
isempty(PISP.source_specs(2026)) || error("this documentation assumes no registered ISP 2026 SourceSpecs")

required_locations = [
    joinpath(PROFILE.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm"),
    joinpath(PROFILE.download_root, "aemo-2025-iasr-ev-workbook.xlsx"),
    joinpath(PROFILE.download_root, "Core scenarios"),
    joinpath(PROFILE.download_root, "Sensitivities"),
    joinpath(PROFILE.download_root, "2026 ISP Model"),
    joinpath(PROFILE.download_root, "Traces", "2026 ISP Solar traces", "solar"),
    joinpath(PROFILE.download_root, "Traces", "2026 ISP Wind traces", "wind"),
]
all(ispath, required_locations) || error("one or more required ISP 2026 source locations are unavailable")

inputs_workbook = required_locations[1]
ev_workbook = required_locations[2]
required_inputs_sheets = Set([
    "Existing Gen Data Summary",
    "Emissions intensity",
    "Maximum capacity",
    "Summary Mapping",
    "Generator Reliability Settings",
    "Retirement",
    "Storage properties",
    "Hydro Scheme Inflows",
    "DSP",
    "Rooftop PV",
    "Data Centre Forecasts",
    "Distribution network",
    "Hybrid site limits",
])
required_ev_sheets = Set([
    "BEV_Numbers",
    "PHEV_Numbers",
    "FCEV_Numbers",
    "Hybrid_Numbers",
    "ICE_Numbers",
    "BEV_PHEV_Consumption (GWh)",
    "BEV_PHEV_Charge_Type (%)",
    "BEV_PHEV_Profile_kW (Weekday)",
    "BEV_PHEV_Profile_kW (Weekend)",
])

observed_inputs_sheets = XLSX.openxlsx(inputs_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end
observed_ev_sheets = XLSX.openxlsx(ev_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end
required_inputs_sheets ⊆ observed_inputs_sheets || error("the ISP 2026 inputs workbook is missing a documented worksheet")
required_ev_sheets ⊆ observed_ev_sheets || error("the 2025 IASR EV workbook is missing a documented worksheet")
nothing #hide

# ## Evidence and lineage
#
# The 2026 PLEXOS Model Instructions describe three scenario models and the
# demand, renewable-generation, gas-availability, DNSP-level CER,
# seasonal-timeslice, and load-subtractor traces used by those models
# ([p. 5](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7)).
# The extracted scenario folders and separate solar and wind archives provide
# the file-level evidence for the trace selections below.
#
# The lineage links every registered ISP 2024 source specification to observed,
# relocated, absent, generated, user-supplied, or legacy-supplement evidence.
# Individual ISP 2024 DSP specifications remain distinct in the lineage even
# though the 2026 workbook stores DSP as one row-oriented table.

# ## Source status
#
# “Observed” means the named file and structure were inspected. “Changed” or
# “relocated” means the source role has a 2024 lineage but a different 2026
# layout. Boundary rows identify absent, generated, user-supplied, legacy, or
# unresolved material rather than treating it as a current source read.

status_labels = Dict(
    "observed" => "Observed source structure",
    "changed" => "Changed source structure",
    "relocated" => "Relocated source structure",
    "unresolved" => "Referenced but unresolved",
    "not-observed" => "No counterpart observed",
    "generated-by-pisp" => "PISP-generated in the 2024 workflow",
    "user-supplied" => "User-supplied input",
    "legacy-supplement" => "Legacy supplement",
)
status_summary = combine(groupby(source_rows, :status), nrow => :source_selections)
status_summary.status = [status_labels[status] for status in status_summary.status]
rename!(status_summary, :status => :evidence_status)
sort!(status_summary, :evidence_status)
PISPDocUtils.markdown_table(status_summary; column_labels = ["Evidence status", "Source selections"])
#-

function reader_table(rows)
    table = select(
        rows,
        :id => :source_id,
        [:path, :selection, :keys] => ByRow((path, selection, keys) -> "$(path) — $(selection); keys: $(keys)") => :source_selection,
        :fields_units => :content,
        :possible_reader => :candidate_consumer,
    )
    return PISPDocUtils.markdown_table(
        table;
        column_labels = ["Source ID", "Source selection", "Content and units", "Candidate PISP consumer"],
    )
end
nothing #hide

# ## Inputs and assumptions workbook
#
# The inputs workbook retains the major generation, storage, reliability,
# retirement, network, REZ, hydro, and DSP subjects used in 2024, but several
# layouts have changed. It also adds reader-relevant rooftop-PV, data-centre,
# distribution-network, hybrid-site, fuel, and gas structures.

inputs_rows = filter(row -> row.group == "Inputs and assumptions workbook", source_rows)
reader_table(inputs_rows)
#-

# ## Electric-vehicle workbook
#
# The 2025 IASR EV workbook preserves number, charge-type, and weekday/weekend
# profile roles while adding FCEV and hybrid vehicle families and a separate
# annual-consumption table.

ev_rows = filter(row -> row.group == "2025 IASR EV workbook", source_rows)
reader_table(ev_rows)
#-

# ## Generation and storage outlook
#
# Core and sensitivity workbooks expose capacity, storage power, storage
# energy, REZ capacity, and CDP catalogues. `Storage Energy` uses the literal
# key header `Technology`, while `Storage Capacity` uses `storage category`.
# `Available CDPs` includes `CDP4 (ODP)`, consistent with AEMO's identification
# of CDP 4 as the 2026 ODP ([2026 ISP Cost Benefit Analysis, p. 162](../../../../../data/2026/pisp-reports/a6-cost-benefit-analysis.pdf#page=162)).

outlook_rows = filter(row -> row.group == "Generation and storage outlook", source_rows)
reader_table(outlook_rows)
#-

# ## Model and renewable trace files
#
# Demand, DNSP, rooftop-PV, and load-subtractor CSVs use `Year`, `Month`,
# `Day`, and half-hour columns `01` to `48`. Gas files use a daily `Value`
# field, while daily hydro files use `Inflows`. The model XML references
# `timeslice_RefYear5000.csv`, but that file is not present in the extracted
# trace folders. Its file schema and consumer contract remain unresolved.

trace_rows = filter(
    row -> row.group in ("Model trace folders", "Separate renewable trace archives"),
    source_rows,
)
reader_table(trace_rows)
#-

# ### Observed trace files by scenario
#
# These counts come from the current extracted directories and distinguish
# scenario-model traces from separately published project-level renewable
# archives.

scenario_names = ["Accelerated Transition", "Slower Growth", "Step Change"]
trace_families = ["demand", "dnsp", "gas", "hydro", "load_subtractor", "rooftop PV"]
model_root = joinpath(PROFILE.download_root, "2026 ISP Model")

observed_trace_files = DataFrame([
    (
        scope = scenario,
        trace_family = family,
        csv_files = count(
            name -> endswith(lowercase(name), ".csv"),
            readdir(joinpath(model_root, "2026 ISP $scenario", "Traces", family)),
        ),
    )
    for scenario in scenario_names for family in trace_families
])

for (family, directory) in [
    "solar" => joinpath(PROFILE.download_root, "Traces", "2026 ISP Solar traces", "solar"),
    "wind" => joinpath(PROFILE.download_root, "Traces", "2026 ISP Wind traces", "wind"),
]
    push!(
        observed_trace_files,
        (
            scope = "Separate renewable archive",
            trace_family = family,
            csv_files = count(name -> endswith(lowercase(name), ".csv"), readdir(directory)),
        ),
    )
end

PISPDocUtils.markdown_table(
    observed_trace_files;
    column_labels = ["Scenario or archive", "Trace family", "Observed CSV files"],
)
#-

#src # NOTE:
#src
#src # A future implementation must verify each selection against the target source,
#src # register an edition-2026 SourceSpec where the structure is stable, connect it
#src # to a tested consumer, and define how it contributes to the PISP data model.
#src # Until those steps exist in `src/`, the entries on this page describe source
#src # structure and possible reader responsibilities only.

# ## Known source boundaries
#
# These rows distinguish missing 2026 sources, PISP-generated 2024
# intermediates, user inputs, and legacy supplements from published 2026 source
# selections.

boundary_rows = filter(row -> row.group == "Known source boundaries", source_rows)
reader_table(boundary_rows)
#-
