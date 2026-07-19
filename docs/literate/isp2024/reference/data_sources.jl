# # ISP 2024: Data sources
#
# PISP combines AEMO workbooks, model archives, development outlooks, and time-series traces with package-defined mappings. The tables below list the configured download targets and the input paths used by the current build pipeline.

using PISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const INPUT_ROOT = ISP2024_PROFILE.download_root

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

replace(relpath(INPUT_ROOT, REPO_ROOT), '\\' => '/')

# ## Configured reference-file downloads
#
# These rows come directly from `PISP.ISPFileDownloader.isp_file_targets()`.

targets = PISP.ISPFileDownloader.isp_file_targets()
configured_downloads = DataFrame(
    key = string.([target.key for target in targets]),
    published_artifact = [target.title for target in targets],
    local_filename = [something(target.filename, "derived from URL") for target in targets],
    subdirectory = [something(target.subdir, "") for target in targets],
)
markdown_table(configured_downloads)

# Demand, solar, and wind traces are discovered from the configured ISP publication page and downloaded separately from the fixed reference-file targets.

trace_downloader = DataFrame([
    (
        publication_page = PISP.ISPTraceDownloader.DEFAULT_PAGE_URL,
        output_directory = PISP.ISPTraceDownloader.DEFAULT_OUTDIR,
        link_selector = string(PISP.ISPTraceDownloader.TRACE_SELECTOR),
    ),
])
markdown_table(trace_downloader)

# ## Expected build inputs
#
# `PISP.default_data_paths` defines the input paths used by the build pipeline. The `exists` column reports whether each path is present under the selected local input root. Set `PISP_DOCS_ISP2024_DOWNLOAD_ROOT` to select a different local download root.

expected_paths = PISP.default_data_paths(filepath = INPUT_ROOT)
expected_input_status = DataFrame([
    (
        input = string(name),
        relative_path = replace(relpath(path, INPUT_ROOT), '\\' => '/'),
        observed_kind = isdir(path) ? "directory" : isfile(path) ? "file" : "not present",
        exists = ispath(path),
    )
    for (name, path) in pairs(expected_paths)
])
markdown_table(expected_input_status)

# ## Source roles
#
# The 2024 Inputs and Assumptions workbook supplies most structured planning assumptions. The ISP model archive supplies model-side material such as hydro inflow data; the generation and storage outlook supplies future development information; the trace archives supply half-hourly demand, solar, and wind profiles; and the supplementary 2023 and 2019 workbooks provide inputs that are not available in the main 2024 workbook.
#
# Source-derived values, code-derived values, and package assumptions have different provenance and update requirements. A new publication may require parser changes, while a changed package mapping can alter outputs even when the downloaded files are unchanged.

# ## Source contribution by output table
#
# PISP combines AEMO source files with package-defined mappings and records derived during dataset construction. The table summarises how each static output table is created and identifies additional source families used for its time-varying schedules.

## `RawMarkdown` emits assembled Markdown verbatim; the PrettyTables backend
## would escape the backticks and underscores this table relies on.
struct RawMarkdown
    markdown::String
end
Base.show(io::IO, ::MIME"text/markdown", table::RawMarkdown) = print(io, table.markdown)

_, static_container, _ = PISP.initialise_time_structures()
static_output_tables = [
    get(PISP.alt_names, field, string(field))
    for field in fieldnames(typeof(static_container))
    if getfield(static_container, field) isa DataFrame
]

## Curated provenance for each static output table. Coverage is validated against
## the live build structures above; only the construction and schedule-input
## descriptions are authored here.
const SOURCE_CONTRIBUTION = Dict(
    "Bus" => ("Bus names, representative coordinates, and NEM area mappings are package-defined constants.", "No time-varying bus schedule is produced."),
    "Demand" => ("PISP creates one demand record for each bus.", "Hourly demand profiles come from the **Demand & Variable Renewable Energy trace data**."),
    "Line" => ("Network capability, transmission reliability, and augmentation-option data come from the **Inputs and Assumptions workbook**.", "Line capacity schedules use the same workbook source family."),
    "Generator" => ("Generator characteristics, capacities, mappings, and reliability parameters come from the **Inputs and Assumptions workbook**.", "Solar and wind schedules also use the **generation and storage outlook** and the **Demand & Variable Renewable Energy trace data**. Hydro inflow schedules additionally use the **Model** dataset."),
    "ESS" => ("Storage characteristics, capacities, mappings, and reliability parameters come from the **Inputs and Assumptions workbook**.", "Behind-the-meter and virtual power plant battery schedules also use the **generation and storage outlook**."),
    "DER" => ("DER records are constructed from the `Demand` and `Bus` tables.", "Demand-response and electric-vehicle charging schedules use the **Inputs and Assumptions workbook**."),
)
const SOURCE_CONTRIBUTION_ORDER = ["Bus", "Demand", "Line", "Generator", "ESS", "DER"]

let
    live = Set(static_output_tables)
    documented = Set(keys(SOURCE_CONTRIBUTION))
    live == documented || error(
        "source-contribution coverage differs from the live static tables: " *
        "only-live=$(sort(collect(setdiff(live, documented)))), " *
        "only-documented=$(sort(collect(setdiff(documented, live))))",
    )
    Set(SOURCE_CONTRIBUTION_ORDER) == documented ||
        error("SOURCE_CONTRIBUTION_ORDER must list exactly the documented tables")
    rows = ["| Table | Static-table construction | Additional schedule inputs |", "|---|---|---|"]
    for table in SOURCE_CONTRIBUTION_ORDER
        construction, schedule_inputs = SOURCE_CONTRIBUTION[table]
        push!(rows, "| `$table` | $construction | $schedule_inputs |")
    end
    RawMarkdown(join(rows, "\n"))
end

# ## Local inventory
#
# [ISP 2024: Source-data inventory](@ref) provides a recursive, dated inventory of the files actually present under the local download root.
