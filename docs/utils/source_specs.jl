function isp2026_source_document(repo_root::AbstractString)
    path = joinpath(repo_root, "docs", "config", "isp2026-source-specs.toml")
    isfile(path) || error("ISP 2026 source specification not found: $path")
    document = TOML.parsefile(path)
    get(document, "edition", nothing) == "2026" || error(
        "the ISP 2026 source specification must declare edition = \"2026\"",
    )
    return document
end

isp2026_source_entries(repo_root::AbstractString) = isp2026_source_document(repo_root)["source"]

function isp2026_source_group_path(
    repo_root::AbstractString,
    download_root::AbstractString,
    group::AbstractString,
)
    entries = filter(
        entry -> entry["group"] == group,
        isp2026_source_entries(repo_root),
    )
    isempty(entries) && throw(KeyError(group))
    paths = unique([entry["path"] for entry in entries])
    length(paths) == 1 || error(
        "ISP 2026 source group $(repr(group)) does not have one shared path",
    )
    return normpath(joinpath(download_root, only(paths)))
end

function isp2026_source_entry(repo_root::AbstractString, id::AbstractString)
    matches = filter(
        entry -> entry["id"] == id,
        isp2026_source_entries(repo_root),
    )
    isempty(matches) && throw(KeyError(id))
    length(matches) == 1 || error("duplicate ISP 2026 source entry: $id")
    return only(matches)
end

function resolve_source_entry_pattern(pattern::AbstractString; replacements...)
    resolved = String(pattern)
    for (name, value) in replacements
        resolved = replace(resolved, "{$(name)}" => string(value))
    end
    unresolved = match(r"\{[^{}]+\}", resolved)
    unresolved === nothing || throw(ArgumentError(
        "unresolved source-entry token $(unresolved.match) in `$(pattern)`",
    ))
    return resolved
end

function isp2026_source_path(
    repo_root::AbstractString,
    download_root::AbstractString,
    id::AbstractString;
    replacements...,
)
    entry = isp2026_source_entry(repo_root, id)
    relative_path = resolve_source_entry_pattern(entry["path"]; replacements...)
    return normpath(download_root, relative_path)
end