```@meta
EditURL = "../../../literate/eda_05_temperature_analysis.jl"
```

# Assessing temperature-related information and climate-zone variation

Temperature can affect demand, renewable output, thermal ratings, and equipment reliability, but those effects are not automatically represented by a planning dataset. This page presents temperature- or reliability-related workbook material, fields exported by PISP, and summer solar summaries for selected climate-zone proxies.

No observed temperature time series is loaded, and no causal temperature-response model is estimated.
Climate-zone comparisons are descriptive solar-trace comparisons, not direct measurements of thermal derating.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames

const EDA05_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "05_temperature_analysis",
)

function read_eda05(table_name)
    path = joinpath(EDA05_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda05(table; rows = 16) = first(table, min(rows, nrow(table)))
````

```@raw html
</details>
```

````
preview_eda05 (generic function with 1 method)
````

## What relevant workbook material exists?

The sheet inventory records keyword matches and the shapes of potentially relevant worksheets.
A keyword match identifies material for review; it does not prove that the sheet contains a usable temperature dependency.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
workbook_sheet_inventory = read_eda05("workbook_sheet_inventory")
preview_eda05(workbook_sheet_inventory; rows = 24)

workbook_relevant_sheet_shapes = read_eda05("workbook_relevant_sheet_shapes")
workbook_relevant_sheet_shapes

workbook_rooftop_sheet_summary = read_eda05("workbook_rooftop_sheet_summary")
workbook_rooftop_sheet_summary

workbook_reliability_sheet_shapes = read_eda05("workbook_reliability_sheet_shapes")
workbook_reliability_sheet_shapes
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">sheet_name</th><th style = "text-align: left;">n_rows</th><th style = "text-align: left;">n_cols</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Transmission Reliability</td><td style = "text-align: right;">11</td><td style = "text-align: right;">7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Generator Reliability Settings</td><td style = "text-align: right;">64</td><td style = "text-align: right;">14</td></tr></tbody></table></div>
```

## What temperature-related fields reach the output dataset?

The output inventory and generator-column table distinguish information present in the downloaded workbook from fields exported by PISP.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
pisp_output_inventory = read_eda05("pisp_output_inventory")
pisp_output_inventory

generator_temperature_columns = read_eda05("generator_temperature_columns")
generator_temperature_columns
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">generator_table_exists</th><th style = "text-align: left;">total_columns</th><th style = "text-align: left;">n_temp_columns</th><th style = "text-align: left;">temp_columns_list</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Missing" style = "text-align: left;">Missing</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: right;">48</td><td style = "text-align: right;">0</td><td style = "font-style: italic; text-align: right;">missing</td></tr></tbody></table></div>
```

Solar and wind generator details provide the static reliability and capacity fields available for later modelling.
Their presence should not be interpreted as a temperature-dependent outage or derating process.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
generator_solar_wind_details = read_eda05("generator_solar_wind_details")
preview_eda05(generator_solar_wind_details; rows = 20)
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>20×9 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">category</th><th style = "text-align: left;">id_gen</th><th style = "text-align: left;">name</th><th style = "text-align: left;">tech</th><th style = "text-align: left;">forate</th><th style = "text-align: left;">derate</th><th style = "text-align: left;">pmin</th><th style = "text-align: left;">pmax</th><th style = "text-align: left;">n</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">92</td><td style = "text-align: left;">RTPV_NQ</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">93</td><td style = "text-align: left;">RTPV_CQ</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">94</td><td style = "text-align: left;">RTPV_GG</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">95</td><td style = "text-align: left;">RTPV_SQ</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">96</td><td style = "text-align: left;">RTPV_NNSW</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">97</td><td style = "text-align: left;">RTPV_CNSW</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">98</td><td style = "text-align: left;">RTPV_SNW</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">99</td><td style = "text-align: left;">RTPV_SNSW</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">100</td><td style = "text-align: left;">RTPV_VIC</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">101</td><td style = "text-align: left;">RTPV_TAS</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">102</td><td style = "text-align: left;">RTPV_CSA</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">103</td><td style = "text-align: left;">RTPV_SESA</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">104</td><td style = "text-align: left;">LSPV_CQ</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">869.9</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">105</td><td style = "text-align: left;">LSPV_VIC</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">1313.68</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">106</td><td style = "text-align: left;">LSPV_NNSW</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">721.0</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">107</td><td style = "text-align: left;">LSPV_SQ</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">2042.66</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">108</td><td style = "text-align: left;">LSPV_CSA</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">648.04</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">109</td><td style = "text-align: left;">LSPV_NQ</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">599.97</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">110</td><td style = "text-align: left;">LSPV_SNSW</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">2345.46</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">111</td><td style = "text-align: left;">LSPV_CNSW</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">2053.78</td><td style = "text-align: right;">1</td></tr></tbody></table></div>
```

## How do selected climate-zone solar traces differ?

The zone labels are analytical groupings attached to representative sites.
The summary describes summer solar capacity-factor distributions and does not isolate temperature from cloud, season, geography, or trace construction.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
climate_zone_summer_cf_summary = read_eda05("climate_zone_summer_cf_summary")
climate_zone_summer_cf_summary
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>4×7 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">zone</th><th style = "text-align: left;">location</th><th style = "text-align: left;">n_summer_days</th><th style = "text-align: left;">mean_daily_cf</th><th style = "text-align: left;">mean_midday_cf</th><th style = "text-align: left;">min_midday_cf</th><th style = "text-align: left;">p5_midday_cf</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Hot_Inland</td><td style = "text-align: left;">Bomen_SAT</td><td style = "text-align: right;">3068</td><td style = "text-align: right;">0.379055</td><td style = "text-align: right;">0.771988</td><td style = "text-align: right;">0.054019</td><td style = "text-align: right;">0.219576</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Hot_SA</td><td style = "text-align: left;">Cultana_SAT</td><td style = "text-align: right;">3068</td><td style = "text-align: right;">0.37932</td><td style = "text-align: right;">0.847259</td><td style = "text-align: right;">0.230202</td><td style = "text-align: right;">0.303985</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">Moderate_VIC</td><td style = "text-align: left;">Bannerton_SAT</td><td style = "text-align: right;">3068</td><td style = "text-align: right;">0.404872</td><td style = "text-align: right;">0.859197</td><td style = "text-align: right;">0.1881</td><td style = "text-align: right;">0.307869</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Cool_TAS</td><td style = "text-align: left;">Derby_SAT</td><td style = "text-align: right;">3068</td><td style = "text-align: right;">0.387393</td><td style = "text-align: right;">0.810406</td><td style = "text-align: right;">0.0913513</td><td style = "text-align: right;">0.321397</td></tr></tbody></table></div>
```

