# Documenter.jl site build for PISP.jl.
#
# A normal docs build publishes the Markdown already present under docs/src/.
# Executable pages are regenerated through the separate maintainer command in docs/render_literate.jl, so the site build does not require local AEMO or PISP output data.

using Documenter
using PISP

include(joinpath(@__DIR__, "utils", "page_registry.jl"))
include(joinpath(@__DIR__, "utils", "navigation.jl"))

const DOCS_DIR = @__DIR__
const SRC = joinpath(DOCS_DIR, "src")
const STAGED_SRC = joinpath(DOCS_DIR, ".documenter-source")
const BUILD = joinpath(DOCS_DIR, "build")
const REGISTRY_PATH = joinpath(DOCS_DIR, "config", "page-registry.toml")
const REPO_ROOT = realpath(dirname(DOCS_DIR))
const PISP_REMOTE = Documenter.Remotes.GitHub("ARPST-UniMelb", "PISP.jl")
const PISP_SOURCE_ROOT = realpath(dirname(dirname(pathof(PISP))))

# Preserve source and edit links when the repository or PISP package is supplied
# as an archive rather than a Git checkout.
const DOCUMENTATION_REMOTES = let
    remotes = Dict{String, Any}()
    if !ispath(joinpath(REPO_ROOT, ".git"))
        remotes[REPO_ROOT] = (PISP_REMOTE, "main")
    end
    if PISP_SOURCE_ROOT != REPO_ROOT
        remotes[PISP_SOURCE_ROOT] = (PISP_REMOTE, "v$(pkgversion(PISP))")
    end
    remotes
end

include(joinpath(DOCS_DIR, "utils", "source_links.jl"))

link_target_name = get(ENV, "PISP_DOCS_LINK_TARGET", "local")
link_target_name in ("local", "public") || error("PISP_DOCS_LINK_TARGET must be local or public")
link_target = Symbol(link_target_name)
stage_documentation!(SRC, STAGED_SRC, joinpath(DOCS_DIR, "config", "source-links.toml"), link_target;
    repo_root = dirname(DOCS_DIR))

registry_pages = try
    load_page_registry(REGISTRY_PATH; require_published_outputs = true)
catch
    println(stderr, "\nERROR: Documenter cannot start because one or more generated pages are missing or invalid.")
    println(stderr, "Run docs/render_literate.jl with the same active Julia project.")
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
    remotes = DOCUMENTATION_REMOTES,
)

if get(ENV, "GITHUB_ACTIONS", "false") == "true"
    repository = get(ENV, "GITHUB_REPOSITORY", "")
    isempty(repository) && error("GITHUB_REPOSITORY is required for GitHub Pages deployment")

    deploydocs(;
        repo = "github.com/$(repository).git",
        devbranch = "main",
        push_preview = false,
    )
end
