# # Data sources
#
# PISP combines AEMO workbooks, model archives, development outlooks, and time-series traces with package-defined mappings. The tables below list the configured download targets and the input paths used by the current build pipeline.

using PISP
using DataFrames

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))
const INPUT_ROOT = normpath(get(ENV, "PISP_DATA_ROOT", joinpath(REPO_ROOT, "data", "2024", "pisp-downloads")))

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
# `PISP.default_data_paths` defines the input paths used by the build pipeline. The `exists` column reports whether each path is present under the selected local input root. Set `PISP_DATA_ROOT` to use a different checkout.

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

# ## Local inventory
#
# [Source-data inventory](@ref) provides a recursive, dated inventory of the files actually present under the local download root.
