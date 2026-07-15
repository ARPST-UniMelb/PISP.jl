```@meta
EditURL = "../../../literate/eda_11_rez_resource_vs_cost.jl"
```

# REZ resource potential versus connection cost

This analysis asks whether Renewable Energy Zones (REZs) with larger workbook-derived resource potential also have higher expected connection cost, or whether resource potential and connection cost are effectively separate dimensions.

The evidence comes from the AEMO 2024 ISP Inputs and Assumptions workbook at `data/2024/pisp-downloads/2024-isp-inputs-and-assumptions-workbook.xlsx`.
The workbook sheets named most naturally for the question are not directly joinable: `Renewable Energy Zones` identifies REZ geography without numeric resource limits, while `REZ Costs forecast` gives named cost trajectories without REZ-level capacity figures.
The evidence therefore uses `Build limits` for `total_resource_limit_mw` and `REZ Augmentations Options` for the primary option's `expected_cost_million`, joined by REZ identifier and name.

No AEMO report-PDF page citation is currently verified for this specific workbook-derived join, so this page cites only the local workbook-derived evidence.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames
using Printf

const EDA11_EVIDENCE_DIR = joinpath(
    normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", ".."))),
    "eda", "tables", "julia", "11_rez_resource_vs_cost",
)

function read_eda11(table_name)
    path = joinpath(EDA11_EVIDENCE_DIR, "$(table_name).csv")
    isfile(path) || error("missing EDA evidence table: $path")
    return CSV.read(path, DataFrame)
end

function rounded_columns(frame, columns; digits = 3)
    copy_frame = copy(frame)
    for column in columns
        copy_frame[!, column] = round.(copy_frame[!, column]; digits = digits)
    end
    return copy_frame
end
````

```@raw html
</details>
```

````
rounded_columns (generic function with 1 method)
````

## Evidence tables loaded from the EDA producer

The producer writes the workbook-derived join and a compact correlation summary.
The summary records the method, the exact source columns, the joined-row count, the zero-resource exclusion count, and the usable row count used for the coefficient.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
correlation_summary = read_eda11("rez_resource_cost_correlation_summary")
correlation_summary
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×7 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">method</th><th style = "text-align: left;">coefficient</th><th style = "text-align: left;">usable_row_count</th><th style = "text-align: left;">zero_resource_exclusion_count</th><th style = "text-align: left;">joined_row_count</th><th style = "text-align: left;">source_column_x</th><th style = "text-align: left;">source_column_y</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Pearson correlation</td><td style = "text-align: right;">0.0159535</td><td style = "text-align: right;">22</td><td style = "text-align: right;">1</td><td style = "text-align: right;">23</td><td style = "text-align: left;">total_resource_limit_mw</td><td style = "text-align: left;">expected_cost_million</td></tr></tbody></table></div>
```

The joined evidence still contains the zero-resource REZ before ratio and correlation exclusions, making the exclusion visible instead of silently dropping the row.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
joined_rez = read_eda11("rez_resource_vs_cost")
first(joined_rez, 8)

zero_resource_rez = read_eda11("rez_zero_resource_limit_excluded")
zero_resource_rez[:, [:rez_id, :rez_name, :total_resource_limit_mw, :expected_cost_million]]
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>1×4 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">rez_id</th><th style = "text-align: left;">rez_name</th><th style = "text-align: left;">total_resource_limit_mw</th><th style = "text-align: left;">expected_cost_million</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String3" style = "text-align: left;">String3</th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">N12</td><td style = "text-align: left;">Illawarra</td><td style = "text-align: right;">0.0</td><td style = "text-align: right;">814.0</td></tr></tbody></table></div>
```

The cost-efficiency ranking excludes zero-resource rows because expected cost divided by zero resource potential is not a meaningful finite ratio.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ranking = read_eda11("rez_cost_efficiency_ranking");
````

```@raw html
</details>
```

Lowest cost per MW of workbook-derived resource potential:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
first(rounded_columns(ranking, [:cost_per_resource_mw]; digits = 4), 6)
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>6×6 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">rez_id</th><th style = "text-align: left;">rez_name</th><th style = "text-align: left;">total_resource_limit_mw</th><th style = "text-align: left;">expected_cost_million</th><th style = "text-align: left;">dollar_million_per_mw</th><th style = "text-align: left;">cost_per_resource_mw</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String3" style = "text-align: left;">String3</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">T4</td><td style = "text-align: left;">North Tasmania Coast</td><td style = "text-align: right;">40550.0</td><td style = "text-align: right;">206.0</td><td style = "text-align: right;">0.151471</td><td style = "text-align: right;">0.0051</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">V7</td><td style = "text-align: left;">Gippsland Coast</td><td style = "text-align: right;">59996.0</td><td style = "text-align: right;">684.0</td><td style = "text-align: right;">0.342</td><td style = "text-align: right;">0.0114</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">S8</td><td style = "text-align: left;">Eastern Eyre Peninsula</td><td style = "text-align: right;">6700.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">0.333333</td><td style = "text-align: right;">0.0149</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">S2</td><td style = "text-align: left;">Riverland</td><td style = "text-align: right;">5000.0</td><td style = "text-align: right;">100.0</td><td style = "text-align: right;">0.142857</td><td style = "text-align: right;">0.02</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">N2</td><td style = "text-align: left;">New England</td><td style = "text-align: right;">8585.0</td><td style = "text-align: right;">370.0</td><td style = "text-align: right;">0.37</td><td style = "text-align: right;">0.0431</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">T3</td><td style = "text-align: left;">Central Highlands</td><td style = "text-align: right;">2650.0</td><td style = "text-align: right;">201.0</td><td style = "text-align: right;">0.628986</td><td style = "text-align: right;">0.0758</td></tr></tbody></table></div>
```

Highest cost per MW of workbook-derived resource potential:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
last(rounded_columns(ranking, [:cost_per_resource_mw]; digits = 4), 6)
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>6×6 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">rez_id</th><th style = "text-align: left;">rez_name</th><th style = "text-align: left;">total_resource_limit_mw</th><th style = "text-align: left;">expected_cost_million</th><th style = "text-align: left;">dollar_million_per_mw</th><th style = "text-align: left;">cost_per_resource_mw</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String3" style = "text-align: left;">String3</th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">N5</td><td style = "text-align: left;">South West NSW</td><td style = "text-align: right;">5156.0</td><td style = "text-align: right;">1418.0</td><td style = "text-align: right;">0.5672</td><td style = "text-align: right;">0.275</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">T1</td><td style = "text-align: left;">North East Tasmania</td><td style = "text-align: right;">1300.0</td><td style = "text-align: right;">400.0</td><td style = "text-align: right;">0.5</td><td style = "text-align: right;">0.3077</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">N4</td><td style = "text-align: left;">Broken Hill</td><td style = "text-align: right;">11800.0</td><td style = "text-align: right;">5098.0</td><td style = "text-align: right;">2.91314</td><td style = "text-align: right;">0.432</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">S4</td><td style = "text-align: left;">Yorke Peninsula</td><td style = "text-align: right;">1000.0</td><td style = "text-align: right;">566.0</td><td style = "text-align: right;">1.25778</td><td style = "text-align: right;">0.566</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Q1</td><td style = "text-align: left;">Far North QLD</td><td style = "text-align: right;">2810.0</td><td style = "text-align: right;">1836.0</td><td style = "text-align: right;">1.42326</td><td style = "text-align: right;">0.6534</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">N8</td><td style = "text-align: left;">Cooma-Monaro</td><td style = "text-align: right;">200.0</td><td style = "text-align: right;">202.0</td><td style = "text-align: right;">1.34667</td><td style = "text-align: right;">1.01</td></tr></tbody></table></div>
```

## Interpreting the evidence

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
coefficient = only(correlation_summary.coefficient)
usable_rows = only(correlation_summary.usable_row_count)
joined_rows = only(correlation_summary.joined_row_count)
zero_exclusions = only(correlation_summary.zero_resource_exclusion_count)
most_cost_efficient = first(ranking)
least_cost_efficient = last(ranking)
largest_expected_cost = ranking[argmax(ranking.expected_cost_million), :]

@printf(
    "Pearson coefficient %.3f from %d usable rows (%d joined rows, %d zero-resource exclusion).\n",
    coefficient,
    usable_rows,
    joined_rows,
    zero_exclusions,
)
@printf(
    "Largest expected cost: %s (%s), \$%.0fM.\n",
    largest_expected_cost.rez_id,
    largest_expected_cost.rez_name,
    largest_expected_cost.expected_cost_million,
)
@printf(
    "Most cost-efficient: %s (%s), %.4f \$M per MW of resource.\n",
    most_cost_efficient.rez_id,
    most_cost_efficient.rez_name,
    most_cost_efficient.cost_per_resource_mw,
)
@printf(
    "Least cost-efficient: %s (%s), %.4f \$M per MW of resource.\n",
    least_cost_efficient.rez_id,
    least_cost_efficient.rez_name,
    least_cost_efficient.cost_per_resource_mw,
)
````

```@raw html
</details>
```

````
Pearson coefficient 0.016 from 22 usable rows (23 joined rows, 1 zero-resource exclusion).
Largest expected cost: N4 (Broken Hill), $5098M.
Most cost-efficient: T4 (North Tasmania Coast), 0.0051 $M per MW of resource.
Least cost-efficient: N8 (Cooma-Monaro), 1.0100 $M per MW of resource.

````

A Pearson coefficient of 0.016 across 22 usable REZ rows is effectively zero for this workbook-derived join: the REZs with the highest resource potential do not also tend to have the highest primary-option expected connection cost.
The join contains 23 rows before ratio/correlation filtering, and N12 (Illawarra) is the single excluded zero-resource row; it remains visible in the evidence because its `0 MW` resource limit is part of the workbook-derived data and makes a finite cost-per-resource ratio undefined.
N4 (Broken Hill) has the largest expected cost at \$5,098M, while T4 (North Tasmania Coast) is the most cost-efficient joined REZ at about \$0.0051M per MW of resource.
N8 (Cooma-Monaro) is the least cost-efficient joined REZ at \$1.0100M per MW of resource.

The main limitation is source structure: this is not a direct join between `Renewable Energy Zones` and `REZ Costs forecast`, because those sheets do not contain the numeric fields needed for the question.
The result should therefore be interpreted as a workbook-derived comparison between REZ resource limits and first-listed standalone augmentation-option cost, not as a complete cost-benefit assessment of every possible augmentation pathway.

