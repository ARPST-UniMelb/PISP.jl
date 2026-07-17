```@meta
EditURL = "../../../literate/tutorials/problem_table.jl"
```

# Building a `PISPtimeConfig` problem table

PISP starts each build by constructing a **problem table**: one row for each scenario/time block that the rest of the pipeline will populate. This table is small, but it determines how later static and schedule tables are grouped.

The examples below use the real helper functions that populate the table. They do not download AEMO data; all outputs come from in-memory date arithmetic and package constants.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using Dates

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))

include(joinpath(REPO_ROOT, "eda", "eda_support.jl"))
using .EdaSupport
````

```@raw html
</details>
```

## Step 1 — start with an empty problem table

`PISP.initialise_time_structures()` returns three containers. The first, `tc::PISPtimeConfig`, owns the `problem` table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tc, _ts, _tv = PISP.initialise_time_structures()
markdown_table(tc.problem)
````

```@raw html
</details>
```

| **id** | **name** | **scenario** | **weight** | **problem\_type** | **dstart** | **dend** | **tstep** |
|--:|--:|--:|--:|--:|--:|--:|--:|


The table schema comes from `MOD_PROBLEM` in `src/datamodel/PISPdata-config.jl`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
names(tc.problem)
````

```@raw html
</details>
```

````
8-element Vector{String}:
 "id"
 "name"
 "scenario"
 "weight"
 "problem_type"
 "dstart"
 "dend"
 "tstep"
````

## Step 2 — fill a whole planning year

`fill_problem_table_year` splits a planning year into January-June and July-December blocks. With all three ISP scenarios, this produces 6 rows.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISP.fill_problem_table_year(tc, 2030)
markdown_table(tc.problem)
````

```@raw html
</details>
```

| **id** | **name** | **scenario** | **weight** | **problem\_type** | **dstart** | **dend** | **tstep** |
|--:|--:|--:|--:|--:|--:|--:|--:|
| 1 | Progressive\_Change\_2030\_H1 | 1 | 1.0 | UC | 2030-01-01T00:00:00 | 2030-06-30T23:00:00 | 60 |
| 2 | Step\_Change\_2030\_H1 | 2 | 1.0 | UC | 2030-01-01T00:00:00 | 2030-06-30T23:00:00 | 60 |
| 3 | Green\_Energy\_Exports\_2030\_H1 | 3 | 1.0 | UC | 2030-01-01T00:00:00 | 2030-06-30T23:00:00 | 60 |
| 4 | Progressive\_Change\_2030\_H2 | 1 | 1.0 | UC | 2030-07-01T00:00:00 | 2030-12-31T23:00:00 | 60 |
| 5 | Step\_Change\_2030\_H2 | 2 | 1.0 | UC | 2030-07-01T00:00:00 | 2030-12-31T23:00:00 | 60 |
| 6 | Green\_Energy\_Exports\_2030\_H2 | 3 | 1.0 | UC | 2030-07-01T00:00:00 | 2030-12-31T23:00:00 | 60 |


The generated names encode scenario and half-year so later schedules remain distinguishable.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tc.problem.name
````

```@raw html
</details>
```

````
6-element Vector{String}:
 "Progressive_Change_2030_H1"
 "Step_Change_2030_H1"
 "Green_Energy_Exports_2030_H1"
 "Progressive_Change_2030_H2"
 "Step_Change_2030_H2"
 "Green_Energy_Exports_2030_H2"
````

## Step 3 — fill an arbitrary date range

`fill_problem_table_drange` accepts explicit `DateTime` bounds. A range that stays on one side of 1 July produces one block per scenario.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tc2, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc2,
    DateTime(2031, 7, 1, 0, 0, 0),
    DateTime(2031, 9, 30, 23, 0, 0),
)
tc2.problem.name
````

```@raw html
</details>
```

````
3-element Vector{String}:
 "Progressive_Change_01072031-30092031"
 "Step_Change_01072031-30092031"
 "Green_Energy_Exports_01072031-30092031"
````

A range that crosses 1 July is clipped into two blocks per scenario.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tc3, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc3,
    DateTime(2030, 4, 1, 0, 0, 0),
    DateTime(2030, 9, 30, 23, 0, 0),
)
markdown_table(tc3.problem[:, [:name, :dstart, :dend]])
````

```@raw html
</details>
```

| **name** | **dstart** | **dend** |
|--:|--:|--:|
| Progressive\_Change\_01042030-30062030 | 2030-04-01T00:00:00 | 2030-06-30T23:00:00 |
| Step\_Change\_01042030-30062030 | 2030-04-01T00:00:00 | 2030-06-30T23:00:00 |
| Green\_Energy\_Exports\_01042030-30062030 | 2030-04-01T00:00:00 | 2030-06-30T23:00:00 |
| Progressive\_Change\_01072030-30092030 | 2030-07-01T00:00:00 | 2030-09-30T23:00:00 |
| Step\_Change\_01072030-30092030 | 2030-07-01T00:00:00 | 2030-09-30T23:00:00 |
| Green\_Energy\_Exports\_01072030-30092030 | 2030-07-01T00:00:00 | 2030-09-30T23:00:00 |


The first block ends at 30 June and the second starts at 1 July.

## Step 4 — restrict to one scenario

Both helpers accept `sce` when a study only needs a subset of the three ISP scenarios.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tc4, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_year(tc4, 2030; sce = [2])
tc4.problem.name
````

```@raw html
</details>
```

````
2-element Vector{String}:
 "Step_Change_2030_H1"
 "Step_Change_2030_H2"
````

## Summary

- Whole-year mode always creates two half-year blocks per scenario.
- Date-range mode splits only when the requested range crosses 1 July.
- The problem table is the first scenario/time index used by `PISP.build_ISP24_datasets` before AEMO input files are parsed.

