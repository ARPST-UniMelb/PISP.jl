# # What did the downloader actually put on disk?
#
# [Data sources](@ref) describes what the PISP downloader is *configured* to fetch: which published artifacts it targets and which local filenames and folders it expects to produce.
# That page is hand-written and does not verify what is actually present in a given local checkout.
# This page is the complementary, code-verified check: real Julia code walks the local `data/pisp-downloads/` tree (via `eda/09_download_inventory.jl`) and reports what is actually there, rather than what should be there.
#
# The evidence read below was computed from the local download tree by that script, not read live by this page.

using CSV
using DataFrames

const EDA09_EVIDENCE_DIR = joinpath(
    @__DIR__, "..", "..", "..", "eda", "tables", "julia", "09_download_inventory",
)

function read_eda09(table_name)
    path = joinpath(EDA09_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    ## keep empty-string cells as empty strings, not `missing`
    return CSV.read(path, DataFrame; missingstring = nothing)
end

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

#md # ```@raw html
#md # <details><summary>Show tree-rendering code</summary>
#md # ```

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

#md # ```@raw html
#md # </details>
#md # ```

print(tree_text) #hide

# ## Interpretation after execution
#
# The download root (`data/pisp-downloads/`) contained 8,250 files totalling roughly 66.7 GB at the time this page was last regenerated.
# `Traces/` is the largest top-level entry by both file count (8,074 files, almost entirely half-hourly demand/solar/wind CSVs) and size (~50.3 GB), followed by `zip/` (64 files, ~19.0 GB, the original downloaded archives retained alongside their extracted contents).
# Everything else is comparatively small: the `2024 ISP Model` directory (~0.5 GB) is the only other top-level entry that mixes file types (`csv` and `xml`), reflecting the PLEXOS model files it holds alongside its own nested `Traces/` subfolder, and the remaining workbook files and `Auxiliary`/`Core`/`Sensitivities` directories are all `xlsx`-only and under 30 MB each.
# All nine top-level entries documented in [Data sources](@ref)'s configured-artifact table were present in this checkout; this page does not itself compare filenames against that table row by row, so a genuinely missing or renamed artifact would need to be checked against that page directly.
