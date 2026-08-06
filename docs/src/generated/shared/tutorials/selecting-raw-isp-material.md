```@meta
EditURL = "../../../../literate/shared/tutorials/selecting_raw_isp_material.jl"
```

# ISP 2024 and ISP 2026: Selecting raw source material

This tutorial selects one demand trace from ISP 2024 and one renewable trace
from ISP 2026. The 2024 example uses a registered `SourceSpec`; the 2026
example uses the edition profile and the released trace filename.

## Selection inputs

The ISP 2024 example selects an operational-demand trace by subregion,
scenario, reference-weather trace, and demand probability of exceedance.
It defaults to VIC, Step Change, `reftrace = 2017`, and `poe = 10`.
Set `ParseISP_DOCS_RAW_REFTRACE` or `ParseISP_DOCS_RAW_POE` to choose another ISP
2024 trace, including composite trace `4006` where that combination exists.

[Domain concepts](../../../concepts.md) explains why planning year is separate
from the raw-source selectors used here.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames
using ParseISP

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

function integer_selection(variable, default)
    value = get(ENV, variable, string(default))
    parsed = tryparse(Int, value)
    parsed === nothing && error("$variable must be an integer, received $(repr(value))")
    return parsed
end

const ISP2024 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")
const RAW_SUBREGION = get(ENV, "ParseISP_DOCS_RAW_SUBREGION", "VIC")
const RAW_SCENARIO = get(ENV, "ParseISP_DOCS_RAW_SCENARIO", "Step Change")
haskey(ParseISP.DEMSCE, RAW_SCENARIO) || error(
    "unknown ISP 2024 demand scenario $(repr(RAW_SCENARIO)); choose one of $(join(keys(ParseISP.DEMSCE), ", "))",
)
const RAW_SCENARIO_CODE = ParseISP.DEMSCE[RAW_SCENARIO]
const RAW_REFTRACE = integer_selection("ParseISP_DOCS_RAW_REFTRACE", 2017)
const RAW_POE = integer_selection("ParseISP_DOCS_RAW_POE", 10)
const DEMAND_SOURCE = ParseISP.source_spec(:operational_demand_trace, 2024)
const ISP2024_TRACE_ROOT = joinpath(ISP2024.download_root, "Traces")
const ISP2024_DEMAND_PATH = ParseISP.source_path(
    ISP2024_TRACE_ROOT,
    DEMAND_SOURCE;
    subregion = RAW_SUBREGION,
    scenario = RAW_SCENARIO,
    reference_year = RAW_REFTRACE,
    scenario_code = RAW_SCENARIO_CODE,
    poe = RAW_POE,
)
isfile(ISP2024_DEMAND_PATH) || error(
    "the requested ISP 2024 demand trace was not found: " * relpath(ISP2024_DEMAND_PATH, REPO_ROOT),
)
````

```@raw html
</details>
```

## Resolve an ISP 2024 `SourceSpec`

`ParseISP.source_spec` owns the filename template, while `ParseISP.source_path`
substitutes the selected dimensions. The resulting path can be passed to the
package reader without copying the filename pattern into downstream code.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isp2024_demand = ParseISP.read_csv_source(ISP2024_DEMAND_PATH, DEMAND_SOURCE)
isp2024_selection = DataFrame(
    Dimension = ["Subregion", "Scenario", "Reference-weather trace", "Demand POE", "Source file"],
    Selection = [
        RAW_SUBREGION,
        RAW_SCENARIO,
        string(RAW_REFTRACE),
        string(RAW_POE),
        replace(relpath(ISP2024_DEMAND_PATH, REPO_ROOT), '\\' => '/'),
    ],
)

ParseISPDocUtils.markdown_table(isp2024_selection)
````

```@raw html
</details>
```

| **Dimension** | **Selection** |
|:--|:--|
| Subregion | VIC |
| Scenario | Step Change |
| Reference-weather trace | 2017 |
| Demand POE | 10 |
| Source file | data/2024/pisp-downloads/Traces/demand\_VIC\_Step Change/VIC\_RefYear\_2017\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING\_PVLITE.csv |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isp2024_shape = DataFrame(
    Measure = ["Rows", "Columns", "First date column", "Last half-hourly column"],
    Value = [nrow(isp2024_demand), ncol(isp2024_demand), first(names(isp2024_demand)), last(names(isp2024_demand))],
)
ParseISPDocUtils.markdown_table(isp2024_shape)
````

```@raw html
</details>
```

| **Measure** | **Value** |
|:--|:--|
| Rows | 11323 |
| Columns | 51 |
| First date column | Year |
| Last half-hourly column | 48 |


## Select an ISP 2026 renewable trace

The ISP 2026 solar and wind archives use project-level CSV files.
Their filenames use `RefYear5000`; this label is not assumed to have the same
meaning as ISP 2024 trace `2017` or composite trace `4006`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
const ISP2026 = ParseISPDocUtils.edition_profile(REPO_ROOT, "2026")
const ISP2026_TRACE_FAMILY = lowercase(get(ENV, "ParseISP_DOCS_ISP2026_TRACE_FAMILY", "solar"))
ISP2026_TRACE_FAMILY in ("solar", "wind") || error(
    "ParseISP_DOCS_ISP2026_TRACE_FAMILY must be solar or wind",
)
const ISP2026_TRACE_ROOT = if ISP2026_TRACE_FAMILY == "solar"
    joinpath(ISP2026.download_root, "Traces", "2026 ISP Solar traces", "solar")
else
    joinpath(ISP2026.download_root, "Traces", "2026 ISP Wind traces", "wind")
end
isdir(ISP2026_TRACE_ROOT) || error(
    "the selected ISP 2026 trace folder was not found: " * relpath(ISP2026_TRACE_ROOT, REPO_ROOT),
)
available_2026_traces = sort(filter(name -> endswith(lowercase(name), ".csv"), readdir(ISP2026_TRACE_ROOT)))
isempty(available_2026_traces) && error("the selected ISP 2026 trace folder contains no CSV files")
const ISP2026_TRACE_FILE = get(ENV, "ParseISP_DOCS_ISP2026_TRACE_FILE", first(available_2026_traces))
ISP2026_TRACE_FILE in available_2026_traces || error(
    "the requested ISP 2026 trace file was not found; choose one of the CSV filenames in the selected folder",
)
const ISP2026_TRACE_PATH = joinpath(ISP2026_TRACE_ROOT, ISP2026_TRACE_FILE)

isp2026_trace = CSV.read(ISP2026_TRACE_PATH, DataFrame)
isp2026_selection = DataFrame(
    Dimension = ["Edition", "Selection method", "Trace family", "Reference label in filename", "Source file"],
    Selection = [
        "2026",
        "Edition profile and filename",
        ISP2026_TRACE_FAMILY,
        occursin("RefYear5000", ISP2026_TRACE_FILE) ? "RefYear5000" : "No RefYear5000 token",
        replace(relpath(ISP2026_TRACE_PATH, REPO_ROOT), '\\' => '/'),
    ],
)

ParseISPDocUtils.markdown_table(isp2026_selection)
````

```@raw html
</details>
```

| **Dimension** | **Selection** |
|:--|:--|
| Edition | 2026 |
| Selection method | Edition profile and filename |
| Trace family | solar |
| Reference label in filename | RefYear5000 |
| Source file | data/2026/pisp-downloads/Traces/2026 ISP Solar traces/solar/Adelaide\_Desal\_FFP\_RefYear5000.csv |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isp2026_shape = DataFrame(
    Measure = ["CSV files in family", "Rows in selected file", "Columns in selected file"],
    Value = [length(available_2026_traces), nrow(isp2026_trace), ncol(isp2026_trace)],
)
ParseISPDocUtils.markdown_table(isp2026_shape)
````

```@raw html
</details>
```

| **Measure** | **Value** |
|:--|--:|
| CSV files in family | 248 |
| Rows in selected file | 9131 |
| Columns in selected file | 51 |


## Interpretation

The ISP 2024 example resolves a package source specification with scenario,
weather-trace, and POE selectors. The ISP 2026 example selects a project CSV
from the released solar or wind archive. A matching filename token across
editions is not enough to establish the same modelling meaning.
