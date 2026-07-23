# Incremental convenience wrapper around render_literate.jl.
#
# Re-renders ONLY the published/draft Literate pages whose source .jl changed
# versus HEAD (staged, unstaged, or untracked), by resolving those sources to
# page IDs and delegating to render_literate.jl through PISP_LITERATE_PAGES.
#
# Usage:
#   julia --project=docs docs/render_changed.jl
#   PISP_RUN_PRODUCERS=false julia --project=docs docs/render_changed.jl   # reuse existing EDA evidence
#
# SCOPE / CAVEAT: this tracks only changed docs/literate/**/*.jl page sources.
# It does NOT detect changes to shared helpers (eda_support.jl, page_registry.jl),
# EDA producer scripts, package src/, or local data -- any of which can change
# many rendered pages. It also skips the full-set completeness/atomic-swap
# validation that render_literate.jl performs for the whole published set.
# Always run a full `julia --project=docs docs/render_literate.jl` before you
# commit regenerated Markdown.

include(joinpath(@__DIR__, "page_registry.jl"))

const DOCS_DIR = @__DIR__
const REPO_ROOT = normpath(joinpath(DOCS_DIR, ".."))
const REGISTRY_PATH = joinpath(DOCS_DIR, "page-registry.toml")
const RENDER_SCRIPT = joinpath(DOCS_DIR, "render_literate.jl")

function git_lines(args)
    out = read(Cmd(`git $(args)`; dir = REPO_ROOT), String)
    return filter(!isempty, strip.(split(out, '\n')))
end

function changed_docs_jl()
    paths = String[]
    append!(paths, git_lines(["diff", "--name-only", "--", "docs"]))
    append!(paths, git_lines(["diff", "--name-only", "--cached", "--", "docs"]))
    append!(paths, git_lines(["ls-files", "--others", "--exclude-standard", "--", "docs"]))
    return unique(filter(p -> endswith(p, ".jl"), paths))
end

function main()
    pages = PISPDocsPageRegistry.load_page_registry(REGISTRY_PATH; check_generated_outputs = false)
    by_repo_path = Dict(normpath(joinpath("docs", page.source)) => page for page in pages)

    changed_pages = String[]
    changed_other = String[]
    skipped_archived = String[]
    for path in changed_docs_jl()
        key = normpath(path)
        if haskey(by_repo_path, key)
            page = by_repo_path[key]
            if PISPDocsPageRegistry.is_renderable(page)
                push!(changed_pages, page.id)
            else
                push!(skipped_archived, page.id)
            end
        else
            push!(changed_other, path)
        end
    end
    changed_pages = unique(changed_pages)

    if !isempty(changed_other)
        println("NOTE: changed docs .jl files that are not registry page sources")
        println("      (shared helper / producer / registry) -- these can affect many")
        println("      pages, so a full render is recommended:")
        for path in changed_other
            println("  - $(path)")
        end
    end
    isempty(skipped_archived) || println("Skipping archived page(s): ", join(skipped_archived, ", "))

    if isempty(changed_pages)
        println("No changed renderable Literate page sources vs HEAD; nothing to render.")
        println("(Run `julia --project=docs docs/render_literate.jl` for a full render.)")
        return
    end

    println("Changed pages to re-render: ", join(changed_pages, ", "))
    ENV["PISP_LITERATE_PAGES"] = join(changed_pages, ",")
    run(Cmd(`$(Base.julia_cmd()) --project=$(DOCS_DIR) $(RENDER_SCRIPT)`; dir = REPO_ROOT))
    println("\nIncremental render complete. Run a full render before committing regenerated Markdown.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
