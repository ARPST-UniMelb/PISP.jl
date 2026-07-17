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

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))
const INPUT_ROOT = normpath(get(ENV, "PISP_DATA_ROOT", joinpath(REPO_ROOT, "data", "2024", "pisp-downloads")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

replace(relpath(INPUT_ROOT, REPO_ROOT), '\\' => '/')
````

```@raw html
</details>
```

````
"data/2024/pisp-downloads"
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
markdown_table(configured_downloads)
````

```@raw html
</details>
```

| **key** | **published\_artifact** | **local\_filename** | **subdirectory** |
|--:|--:|--:|--:|
| isp24\_inputs | 2024 ISP Inputs and Assumptions workbook | 2024-isp-inputs-and-assumptions-workbook.xlsx |  |
| iasr23\_ev\_workbook | 2023 IASR EV workbook | 2023-iasr-ev-workbook.xlsx |  |
| isp24\_model | 2024 ISP Model | 2024-isp-model.zip |  |
| isp24\_outlook | 2024 ISP generation and storage outlook | 2024-isp-generation-and-storage-outlook.zip |  |
| isp19\_inputs\_v13 | 2019 input and assumptions workbook v1.3 | 2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx |  |


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
markdown_table(trace_downloader)
````

```@raw html
</details>
```

| **publication\_page** | **output\_directory** | **link\_selector** |
|--:|--:|--:|
| https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp | scrapped/ISP\_2024\_traces | Cascadia.Selector(Cascadia.var"#descendantSelector##0#descendantSelector##1"{Cascadia.Selector, Cascadia.Selector}(Cascadia.Selector(Cascadia.var"#intersectionSelector##0#intersectionSelector##1"{Cascadia.Selector, Cascadia.Selector}(Cascadia.Selector(Cascadia.var"#typeSelector##0#typeSelector##1"{String}("div")), Cascadia.Selector(Cascadia.var"#attributeSelector##0#attributeSelector##1"{Cascadia.var"#attributeIncludesSelector##0#attributeIncludesSelector##1"{String}, String}(Cascadia.var"#attributeIncludesSelector##0#attributeIncludesSelector##1"{String}("field-link"), "class")))), Cascadia.Selector(Cascadia.var"#typeSelector##0#typeSelector##1"{String}("a")))) |


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
markdown_table(expected_input_status)
````

```@raw html
</details>
```

| **input** | **relative\_path** | **observed\_kind** | **exists** |
|--:|--:|--:|--:|
| ispdata19 | 2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx | file | true |
| ispdata24 | 2024-isp-inputs-and-assumptions-workbook.xlsx | file | true |
| iasr23\_ev\_workbook | 2023-iasr-ev-workbook.xlsx | file | true |
| ispmodel | 2024 ISP Model | directory | true |
| profiledata | Traces | directory | true |
| outlookdata | Core | directory | true |
| outlookAEMO | Auxiliary/CapacityOutlook2024\_Condensed.xlsx | file | true |
| vpp\_cap | Auxiliary/StorageCapacityOutlook\_2024\_ISP.xlsx | file | true |
| vpp\_ene | Auxiliary/StorageEnergyOutlook\_2024\_ISP.xlsx | file | true |


## Source roles

The 2024 Inputs and Assumptions workbook supplies most structured planning assumptions. The ISP model archive supplies model-side material such as hydro inflow data; the generation and storage outlook supplies future development information; the trace archives supply half-hourly demand, solar, and wind profiles; and the supplementary 2023 and 2019 workbooks provide inputs that are not available in the main 2024 workbook.

Source-derived values, code-derived values, and package assumptions have different provenance and update requirements. A new publication may require parser changes, while a changed package mapping can alter outputs even when the downloaded files are unchanged.

## Local inventory

[Source-data inventory](@ref) provides a recursive, dated inventory of the files actually present under the local download root.

