```@meta
EditURL = "../../../literate/eda_09_download_inventory.jl"
```

# Source-data inventory

This page lists the files and directories present under the selected PISP download root. The snapshot metadata identifies the inspected path and generation time.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames

const EDA09_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "09_download_inventory",
)

function read_eda09(table_name)
    path = joinpath(EDA09_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    # keep empty-string cells as empty strings, not `missing`
    return CSV.read(path, DataFrame; missingstring = nothing)
end
````

```@raw html
</details>
```

````
read_eda09 (generic function with 1 method)
````

## Inventory snapshot

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
snapshot_metadata = read_eda09("snapshot_metadata")
snapshot_metadata
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×6 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">generated_at_utc</th><th style = "text-align: left;">download_root</th><th style = "text-align: left;">total_files</th><th style = "text-align: left;">total_bytes</th><th style = "text-align: left;">tree_depth</th><th style = "text-align: left;">max_files_per_directory</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2026-07-12T03:53:22Z</td><td style = "text-align: left;">data/pisp-downloads</td><td style = "text-align: right;">8250</td><td style = "text-align: right;">69981235354</td><td style = "text-align: right;">3</td><td style = "text-align: right;">3</td></tr></tbody></table></div>
```

## Top-level summary

One row per immediate child of the download root, whether a plain file or a directory.
`file_count` and `total_bytes` are recursive for directories; `extensions` lists the distinct file extensions found under a directory (empty for a plain file, since a file has no children to list extensions for).

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
top_level_summary = read_eda09("top_level_summary")
top_level_summary
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>9×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">name</th><th style = "text-align: left;">kind</th><th style = "text-align: left;">file_count</th><th style = "text-align: left;">total_bytes</th><th style = "text-align: left;">extensions</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">1</td><td style = "text-align: right;">25926656</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">2023-iasr-ev-workbook.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">1</td><td style = "text-align: right;">505291</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">2024 ISP Model</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">90</td><td style = "text-align: right;">495584080</td><td style = "text-align: left;">csv,xml</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">2024-isp-inputs-and-assumptions-workbook.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">1</td><td style = "text-align: right;">11339818</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Auxiliary</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">7</td><td style = "text-align: right;">6282064</td><td style = "text-align: left;">xlsx</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">Core</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">3</td><td style = "text-align: right;">27871688</td><td style = "text-align: left;">xlsx</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">Sensitivities</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">9</td><td style = "text-align: right;">31047416</td><td style = "text-align: left;">xlsx</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">Traces</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">8074</td><td style = "text-align: right;">50348183696</td><td style = "text-align: left;">csv</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">zip</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">64</td><td style = "text-align: right;">19034494645</td><td style = "text-align: left;">zip</td></tr></tbody></table></div>
```

## Extension summary

One row per distinct file extension across the whole tree, with the total file count and byte size for that extension.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
extension_summary = read_eda09("extension_summary")
extension_summary
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>4×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">extension</th><th style = "text-align: left;">file_count</th><th style = "text-align: left;">total_bytes</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">csv</td><td style = "text-align: right;">8158</td><td style = "text-align: right;">50752303703</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">xlsx</td><td style = "text-align: right;">22</td><td style = "text-align: right;">102972933</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">xml</td><td style = "text-align: right;">6</td><td style = "text-align: right;">91464073</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">zip</td><td style = "text-align: right;">64</td><td style = "text-align: right;">19034494645</td></tr></tbody></table></div>
```

## Directory tree (depth ≤ 3)

The tree below mirrors the on-disk folder layout down to three levels deep.
Some folders hold far more files than are useful to list one by one — a single `Traces/<tech>_<year>/` folder holds hundreds of near-identical per-location trace CSVs — so a folder with many files shows only its first several, followed by a line stating how many more were left out.

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

directory_tree = read_eda09("directory_tree")
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

## Inventory totals

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">total_files</th><th style = "text-align: left;">total_bytes</th><th style = "text-align: left;">top_level_entries</th><th style = "text-align: left;">largest_entry</th><th style = "text-align: left;">largest_entry_bytes</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">8250</td><td style = "text-align: right;">69981235354</td><td style = "text-align: right;">9</td><td style = "text-align: left;">Traces</td><td style = "text-align: right;">50348183696</td></tr></tbody></table></div>
```

