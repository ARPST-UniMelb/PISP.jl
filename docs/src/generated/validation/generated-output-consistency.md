```@meta
EditURL = "../../../literate/validation/generated_output_consistency.jl"
```

# Generated-output consistency

PISP writes static asset tables and time-varying schedules as one connected dataset. This page describes identifier coverage, schedule coverage, generator classifications, and daily series alignment for one generated build.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames

const EDA06_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", ".."))),
    "eda", "tables", "julia", "06_pisp_outputs",
)

function read_eda06(table_name)
    path = joinpath(EDA06_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame; missingstring = nothing)
end
````

```@raw html
</details>
```

````
read_eda06 (generic function with 1 method)
````

## Build snapshot

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
build_metadata = read_eda06("build_metadata")
build_metadata
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">generated_at_utc</th><th style = "text-align: left;">pisp_output_root</th><th style = "text-align: left;">schedule_tag</th><th style = "text-align: left;">schedule_directory</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "String" style = "text-align: left;">String</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2026-07-12T02:13:22Z</td><td style = "text-align: left;">/Users/myasirroni/Documents/Git/arpst-unimelb-agents/projects/PISP.jl/data/pisp-datasets/out-ref4006-poe10/csv</td><td style = "text-align: left;">schedule-2030</td><td style = "text-align: left;">/Users/myasirroni/Documents/Git/arpst-unimelb-agents/projects/PISP.jl/data/pisp-datasets/out-ref4006-poe10/csv/schedule-2030</td></tr></tbody></table></div>
```

## Schedule coverage

The schedule tables record the row and column counts and the represented time interval for generator PMax and demand load.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
schedule_shapes = read_eda06("schedule_shapes")
schedule_shapes
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">schedule</th><th style = "text-align: left;">n_rows</th><th style = "text-align: left;">n_cols</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Generator_pmax_sched</td><td style = "text-align: right;">289083</td><td style = "text-align: right;">5</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Demand_load_sched</td><td style = "text-align: right;">105120</td><td style = "text-align: right;">5</td></tr></tbody></table></div>
```

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
schedule_time_coverage = read_eda06("schedule_time_coverage")
schedule_time_coverage
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">schedule</th><th style = "text-align: left;">first_timestamp</th><th style = "text-align: left;">last_timestamp</th><th style = "text-align: left;">unique_timestamps</th><th style = "text-align: left;">unique_days</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Generator_pmax_sched</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: left;">2044-07-01T00:00:00</td><td style = "text-align: right;">8761</td><td style = "text-align: right;">366</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Demand_load_sched</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: left;">2030-12-31T23:00:00</td><td style = "text-align: right;">8760</td><td style = "text-align: right;">365</td></tr></tbody></table></div>
```

## Join coverage

The join-coverage table compares schedule identifiers with their static-table identifiers and compares generator and demand bus references with `Bus.csv`. `left_unmatched_ids` identifies schedule or asset rows without a corresponding referenced record. `right_unmatched_ids` identifies static records without a corresponding row in the compared table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
join_coverage = read_eda06("join_coverage")
join_coverage
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>4×7 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">relationship</th><th style = "text-align: left;">left_label</th><th style = "text-align: left;">right_label</th><th style = "text-align: left;">left_unique_ids</th><th style = "text-align: left;">right_unique_ids</th><th style = "text-align: left;">left_unmatched_ids</th><th style = "text-align: left;">right_unmatched_ids</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator_pmax_sched.id_gen</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">34</td><td style = "text-align: right;">124</td><td style = "text-align: right;">0</td><td style = "text-align: right;">90</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">demand schedule to static demand</td><td style = "text-align: left;">Demand_load_sched.id_dem</td><td style = "text-align: left;">Demand.id_dem</td><td style = "text-align: right;">12</td><td style = "text-align: right;">12</td><td style = "text-align: right;">0</td><td style = "text-align: right;">0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">generator bus to bus table</td><td style = "text-align: left;">Generator.id_bus</td><td style = "text-align: left;">Bus.id_bus</td><td style = "text-align: right;">12</td><td style = "text-align: right;">12</td><td style = "text-align: right;">0</td><td style = "text-align: right;">0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">demand bus to bus table</td><td style = "text-align: left;">Demand.id_bus</td><td style = "text-align: left;">Bus.id_bus</td><td style = "text-align: right;">12</td><td style = "text-align: right;">12</td><td style = "text-align: right;">0</td><td style = "text-align: right;">0</td></tr></tbody></table></div>
```

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
unmatched_ids = read_eda06("unmatched_ids")
unmatched_ids
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>90×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">relationship</th><th style = "text-align: left;">unmatched_side</th><th style = "text-align: left;">id</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">3</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">4</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">5</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">6</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">8</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">9</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">10</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">11</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">12</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">13</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">14</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">15</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">15</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">16</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">16</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">17</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">17</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">18</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">18</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">19</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">19</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">20</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">20</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">21</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">21</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">22</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">22</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">23</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">23</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">24</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">24</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">25</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">25</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">26</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">26</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">27</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">27</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">28</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">28</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">29</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">29</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">30</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">30</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">31</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">31</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">32</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">32</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">33</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">33</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">34</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">34</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">35</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">35</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">36</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">36</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">37</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">37</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">38</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">38</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">39</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">39</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">40</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">40</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">41</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">41</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">42</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">42</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">43</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">43</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">44</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">44</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">45</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">45</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">46</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">46</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">47</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">47</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">48</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">48</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">49</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">49</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">50</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">50</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">51</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">51</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">52</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">52</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">53</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">53</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">54</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">54</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">55</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">55</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">56</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">56</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">57</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">57</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">58</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">58</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">59</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">59</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">60</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">60</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">61</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">61</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">62</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">62</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">63</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">63</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">64</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">64</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">65</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">65</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">66</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">66</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">67</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">67</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">68</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">68</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">69</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">69</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">70</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">70</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">71</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">71</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">72</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">72</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">73</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">73</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">74</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">74</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">75</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">75</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">76</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">76</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">77</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">77</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">78</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">79</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">79</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">80</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">80</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">81</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">81</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">82</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">82</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">83</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">83</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">84</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">84</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">85</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">85</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">86</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">86</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">87</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">87</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">88</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">88</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">89</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">89</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">90</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">90</td><td style = "text-align: left;">generator schedule to static generator</td><td style = "text-align: left;">Generator.id_gen</td><td style = "text-align: right;">91</td></tr></tbody></table></div>
```

## Generator classification

Generator fuel and technology counts show which static classifications are available for schedule joins and technology-specific aggregation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
generator_fuel_counts = read_eda06("generator_fuel_counts")
generator_fuel_counts
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>7×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">fuel</th><th style = "text-align: left;">count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Coal</td><td style = "text-align: right;">15</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Diesel</td><td style = "text-align: right;">7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">Hydro</td><td style = "text-align: right;">30</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Hydrogen</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Natural Gas</td><td style = "text-align: right;">37</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">Solar</td><td style = "text-align: right;">22</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">Wind</td><td style = "text-align: right;">11</td></tr></tbody></table></div>
```

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
generator_tech_counts = read_eda06("generator_tech_counts")
generator_tech_counts
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>13×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">tech</th><th style = "text-align: left;">count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Black Coal NSW</td><td style = "text-align: right;">4</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Black Coal QLD</td><td style = "text-align: right;">8</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">Brown Coal VIC</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Brown Coal</td><td style = "text-align: right;">1</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Diesel</td><td style = "text-align: right;">7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">Run-of-River</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">Reservoir</td><td style = "text-align: right;">28</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">Hydrogen-based gas turbines</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">OCGT</td><td style = "text-align: right;">28</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">CCGT</td><td style = "text-align: right;">9</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">12</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">10</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">Wind</td><td style = "text-align: right;">11</td></tr></tbody></table></div>
```

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
solar_wind_generator_counts = read_eda06("solar_wind_generator_counts")
solar_wind_generator_counts
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>2×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">category</th><th style = "text-align: left;">n_generators</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String7" style = "text-align: left;">String7</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">solar</td><td style = "text-align: right;">22</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">wind</td><td style = "text-align: right;">11</td></tr></tbody></table></div>
```

## Daily schedule alignment

Generator schedules are joined to generator identities and demand schedules to demand identities before aggregating solar PMax, wind PMax, and demand.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
daily_series = read_eda06("daily_solar_wind_demand_gw")

daily_coverage = DataFrame([
    (
        first_date = minimum(daily_series.date),
        last_date = maximum(daily_series.date),
        n_days = nrow(daily_series),
        missing_solar = count(ismissing, daily_series.solar_gw),
        missing_wind = count(ismissing, daily_series.wind_gw),
        missing_demand = count(ismissing, daily_series.demand_gw),
    ),
])
daily_coverage
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×6 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">first_date</th><th style = "text-align: left;">last_date</th><th style = "text-align: left;">n_days</th><th style = "text-align: left;">missing_solar</th><th style = "text-align: left;">missing_wind</th><th style = "text-align: left;">missing_demand</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Dates.Date" style = "text-align: left;">Date</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">2030-01-01</td><td style = "text-align: left;">2030-12-31</td><td style = "text-align: right;">365</td><td style = "text-align: right;">0</td><td style = "text-align: right;">0</td><td style = "text-align: right;">0</td></tr></tbody></table></div>
```

## VRE and demand summary

The summary reports the scale and correlation of the joined daily series for the selected build.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
vre_vs_demand_summary = read_eda06("vre_vs_demand_summary")
vre_vs_demand_summary
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">n_days</th><th style = "text-align: left;">mean_demand_gw</th><th style = "text-align: left;">mean_vre_gw</th><th style = "text-align: left;">min_demand_gw</th><th style = "text-align: left;">max_demand_gw</th><th style = "text-align: left;">min_vre_gw</th><th style = "text-align: left;">max_vre_gw</th><th style = "text-align: left;">corr_demand_vre</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">365</td><td style = "text-align: right;">656.483</td><td style = "text-align: right;">672.4</td><td style = "text-align: right;">547.968</td><td style = "text-align: right;">776.754</td><td style = "text-align: right;">223.515</td><td style = "text-align: right;">1189.63</td><td style = "text-align: right;">-0.0447203</td></tr></tbody></table></div>
```

