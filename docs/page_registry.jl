module PISPDocsPageRegistry

using TOML

export PageSpec, load_page_registry

const VALID_KINDS = Set(["reference", "tutorial", "validation", "analysis"])
const VALID_DATA_LAYERS = Set(["package-workflow", "source-data", "pisp-dataset", "cross-layer"])
const VALID_STATUSES = Set(["draft", "published", "archived"])

Base.@kwdef struct PageSpec
    id::String
    title::String
    kind::String
    data_layer::String
    source::String
    output::String
    status::String
    nav_order::Int
    snapshot::Bool
    evidence_dir::Union{Nothing, String} = nothing
    producer::Union{Nothing, String} = nothing
    data_requirements::Vector{String} = String[]
    related_reference_pages::Vector{String} = String[]
    notes::Union{Nothing, String} = nothing
end

function required_string(entry, key, page_number)
    value = get(entry, key, nothing)
    value isa String || error("page $page_number requires string field \"$key\"")
    isempty(strip(value)) && error("page $page_number has an empty \"$key\" field")
    return value
end

function optional_string(entry, key, page_number)
    value = get(entry, key, nothing)
    value === nothing && return nothing
    value isa String || error("page $page_number field \"$key\" must be a string")
    isempty(strip(value)) && error("page $page_number has an empty \"$key\" field")
    return value
end

function string_vector(entry, key, page_number)
    value = get(entry, key, Any[])
    value isa AbstractVector || error("page $page_number field \"$key\" must be an array")
    all(item -> item isa String && !isempty(strip(item)), value) ||
        error("page $page_number field \"$key\" must contain non-empty strings")
    return String.(value)
end

function relative_path(value, field, page_id)
    isabspath(value) && error("page \"$page_id\" field \"$field\" must be relative: $value")
    normalized = replace(normpath(value), '\\' => '/')
    any(part -> part == "..", splitpath(normalized)) &&
        error("page \"$page_id\" field \"$field\" escapes its root: $value")
    normalized == "." && error("page \"$page_id\" field \"$field\" cannot be current directory")
    return normalized
end

function parse_page(entry, page_number)
    id = required_string(entry, "id", page_number)
    title = required_string(entry, "title", page_number)
    kind = required_string(entry, "kind", page_number)
    data_layer = required_string(entry, "data_layer", page_number)
    source = relative_path(required_string(entry, "source", page_number), "source", id)
    output = relative_path(required_string(entry, "output", page_number), "output", id)
    status = required_string(entry, "status", page_number)

    kind in VALID_KINDS || error("page \"$id\" has unsupported kind \"$kind\"")
    data_layer in VALID_DATA_LAYERS || error("page \"$id\" has unsupported data_layer \"$data_layer\"")
    status in VALID_STATUSES || error("page \"$id\" has unsupported status \"$status\"")
    startswith(source, "literate/") || error("page \"$id\" source must be under docs/literate/")
    endswith(source, ".jl") || error("page \"$id\" source must be a Julia Literate file")
    endswith(output, ".md") || error("page \"$id\" output must be Markdown")

    nav_order = get(entry, "nav_order", nothing)
    nav_order isa Integer || error("page \"$id\" requires integer field \"nav_order\"")
    nav_order > 0 || error("page \"$id\" nav_order must be positive")

    snapshot = get(entry, "snapshot", nothing)
    snapshot isa Bool || error("page \"$id\" requires boolean field \"snapshot\"")

    evidence_dir = optional_string(entry, "evidence_dir", page_number)
    evidence_dir === nothing || (evidence_dir = relative_path(evidence_dir, "evidence_dir", id))

    producer = optional_string(entry, "producer", page_number)
    producer === nothing || (producer = relative_path(producer, "producer", id))
    evidence_dir !== nothing && producer === nothing &&
        error("page \"$id\" requires a producer when evidence_dir is set")

    data_requirements = [
        relative_path(path, "data_requirements", id)
        for path in string_vector(entry, "data_requirements", page_number)
    ]

    related_reference_pages = [
        relative_path(path, "related_reference_pages", id)
        for path in string_vector(entry, "related_reference_pages", page_number)
    ]

    return PageSpec(
        id = id,
        title = title,
        kind = kind,
        data_layer = data_layer,
        source = source,
        output = output,
        status = status,
        nav_order = Int(nav_order),
        snapshot = snapshot,
        evidence_dir = evidence_dir,
        producer = producer,
        data_requirements = data_requirements,
        related_reference_pages = related_reference_pages,
        notes = optional_string(entry, "notes", page_number),
    )
end

function reject_duplicates(pages, field, label)
    seen = Dict{Any, String}()
    for page in pages
        value = getfield(page, field)
        haskey(seen, value) && error("duplicate $label \"$value\" for pages \"$(seen[value])\" and \"$(page.id)\"")
        seen[value] = page.id
    end
end

function validate_navigation_positions(pages)
    seen = Dict{Tuple{String, Int}, String}()
    for page in pages
        page.status == "archived" && continue
        key = (page.kind, page.nav_order)
        haskey(seen, key) && error(
            "duplicate navigation position $(page.nav_order) in $(page.kind) pages " *
            "\"$(seen[key])\" and \"$(page.id)\"",
        )
        seen[key] = page.id
    end
end

function validate_files(
    pages,
    registry_path;
    require_published_outputs,
    check_generated_outputs,
)
    docs_dir = dirname(registry_path)
    repo_root = normpath(joinpath(docs_dir, ".."))
    src_root = joinpath(docs_dir, "src")
    registered_outputs = Set(page.output for page in pages)

    for page in pages
        source_path = joinpath(docs_dir, page.source)
        isfile(source_path) || error("page \"$(page.id)\" source does not exist: $source_path")

        if page.producer !== nothing
            producer_path = joinpath(repo_root, page.producer)
            isfile(producer_path) || error("page \"$(page.id)\" producer does not exist: $producer_path")
        end

        for reference_page in page.related_reference_pages
            reference_path = joinpath(src_root, reference_page)
            (isfile(reference_path) || reference_page in registered_outputs) || error(
                "page \"$(page.id)\" related reference does not exist: $reference_path",
            )
        end

        if require_published_outputs && page.status != "archived"
            output_path = joinpath(src_root, page.output)
            isfile(output_path) || error("active page \"$(page.id)\" output does not exist: $output_path")
        end
    end

    registered_sources = Set(page.source for page in pages)
    discovered_sources = Set{String}()
    literate_root = joinpath(docs_dir, "literate")
    for (directory, _, files) in walkdir(literate_root)
        for filename in files
            endswith(filename, ".jl") || continue
            path = joinpath(directory, filename)
            push!(discovered_sources, replace(relpath(path, docs_dir), '\\' => '/'))
        end
    end
    unregistered_sources = sort(collect(setdiff(discovered_sources, registered_sources)))
    isempty(unregistered_sources) || error(
        "unregistered Literate sources: $(join(unregistered_sources, ", "))",
    )

    if check_generated_outputs
        discovered_generated_outputs = Set{String}()
        generated_root = joinpath(src_root, "generated")
        if isdir(generated_root)
            for (directory, _, files) in walkdir(generated_root)
                for filename in files
                    endswith(filename, ".md") || continue
                    path = joinpath(directory, filename)
                    push!(discovered_generated_outputs, replace(relpath(path, src_root), '\\' => '/'))
                end
            end
        end
        orphan_generated_outputs = sort(collect(setdiff(discovered_generated_outputs, registered_outputs)))
        isempty(orphan_generated_outputs) || error(
            "generated Markdown without a page-registry entry: $(join(orphan_generated_outputs, ", "))",
        )
    end
end

function load_page_registry(
    registry_path;
    require_published_outputs = false,
    check_generated_outputs = true,
)
    isfile(registry_path) || error("page registry does not exist: $registry_path")
    document = TOML.parsefile(registry_path)
    entries = get(document, "page", nothing)
    entries isa AbstractVector || error("page registry must contain one or more [[page]] tables")
    isempty(entries) && error("page registry must contain at least one [[page]] table")

    pages = [parse_page(entry, page_number) for (page_number, entry) in enumerate(entries)]
    reject_duplicates(pages, :id, "page id")
    reject_duplicates(pages, :title, "page title")
    reject_duplicates(pages, :output, "output path")
    validate_navigation_positions(pages)
    validate_files(
        pages,
        registry_path;
        require_published_outputs = require_published_outputs,
        check_generated_outputs = check_generated_outputs,
    )
    return pages
end

end