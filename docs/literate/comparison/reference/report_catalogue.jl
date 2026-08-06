# # ISP report catalogue
#
# The catalogue follows the ordered report targets exposed by the ISP 2024 and
# ISP 2026 downloaders. Each entry identifies the report, its repository PDF,
# and the corresponding publication on the Australian Energy Market Operator
# website.

using ParseISP

const REPO_ROOT = normpath(
    get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..", "..")),
)
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const REPORT_PDF_ROOT = "../../../../../data"

function report_pdf_link(edition, target)
    path = "$(REPORT_PDF_ROOT)/$(edition)/pisp-reports/$(target.filename)#page=1"
    return "[$(target.filename)]($(path))"
end

function report_filename_cell(edition, target)
    return "$(report_pdf_link(edition, target)) · [AEMO]($(target.url))"
end

function counterpart_cell(edition, target)
    return "$(target.title) — $(report_filename_cell(edition, target))"
end

function inventory_rows(edition, targets)
    return [
        Any[target.title, report_filename_cell(edition, target)]
        for target in targets
    ]
end

targets_2024 = collect(ParseISP.ISP2024ReportDownloader.report_targets())
targets_2026 = collect(ParseISP.ISP2026ReportDownloader.report_targets())
targets_2024_by_key = Dict(target.key => target for target in targets_2024)
targets_2026_by_key = Dict(target.key => target for target in targets_2026)
counterpart_rows = [
    Any[
        counterpart_cell("2024", targets_2024_by_key[key_2024]),
        counterpart_cell("2026", targets_2026_by_key[key_2026]),
    ]
    for (key_2024, key_2026) in ParseISPDocUtils.report_counterpart_key_map()
]
nothing #hide

# ## Explicit counterparts
#
# These rows show only conservative semantic counterparts. Reports without an
# explicit counterpart remain in the complete edition inventories below.

ParseISPDocUtils.markdown_table(
    ["ISP 2024 report", "ISP 2026 report"],
    counterpart_rows;
    alignment = [:left, :left],
)

# ## ISP 2024 report inventory
#
# The order follows `ISP2024ReportDownloader.report_targets()`.

ParseISPDocUtils.markdown_table(
    ["Report title", "Filename"],
    inventory_rows("2024", targets_2024);
    alignment = [:left, :left],
)

# ## ISP 2026 report inventory
#
# The order follows `ISP2026ReportDownloader.report_targets()`.

ParseISPDocUtils.markdown_table(
    ["Report title", "Filename"],
    inventory_rows("2026", targets_2026);
    alignment = [:left, :left],
)
