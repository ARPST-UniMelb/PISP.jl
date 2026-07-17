# Documenter.jl site build for PISP.jl.
#
# A normal docs build publishes the Markdown already present under docs/src/. Literate regeneration is a separate maintainer step in docs/render_literate.jl so the site build does not require local AEMO or PISP output data.

using Documenter
using PISP

include(joinpath(@__DIR__, "page_registry.jl"))
using .PISPDocsPageRegistry
include(joinpath(@__DIR__, "navigation.jl"))
using .PISPDocsNavigation

const DOCS_DIR = @__DIR__
const SRC = joinpath(DOCS_DIR, "src")
const STAGED_SRC = joinpath(DOCS_DIR, ".documenter-source")
const BUILD = joinpath(DOCS_DIR, "build")
const REGISTRY_PATH = joinpath(DOCS_DIR, "page-registry.toml")

include(joinpath(DOCS_DIR, "source_links.jl"))
using .SourceLinks

link_target_name = get(ENV, "PISP_DOCS_LINK_TARGET", "local")
link_target_name in ("local", "public") || error("PISP_DOCS_LINK_TARGET must be local or public")
link_target = Symbol(link_target_name)
stage_documentation!(SRC, STAGED_SRC, joinpath(DOCS_DIR, "source-links.toml"), link_target;
    repo_root = dirname(DOCS_DIR))

registry_pages = try
    load_page_registry(REGISTRY_PATH; require_published_outputs = true)
catch
    println(stderr, "\nERROR: Documenter cannot start because one or more generated pages are missing or invalid.")
    println(stderr, "Run: julia --project=docs docs/render_literate.jl")
    rethrow()
end

format = Documenter.HTML(;
    prettyurls = link_target == :public && get(ENV, "CI", "false") == "true",
    inventory_version = "dev",
    edit_link = "main",
    size_threshold = 512 * 2^10,
    size_threshold_warn = 256 * 2^10,
    search_size_threshold_warn = 2^20,
)

makedocs(;
    sitename = "PISP.jl",
    format = format,
    build = BUILD,
    source = STAGED_SRC,
    linkcheck = false,
    warnonly = link_target == :local ? :cross_references : false,
    pages = registry_navigation(registry_pages),
)
