# # ISP 2024: Source-data inventory
#
# The inventory summarises files, extensions, top-level directories, and a three-level directory view for the configured ISP 2024 download root.

using CSV
using DataFrames
using Printf

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_09_download_inventory"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const DOWNLOAD_ROOT = relpath(ISP2024_PROFILE.download_root, REPO_ROOT)  # kept relative: this is the path form recorded in the tables below
const MAX_TREE_DEPTH = 3
const MAX_TREE_CHILDREN_PER_DIR = 3
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a DOWNLOAD_ROOT-relative path to an absolute location for reading

to_forward_slashes(path) = replace(path, "\\" => "/")

function lowercase_extension(name)
    ext = lowercase(splitext(name)[2])
    return isempty(ext) ? "" : ext[2:end]
end
nothing #hide

# The inventory covers the complete download tree and records a compact three-level directory view.
function walk_download_root(root; max_tree_depth = MAX_TREE_DEPTH, max_children_per_dir = MAX_TREE_CHILDREN_PER_DIR)
    files = NamedTuple[]
    tree_rows = NamedTuple[]

    for (dirpath, dirnames, filenames) in walkdir(root)
        filter!(name -> !startswith(name, "."), dirnames)
        filter!(name -> !startswith(name, "."), filenames)
        rel_dir = dirpath == root ? "" : to_forward_slashes(relpath(dirpath, root))
        dir_depth = isempty(rel_dir) ? 0 : length(splitpath(rel_dir))
        child_depth = dir_depth + 1

        if child_depth <= max_tree_depth
            for name in sort(dirnames)
                push!(
                    tree_rows,
                    (depth = child_depth, parent_relative_path = rel_dir, name = name, kind = "directory"),
                )
            end
            ## Depth alone does not bound how many files sit in one directory (e.g. a single Traces/<tech>_<year>/ folder holds hundreds of per-location trace CSVs); cap the listed files per directory so the rendered tree stays readable, and record how many were omitted rather than silently truncating.
            sorted_filenames = sort(filenames)
            shown_filenames = first(sorted_filenames, min(length(sorted_filenames), max_children_per_dir))
            for name in shown_filenames
                push!(
                    tree_rows,
                    (depth = child_depth, parent_relative_path = rel_dir, name = name, kind = "file"),
                )
            end
            omitted = length(sorted_filenames) - length(shown_filenames)
            if omitted > 0
                push!(
                    tree_rows,
                    (
                        depth = child_depth,
                        parent_relative_path = rel_dir,
                        name = "... ($(omitted) more file$(omitted == 1 ? "" : "s") omitted)",
                        kind = "note",
                    ),
                )
            end
        end

        for filename in sort(filenames)
            full_path = joinpath(dirpath, filename)
            rel_path = isempty(rel_dir) ? filename : rel_dir * "/" * filename
            push!(
                files,
                (
                    relative_path = rel_path,
                    size_bytes = filesize(full_path),
                    extension = lowercase_extension(filename),
                    depth = length(splitpath(rel_path)),
                ),
            )
        end
    end

    return files, tree_rows
end

function summarize_extensions(files)
    counts = Dict{String, Int}()
    bytes = Dict{String, Int}()
    for f in files
        counts[f.extension] = get(counts, f.extension, 0) + 1
        bytes[f.extension] = get(bytes, f.extension, 0) + f.size_bytes
    end
    exts = sort(collect(keys(counts)))
    rows = [(extension = ext, file_count = counts[ext], total_bytes = bytes[ext]) for ext in exts]
    return DataFrame(rows)
end
nothing #hide

# One row per immediate child of the download root, whether a file or a directory. Directory rows aggregate recursively over `files`; a plain file's own extension is not repeated in `extensions` since that column describes what is found *under* an entry, not the entry itself.
function summarize_top_level(root, files)
    rows = NamedTuple[]
    for name in sort(filter(n -> !startswith(n, "."), readdir(root)))
        full_path = joinpath(root, name)
        if isdir(full_path)
            prefix = name * "/"
            matching = filter(f -> startswith(f.relative_path, prefix), files)
            total_bytes = isempty(matching) ? 0 : sum(f.size_bytes for f in matching)
            exts = sort(unique(f.extension for f in matching if !isempty(f.extension)))
            push!(
                rows,
                (
                    name = name,
                    kind = "directory",
                    file_count = length(matching),
                    total_bytes = total_bytes,
                    extensions = join(exts, ","),
                ),
            )
        else
            push!(
                rows,
                (
                    name = name,
                    kind = "file",
                    file_count = 1,
                    total_bytes = filesize(full_path),
                    extensions = "",
                ),
            )
        end
    end
    return DataFrame(rows)
end
nothing #hide

# Renders the depth-limited directory-tree rows as an indented plain-text tree, root-first.
function render_tree(tree::DataFrame; root_label = "pisp-downloads")
    children_by_parent = Dict{String, Vector{Int}}()
    for (i, row) in enumerate(eachrow(tree))
        push!(get!(children_by_parent, row.parent_relative_path, Int[]), i)
    end

    io = IOBuffer()
    println(io, root_label, "/")

    function emit(parent_path, indent)
        for i in get(children_by_parent, parent_path, Int[])
            row = tree[i, :]
            label = row.kind == "directory" ? "$(row.name)/" : row.name
            println(io, indent, "- ", label)
            if row.kind == "directory"
                child_path = isempty(parent_path) ? row.name : "$(parent_path)/$(row.name)"
                emit(child_path, indent * "  ")
            end
        end
    end

    emit("", "  ")
    return String(take!(io))
end
nothing #hide

# ## Source-tree coverage
#
# A recursive inventory over the download root produces a flat file inventory (every file, at every depth) and a depth-limited directory-tree listing in the same pass.

isdir(abs_path(DOWNLOAD_ROOT)) || error(
    "expected local download tree at \"$DOWNLOAD_ROOT\"; " *
    "run the PISP downloader to populate $(DOWNLOAD_ROOT)/ before rendering the source inventory",
)

files, tree_rows = walk_download_root(abs_path(DOWNLOAD_ROOT))
println("Total files discovered under ", DOWNLOAD_ROOT, ": ", length(files))
nothing #hide

# ## File and extension summary
#
# `file_inventory` lists every discovered file. The table below shows the ten largest files, while `top_level_summary` and `extension_summary` aggregate the complete inventory.

file_inventory = DataFrame(files)
write_table(file_inventory, SCRIPT_STEM, "file_inventory")
println("Full file inventory written: ", nrow(file_inventory), " rows (previewing the ten largest files below)")

largest_files = first(sort(file_inventory, :size_bytes; rev = true), 10)
markdown_table(largest_files)

#-

top_level_summary = summarize_top_level(abs_path(DOWNLOAD_ROOT), files)
write_table(top_level_summary, SCRIPT_STEM, "top_level_summary")
markdown_table(top_level_summary)

#-

extension_summary = summarize_extensions(files)
write_table(extension_summary, SCRIPT_STEM, "extension_summary")
markdown_table(extension_summary)

# ## Directory structure
#
# The tree below mirrors the on-disk folder layout down to three levels deep. Some folders hold far more files than are useful to list one by one — a single `Traces/<tech>_<year>/` folder holds hundreds of near-identical per-location trace CSVs — so a folder with many files shows only its first several, followed by a line stating how many more were left out.

directory_tree = DataFrame(tree_rows)
write_table(directory_tree, SCRIPT_STEM, "directory_tree")
nrow(directory_tree)

#-

tree_text = render_tree(directory_tree);

print(tree_text) #hide

# ## Inventory totals

total_bytes = isempty(files) ? 0 : sum(f.size_bytes for f in files)
inventory_summary = DataFrame([
    (
        download_root = DOWNLOAD_ROOT,
        total_files = length(files),
        total_bytes = total_bytes,
        tree_depth = MAX_TREE_DEPTH,
        max_files_per_directory = MAX_TREE_CHILDREN_PER_DIR,
        top_level_entries = nrow(top_level_summary),
        largest_entry = top_level_summary.name[argmax(top_level_summary.total_bytes)],
        largest_entry_bytes = maximum(top_level_summary.total_bytes),
    ),
])
write_table(inventory_summary, SCRIPT_STEM, "inventory_summary")
metric_value_table([
    "Download root" => inventory_summary.download_root[1],
    "Total files" => inventory_summary.total_files[1],
    "Total bytes" => inventory_summary.total_bytes[1],
    "Tree depth" => inventory_summary.tree_depth[1],
    "Maximum files in one directory" => inventory_summary.max_files_per_directory[1],
    "Top-level entries" => inventory_summary.top_level_entries[1],
    "Largest entry" => inventory_summary.largest_entry[1],
    "Largest entry (bytes)" => inventory_summary.largest_entry_bytes[1],
])

#-

@printf("Total: %d files, %.2f MB under %s\n", length(files), total_bytes / (1024^2), DOWNLOAD_ROOT)

# ## Summary
#
# - The download root currently holds the file counts and sizes shown in `inventory_summary` above, broken down by top-level entry and by file extension.
# - The complete per-file inventory and three-level directory tree are retained in `file_inventory.csv` and `directory_tree.csv`; the main summary presents the counts needed for interpretation.
