```@meta
EditURL = "../../../literate/reference/data_sources.jl"
```

# Data sources

PISP combines AEMO workbooks, model archives, development outlooks, and time-series traces with package-defined mappings. The tables below list the configured download targets and the input paths used by the current build pipeline.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))
const INPUT_ROOT = normpath(get(ENV, "PISP_DATA_ROOT", joinpath(REPO_ROOT, "data", "pisp-downloads")))
````

```@raw html
</details>
```

````
"/Users/myasirroni/Documents/Git/arpst-unimelb-agents/projects/PISP.jl/data/pisp-downloads"
````

## Configured reference-file downloads

These rows come directly from `PISP.ISPFileDownloader.isp_file_targets()`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
targets = PISP.ISPFileDownloader.isp_file_targets()
configured_downloads = DataFrame(
    key = string.([target.key for target in targets]),
    published_artifact = [target.title for target in targets],
    local_filename = [something(target.filename, "derived from URL") for target in targets],
    subdirectory = [something(target.subdir, "") for target in targets],
)
configured_downloads
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>5×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">key</th><th style = "text-align: left;">published_artifact</th><th style = "text-align: left;">local_filename</th><th style = "text-align: left;">subdirectory</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">isp24_inputs</td><td style = "text-align: left;">2024 ISP Inputs and Assumptions workbook</td><td style = "text-align: left;">2024-isp-inputs-and-assumptions-workbook.xlsx</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">iasr23_ev_workbook</td><td style = "text-align: left;">2023 IASR EV workbook</td><td style = "text-align: left;">2023-iasr-ev-workbook.xlsx</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">isp24_model</td><td style = "text-align: left;">2024 ISP Model</td><td style = "text-align: left;">2024-isp-model.zip</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">isp24_outlook</td><td style = "text-align: left;">2024 ISP generation and storage outlook</td><td style = "text-align: left;">2024-isp-generation-and-storage-outlook.zip</td><td style = "text-align: left;"></td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">isp19_inputs_v13</td><td style = "text-align: left;">2019 input and assumptions workbook v1.3</td><td style = "text-align: left;">2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx</td><td style = "text-align: left;"></td></tr></tbody></table></div>
```

Demand, solar, and wind traces are discovered from the configured ISP publication page and downloaded separately from the fixed reference-file targets.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_downloader = DataFrame([
    (
        publication_page = PISP.ISPTraceDownloader.DEFAULT_PAGE_URL,
        output_directory = PISP.ISPTraceDownloader.DEFAULT_OUTDIR,
        link_selector = string(PISP.ISPTraceDownloader.TRACE_SELECTOR),
    ),
])
trace_downloader
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">publication_page</th><th style = "text-align: left;">output_directory</th><th style = "text-align: left;">link_selector</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp</td><td style = "text-align: left;">scrapped/ISP_2024_traces</td><td style = "text-align: left;">Cascadia.Selector(Cascadia.var&quot;#descendantSelector##0#descendantSelector##1&quot;{Cascadia.Selector, Cascadia.Selector}(Cascadia.Selector(Cascadia.var&quot;#intersectionSelector##0#intersectionSelector##1&quot;{Cascadia.Selector, Cascadia.Selector}(Cascadia.Selector(Cascadia.var&quot;#typeSelector##0#typeSelector##1&quot;{String}(&quot;div&quot;)), Cascadia.Selector(Cascadia.var&quot;#attributeSelector##0#attributeSelector##1&quot;{Cascadia.var&quot;#attributeIncludesSelector##0#attributeIncludesSelector##1&quot;{String}, String}(Cascadia.var&quot;#attributeIncludesSelector##0#attributeIncludesSelector##1&quot;{String}(&quot;field-link&quot;), &quot;class&quot;)))), Cascadia.Selector(Cascadia.var&quot;#typeSelector##0#typeSelector##1&quot;{String}(&quot;a&quot;))))</td></tr></tbody></table></div>
```

## Expected build inputs

`PISP.default_data_paths` defines the input paths used by the build pipeline. The `exists` column reports whether each path is present under the selected local input root. Set `PISP_DATA_ROOT` to use a different checkout.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
expected_paths = PISP.default_data_paths(filepath = INPUT_ROOT)
expected_input_status = DataFrame([
    (
        input = string(name),
        relative_path = replace(relpath(path, INPUT_ROOT), '\\' => '/'),
        observed_kind = isdir(path) ? "directory" : isfile(path) ? "file" : "not present",
        exists = ispath(path),
    )
    for (name, path) in pairs(expected_paths)
])
expected_input_status
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>9×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">input</th><th style = "text-align: left;">relative_path</th><th style = "text-align: left;">observed_kind</th><th style = "text-align: left;">exists</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "Bool" style = "text-align: left;">Bool</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">ispdata19</td><td style = "text-align: left;">2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">ispdata24</td><td style = "text-align: left;">2024-isp-inputs-and-assumptions-workbook.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">iasr23_ev_workbook</td><td style = "text-align: left;">2023-iasr-ev-workbook.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">ispmodel</td><td style = "text-align: left;">2024 ISP Model</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">profiledata</td><td style = "text-align: left;">Traces</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">outlookdata</td><td style = "text-align: left;">Core</td><td style = "text-align: left;">directory</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">outlookAEMO</td><td style = "text-align: left;">Auxiliary/CapacityOutlook2024_Condensed.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">vpp_cap</td><td style = "text-align: left;">Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">true</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">vpp_ene</td><td style = "text-align: left;">Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx</td><td style = "text-align: left;">file</td><td style = "text-align: right;">true</td></tr></tbody></table></div>
```

## Source roles

The 2024 Inputs and Assumptions workbook supplies most structured planning assumptions. The ISP model archive supplies model-side material such as hydro inflow data; the generation and storage outlook supplies future development information; the trace archives supply half-hourly demand, solar, and wind profiles; and the supplementary 2023 and 2019 workbooks provide inputs that are not available in the main 2024 workbook.

Source-derived values, code-derived values, and package assumptions have different provenance and update requirements. A new publication may require parser changes, while a changed package mapping can alter outputs even when the downloaded files are unchanged.

## Local inventory

[Source-data inventory](@ref) provides a recursive, dated inventory of the files actually present under the local download root.

