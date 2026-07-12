# Regenerate committed Markdown for every active registry-managed Literate page.
#
# Run this script before the Documenter build whenever package code, local data,
# EDA evidence, or a Literate source changes.

using Literate

include(joinpath(@__DIR__, "page_registry.jl"))
using .PISPDocsPageRegistry

const DOCS_DIR = @__DIR__
const SRC_DIR = joinpath(DOCS_DIR, "src")
const REPO_ROOT = normpath(joinpath(DOCS_DIR, ".."))
const REGISTRY_PATH = joinpath(DOCS_DIR, "page-registry.toml")

function env_flag(name, default)
    value = lowercase(strip(get(ENV, name, default ? "true" : "false")))
    value in ("1", "true", "yes", "on") && return true
    value in ("0", "false", "no", "off") && return false
    error("$name must be one of true/false, yes/no, on/off, or 1/0")
end

function select_pages(registry_pages)
    explicit_ids = strip(get(ENV, "PISP_LITERATE_PAGES", ""))
    if !isempty(explicit_ids)
        requested_ids = String.(filter(id -> !isempty(id), strip.(split(explicit_ids, ","))))
        length(requested_ids) == length(unique(requested_ids)) ||
            error("PISP_LITERATE_PAGES contains duplicate page IDs")

        pages_by_id = Dict(page.id => page for page in registry_pages)
        unknown_ids = filter(id -> !haskey(pages_by_id, id), requested_ids)
        isempty(unknown_ids) || error("unknown page IDs in PISP_LITERATE_PAGES: $(join(unknown_ids, ", "))")
        return [pages_by_id[id] for id in requested_ids]
    end

    source_set = lowercase(strip(get(ENV, "PISP_LITERATE_SET", "all")))
    selected = if source_set == "published"
        filter(page -> page.status == "published", registry_pages)
    elseif source_set == "draft" || source_set == "eda-drafts"
        filter(page -> page.status == "draft", registry_pages)
    elseif source_set == "all"
        filter(page -> page.status != "archived", registry_pages)
    else
        error(
            "unsupported PISP_LITERATE_SET=\"$source_set\"; " *
            "use \"published\", \"draft\" (or legacy \"eda-drafts\"), or \"all\", or set PISP_LITERATE_PAGES",
        )
    end

    kind_order = Dict("reference" => 1, "tutorial" => 2, "validation" => 3, "analysis" => 4)
    return sort(selected; by = page -> (kind_order[page.kind], page.nav_order, page.id))
end

function selected_producers(pages)
    producers = Pair{String, Vector{String}}[]
    index_by_path = Dict{String, Int}()

    for page in pages
        page.producer === nothing && continue
        if haskey(index_by_path, page.producer)
            push!(producers[index_by_path[page.producer]].second, page.id)
        else
            push!(producers, page.producer => [page.id])
            index_by_path[page.producer] = length(producers)
        end
    end

    return producers
end

function run_producer(relative_path, page_ids)
    producer_path = joinpath(REPO_ROOT, relative_path)
    command = `$(Base.julia_cmd()) --project=$(REPO_ROOT) $(producer_path)`
    println("\n=== EDA producer: $relative_path ===")
    println("Pages: $(join(page_ids, ", "))")

    try
        run(Cmd(command; dir = REPO_ROOT))
    catch
        println(stderr, "\nERROR: EDA producer failed: $relative_path")
        println(stderr, "Affected pages: $(join(page_ids, ", "))")
        println(stderr, "No Literate page using this producer was rendered.")
        rethrow()
    end
end

function run_selected_producers(pages)
    env_flag("PISP_RUN_PRODUCERS", true) || begin
        println("Skipping registered EDA producers because PISP_RUN_PRODUCERS=false.")
        return
    end

    for (producer, page_ids) in selected_producers(pages)
        run_producer(producer, page_ids)
    end
end

function collapse_julia_source(markdown)
    lines = split(markdown, '\n'; keepempty = true)
    output = String[]
    closing_fence = nothing

    for line in lines
        stripped = strip(line)
        if closing_fence === nothing
            match_result = match(r"^(`{3,})julia\s*$", stripped)
            if match_result !== nothing
                closing_fence = match_result.captures[1]
                append!(
                    output,
                    [
                        "```@raw html",
                        "<details class=\"source-code\"><summary>Show source code</summary>",
                        "```",
                        "",
                        line,
                    ],
                )
                continue
            end
        elseif stripped == closing_fence
            push!(output, line)
            append!(
                output,
                [
                    "",
                    "```@raw html",
                    "</details>",
                    "```",
                ],
            )
            closing_fence = nothing
            continue
        end

        push!(output, line)
    end

    closing_fence === nothing || error("unterminated Julia source block in generated Markdown")
    return join(output, '\n')
end

function set_edit_url(markdown, source_path, final_output_path)
    edit_url = replace(relpath(source_path, dirname(final_output_path)), '\\' => '/')
    lines = split(markdown, '\n'; keepempty = true)
    edit_url_index = findfirst(line -> startswith(strip(line), "EditURL = "), lines)
    edit_url_index === nothing && error("generated Markdown does not contain a Documenter EditURL")
    lines[edit_url_index] = "EditURL = \"$edit_url\""
    return join(lines, '\n')
end

function validate_render_preconditions(page)
    if page.evidence_dir !== nothing
        evidence_path = joinpath(REPO_ROOT, page.evidence_dir)
        isdir(evidence_path) || error(
            "page \"$(page.id)\" expects EDA evidence at \"$evidence_path\"; " *
            "run julia --project=. $(page.producer) from the repository root first",
        )
    end

    for requirement in page.data_requirements
        requirement_path = joinpath(REPO_ROOT, requirement)
        ispath(requirement_path) || error(
            "page \"$(page.id)\" requires local data at \"$requirement_path\"",
        )
    end
end

function with_page_environment(callback, output_dir)
    keys = ("PISP_DOCS_REPO_ROOT", "PISP_LITERATE_OUTPUT_DIR")
    previous = Dict(key => get(ENV, key, nothing) for key in keys)

    ENV["PISP_DOCS_REPO_ROOT"] = REPO_ROOT
    ENV["PISP_LITERATE_OUTPUT_DIR"] = output_dir

    try
        return callback()
    finally
        for key in keys
            value = previous[key]
            if value === nothing
                haskey(ENV, key) && delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

function render_page(page; src_dir = SRC_DIR)
    validate_render_preconditions(page)

    source_path = joinpath(DOCS_DIR, page.source)
    output_path = joinpath(src_dir, page.output)
    output_dir = dirname(output_path)
    mkpath(output_dir)

    source_stem = splitext(basename(source_path))[1]
    generated_path = joinpath(output_dir, "$source_stem.md")
    final_output_path = joinpath(SRC_DIR, page.output)

    try
        with_page_environment(output_dir) do
            Literate.markdown(
                source_path,
                output_dir;
                flavor = Literate.DocumenterFlavor(),
                execute = true,
                credit = false,
            )
        end
    catch
        println(stderr, "\nERROR: Literate page failed: $(page.id)")
        println(stderr, "Source: $(relpath(source_path, REPO_ROOT))")
        println(stderr, "Registered output: $(relpath(final_output_path, REPO_ROOT))")
        rethrow()
    end

    isfile(generated_path) || error(
        "Literate did not create the expected intermediate output for page \"$(page.id)\": $generated_path",
    )
    generated_markdown = read(generated_path, String)
    generated_markdown = set_edit_url(generated_markdown, source_path, final_output_path)
    write(generated_path, collapse_julia_source(generated_markdown))

    if normpath(generated_path) != normpath(output_path)
        mv(generated_path, output_path; force = true)
    end

    println("Rendered $(page.id): $(relpath(output_path, REPO_ROOT))")
end

function validate_staged_outputs(pages, staged_src_dir)
    expected_outputs = Set(page.output for page in pages)
    for page in pages
        output_path = joinpath(staged_src_dir, page.output)
        isfile(output_path) || error(
            "Literate did not create the registered output for page \"$(page.id)\": $output_path",
        )
    end

    discovered_outputs = Set{String}()
    generated_root = joinpath(staged_src_dir, "generated")
    if isdir(generated_root)
        for (directory, _, files) in walkdir(generated_root)
            for filename in files
                endswith(filename, ".md") || continue
                path = joinpath(directory, filename)
                push!(discovered_outputs, replace(relpath(path, staged_src_dir), '\\' => '/'))
            end
        end
    end

    orphan_outputs = sort(collect(setdiff(discovered_outputs, expected_outputs)))
    isempty(orphan_outputs) || error(
        "complete render created unregistered Markdown: $(join(orphan_outputs, ", "))",
    )
end

function install_generated_tree(staged_src_dir)
    staged_generated = joinpath(staged_src_dir, "generated")
    isdir(staged_generated) || error("complete render did not create a generated documentation tree")

    generated_root = joinpath(SRC_DIR, "generated")
    backup_root = joinpath(SRC_DIR, ".generated-backup-$(getpid())")
    ispath(backup_root) && rm(backup_root; recursive = true, force = true)
    had_existing_tree = ispath(generated_root)

    if had_existing_tree
        mv(generated_root, backup_root; force = true)
    end

    try
        mv(staged_generated, generated_root; force = true)
    catch
        ispath(generated_root) && rm(generated_root; recursive = true, force = true)
        had_existing_tree && ispath(backup_root) && mv(backup_root, generated_root; force = true)
        rethrow()
    end

    return had_existing_tree ? backup_root : nothing
end

function rollback_generated_tree(backup_root)
    generated_root = joinpath(SRC_DIR, "generated")
    ispath(generated_root) && rm(generated_root; recursive = true, force = true)
    backup_root === nothing || mv(backup_root, generated_root; force = true)
end

function discard_generated_backup(backup_root)
    backup_root === nothing && return
    ispath(backup_root) && rm(backup_root; recursive = true, force = true)
end

function render_all_active(pages)
    generated_root = joinpath(SRC_DIR, "generated")
    had_existing_tree = isdir(generated_root)

    try
        mktempdir(DOCS_DIR; prefix = ".literate-staging-") do staging_dir
            staged_src_dir = joinpath(staging_dir, "src")
            for page in pages
                render_page(page; src_dir = staged_src_dir)
            end
            validate_staged_outputs(pages, staged_src_dir)

            backup_root = install_generated_tree(staged_src_dir)
            try
                load_page_registry(REGISTRY_PATH; require_published_outputs = true)
            catch
                rollback_generated_tree(backup_root)
                rethrow()
            end
            discard_generated_backup(backup_root)
        end
    catch
        println(stderr, "\nERROR: Complete Literate regeneration failed.")
        if had_existing_tree
            println(stderr, "The previous docs/src/generated/ tree remains intact.")
        else
            println(stderr, "No previous docs/src/generated/ tree was available to preserve.")
        end
        println(stderr, "Documenter was not run by this script.")
        rethrow()
    end
end

function main()
    registry_pages = load_page_registry(REGISTRY_PATH; check_generated_outputs = false)
    selected_pages = select_pages(registry_pages)
    isempty(selected_pages) && error("no Literate pages matched the requested selection")

    rendering_all_active = length(selected_pages) == count(page -> page.status != "archived", registry_pages)
    try
        run_selected_producers(selected_pages)

        if rendering_all_active
            render_all_active(selected_pages)
            println("Validated all active generated outputs against the page registry.")
        else
            for page in selected_pages
                render_page(page)
            end
        end
    catch
        println(stderr, "\nERROR: Documentation regeneration stopped.")
        if rendering_all_active
            generated_root = joinpath(SRC_DIR, "generated")
            if isdir(generated_root)
                println(stderr, "The installed docs/src/generated/ tree was not replaced by the failed complete render.")
            else
                println(stderr, "No complete docs/src/generated/ tree is currently installed.")
            end
        else
            println(stderr, "The selected-page render did not complete; inspect any selected output written before the failure.")
        end
        println(stderr, "Documenter was not run by render_literate.jl.")
        rethrow()
    end
end

main()
