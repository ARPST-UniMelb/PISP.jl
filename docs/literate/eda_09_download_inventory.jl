# # Source-data inventory
#
# This page lists the files and directories present under the selected PISP download root. The snapshot metadata identifies the inspected path and generation time.

using CSV
using DataFrames

const EDA09_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "09_download_inventory",
)

function read_eda09(table_name)
    path = joinpath(EDA09_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    ## keep empty-string cells as empty strings, not `missing`
    return CSV.read(path, DataFrame; missingstring = nothing)
end

# ## Inventory snapshot

snapshot_metadata = read_eda09("snapshot_metadata")
snapshot_metadata

# ## Top-level summary
#
# One row per immediate child of the download root, whether a plain file or a directory.
# `file_count` and `total_bytes` are recursive for directories; `extensions` lists the distinct file extensions found under a directory (empty for a plain file, since a file has no children to list extensions for).

top_level_summary = read_eda09("top_level_summary")
top_level_summary

# ## Extension summary
#
# One row per distinct file extension across the whole tree, with the total file count and byte size for that extension.

extension_summary = read_eda09("extension_summary")
extension_summary

# ## Directory tree (depth ≤ 3)
#
# The tree below mirrors the on-disk folder layout down to three levels deep.
# Some folders hold far more files than are useful to list one by one — a single `Traces/<tech>_<year>/` folder holds hundreds of near-identical per-location trace CSVs — so a folder with many files shows only its first several, followed by a line stating how many more were left out.

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

directory_tree = read_eda09("directory_tree")
tree_text = render_tree(directory_tree);

print(tree_text) #hide

# ## Inventory totals

inventory_summary = DataFrame([
    (
        total_files = snapshot_metadata.total_files[1],
        total_bytes = snapshot_metadata.total_bytes[1],
        top_level_entries = nrow(top_level_summary),
        largest_entry = top_level_summary.name[argmax(top_level_summary.total_bytes)],
        largest_entry_bytes = maximum(top_level_summary.total_bytes),
    ),
])
inventory_summary
