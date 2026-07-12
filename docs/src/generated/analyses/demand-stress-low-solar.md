```@meta
EditURL = "../../../literate/eda_07_demand_heat_events.jl"
```

# Demand stress and low-solar coincidence

High demand can coincide with low renewable availability, but that relationship depends on aligned dates, explicit thresholds, and the event definition. This page presents Victorian demand distributions, demand-defined stress days, hourly demand profiles, and solar availability on selected high-demand dates.

Here, `heat event` is an operational label for days at or above the 95th percentile of demand.
It does not use air temperature, an excess-heat factor, or a meteorological heatwave definition.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames

const EDA07_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "07_demand_heat_events",
)

function read_eda07(table_name)
    path = joinpath(EDA07_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

preview_eda07(table; rows = 16) = first(table, min(rows, nrow(table)))
````

```@raw html
</details>
```

````
preview_eda07 (generic function with 1 method)
````

## Demand and trace coverage

The trace inventory and area-level daily demand table establish the available inputs before the Victorian subset is analysed.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_trace_inventory = read_eda07("demand_trace_inventory")
preview_eda07(demand_trace_inventory; rows = 12)

demand_by_area_daily = read_eda07("demand_by_area_daily")
preview_eda07(demand_by_area_daily; rows = 20)
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>20×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">date</th><th style = "text-align: left;">area</th><th style = "text-align: left;">demand_mw</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2030-01-01</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2036.17</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">2030-01-02</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1930.09</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">2030-01-03</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1976.31</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">2030-01-04</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2048.65</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">2030-01-05</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1929.37</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">2030-01-06</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1902.88</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">2030-01-07</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1991.96</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">2030-01-08</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1990.8</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">2030-01-09</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1928.44</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">2030-01-10</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1976.25</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">2030-01-11</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2047.65</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">2030-01-12</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1981.62</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">2030-01-13</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1967.9</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">2030-01-14</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2108.76</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: left;">2030-01-15</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2093.02</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: left;">2030-01-16</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2144.17</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: left;">2030-01-17</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2601.81</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: left;">2030-01-18</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2594.38</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: left;">2030-01-19</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2212.96</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: left;">2030-01-20</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2220.58</td></tr></tbody></table></div>
```

## Victorian demand and solar alignment

The merged table contains only dates present in both the PISP demand schedule and the selected Victorian solar trace.
Any missing-date pattern should be reviewed before interpreting coincidence statistics.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vic_demand_solar_merged = read_eda07("vic_demand_solar_merged")
preview_eda07(vic_demand_solar_merged; rows = 20)
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>20×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">date</th><th style = "text-align: left;">demand</th><th style = "text-align: left;">solar_cf</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2030-01-01</td><td style = "text-align: right;">5012.78</td><td style = "text-align: right;">0.397264</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">2030-01-02</td><td style = "text-align: right;">9777.6</td><td style = "text-align: right;">0.483717</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">2030-01-03</td><td style = "text-align: right;">6687.24</td><td style = "text-align: right;">0.241476</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">2030-01-04</td><td style = "text-align: right;">6436.95</td><td style = "text-align: right;">0.489338</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">2030-01-05</td><td style = "text-align: right;">6886.62</td><td style = "text-align: right;">0.410079</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">2030-01-06</td><td style = "text-align: right;">5249.67</td><td style = "text-align: right;">0.251517</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">2030-01-07</td><td style = "text-align: right;">5809.83</td><td style = "text-align: right;">0.48421</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">2030-01-08</td><td style = "text-align: right;">6366.19</td><td style = "text-align: right;">0.473849</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">2030-01-09</td><td style = "text-align: right;">9789.05</td><td style = "text-align: right;">0.483717</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">2030-01-10</td><td style = "text-align: right;">6702.25</td><td style = "text-align: right;">0.241476</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">2030-01-11</td><td style = "text-align: right;">5773.31</td><td style = "text-align: right;">0.0329821</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">2030-01-12</td><td style = "text-align: right;">5155.83</td><td style = "text-align: right;">0.0367703</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">2030-01-13</td><td style = "text-align: right;">5249.45</td><td style = "text-align: right;">0.101861</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">2030-01-14</td><td style = "text-align: right;">6380.67</td><td style = "text-align: right;">0.20895</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: left;">2030-01-15</td><td style = "text-align: right;">6168.14</td><td style = "text-align: right;">0.28795</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: left;">2030-01-16</td><td style = "text-align: right;">5943.89</td><td style = "text-align: right;">0.153562</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: left;">2030-01-17</td><td style = "text-align: right;">5776.23</td><td style = "text-align: right;">0.416609</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: left;">2030-01-18</td><td style = "text-align: right;">5876.0</td><td style = "text-align: right;">0.481258</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: left;">2030-01-19</td><td style = "text-align: right;">5299.23</td><td style = "text-align: right;">0.425757</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: left;">2030-01-20</td><td style = "text-align: right;">5004.8</td><td style = "text-align: right;">0.480979</td></tr></tbody></table></div>
```

## High-demand and low-solar threshold screen

The screen uses the 90th demand percentile and 10th solar-capacity-factor percentile within the merged sample.
These are relative thresholds, so the resulting count depends on the selected period and is not an absolute adequacy criterion.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
high_demand_low_solar_summary = read_eda07("high_demand_low_solar_summary")
high_demand_low_solar_summary
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×6 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">demand_quantile</th><th style = "text-align: left;">solar_quantile</th><th style = "text-align: left;">threshold_demand_mw</th><th style = "text-align: left;">threshold_solar_cf</th><th style = "text-align: left;">bad_day_count</th><th style = "text-align: left;">total_day_count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">0.9</td><td style = "text-align: right;">0.1</td><td style = "text-align: right;">7139.93</td><td style = "text-align: right;">0.0912422</td><td style = "text-align: right;">3</td><td style = "text-align: right;">365</td></tr></tbody></table></div>
```

## Demand-defined stress days

The summary records the P90 and P95 demand thresholds, event counts, and peak-demand date.
The hourly profile then compares demand on P95 stress days with days below P90.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_heat_event_summary = read_eda07("demand_heat_event_summary")
demand_heat_event_summary

heat_normal_hourly_profile = read_eda07("heat_normal_hourly_profile")
heat_normal_hourly_profile
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>24×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">hour</th><th style = "text-align: left;">heat_mean_demand_mw</th><th style = "text-align: left;">normal_mean_demand_mw</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">0</td><td style = "text-align: right;">6422.62</td><td style = "text-align: right;">5424.77</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">1</td><td style = "text-align: right;">6301.45</td><td style = "text-align: right;">5226.55</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">2</td><td style = "text-align: right;">5921.9</td><td style = "text-align: right;">4870.9</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">3</td><td style = "text-align: right;">5684.41</td><td style = "text-align: right;">4683.32</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">4</td><td style = "text-align: right;">5686.27</td><td style = "text-align: right;">4705.25</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: right;">5</td><td style = "text-align: right;">6059.81</td><td style = "text-align: right;">5041.43</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: right;">6</td><td style = "text-align: right;">7054.82</td><td style = "text-align: right;">5721.08</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: right;">7</td><td style = "text-align: right;">8047.01</td><td style = "text-align: right;">6217.16</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: right;">8</td><td style = "text-align: right;">8703.03</td><td style = "text-align: right;">6635.65</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: right;">9</td><td style = "text-align: right;">9027.88</td><td style = "text-align: right;">6867.61</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: right;">10</td><td style = "text-align: right;">9138.19</td><td style = "text-align: right;">6982.72</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: right;">11</td><td style = "text-align: right;">9198.58</td><td style = "text-align: right;">7023.56</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: right;">12</td><td style = "text-align: right;">9233.39</td><td style = "text-align: right;">6997.17</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: right;">13</td><td style = "text-align: right;">9248.78</td><td style = "text-align: right;">6933.84</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: right;">14</td><td style = "text-align: right;">9094.69</td><td style = "text-align: right;">6796.92</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: right;">15</td><td style = "text-align: right;">8991.5</td><td style = "text-align: right;">6717.16</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: right;">16</td><td style = "text-align: right;">9076.8</td><td style = "text-align: right;">6708.16</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: right;">17</td><td style = "text-align: right;">9251.63</td><td style = "text-align: right;">6750.31</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: right;">18</td><td style = "text-align: right;">9136.51</td><td style = "text-align: right;">6747.13</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: right;">19</td><td style = "text-align: right;">8749.59</td><td style = "text-align: right;">6628.25</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">21</td><td style = "text-align: right;">20</td><td style = "text-align: right;">8389.32</td><td style = "text-align: right;">6422.13</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">22</td><td style = "text-align: right;">21</td><td style = "text-align: right;">7834.15</td><td style = "text-align: right;">6030.69</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">23</td><td style = "text-align: right;">22</td><td style = "text-align: right;">7209.96</td><td style = "text-align: right;">5690.17</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">24</td><td style = "text-align: right;">23</td><td style = "text-align: right;">6945.96</td><td style = "text-align: right;">5797.04</td></tr></tbody></table></div>
```

## Demand duration and normalised coincidence

Duration-curve and normalised tables preserve ranking information but discard chronology.
They can describe distributional alignment, not event persistence or sequential operational stress.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
demand_duration_curve = read_eda07("demand_duration_curve")
preview_eda07(demand_duration_curve; rows = 20)

normalized_vre_demand_summary = read_eda07("normalized_vre_demand_summary")
preview_eda07(normalized_vre_demand_summary; rows = 20)
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>20×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">day_rank</th><th style = "text-align: left;">demand_norm</th><th style = "text-align: left;">solar_norm</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: right;">0.482939</td><td style = "text-align: right;">0.385833</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: right;">0.494892</td><td style = "text-align: right;">0.932854</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: right;">0.511265</td><td style = "text-align: right;">0.963109</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">4</td><td style = "text-align: right;">0.51208</td><td style = "text-align: right;">0.795478</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">5</td><td style = "text-align: right;">0.5158</td><td style = "text-align: right;">0.943357</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: right;">6</td><td style = "text-align: right;">0.519674</td><td style = "text-align: right;">0.544215</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: right;">7</td><td style = "text-align: right;">0.52186</td><td style = "text-align: right;">0.963681</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: right;">8</td><td style = "text-align: right;">0.522755</td><td style = "text-align: right;">0.669011</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: right;">9</td><td style = "text-align: right;">0.525825</td><td style = "text-align: right;">0.588245</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: right;">10</td><td style = "text-align: right;">0.526694</td><td style = "text-align: right;">0.0736285</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: right;">11</td><td style = "text-align: right;">0.528977</td><td style = "text-align: right;">1.0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: right;">12</td><td style = "text-align: right;">0.531846</td><td style = "text-align: right;">0.85552</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: right;">13</td><td style = "text-align: right;">0.531855</td><td style = "text-align: right;">0.83574</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: right;">14</td><td style = "text-align: right;">0.532694</td><td style = "text-align: right;">0.946325</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: right;">15</td><td style = "text-align: right;">0.53424</td><td style = "text-align: right;">0.844643</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: right;">16</td><td style = "text-align: right;">0.534835</td><td style = "text-align: right;">0.531605</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: right;">17</td><td style = "text-align: right;">0.535648</td><td style = "text-align: right;">0.850889</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: right;">18</td><td style = "text-align: right;">0.536257</td><td style = "text-align: right;">0.203966</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: right;">19</td><td style = "text-align: right;">0.53628</td><td style = "text-align: right;">0.503635</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: right;">20</td><td style = "text-align: right;">0.537416</td><td style = "text-align: right;">0.678979</td></tr></tbody></table></div>
```

## Solar availability on the highest-demand days

The detail table reports solar capacity factor for the selected top-demand dates that could be matched to the trace.
It should be read with the representative-site and date-alignment limitations above.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hot_day_solar_cf_detail = read_eda07("hot_day_solar_cf_detail")
hot_day_solar_cf_detail
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>10×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">rank</th><th style = "text-align: left;">date</th><th style = "text-align: left;">solar_cf</th><th style = "text-align: left;">mean_solar_cf_top10</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: left;">2030-01-02</td><td style = "text-align: right;">0.483717</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-09</td><td style = "text-align: right;">0.483717</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: left;">2030-01-24</td><td style = "text-align: right;">0.47003</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">4</td><td style = "text-align: left;">2030-02-13</td><td style = "text-align: right;">0.42786</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">5</td><td style = "text-align: left;">2030-05-15</td><td style = "text-align: right;">0.217938</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: right;">6</td><td style = "text-align: left;">2030-06-03</td><td style = "text-align: right;">0.211081</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: right;">7</td><td style = "text-align: left;">2030-06-04</td><td style = "text-align: right;">0.148711</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: right;">8</td><td style = "text-align: left;">2030-06-05</td><td style = "text-align: right;">0.186725</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: right;">9</td><td style = "text-align: left;">2030-06-06</td><td style = "text-align: right;">0.140501</td><td style = "text-align: right;">0.294279</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: right;">10</td><td style = "text-align: left;">2030-06-14</td><td style = "text-align: right;">0.172506</td><td style = "text-align: right;">0.294279</td></tr></tbody></table></div>
```

