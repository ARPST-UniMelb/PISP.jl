module SourceLinks

using TOML

export SourceLinkError, SourceEntry, load_registry, stage_documentation!

struct SourceLinkError <: Exception
    message::String
end
Base.showerror(io::IO, error::SourceLinkError) = print(io, error.message)

struct SourceEntry
    title::String
    publisher::String
    local_path::String
    public_url::String
    public_origin::String
end

const FENCE_RE = r"^ {0,3}(`{3,}|~{3,})"
const DEFINITION_RE = r"^\[([^\]\n]+)\]:\s+(\S+)\s*$"
const INLINE_LINK_RE = r"\[([^\]\n]+)\]\(([^\s()]+)\)"

is_markdown_table_row(line) = occursin(r"^\s*\|.*\|\s*$", line)

function normalise_local_path(path::AbstractString)
    isabspath(path) && throw(SourceLinkError("local_path must be relative: '$path'"))
    occursin(r"[?#]", path) && throw(SourceLinkError("local_path must not contain a query or fragment: '$path'"))
    parts = String[]
    for part in split(replace(path, '\\' => '/'), '/')
        part in ("", ".") && continue
        if part == ".."
            isempty(parts) && throw(SourceLinkError("local_path escapes the repository root: '$path'"))
            pop!(parts)
        else
            push!(parts, part)
        end
    end
    isempty(parts) && throw(SourceLinkError("local_path must not be empty"))
    return join(parts, "/")
end

function validate_public_url(url::AbstractString)
    startswith(lowercase(url), "https://") || throw(SourceLinkError("public_url must be an absolute https URL: '$url'"))
    occursin('#', url) && throw(SourceLinkError("public_url must not contain a fragment: '$url'"))
    occursin(r"^https://[^/]*:[^/]*@", url) && throw(SourceLinkError("public_url must not contain credentials"))
    return String(url)
end

function load_registry(path::AbstractString)
    isfile(path) || throw(SourceLinkError("source-links registry not found: '$path'"))
    data = TOML.parsefile(path)
    get(data, "schema_version", nothing) == 2 || throw(SourceLinkError("source-links registry must declare schema_version = 2"))
    raw_sources = get(data, "source", nothing)
    raw_sources isa Vector && !isempty(raw_sources) || throw(SourceLinkError("source-links registry must contain [[source]] entries"))
    entries = SourceEntry[]
    seen = Set{String}()
    for raw in raw_sources
        all(haskey(raw, field) for field in ("title", "publisher", "local_path", "public_url", "public_origin")) ||
            throw(SourceLinkError("each [[source]] entry must declare title, publisher, local_path, public_url, and public_origin"))
        local_path = normalise_local_path(raw["local_path"])
        local_path in seen && throw(SourceLinkError("duplicate normalized local_path: '$local_path'"))
        push!(seen, local_path)
        raw["public_origin"] == "official" || throw(SourceLinkError("public_origin must be 'official'"))
        push!(entries, SourceEntry(String(raw["title"]), String(raw["publisher"]), local_path,
            validate_public_url(String(raw["public_url"])), "official"))
    end
    return entries
end

function split_lines(text::String)
    lines = String[]
    start = firstindex(text)
    isempty(text) && return lines
    while start <= lastindex(text)
        stop = findnext('\n', text, start)
        if stop === nothing
            push!(lines, text[start:end]); break
        end
        push!(lines, text[start:stop])
        start = nextind(text, stop)
    end
    return lines
end

function inline_link_in_code(line, position)
    delimiter = nothing
    index = firstindex(line)
    while index < position
        if line[index] == '`'
            start = index
            while index < position && line[index] == '`'
                index = nextind(line, index)
            end
            run = line[start:prevind(line, index)]
            delimiter = delimiter === run ? nothing : (delimiter === nothing ? run : delimiter)
        else
            index = nextind(line, index)
        end
    end
    return delimiter !== nothing
end

function rewrite_inline_links(line, rel_path, line_no, by_path, repo_root, tree_rel, target)
    matches = collect(eachmatch(INLINE_LINK_RE, line))
    isempty(matches) && return line
    output = IOBuffer()
    cursor = firstindex(line)
    for match_result in matches
        start = match_result.offset
        finish = start + ncodeunits(match_result.match) - 1
        print(output, line[cursor:prevind(line, start)])
        label, destination = match_result.captures
        escaped = start > firstindex(line) && line[prevind(line, start)] == '\\'
        image = start > firstindex(line) && line[prevind(line, start)] == '!'
        if escaped || image || inline_link_in_code(line, start)
            print(output, match_result.match)
        else
            rewritten = rewrite_inline_destination(label, destination, rel_path, line_no, by_path, repo_root, tree_rel, target)
            print(output, "[", label, "](", rewritten === nothing ? destination : rewritten, ")")
        end
        cursor = nextind(line, finish)
    end
    cursor <= lastindex(line) && print(output, line[cursor:end])
    return String(take!(output))
end

function rewrite_inline_destination(label, destination, rel_path, line_no, by_path, repo_root, tree_rel, target)
    startswith(destination, "<") && return nothing
    (startswith(lowercase(destination), "//") || match(r"^[A-Za-z][A-Za-z0-9+.-]*:", destination) !== nothing) && return nothing
    hash = findfirst('#', destination)
    hash === nothing && return nothing
    base = destination[1:prevind(destination, hash)]
    fragment = destination[nextind(destination, hash):end]
    occursin('?', base) && throw(SourceLinkError("$rel_path:$line_no: inline link '$label' has a query string"))
    endswith(lowercase(base), ".pdf") || return nothing
    page_match = match(r"^page=(\d+)$", fragment)
    page_match === nothing && throw(SourceLinkError("$rel_path:$line_no: inline link '$label' has malformed page fragment"))
    page = parse(Int, page_match.captures[1])
    page > 0 || throw(SourceLinkError("$rel_path:$line_no: inline link '$label' has a non-positive page"))
    resolved = replace(relpath(normpath(joinpath(repo_root, tree_rel, dirname(rel_path), base)), repo_root), '\\' => '/')
    (resolved == ".." || startswith(resolved, "../")) && throw(SourceLinkError("$rel_path:$line_no: inline link '$label' escapes the repository"))
    entry = get(by_path, resolved, nothing)
    entry === nothing && throw(SourceLinkError("$rel_path:$line_no: inline link '$label' has no registry entry for '$resolved'"))
    target == :local && return destination
    target == :public && return "$(entry.public_url)#page=$page"
    throw(SourceLinkError("target must be :local or :public"))
end

function rewrite_markdown(text::String, rel_path::String, by_path::Dict{String,SourceEntry}, repo_root::String, tree_rel::String, target::Symbol)
    output = IOBuffer()
    fence = nothing
    fence_length = 0
    frontmatter = false
    for (line_no, line) in enumerate(split_lines(text))
        stripped = rstrip(line, ['\n', '\r'])
        if line_no == 1 && stripped == "---"
            frontmatter = true; print(output, line); continue
        elseif frontmatter
            print(output, line); stripped == "---" && (frontmatter = false); continue
        end
        if fence !== nothing
            print(output, line)
            closing = strip(stripped)
            if !isempty(closing) && length(closing) >= fence_length && all(char -> char == fence, closing)
                fence = nothing
            end
            continue
        end
        match_fence = match(FENCE_RE, stripped)
        if match_fence !== nothing
            fence = match_fence.captures[1][1]; fence_length = length(match_fence.captures[1])
            print(output, line); continue
        end
        if startswith(stripped, "    ") || startswith(stripped, "\t")
            print(output, line); continue
        end
        if is_markdown_table_row(stripped)
            print(output, line); continue
        end
        definition = match(DEFINITION_RE, stripped)
        if definition === nothing
            if occursin(r"<[A-Za-z/][^>]*>", stripped)
                print(output, line)
            else
                print(output, rewrite_inline_links(line, rel_path, line_no, by_path, repo_root, tree_rel, target))
            end
            continue
        end
        label, destination = definition.captures
        hash = findfirst('#', destination)
        if hash === nothing || !endswith(lowercase(destination[1:prevind(destination, hash)]), ".pdf")
            print(output, line); continue
        end
        base = destination[1:prevind(destination, hash)]
        fragment = destination[nextind(destination, hash):end]
        page_match = match(r"^page=(\d+)$", fragment)
        page_match === nothing && throw(SourceLinkError("$rel_path:$line_no: PDF citations require #page=N"))
        page = parse(Int, page_match.captures[1])
        page > 0 || throw(SourceLinkError("$rel_path:$line_no: page must be positive"))
        resolved = replace(relpath(normpath(joinpath(repo_root, tree_rel, dirname(rel_path), base)), repo_root), '\\' => '/')
        startswith(resolved, "..") && throw(SourceLinkError("$rel_path:$line_no: PDF path escapes the repository"))
        entry = get(by_path, resolved, nothing)
        entry === nothing && throw(SourceLinkError("$rel_path:$line_no: no registry entry for '$resolved'"))
        replacement = target == :local ? destination : "$(entry.public_url)#page=$page"
        terminator = line[length(stripped)+1:end]
        print(output, "[", label, "]: ", replacement, terminator)
    end
    return String(take!(output))
end

function stage_documentation!(maintained_root::AbstractString, staging_root::AbstractString, registry_path::AbstractString,
                             target::Symbol; repo_root::AbstractString=dirname(maintained_root))
    target in (:local, :public) || throw(SourceLinkError("target must be :local or :public"))
    isdir(maintained_root) || throw(SourceLinkError("maintained documentation tree not found"))
    entries = load_registry(registry_path)
    by_path = Dict(entry.local_path => entry for entry in entries)
    repo = abspath(repo_root)
    tree = abspath(maintained_root)
    tree_rel = replace(relpath(tree, repo), '\\' => '/')
    startswith(tree_rel, "..") && throw(SourceLinkError("maintained documentation tree is outside repo_root"))
    parent = dirname(abspath(staging_root)); mkpath(parent)
    temporary_parent = mktempdir(parent; prefix=".documenter-source-")
    temporary = joinpath(temporary_parent, "tree")
    try
        cp(tree, temporary)
        for (dir, _, files) in walkdir(temporary)
            for file in files
                endswith(file, ".md") || continue
                path = joinpath(dir, file)
                rel = replace(relpath(path, temporary), '\\' => '/')
                write(path, rewrite_markdown(read(path, String), rel, by_path, repo, tree_rel, target))
            end
        end
        old = isdir(staging_root) ? staging_root * ".previous" : nothing
        old !== nothing && rm(old; recursive=true, force=true)
        old !== nothing && mv(staging_root, old)
        try
            mv(temporary, staging_root)
        catch error
            old !== nothing && mv(old, staging_root; force=true)
            rethrow(error)
        end
        old !== nothing && rm(old; recursive=true, force=true)
    finally
        rm(temporary_parent; recursive=true, force=true)
    end
    return abspath(staging_root)
end

end
