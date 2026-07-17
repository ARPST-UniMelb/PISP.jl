```@meta
EditURL = "../../../literate/validation/source_data_inventory.jl"
```

# Source-data inventory

This page walks the local PISP download root directly, producing a file inventory, a top-level summary, an extension summary, and a depth-limited directory tree, all computed live on this page.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames
using Printf

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

EdaSupport.snapshot_metadata_line(REPO_ROOT; context = "local PISP download tree inventory")

const SCRIPT_STEM = "09_download_inventory"
const DOWNLOAD_ROOT = joinpath("data", "2024", "pisp-downloads")  # kept relative: this is the path form recorded in the tables below
const MAX_TREE_DEPTH = 3
const MAX_TREE_CHILDREN_PER_DIR = 3
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a DOWNLOAD_ROOT-relative path to an absolute location for reading

to_forward_slashes(path) = replace(path, "\\" => "/")

function lowercase_extension(name)
    ext = lowercase(splitext(name)[2])
    return isempty(ext) ? "" : ext[2:end]
end
````

```@raw html
</details>
```

````
Snapshot: PISP.jl commit bba8297+dirty, generated 2026-07-17 — local PISP download tree inventory

````

Single recursive walk of the download tree that produces both a flat file inventory (every depth) and a depth-limited directory-tree listing, so the tree structure does not need a second filesystem walk.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
            # Depth alone does not bound how many files sit in one directory (e.g. a single Traces/<tech>_<year>/ folder holds hundreds of per-location trace CSVs); cap the listed files per directory so the rendered tree stays readable, and record how many were omitted rather than silently truncating.
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
````

```@raw html
</details>
```

One row per immediate child of the download root, whether a file or a directory. Directory rows aggregate recursively over `files`; a plain file's own extension is not repeated in `extensions` since that column describes what is found *under* an entry, not the entry itself.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

Renders the depth-limited directory-tree rows as an indented plain-text tree, root-first.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

## Step 1 — walk the local download tree

A single recursive walk over the download root produces a flat file inventory (every file, at every depth) and a depth-limited directory-tree listing in the same pass.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isdir(abs_path(DOWNLOAD_ROOT)) || error(
    "expected local download tree at \"$DOWNLOAD_ROOT\"; " *
    "run the PISP downloader to populate $(DOWNLOAD_ROOT)/ before rendering this page",
)

files, tree_rows = walk_download_root(abs_path(DOWNLOAD_ROOT))
println("Total files discovered under ", DOWNLOAD_ROOT, ": ", length(files))
````

```@raw html
</details>
```

````
Total files discovered under data/2024/pisp-downloads: 8250

````

## Step 2 — file inventory, top-level summary, and extension summary

`file_inventory` lists every discovered file; the full inventory is written as evidence, while the table below previews only the ten largest files by size. `top_level_summary` aggregates by immediate child of the download root, and `extension_summary` aggregates by file extension across the whole tree.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
file_inventory = DataFrame(files)
write_table(file_inventory, SCRIPT_STEM, "file_inventory")
println("Full file inventory written: ", nrow(file_inventory), " rows (previewing the ten largest files below)")

largest_files = first(sort(file_inventory, :size_bytes; rev = true), 10)
markdown_table(largest_files)
````

```@raw html
</details>
```

| **relative\_path** | **size\_bytes** | **extension** | **depth** |
|--:|--:|--:|--:|
| zip/Traces/57\_ISP\_Wind\_Traces\_r2018.zip | 361191687 | zip | 3 |
| zip/Traces/53\_ISP\_Wind\_Traces\_r2014.zip | 361112039 | zip | 3 |
| zip/Traces/51\_ISP\_Wind\_Traces\_r2012.zip | 361090963 | zip | 3 |
| zip/Traces/52\_ISP\_Wind\_Traces\_r2013.zip | 360736109 | zip | 3 |
| zip/Traces/58\_ISP\_Wind\_Traces\_r2019.zip | 360572827 | zip | 3 |
| zip/Traces/50\_ISP\_Wind\_Traces\_r2011.zip | 359615789 | zip | 3 |
| zip/Traces/55\_ISP\_Wind\_Traces\_r2016.zip | 359156768 | zip | 3 |
| zip/Traces/56\_ISP\_Wind\_Traces\_r2017.zip | 358943761 | zip | 3 |
| zip/Traces/54\_ISP\_Wind\_Traces\_r2015.zip | 358554638 | zip | 3 |
| zip/Traces/60\_ISP\_Wind\_Traces\_r2021.zip | 342367162 | zip | 3 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
top_level_summary = summarize_top_level(abs_path(DOWNLOAD_ROOT), files)
write_table(top_level_summary, SCRIPT_STEM, "top_level_summary")
markdown_table(top_level_summary)
````

```@raw html
</details>
```

| **name** | **kind** | **file\_count** | **total\_bytes** | **extensions** |
|--:|--:|--:|--:|--:|
| 2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx | file | 1 | 25926656 |  |
| 2023-iasr-ev-workbook.xlsx | file | 1 | 505291 |  |
| 2024 ISP Model | directory | 90 | 495584080 | csv,xml |
| 2024-isp-inputs-and-assumptions-workbook.xlsx | file | 1 | 11339818 |  |
| Auxiliary | directory | 7 | 6282064 | xlsx |
| Core | directory | 3 | 27871688 | xlsx |
| Sensitivities | directory | 9 | 31047416 | xlsx |
| Traces | directory | 8074 | 50348183696 | csv |
| zip | directory | 64 | 19034494645 | zip |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
extension_summary = summarize_extensions(files)
write_table(extension_summary, SCRIPT_STEM, "extension_summary")
markdown_table(extension_summary)
````

```@raw html
</details>
```

| **extension** | **file\_count** | **total\_bytes** |
|--:|--:|--:|
| csv | 8158 | 50752303703 |
| xlsx | 22 | 102972933 |
| xml | 6 | 91464073 |
| zip | 64 | 19034494645 |


## Step 3 — directory tree (depth ≤ 3)

The tree below mirrors the on-disk folder layout down to three levels deep. Some folders hold far more files than are useful to list one by one — a single `Traces/<tech>_<year>/` folder holds hundreds of near-identical per-location trace CSVs — so a folder with many files shows only its first several, followed by a line stating how many more were left out.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
directory_tree = DataFrame(tree_rows)
write_table(directory_tree, SCRIPT_STEM, "directory_tree")
nrow(directory_tree)
````

```@raw html
</details>
```

````
359
````

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tree_text = render_tree(directory_tree);

````

```@raw html
</details>
```

````
pisp-downloads/
  - 2024 ISP Model/
    - 2024 ISP Green Energy Exports/
      - Traces/
      - 2024 ISP Green Energy Exports Model.xml
      - PLEXOS_Solverparam.xml
    - 2024 ISP Progressive Change/
      - Traces/
      - 2024 ISP Progressive Change Model.xml
      - PLEXOS_Solverparam.xml
    - 2024 ISP Step Change/
      - Traces/
      - 2024 ISP Step Change Model.xml
      - PLEXOS_Solverparam.xml
  - Auxiliary/
    - 2024 ISP - Green Energy Exports - Core_REZCAP.xlsx
    - 2024 ISP - Progressive Change - Core_REZCAP.xlsx
    - 2024 ISP - Step Change - Core_REZCAP.xlsx
    - ... (4 more files omitted)
  - Core/
    - 2024 ISP - Green Energy Exports - Core.xlsx
    - 2024 ISP - Progressive Change - Core.xlsx
    - 2024 ISP - Step Change - Core.xlsx
  - Sensitivities/
    - 2024 ISP - Green Energy Exports - Extended Eraring.xlsx
    - 2024 ISP - Progressive Change - Extended Eraring.xlsx
    - 2024 ISP - Step Change - Additional Load.xlsx
    - ... (6 more files omitted)
  - Traces/
    - demand_CNSW_Green Energy Exports/
      - CNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - CNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - CNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CNSW_Progressive Change/
      - CNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - CNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - CNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CNSW_Step Change/
      - CNSW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - CNSW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - CNSW_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CQ_Green Energy Exports/
      - CQ_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - CQ_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - CQ_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CQ_Progressive Change/
      - CQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - CQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - CQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CQ_Step Change/
      - CQ_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - CQ_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - CQ_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CSA_Green Energy Exports/
      - CSA_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - CSA_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - CSA_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CSA_Progressive Change/
      - CSA_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - CSA_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - CSA_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_CSA_Step Change/
      - CSA_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - CSA_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - CSA_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_GG_Green Energy Exports/
      - GG_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - GG_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - GG_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_GG_Progressive Change/
      - GG_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - GG_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - GG_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_GG_Step Change/
      - GG_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - GG_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - GG_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_NNSW_Green Energy Exports/
      - NNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - NNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - NNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_NNSW_Progressive Change/
      - NNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - NNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - NNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_NNSW_Step Change/
      - NNSW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - NNSW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - NNSW_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_NQ_Green Energy Exports/
      - NQ_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - NQ_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - NQ_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_NQ_Progressive Change/
      - NQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - NQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - NQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_NQ_Step Change/
      - NQ_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - NQ_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - NQ_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SESA_Green Energy Exports/
      - SESA_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - SESA_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - SESA_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SESA_Progressive Change/
      - SESA_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - SESA_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SESA_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SESA_Step Change/
      - SESA_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - SESA_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SESA_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SNSW_Green Energy Exports/
      - SNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - SNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - SNSW_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SNSW_Progressive Change/
      - SNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - SNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SNSW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SNSW_Step Change/
      - SNSW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - SNSW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SNSW_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SNW_Green Energy Exports/
      - SNW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - SNW_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - SNW_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SNW_Progressive Change/
      - SNW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - SNW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SNW_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SNW_Step Change/
      - SNW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - SNW_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SNW_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SQ_Green Energy Exports/
      - SQ_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - SQ_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - SQ_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SQ_Progressive Change/
      - SQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - SQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SQ_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_SQ_Step Change/
      - SQ_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - SQ_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - SQ_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_TAS_Green Energy Exports/
      - TAS_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - TAS_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - TAS_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_TAS_Progressive Change/
      - TAS_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - TAS_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - TAS_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_TAS_Step Change/
      - TAS_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - TAS_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - TAS_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_VIC_Green Energy Exports/
      - VIC_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING.csv
      - VIC_RefYear_2011_HYDROGEN_EXPORT_POE10_OPSO_MODELLING_PVLITE.csv
      - VIC_RefYear_2011_HYDROGEN_EXPORT_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_VIC_Progressive Change/
      - VIC_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING.csv
      - VIC_RefYear_2011_PROGRESSIVE_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - VIC_RefYear_2011_PROGRESSIVE_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - demand_VIC_Step Change/
      - VIC_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING.csv
      - VIC_RefYear_2011_STEP_CHANGE_POE10_OPSO_MODELLING_PVLITE.csv
      - VIC_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv
      - ... (77 more files omitted)
    - solar_2011/
      - Adelaide_Desal_FFP_RefYear2011.csv
      - Aramara_SAT_RefYear2011.csv
      - Avonlie_SAT_RefYear2011.csv
      - ... (186 more files omitted)
    - solar_2012/
      - Adelaide_Desal_FFP_RefYear2012.csv
      - Aramara_SAT_RefYear2012.csv
      - Avonlie_SAT_RefYear2012.csv
      - ... (186 more files omitted)
    - solar_2013/
      - Adelaide_Desal_FFP_RefYear2013.csv
      - Aramara_SAT_RefYear2013.csv
      - Avonlie_SAT_RefYear2013.csv
      - ... (186 more files omitted)
    - solar_2014/
      - Adelaide_Desal_FFP_RefYear2014.csv
      - Aramara_SAT_RefYear2014.csv
      - Avonlie_SAT_RefYear2014.csv
      - ... (186 more files omitted)
    - solar_2015/
      - Adelaide_Desal_FFP_RefYear2015.csv
      - Aramara_SAT_RefYear2015.csv
      - Avonlie_SAT_RefYear2015.csv
      - ... (186 more files omitted)
    - solar_2016/
      - Adelaide_Desal_FFP_RefYear2016.csv
      - Aramara_SAT_RefYear2016.csv
      - Avonlie_SAT_RefYear2016.csv
      - ... (186 more files omitted)
    - solar_2017/
      - Adelaide_Desal_FFP_RefYear2017.csv
      - Aramara_SAT_RefYear2017.csv
      - Avonlie_SAT_RefYear2017.csv
      - ... (186 more files omitted)
    - solar_2018/
      - Adelaide_Desal_FFP_RefYear2018.csv
      - Aramara_SAT_RefYear2018.csv
      - Avonlie_SAT_RefYear2018.csv
      - ... (186 more files omitted)
    - solar_2019/
      - Adelaide_Desal_FFP_RefYear2019.csv
      - Aramara_SAT_RefYear2019.csv
      - Avonlie_SAT_RefYear2019.csv
      - ... (186 more files omitted)
    - solar_2020/
      - Adelaide_Desal_FFP_RefYear2020.csv
      - Aramara_SAT_RefYear2020.csv
      - Avonlie_SAT_RefYear2020.csv
      - ... (186 more files omitted)
    - solar_2021/
      - Adelaide_Desal_FFP_RefYear2021.csv
      - Aramara_SAT_RefYear2021.csv
      - Avonlie_SAT_RefYear2021.csv
      - ... (186 more files omitted)
    - solar_2022/
      - Adelaide_Desal_FFP_RefYear2022.csv
      - Aramara_SAT_RefYear2022.csv
      - Avonlie_SAT_RefYear2022.csv
      - ... (186 more files omitted)
    - solar_2023/
      - Adelaide_Desal_FFP_RefYear2023.csv
      - Aramara_SAT_RefYear2023.csv
      - Avonlie_SAT_RefYear2023.csv
      - ... (186 more files omitted)
    - solar_4006/
      - Adelaide_Desal_FFP_RefYear4006.csv
      - Aramara_SAT_RefYear4006.csv
      - Avonlie_SAT_RefYear4006.csv
      - ... (186 more files omitted)
    - wind_2011/
      - ARWF1_RefYear2011.csv
      - BALDHWF1_RefYear2011.csv
      - BANGOWF1_RefYear2011.csv
      - ... (179 more files omitted)
    - wind_2012/
      - ARWF1_RefYear2012.csv
      - BALDHWF1_RefYear2012.csv
      - BANGOWF1_RefYear2012.csv
      - ... (179 more files omitted)
    - wind_2013/
      - ARWF1_RefYear2013.csv
      - BALDHWF1_RefYear2013.csv
      - BANGOWF1_RefYear2013.csv
      - ... (179 more files omitted)
    - wind_2014/
      - ARWF1_RefYear2014.csv
      - BALDHWF1_RefYear2014.csv
      - BANGOWF1_RefYear2014.csv
      - ... (179 more files omitted)
    - wind_2015/
      - ARWF1_RefYear2015.csv
      - BALDHWF1_RefYear2015.csv
      - BANGOWF1_RefYear2015.csv
      - ... (179 more files omitted)
    - wind_2016/
      - ARWF1_RefYear2016.csv
      - BALDHWF1_RefYear2016.csv
      - BANGOWF1_RefYear2016.csv
      - ... (179 more files omitted)
    - wind_2017/
      - ARWF1_RefYear2017.csv
      - BALDHWF1_RefYear2017.csv
      - BANGOWF1_RefYear2017.csv
      - ... (179 more files omitted)
    - wind_2018/
      - ARWF1_RefYear2018.csv
      - BALDHWF1_RefYear2018.csv
      - BANGOWF1_RefYear2018.csv
      - ... (179 more files omitted)
    - wind_2019/
      - ARWF1_RefYear2019.csv
      - BALDHWF1_RefYear2019.csv
      - BANGOWF1_RefYear2019.csv
      - ... (179 more files omitted)
    - wind_2020/
      - ARWF1_RefYear2020.csv
      - BALDHWF1_RefYear2020.csv
      - BANGOWF1_RefYear2020.csv
      - ... (179 more files omitted)
    - wind_2021/
      - ARWF1_RefYear2021.csv
      - BALDHWF1_RefYear2021.csv
      - BANGOWF1_RefYear2021.csv
      - ... (179 more files omitted)
    - wind_2022/
      - ARWF1_RefYear2022.csv
      - BALDHWF1_RefYear2022.csv
      - BANGOWF1_RefYear2022.csv
      - ... (179 more files omitted)
    - wind_2023/
      - ARWF1_RefYear2023.csv
      - BALDHWF1_RefYear2023.csv
      - BANGOWF1_RefYear2023.csv
      - ... (179 more files omitted)
    - wind_4006/
      - ARWF1_RefYear4006.csv
      - BALDHWF1_RefYear4006.csv
      - BANGOWF1_RefYear4006.csv
      - ... (179 more files omitted)
  - zip/
    - Traces/
      - 01_ISP_Demand_Traces_CNSW_Green_Energy_Exports.zip
      - 02_ISP_Demand_Traces_CNSW_Progressive_Change.zip
      - 03_ISP_Demand_Traces_CNSW_Step_Change.zip
      - ... (59 more files omitted)
    - 2024-isp-generation-and-storage-outlook.zip
    - 2024-isp-model.zip
  - 2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx
  - 2023-iasr-ev-workbook.xlsx
  - 2024-isp-inputs-and-assumptions-workbook.xlsx

````

## Step 4 — inventory totals

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
markdown_table(inventory_summary)
````

```@raw html
</details>
```

| **download\_root** | **total\_files** | **total\_bytes** | **tree\_depth** | **max\_files\_per\_directory** | **top\_level\_entries** | **largest\_entry** | **largest\_entry\_bytes** |
|--:|--:|--:|--:|--:|--:|--:|--:|
| data/2024/pisp-downloads | 8250 | 69981235354 | 3 | 3 | 9 | Traces | 50348183696 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
@printf("Total: %d files, %.2f MB under %s\n", length(files), total_bytes / (1024^2), DOWNLOAD_ROOT)
````

```@raw html
</details>
```

````
Total: 8250 files, 66739.31 MB under data/2024/pisp-downloads

````

## Summary

- The download root currently holds the file counts and sizes shown in `inventory_summary` above, broken down by top-level entry and by file extension.
- The full per-file inventory (`file_inventory.csv`) and the depth-limited directory tree (`directory_tree.csv`) are both written as evidence for downstream inspection, even though only bounded previews are rendered on this page.

