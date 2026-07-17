```@meta
EditURL = "../../../literate/analysis/rez_resource_versus_connection_cost.jl"
```

# REZ resource potential versus connection cost

This analysis asks whether Renewable Energy Zones (REZs) with larger workbook-derived resource potential also have higher expected connection cost, or whether resource potential and connection cost are effectively separate dimensions.

The evidence comes from the AEMO 2024 ISP Inputs and Assumptions workbook at `data/2024/pisp-downloads/2024-isp-inputs-and-assumptions-workbook.xlsx`.
The workbook sheets named most naturally for the question are not directly joinable: `Renewable Energy Zones` identifies REZ geography without numeric resource limits, while `REZ Costs forecast` gives named cost trajectories without REZ-level capacity figures.
The evidence therefore uses `Build limits` for `total_resource_limit_mw` and `REZ Augmentations Options` for the primary option's `expected_cost_million`, joined by REZ identifier and name, all computed live on this page.

No AEMO report-PDF page citation is currently verified for this specific workbook-derived join, so this page cites only the local workbook-derived evidence.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using CSV
using DataFrames
using XLSX
using Printf
using Statistics

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

EdaSupport.snapshot_metadata_line(REPO_ROOT; context = "2024 ISP Inputs and Assumptions workbook, Build limits + REZ Augmentations Options")

const SCRIPT_STEM = "11_rez_resource_vs_cost"
const DOWNLOADS = joinpath("data", "2024", "pisp-downloads")  # kept relative: this is the path form recorded below
const IASR_WORKBOOK = joinpath(DOWNLOADS, "2024-isp-inputs-and-assumptions-workbook.xlsx")
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a DOWNLOADS-relative path to an absolute location for reading

function trim_sheet(matrix)
    nrows, ncols = size(matrix)
    last_row = 0
    for r in 1:nrows
        if any(x -> x !== missing, view(matrix, r, :))
            last_row = r
        end
    end
    last_col = 0
    for c in 1:ncols
        if any(x -> x !== missing, view(matrix, :, c))
            last_col = c
        end
    end
    (last_row == 0 || last_col == 0) && return Matrix{Any}(undef, 0, 0)
    return matrix[1:last_row, 1:last_col]
end

as_float(x::Missing) = missing
as_float(x::Real) = Float64(x)
````

```@raw html
</details>
```

````
Snapshot: PISP.jl commit bba8297+dirty, generated 2026-07-17 — 2024 ISP Inputs and Assumptions workbook, Build limits + REZ Augmentations Options

````

A handful of "Build limits" cells hold text rather than a bare number: "-" (no value; confirmed against the sheet's own dash convention elsewhere) and "5696 (Note 14)" (N11's offshore-floating limit, with the sheet's own inline footnote reference kept in the cell). The footnote itself (row 65: "Values shown are as per modelled. If updated to the recently declared area ... values would change to 0 MW fixed capacity, and 4,452 MW floating capacity.") is a caveat about a boundary redeclaration, not a reason to distrust the modelled number -- so this uses the modelled 5696 MW figure and keeps the footnote text out of the parsed value.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function as_float(x::AbstractString)
    stripped = strip(x)
    stripped == "-" && return missing
    m = match(r"^-?[\d,]+\.?\d*", stripped)
    m === nothing && return missing
    return parse(Float64, replace(m.match, "," => ""))
end
````

```@raw html
</details>
```

"Build limits" sheet: two-row merged header (row 6 group labels, row 7 wind sub-labels), one row per REZ from row 8 to the last REZ row (before the "Notes" section). REZs with onshore wind data have High/Medium (MW) populated and Offshore columns missing, and vice versa for the two offshore-only REZs (S10, T4) -- confirmed by direct inspection.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function load_rez_resource_limits(matrix)
    rows = NamedTuple[]
    nrows = size(matrix, 1)
    for r in 8:nrows
        rez_id = matrix[r, 2]
        rez_id === missing && break  # "Notes" section starts once REZ ID runs out
        rez_id == "Notes" && break
        push!(
            rows,
            (
                rez_id = String(rez_id),
                rez_name = matrix[r, 3] === missing ? missing : String(matrix[r, 3]),
                region = matrix[r, 4] === missing ? missing : String(matrix[r, 4]),
                wind_high_mw = as_float(matrix[r, 7]),
                wind_medium_mw = as_float(matrix[r, 8]),
                wind_offshore_fixed_mw = as_float(matrix[r, 9]),
                wind_offshore_floating_mw = as_float(matrix[r, 10]),
                solar_mw = as_float(matrix[r, 11]),
            ),
        )
    end
    df = DataFrame(rows)
    # A single wind-resource figure per REZ: onshore REZs use the more permissive of the two onshore land-use assumptions (Medium, always >= High in this sheet); the two offshore-only REZs (S10, T4) have High/Medium at 0 and carry their resource in the offshore columns instead, so those are added in (they are mutually exclusive with onshore in every row observed).
    df.wind_resource_mw = [
        coalesce(row.wind_medium_mw, 0.0) +
        coalesce(row.wind_offshore_fixed_mw, 0.0) +
        coalesce(row.wind_offshore_floating_mw, 0.0) for row in eachrow(df)
    ]
    df.total_resource_limit_mw = df.wind_resource_mw .+ [coalesce(v, 0.0) for v in df.solar_mw]
    return df
end
````

```@raw html
</details>
```

"REZ Augmentations Options" sheet: repeated region sub-header rows (bare region name, e.g. "QLD", with every other column missing) interleaved with REZ blocks. A genuine data row is any row where the Option column (6) is not missing; REZ ID/Name are only populated on an option's first row and must be forward-filled for that REZ's later options (e.g. Q1's "Option 2" row carries no REZ ID/Name of its own).

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function load_rez_augmentation_options(matrix)
    rows = NamedTuple[]
    nrows = size(matrix, 1)
    current_id = missing
    current_name = missing
    for r in 12:nrows
        option = matrix[r, 4]
        option === missing && continue  # region sub-header or blank row
        option == "Option" && continue  # the header row repeats before every region block
        if matrix[r, 2] !== missing
            current_id = String(matrix[r, 2])
            current_name = matrix[r, 3] === missing ? missing : String(matrix[r, 3])
        end
        current_id === missing && continue
        push!(
            rows,
            (
                rez_id = current_id,
                rez_name = current_name,
                option = String(option),
                additional_capacity_mw = as_float(matrix[r, 6]),
                expected_cost_million = as_float(matrix[r, 7]),
                dollar_million_per_mw = as_float(matrix[r, 10]),
            ),
        )
    end
    return DataFrame(rows)
end
````

```@raw html
</details>
```

One representative option per REZ: the first-listed option in sheet order (typically labelled "Option 1"), the foundational augmentation that later options build on. Excludes any REZ whose first-listed option has no numeric capacity or cost of its own -- most such exclusions are a bare cross-reference to a shared subregional/group-constraint augmentation (e.g. "See NQ-CQ subregional augmentations"), but a few are a literal "Option 1" whose capacity/cost cells are themselves blank or non-numeric in the sheet.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
function primary_option_per_rez(augmentation_options)
    rows = NamedTuple[]
    excluded = NamedTuple[]
    for key_df in groupby(augmentation_options, :rez_id)
        first_row = first(key_df)
        if first_row.additional_capacity_mw === missing || first_row.expected_cost_million === missing
            push!(excluded, (rez_id = first_row.rez_id, rez_name = first_row.rez_name, option = first_row.option))
            continue
        end
        push!(
            rows,
            (
                rez_id = first_row.rez_id,
                rez_name = first_row.rez_name,
                primary_option = first_row.option,
                additional_capacity_mw = first_row.additional_capacity_mw,
                expected_cost_million = first_row.expected_cost_million,
                dollar_million_per_mw = first_row.dollar_million_per_mw,
            ),
        )
    end
    return DataFrame(rows), DataFrame(excluded)
end

function pearson_correlation(x, y)
    n = length(x)
    mx, my = mean(x), mean(y)
    cov_xy = sum((x .- mx) .* (y .- my)) / (n - 1)
    sx, sy = std(x), std(y)
    return cov_xy / (sx * sy)
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

## Step 1 — load and trim the "Build limits" and "REZ Augmentations Options" sheets

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
println("Workbook exists: ", isfile(abs_path(IASR_WORKBOOK)))
isfile(abs_path(IASR_WORKBOOK)) || error("IASR workbook not found at $IASR_WORKBOOK")

resource_matrix, augmentation_matrix = XLSX.openxlsx(abs_path(IASR_WORKBOOK)) do xf
    trim_sheet(xf["Build limits"][:]), trim_sheet(xf["REZ Augmentations Options"][:])
end
````

```@raw html
</details>
```

````
Workbook exists: true

````

## Step 2 — resource limits and augmentation options per REZ

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
resource_limits = load_rez_resource_limits(resource_matrix)
write_table(resource_limits, SCRIPT_STEM, "rez_resource_limits")
println("REZ resource-limit rows (Build limits sheet): ", nrow(resource_limits))
markdown_table(first(resource_limits, 8))
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **region** | **wind\_high\_mw** | **wind\_medium\_mw** | **wind\_offshore\_fixed\_mw** | **wind\_offshore\_floating\_mw** | **solar\_mw** | **wind\_resource\_mw** | **total\_resource\_limit\_mw** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Q1 | Far North QLD | QLD | 570.0 | 1710.0 | missing | missing | 1100.0 | 1710.0 | 2810.0 |
| Q2 | North Qld Clean Energy Hub | QLD | 4700.0 | 13900.0 | missing | missing | 8000.0 | 13900.0 | 21900.0 |
| Q3 | Northern Qld | QLD | 0.0 | 0.0 | missing | missing | 3400.0 | 0.0 | 3400.0 |
| Q4 | Isaac | QLD | 1000.0 | 2800.0 | missing | missing | 6900.0 | 2800.0 | 9700.0 |
| Q5 | Barcaldine | QLD | 1000.0 | 2900.0 | missing | missing | 8000.0 | 2900.0 | 10900.0 |
| Q6 | Fitzroy | QLD | 900.0 | 2600.0 | missing | missing | 7533.0 | 2600.0 | 10133.0 |
| Q7 | Wide Bay | QLD | 300.0 | 800.0 | missing | missing | 2200.0 | 800.0 | 3000.0 |
| Q8 | Darling Downs | QLD | 1400.0 | 4200.0 | missing | missing | 6992.0 | 4200.0 | 11192.0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
augmentation_options = load_rez_augmentation_options(augmentation_matrix)
write_table(augmentation_options, SCRIPT_STEM, "rez_augmentation_options")
println("REZ augmentation-option rows (REZ Augmentations Options sheet): ", nrow(augmentation_options))
markdown_table(first(augmentation_options, 8))
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **option** | **additional\_capacity\_mw** | **expected\_cost\_million** | **dollar\_million\_per\_mw** |
|--:|--:|--:|--:|--:|--:|
| Q1 | Far North QLD | Option 1 | 1290.0 | 1836.0 | 1.42326 |
| Q1 | Far North QLD | Option 2 | 1290.0 | 2780.0 | 2.15504 |
| Q2 | North Qld Clean Energy Hub | CopperString | 1500.0 | missing | missing |
| Q2 | North Qld Clean Energy Hub | Option 1 | 500.0 | 651.0 | 0.434 |
| Q2 | North Qld Clean Energy Hub | Option 2 | 1000.0 | 0.0 | 0.0 |
| Q3 | Northern Qld | See NQ-CQ subregional augmentations | missing | missing | missing |
| Q4 | Isaac | See NQ2 group constraint augmentations | missing | missing | missing |
| Q5 | Barcaldine | Option 1 | 500.0 | 1068.0 | 0.791111 |


## Step 3 — primary option per REZ and the resource-vs-cost join

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
primary_options, excluded = primary_option_per_rez(augmentation_options)
write_table(excluded, SCRIPT_STEM, "rez_augmentation_excluded")
println("REZs with a usable primary (first-listed) option: ", nrow(primary_options))
println("REZs excluded (first-listed option has no standalone numeric capacity/cost -- a cross-reference to a shared augmentation, or a named option with blank/non-numeric figures): ", nrow(excluded))
markdown_table(excluded)
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **option** |
|--:|--:|--:|
| Q2 | North Qld Clean Energy Hub | CopperString |
| Q3 | Northern Qld | See NQ-CQ subregional augmentations |
| Q4 | Isaac | See NQ2 group constraint augmentations |
| Q6 | Fitzroy | See CQ-GG subregional augmentations |
| Q7 | Wide Bay | See SQ1 group constraint augmentations |
| Q8 | Darling Downs | See SWQLD1 Transmission Limit constraint augmentations |
| N3 | Central-West Orana | Central West Orana REZ transmission link |
| N6 | Wagga Wagga | Option 1 |
| N7 | Tumut | Option 1 |
| N10 | Hunter Coast | Option 1 |
| S1 | South East SA | See S1-TBMO transmission limit constraint augmentation and VIC-SESA and SESA-SA sub-regional augmentations |
| S3 | Mid-North SA | See MN1 group constraint augmentations |
| S5 | Northern SA | See NSA1 group constraint augmentations |
| S10 | South East SA Coast | See VIC-SESA and SESA-SA sub-regional augmentations |
| V3 | Western Victoria | See V3-EAST secondary transmission limit constraint augmentations |
| V4 | South West Victoria | See SWV1 group constraint augmentations |
| V5 | Gippsland | See SEVIC1 transmission limit constraint augmentations |
| V8 | Southern Ocean | See SWV1 group constraint augmentations |
| SWV1 | Group Constraint - South West Victoria | Option 1 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
joined = innerjoin(resource_limits, primary_options, on = [:rez_id, :rez_name])
joined_row_count = nrow(joined)
write_table(joined, SCRIPT_STEM, "rez_resource_vs_cost")
println("Joined REZs (resource limit + primary augmentation option): ", joined_row_count)
markdown_table(first(joined, 8))
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **region** | **wind\_high\_mw** | **wind\_medium\_mw** | **wind\_offshore\_fixed\_mw** | **wind\_offshore\_floating\_mw** | **solar\_mw** | **wind\_resource\_mw** | **total\_resource\_limit\_mw** | **primary\_option** | **additional\_capacity\_mw** | **expected\_cost\_million** | **dollar\_million\_per\_mw** |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Q1 | Far North QLD | QLD | 570.0 | 1710.0 | missing | missing | 1100.0 | 1710.0 | 2810.0 | Option 1 | 1290.0 | 1836.0 | 1.42326 |
| Q5 | Barcaldine | QLD | 1000.0 | 2900.0 | missing | missing | 8000.0 | 2900.0 | 10900.0 | Option 1 | 500.0 | 1068.0 | 0.791111 |
| Q9 | Banana | QLD | 900.0 | 2500.0 | missing | missing | 6100.0 | 2500.0 | 8600.0 | Option 1 | 3000.0 | 1078.0 | 0.359333 |
| N2 | New England | NSW | 1800.0 | 5600.0 | missing | missing | 2985.0 | 5600.0 | 8585.0 | Option 1 | 1000.0 | 370.0 | 0.37 |
| N4 | Broken Hill | NSW | 1300.0 | 3800.0 | missing | missing | 8000.0 | 3800.0 | 11800.0 | Option 1 | 1750.0 | 5098.0 | 2.91314 |
| N5 | South West NSW | NSW | 1000.0 | 2900.0 | missing | missing | 2256.0 | 2900.0 | 5156.0 | Option 1 | 2500.0 | 1418.0 | 0.5672 |
| N8 | Cooma-Monaro | NSW | 100.0 | 200.0 | missing | missing | 0.0 | 200.0 | 200.0 | Option 1 | 150.0 | 202.0 | 1.34667 |
| N9 | Hunter-Central Coast | NSW | 400.0 | 1000.0 | missing | missing | 516.0 | 1000.0 | 1516.0 | Option 1 | 950.0 | 307.0 | 0.323158 |


## Step 4 — zero-resource exclusion, correlation, and cost-efficiency ranking

One REZ (N12, Illawarra) carries a genuine 0 MW total resource limit in this workbook (both wind and solar limits are 0) -- a real modelled value, not a parsing artifact, confirmed by direct inspection of the sheet. It is excluded from the correlation and cost-per-MW ranking (undefined/infinite ratio) and reported separately rather than dropped silently.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
zero_resource_rez = filter(:total_resource_limit_mw => iszero, joined)
zero_resource_exclusion_count = nrow(zero_resource_rez)
zero_resource_exclusion_count > 0 && write_table(zero_resource_rez, SCRIPT_STEM, "rez_zero_resource_limit_excluded")
joined = filter(:total_resource_limit_mw => (v -> v > 0), joined)
markdown_table(zero_resource_rez[:, [:rez_id, :rez_name, :total_resource_limit_mw, :expected_cost_million]])
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **total\_resource\_limit\_mw** | **expected\_cost\_million** |
|--:|--:|--:|--:|
| N12 | Illawarra | 0.0 | 814.0 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
correlation = pearson_correlation(joined.total_resource_limit_mw, joined.expected_cost_million)
correlation_summary = DataFrame(
    method = ["Pearson correlation"],
    coefficient = [correlation],
    usable_row_count = [nrow(joined)],
    zero_resource_exclusion_count = [zero_resource_exclusion_count],
    joined_row_count = [joined_row_count],
    source_column_x = ["total_resource_limit_mw"],
    source_column_y = ["expected_cost_million"],
)
write_table(correlation_summary, SCRIPT_STEM, "rez_resource_cost_correlation_summary")
markdown_table(correlation_summary)
````

```@raw html
</details>
```

| **method** | **coefficient** | **usable\_row\_count** | **zero\_resource\_exclusion\_count** | **joined\_row\_count** | **source\_column\_x** | **source\_column\_y** |
|--:|--:|--:|--:|--:|--:|--:|
| Pearson correlation | 0.0159535 | 22 | 1 | 23 | total\_resource\_limit\_mw | expected\_cost\_million |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
joined.cost_per_resource_mw = joined.expected_cost_million ./ joined.total_resource_limit_mw
ranking = sort(joined, :cost_per_resource_mw)
ranking = select(ranking, [:rez_id, :rez_name, :total_resource_limit_mw, :expected_cost_million, :dollar_million_per_mw, :cost_per_resource_mw])
write_table(ranking, SCRIPT_STEM, "rez_cost_efficiency_ranking")
nrow(ranking)
````

```@raw html
</details>
```

````
22
````

Lowest cost per MW of workbook-derived resource potential:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
markdown_table(first(rounded_columns(ranking, [:cost_per_resource_mw]; digits = 4), 6))
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **total\_resource\_limit\_mw** | **expected\_cost\_million** | **dollar\_million\_per\_mw** | **cost\_per\_resource\_mw** |
|--:|--:|--:|--:|--:|--:|
| T4 | North Tasmania Coast | 40550.0 | 206.0 | 0.151471 | 0.0051 |
| V7 | Gippsland Coast | 59996.0 | 684.0 | 0.342 | 0.0114 |
| S8 | Eastern Eyre Peninsula | 6700.0 | 100.0 | 0.333333 | 0.0149 |
| S2 | Riverland | 5000.0 | 100.0 | 0.142857 | 0.02 |
| N2 | New England | 8585.0 | 370.0 | 0.37 | 0.0431 |
| T3 | Central Highlands | 2650.0 | 201.0 | 0.628986 | 0.0758 |


Highest cost per MW of workbook-derived resource potential:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
markdown_table(last(rounded_columns(ranking, [:cost_per_resource_mw]; digits = 4), 6))
````

```@raw html
</details>
```

| **rez\_id** | **rez\_name** | **total\_resource\_limit\_mw** | **expected\_cost\_million** | **dollar\_million\_per\_mw** | **cost\_per\_resource\_mw** |
|--:|--:|--:|--:|--:|--:|
| N5 | South West NSW | 5156.0 | 1418.0 | 0.5672 | 0.275 |
| T1 | North East Tasmania | 1300.0 | 400.0 | 0.5 | 0.3077 |
| N4 | Broken Hill | 11800.0 | 5098.0 | 2.91314 | 0.432 |
| S4 | Yorke Peninsula | 1000.0 | 566.0 | 1.25778 | 0.566 |
| Q1 | Far North QLD | 2810.0 | 1836.0 | 1.42326 | 0.6534 |
| N8 | Cooma-Monaro | 200.0 | 202.0 | 1.34667 | 1.01 |


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

