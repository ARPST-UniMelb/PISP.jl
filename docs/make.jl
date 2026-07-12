# Documenter.jl site build for PISP.jl.
#
# A normal docs build publishes the Markdown already present under docs/src/.
# Literate regeneration is a separate maintainer step in docs/render_literate.jl
# so the site build does not require local AEMO or PISP output data.

using Documenter
using PISP

include(joinpath(@__DIR__, "page_registry.jl"))
using .PISPDocsPageRegistry

const DOCS_DIR = @__DIR__
const SRC = joinpath(DOCS_DIR, "src")
const BUILD = joinpath(DOCS_DIR, "build")
const REGISTRY_PATH = joinpath(DOCS_DIR, "page-registry.toml")

const PAGE_KIND_LABELS = [
    "tutorial" => "Tutorials",
    "validation" => "Data validation",
    "analysis" => "Analyses and case studies",
]

function registry_navigation(registry_pages)
    navigation = Any["Home" => "index.md"]

    reference_pages = sort(
        filter(page -> page.kind == "reference" && page.status != "archived", registry_pages);
        by = page -> (page.nav_order, page.id),
    )
    isempty(reference_pages) && error("the page registry must contain at least one active reference page")

    for page in reference_pages
        push!(navigation, page.title => page.output)
        page.id == "data-sources" && push!(navigation, "Domain concepts" => "concepts.md")
    end
    push!(navigation, "Assumptions and scope" => "assumptions.md")

    for (kind, label) in PAGE_KIND_LABELS
        pages = sort(
            filter(page -> page.kind == kind && page.status != "archived", registry_pages);
            by = page -> (page.nav_order, page.id),
        )
        isempty(pages) || push!(navigation, label => Any[page.title => page.output for page in pages])
    end

    push!(navigation, "API Reference" => "api.md")
    return navigation
end

registry_pages = try
    load_page_registry(REGISTRY_PATH; require_published_outputs = true)
catch
    println(stderr, "\nERROR: Documenter cannot start because one or more generated pages are missing or invalid.")
    println(stderr, "Run: julia --project=docs docs/render_literate.jl")
    rethrow()
end

format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", "false") == "true",
    inventory_version = "dev",
    edit_link = "main",
)

makedocs(;
    sitename = "PISP.jl",
    format = format,
    build = BUILD,
    source = SRC,
    pages = registry_navigation(registry_pages),
)