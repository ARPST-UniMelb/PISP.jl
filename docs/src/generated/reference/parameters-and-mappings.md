```@meta
EditURL = "../../../literate/reference/parameters_and_mappings.jl"
```

# Parameters and mappings

PISP uses package-defined identifiers and mappings to reconcile source files that do not share one canonical naming system. The tables below list the current scenario, bus, area, weather-year, and reliability-field mappings.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames
using Dates
````

```@raw html
</details>
```

## Scenario identifiers and source labels

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
scenario_mappings = DataFrame([
    (
        scenario_id = scenario_id,
        scenario_name = scenario_name,
        hydro_label = PISP.HYDROSCE[scenario_name],
        demand_trace_label = PISP.DEMSCE[scenario_name],
    )
    for (scenario_id, scenario_name) in PISP.ID2SCE
])
scenario_mappings
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>3×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">scenario_id</th><th style = "text-align: left;">scenario_name</th><th style = "text-align: left;">hydro_label</th><th style = "text-align: left;">demand_trace_label</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: left;">Progressive Change</td><td style = "text-align: left;">NetZero2050</td><td style = "text-align: left;">PROGRESSIVE_CHANGE</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: left;">Step Change</td><td style = "text-align: left;">StepChange</td><td style = "text-align: left;">STEP_CHANGE</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: left;">Green Energy Exports</td><td style = "text-align: left;">HydrogenSuperpower</td><td style = "text-align: left;">HYDROGEN_EXPORT</td></tr></tbody></table></div>
```

## Bus and area constants

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
bus_aliases = collect(keys(PISP.NEMBUSNAME))
bus_area_mappings = DataFrame([
    (
        bus_id = index,
        alias = alias,
        name = PISP.NEMBUSNAME[alias],
        area = PISP.BUS2AREA[alias],
        area_id = PISP.STID[PISP.BUS2AREA[alias]],
        latitude = PISP.NEMBUSES[alias][1],
        longitude = PISP.NEMBUSES[alias][2],
    )
    for (index, alias) in enumerate(bus_aliases)
])
bus_area_mappings
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>12×7 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">bus_id</th><th style = "text-align: left;">alias</th><th style = "text-align: left;">name</th><th style = "text-align: left;">area</th><th style = "text-align: left;">area_id</th><th style = "text-align: left;">latitude</th><th style = "text-align: left;">longitude</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: left;">NQ</td><td style = "text-align: left;">Northern Queensland</td><td style = "text-align: left;">QLD</td><td style = "text-align: right;">1</td><td style = "text-align: right;">-17.7938</td><td style = "text-align: right;">145.564</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: left;">CQ</td><td style = "text-align: left;">Central Queensland</td><td style = "text-align: left;">QLD</td><td style = "text-align: right;">1</td><td style = "text-align: right;">-22.8242</td><td style = "text-align: right;">149.404</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: left;">GG</td><td style = "text-align: left;">Gladstone Grid</td><td style = "text-align: left;">QLD</td><td style = "text-align: right;">1</td><td style = "text-align: right;">-23.8429</td><td style = "text-align: right;">151.249</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">4</td><td style = "text-align: left;">SQ</td><td style = "text-align: left;">Southern Queensland</td><td style = "text-align: left;">QLD</td><td style = "text-align: right;">1</td><td style = "text-align: right;">-27.4766</td><td style = "text-align: right;">153.03</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">5</td><td style = "text-align: left;">NNSW</td><td style = "text-align: left;">Northern New South Wales</td><td style = "text-align: left;">NSW</td><td style = "text-align: right;">2</td><td style = "text-align: right;">-30.5047</td><td style = "text-align: right;">151.652</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: right;">6</td><td style = "text-align: left;">CNSW</td><td style = "text-align: left;">Central New South Wales</td><td style = "text-align: left;">NSW</td><td style = "text-align: right;">2</td><td style = "text-align: right;">-33.4833</td><td style = "text-align: right;">150.158</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: right;">7</td><td style = "text-align: left;">SNW</td><td style = "text-align: left;">Sydney, Newcastle &amp; Wollongong</td><td style = "text-align: left;">NSW</td><td style = "text-align: right;">2</td><td style = "text-align: right;">-33.865</td><td style = "text-align: right;">151.209</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: right;">8</td><td style = "text-align: left;">SNSW</td><td style = "text-align: left;">Southern New South Wales</td><td style = "text-align: left;">NSW</td><td style = "text-align: right;">2</td><td style = "text-align: right;">-35.111</td><td style = "text-align: right;">147.36</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: right;">9</td><td style = "text-align: left;">VIC</td><td style = "text-align: left;">Victoria</td><td style = "text-align: left;">VIC</td><td style = "text-align: right;">3</td><td style = "text-align: right;">-37.7661</td><td style = "text-align: right;">144.943</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: right;">10</td><td style = "text-align: left;">TAS</td><td style = "text-align: left;">Tasmania</td><td style = "text-align: left;">TAS</td><td style = "text-align: right;">4</td><td style = "text-align: right;">-42.8806</td><td style = "text-align: right;">147.325</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: right;">11</td><td style = "text-align: left;">CSA</td><td style = "text-align: left;">Central South Australia</td><td style = "text-align: left;">SA</td><td style = "text-align: right;">5</td><td style = "text-align: right;">-34.8027</td><td style = "text-align: right;">138.522</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: right;">12</td><td style = "text-align: left;">SESA</td><td style = "text-align: left;">South East South Australia</td><td style = "text-align: left;">SA</td><td style = "text-align: right;">5</td><td style = "text-align: right;">-37.6047</td><td style = "text-align: right;">140.837</td></tr></tbody></table></div>
```

## Reference trace 4006 weather-year mapping

The composite trace maps each financial-year interval to a historical weather year. Repeated historical years are part of the mapping and should be considered when comparing planning periods.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
weather_year_mapping = DataFrame([
    (
        financial_year_start = Date(window[1]),
        financial_year_end = Date(window[2]),
        weather_year = parse(Int, weather_year),
    )
    for (window, weather_year) in PISP.WEATHER_YEARS_ISP
])
sort!(weather_year_mapping, :financial_year_start)
weather_year_mapping
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>28×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">financial_year_start</th><th style = "text-align: left;">financial_year_end</th><th style = "text-align: left;">weather_year</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2024-07-01</td><td style = "text-align: left;">2025-06-30</td><td style = "text-align: right;">2019</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">2025-07-01</td><td style = "text-align: left;">2026-06-30</td><td style = "text-align: right;">2020</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">2026-07-01</td><td style = "text-align: left;">2027-06-30</td><td style = "text-align: right;">2021</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">2027-07-01</td><td style = "text-align: left;">2028-06-30</td><td style = "text-align: right;">2022</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">2028-07-01</td><td style = "text-align: left;">2029-06-30</td><td style = "text-align: right;">2023</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">2029-07-01</td><td style = "text-align: left;">2030-06-30</td><td style = "text-align: right;">2015</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">2030-07-01</td><td style = "text-align: left;">2031-06-30</td><td style = "text-align: right;">2011</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">2031-07-01</td><td style = "text-align: left;">2032-06-30</td><td style = "text-align: right;">2012</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">2032-07-01</td><td style = "text-align: left;">2033-06-30</td><td style = "text-align: right;">2013</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">2033-07-01</td><td style = "text-align: left;">2034-06-30</td><td style = "text-align: right;">2014</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">2034-07-01</td><td style = "text-align: left;">2035-06-30</td><td style = "text-align: right;">2015</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">2035-07-01</td><td style = "text-align: left;">2036-06-30</td><td style = "text-align: right;">2016</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">2036-07-01</td><td style = "text-align: left;">2037-06-30</td><td style = "text-align: right;">2017</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">2037-07-01</td><td style = "text-align: left;">2038-06-30</td><td style = "text-align: right;">2018</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: left;">2038-07-01</td><td style = "text-align: left;">2039-06-30</td><td style = "text-align: right;">2019</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: left;">2039-07-01</td><td style = "text-align: left;">2040-06-30</td><td style = "text-align: right;">2020</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: left;">2040-07-01</td><td style = "text-align: left;">2041-06-30</td><td style = "text-align: right;">2021</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: left;">2041-07-01</td><td style = "text-align: left;">2042-06-30</td><td style = "text-align: right;">2022</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: left;">2042-07-01</td><td style = "text-align: left;">2043-06-30</td><td style = "text-align: right;">2023</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: left;">2043-07-01</td><td style = "text-align: left;">2044-06-30</td><td style = "text-align: right;">2015</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">21</td><td style = "text-align: left;">2044-07-01</td><td style = "text-align: left;">2045-06-30</td><td style = "text-align: right;">2011</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">22</td><td style = "text-align: left;">2045-07-01</td><td style = "text-align: left;">2046-06-30</td><td style = "text-align: right;">2012</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">23</td><td style = "text-align: left;">2046-07-01</td><td style = "text-align: left;">2047-06-30</td><td style = "text-align: right;">2013</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">24</td><td style = "text-align: left;">2047-07-01</td><td style = "text-align: left;">2048-06-30</td><td style = "text-align: right;">2014</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">25</td><td style = "text-align: left;">2048-07-01</td><td style = "text-align: left;">2049-06-30</td><td style = "text-align: right;">2015</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">26</td><td style = "text-align: left;">2049-07-01</td><td style = "text-align: left;">2050-06-30</td><td style = "text-align: right;">2016</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">27</td><td style = "text-align: left;">2050-07-01</td><td style = "text-align: left;">2051-06-30</td><td style = "text-align: right;">2017</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">28</td><td style = "text-align: left;">2051-07-01</td><td style = "text-align: left;">2052-06-30</td><td style = "text-align: right;">2018</td></tr></tbody></table></div>
```

## Reliability fields represented in static schemas

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function reliability_fields(table_name)
    schema = PISP.TABLES_POWERSYSTEM[table_name]
    names = [
        column
        for column in keys(schema)
        if occursin(r"forate|out|derate|mttr"i, column)
    ]
    return join(names, ", ")
end

reliability_schema = DataFrame([
    (asset_table = table_name, fields = reliability_fields(table_name))
    for table_name in ("Generator", "ESS", "Line")
])
reliability_schema
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>3×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">asset_table</th><th style = "text-align: left;">fields</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Generator</td><td style = "text-align: left;">forate, fullout, partialout, derate, mttrfull, mttrpart, last_state_output</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">ESS</td><td style = "text-align: left;">fullout, partialout, mttrfull, mttrpart</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">Line</td><td style = "text-align: left;">fullout, mttrfull</td></tr></tbody></table></div>
```

## Using the mappings

Scenario labels, source-specific aliases, bus assignments, weather-year mappings, technology groupings, retirement schedules, and build-out templates are modelling inputs rather than incidental filenames. Changes to these mappings can change generated datasets without any change to the downloaded source files.

Rooftop PV and utility-scale renewable capacity fields require special care. The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator. See [Assumptions and scope](@ref).

