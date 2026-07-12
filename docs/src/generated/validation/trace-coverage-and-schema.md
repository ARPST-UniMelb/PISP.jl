```@meta
EditURL = "../../../literate/eda_01_data_loading.jl"
```

# Trace data availability and structure

PISP uses historical demand, solar, and wind traces with different directory layouts and table schemas. This page summarises the available reference years, sampled table structures, date coverage, value ranges, and one demand-trace example.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames

const EDA01_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "01_data_loading",
)

function read_eda01(table_name)
    path = joinpath(EDA01_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end
````

```@raw html
</details>
```

````
read_eda01 (generic function with 1 method)
````

## Available reference years

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
available_year_checks = read_eda01("available_year_checks")
available_year_checks
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>4×6 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">year</th><th style = "text-align: left;">solar_file</th><th style = "text-align: left;">exists</th><th style = "text-align: left;">first_year</th><th style = "text-align: left;">first_month</th><th style = "text-align: left;">first_day</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">2011</td><td style = "text-align: left;">data/pisp-downloads/Traces/solar_2011/Bannerton_SAT_RefYear2011.csv</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2021</td><td style = "text-align: right;">7</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2015</td><td style = "text-align: left;">data/pisp-downloads/Traces/solar_2015/Bannerton_SAT_RefYear2015.csv</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2021</td><td style = "text-align: right;">7</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">2019</td><td style = "text-align: left;">data/pisp-downloads/Traces/solar_2019/Bannerton_SAT_RefYear2019.csv</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2021</td><td style = "text-align: right;">7</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">2023</td><td style = "text-align: left;">data/pisp-downloads/Traces/solar_2023/Bannerton_SAT_RefYear2023.csv</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2021</td><td style = "text-align: right;">7</td><td style = "text-align: right;">1</td></tr></tbody></table></div>
```

## Solar and wind table structure

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_shape_columns = read_eda01("trace_shape_columns")
trace_shape_columns
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×10 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">trace_type</th><th style = "text-align: left;">file</th><th style = "text-align: left;">file_name</th><th style = "text-align: left;">rows</th><th style = "text-align: left;">columns</th><th style = "text-align: left;">metadata_columns</th><th style = "text-align: left;">value_columns</th><th style = "text-align: left;">first_value_column</th><th style = "text-align: left;">last_value_column</th><th style = "text-align: left;">columns_preview</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "String" style = "text-align: left;">String</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">solar</td><td style = "text-align: left;">data/pisp-downloads/Traces/solar_4006/Bannerton_SAT_RefYear4006.csv</td><td style = "text-align: left;">Bannerton_SAT_RefYear4006.csv</td><td style = "text-align: right;">10227</td><td style = "text-align: right;">51</td><td style = "text-align: left;">Year,Month,Day</td><td style = "text-align: right;">48</td><td style = "text-align: right;">1</td><td style = "text-align: right;">48</td><td style = "text-align: left;">Year|Month|Day|1|2|3|4|5|6|7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">wind</td><td style = "text-align: left;">data/pisp-downloads/Traces/wind_4006/ARWF1_RefYear4006.csv</td><td style = "text-align: left;">ARWF1_RefYear4006.csv</td><td style = "text-align: right;">10227</td><td style = "text-align: right;">51</td><td style = "text-align: left;">Year,Month,Day</td><td style = "text-align: right;">48</td><td style = "text-align: right;">1</td><td style = "text-align: right;">48</td><td style = "text-align: left;">Year|Month|Day|01|02|03|04|05|06|07</td></tr></tbody></table></div>
```

The date ranges identify the period represented by each sampled trace.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_date_ranges = read_eda01("trace_date_ranges")
trace_date_ranges
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">trace_type</th><th style = "text-align: left;">file_name</th><th style = "text-align: left;">first_year</th><th style = "text-align: left;">first_month</th><th style = "text-align: left;">first_day</th><th style = "text-align: left;">last_year</th><th style = "text-align: left;">last_month</th><th style = "text-align: left;">last_day</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">solar</td><td style = "text-align: left;">Bannerton_SAT_RefYear4006.csv</td><td style = "text-align: right;">2024</td><td style = "text-align: right;">7</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2052</td><td style = "text-align: right;">6</td><td style = "text-align: right;">30</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">wind</td><td style = "text-align: left;">ARWF1_RefYear4006.csv</td><td style = "text-align: right;">2024</td><td style = "text-align: right;">7</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2052</td><td style = "text-align: right;">6</td><td style = "text-align: right;">30</td></tr></tbody></table></div>
```

## Trace value ranges

The minimum and maximum values describe the numeric range in each sampled trace.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
trace_value_ranges = read_eda01("trace_value_ranges")
trace_value_ranges
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">trace_type</th><th style = "text-align: left;">file_name</th><th style = "text-align: left;">min_value</th><th style = "text-align: left;">max_value</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">solar</td><td style = "text-align: left;">Bannerton_SAT_RefYear4006.csv</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">1.0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">wind</td><td style = "text-align: left;">ARWF1_RefYear4006.csv</td><td style = "text-align: right;">-0.0</td><td style = "text-align: right;">1.0</td></tr></tbody></table></div>
```

The solar low-output summary includes the threshold and half-hourly window used for the count.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
solar_midday_low_days = read_eda01("solar_midday_low_days")
solar_midday_low_days
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×7 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">trace_type</th><th style = "text-align: left;">file_name</th><th style = "text-align: left;">midday_columns</th><th style = "text-align: left;">low_threshold</th><th style = "text-align: left;">low_days</th><th style = "text-align: left;">total_days</th><th style = "text-align: left;">low_percent</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "String" style = "text-align: left;">String</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">solar</td><td style = "text-align: left;">Bannerton_SAT_RefYear4006.csv</td><td style = "text-align: left;">24|25|26|27|28|29|30|31|32|33|34|35</td><td style = "text-align: right;">0.1</td><td style = "text-align: right;">67</td><td style = "text-align: right;">10227</td><td style = "text-align: right;">0.655129</td></tr></tbody></table></div>
```

## Demand trace example

Demand traces use a different file family and schema from solar and wind traces. The metadata table records the file count, sample shape, and value-column span.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_sample_metadata = read_eda01("demand_sample_metadata")
demand_sample_metadata
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×10 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">demand_dir</th><th style = "text-align: left;">file_count</th><th style = "text-align: left;">sample_file</th><th style = "text-align: left;">sample_rows</th><th style = "text-align: left;">sample_columns</th><th style = "text-align: left;">metadata_columns</th><th style = "text-align: left;">value_columns</th><th style = "text-align: left;">first_value_column</th><th style = "text-align: left;">last_value_column</th><th style = "text-align: left;">columns_list</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">data/pisp-downloads/Traces/demand_VIC_Step Change</td><td style = "text-align: right;">27</td><td style = "text-align: left;">VIC_RefYear_2011_STEP_CHANGE_POE10_PV_TOT.csv</td><td style = "text-align: right;">11323</td><td style = "text-align: right;">51</td><td style = "text-align: left;">Year,Month,Day</td><td style = "text-align: right;">48</td><td style = "text-align: right;">1</td><td style = "text-align: right;">48</td><td style = "text-align: left;">Year|Month|Day|01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|41|42|43|44|45|46|47|48</td></tr></tbody></table></div>
```

