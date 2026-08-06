# # ISP 2026: Workbook and trace structure
#
# ISP 2026 source material combines the inputs and assumptions workbook, the
# electric-vehicle workbook, generation and storage outlooks, scenario models,
# and trace collections.
# The tables below describe their workbook, model-archive, and trace structure.

using DataFrames
using TOML
using XLSX

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const PROFILE = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const SOURCE_MAP_PATH = joinpath(REPO_ROOT, "docs", "config", "isp2026-source-specs.toml")
const SOURCE_MAP = TOML.parsefile(SOURCE_MAP_PATH)
const SOURCE_SPECS = SOURCE_MAP["source"]

required_source_fields = Set([
    "id",
    "group",
    "format",
    "path",
    "selection",
    "keys",
    "fields_units",
])
all(source -> required_source_fields ⊆ keys(source), SOURCE_SPECS) || error(
    "every ISP 2026 source entry must define its file, selection, keys, fields, and units",
)

inputs_workbook = joinpath(PROFILE.download_root, "2026-isp-inputs-and-assumptions-workbook.xlsm")
ev_workbook = joinpath(PROFILE.download_root, "aemo-2025-iasr-ev-workbook.xlsx")
inputs_sheets = XLSX.openxlsx(inputs_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end
ev_sheets = XLSX.openxlsx(ev_workbook) do workbook
    Set(XLSX.sheetnames(workbook))
end

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
required_inputs_sheets ⊆ inputs_sheets || error(
    "the ISP 2026 inputs workbook is missing a documented worksheet",
)
required_ev_sheets ⊆ ev_sheets || error(
    "the ISP 2026 electric-vehicle workbook is missing a documented worksheet",
)

scenario_names = ["Accelerated Transition", "Slower Growth", "Step Change"]
trace_families = ["demand", "dnsp", "gas", "hydro", "load_subtractor", "rooftop PV"]
model_root = joinpath(PROFILE.download_root, "2026 ISP Model")
core_root = joinpath(PROFILE.download_root, "Core scenarios")
sensitivity_root = joinpath(PROFILE.download_root, "Sensitivities")
renewable_trace_root = joinpath(PROFILE.download_root, "Traces")
scenario_roots = [joinpath(model_root, "2026 ISP $scenario") for scenario in scenario_names]
scenario_trace_roots = [
    joinpath(model_root, "2026 ISP $scenario", "Traces", family)
    for scenario in scenario_names for family in trace_families
]
all(isdir, scenario_roots) || error("the ISP 2026 model archive is missing a scenario directory")
all(isdir, scenario_trace_roots) || error("an ISP 2026 scenario model is missing a documented trace folder")
isdir(core_root) || error("the ISP 2026 core scenario outlook directory was not found")
isdir(sensitivity_root) || error("the ISP 2026 sensitivity outlook directory was not found")
isdir(renewable_trace_root) || error("the ISP 2026 renewable trace directory was not found")
nothing #hide

# ## Workbook structure

workbook_structure = DataFrame(
    source_collection = [
        "Inputs and assumptions workbook",
        "Electric-vehicle workbook",
        "Generation and storage outlook",
    ],
    files = [
        "2026-isp-inputs-and-assumptions-workbook.xlsm",
        "aemo-2025-iasr-ev-workbook.xlsx",
        "Core scenario and sensitivity workbooks",
    ],
    selections = [
        join(sort!(collect(required_inputs_sheets)), ", "),
        join(sort!(collect(required_ev_sheets)), ", "),
        "Capacity, Storage Capacity, Storage Energy, REZ Generation Capacity, and development-path tables",
    ],
)
ParseISPDocUtils.markdown_table(
    workbook_structure;
    column_labels = ["Source collection", "Files", "Selections"],
)
#-

# ## Model archive structure

model_structure = DataFrame(
    source_collection = ["Scenario models", "Model trace folders", "Renewable trace collections"],
    files = [
        join(["2026 ISP $scenario" for scenario in scenario_names], ", "),
        "Traces inside each scenario model",
        "Separate solar and wind trace collections",
    ],
    selections = [
        "One scenario directory and model XML file per scenario",
        join(trace_families, ", "),
        "Project or region and reference-year label",
    ],
)
ParseISPDocUtils.markdown_table(
    model_structure;
    column_labels = ["Source collection", "Files", "Selections"],
)
#-

# ## Trace schema

trace_sources = filter(
    source -> source["group"] in ("Model trace folders", "Separate renewable trace archives"),
    SOURCE_SPECS,
)
trace_schema = DataFrame([
    (
        trace_family = titlecase(replace(replace(source["id"], "isp2026-" => ""), "-" => " ")),
        file_or_pattern = "$(source["path"]) — $(source["selection"])",
        keys = source["keys"],
        fields_units = source["fields_units"],
    )
    for source in trace_sources
])
ParseISPDocUtils.markdown_table(
    trace_schema;
    column_labels = ["Trace family", "File or pattern", "Keys", "Fields and units"],
)
#-

# ## Compare editions
#
# The [raw-source comparison](../../comparison/analyses/raw-source-comparison.md)
# compares workbook selections and schemas.
# The [model archive comparison](../../comparison/analyses/model-archive-comparison.md)
# compares scenario directories, model files, and trace folders.
