# Tables every configured ParseISP ISP report against how many times its PDF is
# cited in the documentation and how many distinct pages are cited.
#
# Run with: julia --project=docs docs/test/report_citation_audit.jl

import ParseISP

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DOCS_UTILS_DIR = joinpath(REPO_ROOT, "docs", "utils")
const LITERATE_ROOT = joinpath(REPO_ROOT, "docs", "literate")

include(joinpath(DOCS_UTILS_DIR, "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

function configured_reports()
    rows = NamedTuple[]
    for (edition, targets) in (
        ("2024", ParseISP.ISP2024ReportDownloader.report_targets()),
        ("2026", ParseISP.ISP2026ReportDownloader.report_targets()),
    )
        for target in targets
            push!(rows, (; edition, key = target.key, title = target.title, filename = target.filename))
        end
    end
    return rows
end

function literate_sources()
    sources = String[]
    for (directory, _, files) in walkdir(LITERATE_ROOT)
        for filename in files
            endswith(filename, ".jl") || continue
            push!(sources, read(joinpath(directory, filename), String))
        end
    end
    return join(sources, "\n")
end

function citation_counts(report, corpus)
    pattern = Regex("data/$(report.edition)/pisp-reports/" * escape_string(report.filename) * raw"#page=(\d+)")
    pages = [parse(Int, match.captures[1]) for match in eachmatch(pattern, corpus)]
    return (; citations = length(pages), unique_pages = length(unique(pages)))
end

function audit_report_citations()
    reports = configured_reports()
    corpus = literate_sources()
    rows = map(reports) do report
        counts = citation_counts(report, corpus)
        @assert counts.unique_pages <= counts.citations
        (; report.edition, report.title, report.filename, counts.citations, counts.unique_pages)
    end
    @assert length(rows) == length(reports)
    sort!(rows; by = row -> (row.edition, row.citations))
    return rows
end

if abspath(PROGRAM_FILE) == @__FILE__
    rows = audit_report_citations()
    table = ParseISPDocUtils.markdown_table(
        ["Edition", "Report", "Filename", "Citations", "Unique pages"],
        [[row.edition, row.title, row.filename, row.citations, row.unique_pages] for row in rows];
        alignment = [:left, :left, :left, :right, :right],
    )
    println(table.text)
end
