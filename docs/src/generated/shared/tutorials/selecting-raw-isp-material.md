```@meta
EditURL = "../../../../literate/shared/tutorials/selecting_raw_isp_material.jl"
```

# ISP 2024 and ISP 2026: Selecting raw source material

PISP resolves registered ISP 2024 sources through `SourceSpec` objects.
ISP 2026 currently has download and extraction support but no registered source specifications, parser, dataset builder, or generated-output contract.
This tutorial keeps those interfaces separate while showing one trace selection from each edition.

## Selection inputs

The ISP 2024 example selects an operational-demand trace by subregion, scenario, reference-weather trace, and demand probability of exceedance.
It defaults to VIC, Step Change, `reftrace = 2017`, and `poe = 10`.
Set `PISP_DOCS_RAW_REFTRACE` or `PISP_DOCS_RAW_POE` to choose another available ISP 2024 trace, including composite trace `4006` where that combination exists.

Planning year is not a `SourceSpec` replacement token.
It determines the generated `schedule-<year>` output after preprocessing; composite trace `4006` applies its package-defined historical-weather mapping across planning-year windows.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames
using PISP

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

function integer_selection(variable, default)
    value = get(ENV, variable, string(default))
    parsed = tryparse(Int, value)
    parsed === nothing && error("$variable must be an integer, received $(repr(value))")
    return parsed
end

const ISP2024 = PISPDocUtils.edition_profile(REPO_ROOT, "2024")
const RAW_SUBREGION = get(ENV, "PISP_DOCS_RAW_SUBREGION", "VIC")
const RAW_SCENARIO = get(ENV, "PISP_DOCS_RAW_SCENARIO", "Step Change")
haskey(PISP.DEMSCE, RAW_SCENARIO) || error(
    "unknown ISP 2024 demand scenario $(repr(RAW_SCENARIO)); choose one of $(join(keys(PISP.DEMSCE), ", "))",
)
const RAW_SCENARIO_CODE = PISP.DEMSCE[RAW_SCENARIO]
const RAW_REFTRACE = integer_selection("PISP_DOCS_RAW_REFTRACE", 2017)
const RAW_POE = integer_selection("PISP_DOCS_RAW_POE", 10)
const DEMAND_SOURCE = PISP.source_spec(:operational_demand_trace, 2024)
const ISP2024_TRACE_ROOT = joinpath(ISP2024.download_root, "Traces")
const ISP2024_DEMAND_PATH = PISP.source_path(
    ISP2024_TRACE_ROOT,
    DEMAND_SOURCE;
    subregion = RAW_SUBREGION,
    scenario = RAW_SCENARIO,
    reference_year = RAW_REFTRACE,
    scenario_code = RAW_SCENARIO_CODE,
    poe = RAW_POE,
)
isfile(ISP2024_DEMAND_PATH) || error(
    "the requested ISP 2024 demand trace is unavailable: " * relpath(ISP2024_DEMAND_PATH, REPO_ROOT),
)
````

```@raw html
</details>
```

## Resolve an ISP 2024 `SourceSpec`

`PISP.source_spec` owns the filename template, while `PISP.source_path` substitutes the selected dimensions.
The resulting repository-relative path can be passed to the source's package reader without copying the filename contract into downstream code.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isp2024_demand = PISP.read_csv_source(ISP2024_DEMAND_PATH, DEMAND_SOURCE)
isp2024_selection = DataFrame(
    Dimension = ["Subregion", "Scenario", "Reference-weather trace", "Demand POE", "Resolved source"],
    Selection = [
        RAW_SUBREGION,
        RAW_SCENARIO,
        string(RAW_REFTRACE),
        string(RAW_POE),
        replace(relpath(ISP2024_DEMAND_PATH, REPO_ROOT), '\\' => '/'),
    ],
)

PISPDocUtils.markdown_table(isp2024_selection)
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
| Resolved source | data/2024/pisp-downloads/Traces/demand\_VIC\_Step Change/VIC\_RefYear\_2017\_STEP\_CHANGE\_POE10\_OPSO\_MODELLING\_PVLITE.csv |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isp2024_shape = DataFrame(
    Measure = ["Rows", "Columns", "First date column", "Last hourly column"],
    Value = [nrow(isp2024_demand), ncol(isp2024_demand), first(names(isp2024_demand)), last(names(isp2024_demand))],
)
PISPDocUtils.markdown_table(isp2024_shape)
````

```@raw html
</details>
```

| **Measure** | **Value** |
|:--|:--|
| Rows | 11323 |
| Columns | 51 |
| First date column | Year |
| Last hourly column | 48 |


## Select an observed ISP 2026 trace

PISP currently registers no ISP 2026 `SourceSpec` objects.
The documentation profile therefore identifies the edition root, and the selected source remains an observed file rather than a package parser contract.
The released solar and wind filenames use `RefYear5000`; this label is not treated as equivalent to ISP 2024 trace `2017` or composite trace `4006`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isempty(PISP.source_specs(2026)) || error("this tutorial assumes no registered ISP 2026 SourceSpecs")
const ISP2026 = PISPDocUtils.edition_profile(REPO_ROOT, "2026")
const ISP2026_TRACE_FAMILY = lowercase(get(ENV, "PISP_DOCS_ISP2026_TRACE_FAMILY", "solar"))
ISP2026_TRACE_FAMILY in ("solar", "wind") || error(
    "PISP_DOCS_ISP2026_TRACE_FAMILY must be solar or wind",
)
const ISP2026_TRACE_ROOT = if ISP2026_TRACE_FAMILY == "solar"
    joinpath(ISP2026.download_root, "Traces", "2026 ISP Solar traces", "solar")
else
    joinpath(ISP2026.download_root, "Traces", "2026 ISP Wind traces", "wind")
end
isdir(ISP2026_TRACE_ROOT) || error(
    "the selected ISP 2026 trace family is unavailable: " * relpath(ISP2026_TRACE_ROOT, REPO_ROOT),
)
available_2026_traces = sort(filter(name -> endswith(lowercase(name), ".csv"), readdir(ISP2026_TRACE_ROOT)))
isempty(available_2026_traces) && error("the selected ISP 2026 trace family contains no CSV files")
const ISP2026_TRACE_FILE = get(ENV, "PISP_DOCS_ISP2026_TRACE_FILE", first(available_2026_traces))
ISP2026_TRACE_FILE in available_2026_traces || error(
    "the requested ISP 2026 trace file is unavailable; choose one of the observed CSV filenames",
)
const ISP2026_TRACE_PATH = joinpath(ISP2026_TRACE_ROOT, ISP2026_TRACE_FILE)

isp2026_trace = CSV.read(ISP2026_TRACE_PATH, DataFrame)
isp2026_selection = DataFrame(
    Dimension = ["Edition", "Access interface", "Trace family", "Observed reference label", "Resolved source"],
    Selection = [
        "2026",
        "documentation profile and observed path",
        ISP2026_TRACE_FAMILY,
        occursin("RefYear5000", ISP2026_TRACE_FILE) ? "RefYear5000" : "not encoded as RefYear5000",
        replace(relpath(ISP2026_TRACE_PATH, REPO_ROOT), '\\' => '/'),
    ],
)

PISPDocUtils.markdown_table(isp2026_selection)
````

```@raw html
</details>
```

| **Dimension** | **Selection** |
|:--|:--|
| Edition | 2026 |
| Access interface | documentation profile and observed path |
| Trace family | solar |
| Observed reference label | RefYear5000 |
| Resolved source | data/2026/pisp-downloads/Traces/2026 ISP Solar traces/solar/Adelaide\_Desal\_FFP\_RefYear5000.csv |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
isp2026_shape = DataFrame(
    Measure = ["Observed CSV files in family", "Rows in selected file", "Columns in selected file"],
    Value = [length(available_2026_traces), nrow(isp2026_trace), ncol(isp2026_trace)],
)
PISPDocUtils.markdown_table(isp2026_shape)
````

```@raw html
</details>
```

| **Measure** | **Value** |
|:--|--:|
| Observed CSV files in family | 248 |
| Rows in selected file | 9131 |
| Columns in selected file | 51 |


## Interpretation

ISP 2024 selection is a package contract: the registered source specification owns the path template and the package reader consumes the selected file.
ISP 2026 selection is currently a source-inspection workflow: the profile identifies the downloaded edition root, but the observed path has no integrated PISP parser or output contract.
A matching filename token across editions is not evidence that its modelling meaning is equivalent.

