```@meta
EditURL = "../../../../literate/isp2024/tutorials/problem_table.jl"
```

# ISP 2024: Building a problem table

PISP starts each build by constructing a **problem table**: one row for each scenario/time block that the rest of the pipeline will populate.
The table is small, but it determines how later static and schedule tables are grouped.

## Purpose and scope

This tutorial explains the scenario and date blocks created before an ISP 2024 dataset build.
The examples use the package's in-memory initialisation helpers and do not require source downloads.

## What the problem table controls

Each row identifies a scenario, a start and end time, a problem type, and a model time step.
It is an execution index created by PISP rather than a table supplied by AEMO.
Later schedule tables use these scenario/time blocks to keep otherwise similar outputs distinguishable.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using Dates
using DataFrames

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport
````

```@raw html
</details>
```

## Problem-table schema

`PISP.initialise_time_structures()` returns three containers. The first, `tc::PISPtimeConfig`, owns the `problem` table.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
tc, _ts, _tv = PISP.initialise_time_structures()
problem_schema = DataFrame(
    Field = names(tc.problem),
    Type = string.(eltype.(eachcol(tc.problem))),
    Meaning = [
        "Problem-row identifier",
        "Scenario and time-block name",
        "ISP scenario identifier",
        "Problem weight",
        "Downstream problem type",
        "Inclusive block start",
        "Inclusive block end",
        "Model time step in minutes",
    ],
)
markdown_table(problem_schema)
````

```@raw html
</details>
```

| **Field** | **Type** | **Meaning** |
|:--|:--|:--|
| id | Int64 | Problem-row identifier |
| name | String | Scenario and time-block name |
| scenario | Int64 | ISP scenario identifier |
| weight | Float64 | Problem weight |
| problem\_type | String | Downstream problem type |
| dstart | Dates.DateTime | Inclusive block start |
| dend | Dates.DateTime | Inclusive block end |
| tstep | Int64 | Model time step in minutes |


The executable `tc.problem` table is empty at initialisation; the schema is defined by `MOD_PROBLEM` in `src/datamodel/PISPdata-config.jl` and populated by the selected scenario/time workflow.

## Whole-year blocks

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
|--:|:--|--:|--:|:--|:--|:--|--:|
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

## Explicit date ranges

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
|:--|:--|:--|
| Progressive\_Change\_01042030-30062030 | 2030-04-01T00:00:00 | 2030-06-30T23:00:00 |
| Step\_Change\_01042030-30062030 | 2030-04-01T00:00:00 | 2030-06-30T23:00:00 |
| Green\_Energy\_Exports\_01042030-30062030 | 2030-04-01T00:00:00 | 2030-06-30T23:00:00 |
| Progressive\_Change\_01072030-30092030 | 2030-07-01T00:00:00 | 2030-09-30T23:00:00 |
| Step\_Change\_01072030-30092030 | 2030-07-01T00:00:00 | 2030-09-30T23:00:00 |
| Green\_Energy\_Exports\_01072030-30092030 | 2030-07-01T00:00:00 | 2030-09-30T23:00:00 |


The first block ends at 30 June and the second starts at 1 July.

## Scenario selection

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

## Validate the result

- Whole-year mode creates two half-year blocks per selected scenario.
- Date-range mode creates one block when the range stays on one side of 1 July and two blocks when it crosses that boundary.
- The displayed `dstart` and `dend` values provide the boundary check: the first half ends at 30 June 23:00 and the second starts at 1 July 00:00.
- Restricting `sce` changes the scenario rows without changing the half-year split.

## Next step

`PISP.build_ISP24_datasets` constructs this scenario/time index internally before it parses the AEMO inputs and writes the static and schedule tables.
Most users call the high-level builder; these helpers are useful when inspecting date partitioning or developing a custom workflow.

