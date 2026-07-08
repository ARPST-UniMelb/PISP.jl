```@meta
EditURL = "../../literate/problem_table.jl"
```

Generated from `docs/literate/problem_table.jl` — regenerate with
`julia --project=docs docs/render_literate.jl`.

# Building a `PISPtimeConfig` problem table

This is a Literate.jl source file. It is meant to be processed with
`Literate.markdown` (or `Literate.notebook`) to produce a runnable,
rendered walkthrough — it is not meant to be read only as raw Julia.

PISP builds ISP-2024-based power system datasets around a small set of
scenario/time containers. Before any static or time-varying table is
filled in, PISP first needs a **problem table**: one row per
"sub-problem" that the rest of the pipeline will populate data for,
where a sub-problem is a (scenario, time window) pair.

AEMO's ISP scenarios are the *Progressive Change*, *Step Change*, and
*Green Energy Exports* futures (`PISP.ID2SCE`). PISP additionally splits
each calendar year into two Australian financial-year halves — January
to June (H1) and July to December (H2) — because that is the boundary
some of the underlying AEMO input files change on.

This walkthrough exercises the two real helpers that build that table:
`PISP.fill_problem_table_year` (whole calendar years, split at
the H1/H2 boundary) and `PISP.fill_problem_table_drange`
(an arbitrary date window, split at the boundary only if it actually
crosses one). Both live in `src/utils/general/PISPutils-general.jl` and
are used internally by `PISP.build_ISP24_datasets` — the package's single
public entry point described in the README — to seed
`tc.problem` before the rest of the build pipeline runs.

No AEMO downloads or private data are required for this example: the
`PISPtimeConfig` container starts out as an empty, schema-typed
`DataFrame` (see `PISP.schema_to_dataframe`), and these two helpers only
do in-memory date arithmetic and `DataFrame` row insertion.

````julia
using PISP
using Dates
````

## Step 1 — an empty problem table

`PISP.initialise_time_structures()` returns three fresh containers; we
only need the first one, `tc::PISPtimeConfig`, which owns the `problem`
table.

````julia
tc, _ts, _tv = PISP.initialise_time_structures()
tc.problem
````

```@raw html
<div><div style = "float: left;"><span>0×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">id</th><th style = "text-align: left;">name</th><th style = "text-align: left;">scenario</th><th style = "text-align: left;">weight</th><th style = "text-align: left;">problem_type</th><th style = "text-align: left;">dstart</th><th style = "text-align: left;">dend</th><th style = "text-align: left;">tstep</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "String" style = "text-align: left;">String</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead></table></div>
```

The columns come straight from the `MOD_PROBLEM` schema
(`src/datamodel/PISPdata-config.jl`): an `id`, a human-readable `name`,
the `scenario` id, a `weight`, a `problem_type` tag (`"UC"` for unit
commitment), the `dstart`/`dend` window, and a `tstep` in minutes.

````julia
names(tc.problem)
````

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

`fill_problem_table_year` splits the given year at the July 1 boundary
and writes one row per (scenario, half) pair — 3 scenarios × 2 halves =
6 rows for a full year.

````julia
PISP.fill_problem_table_year(tc, 2030)
tc.problem
````

```@raw html
<div><div style = "float: left;"><span>6×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">id</th><th style = "text-align: left;">name</th><th style = "text-align: left;">scenario</th><th style = "text-align: left;">weight</th><th style = "text-align: left;">problem_type</th><th style = "text-align: left;">dstart</th><th style = "text-align: left;">dend</th><th style = "text-align: left;">tstep</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "String" style = "text-align: left;">String</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "String" style = "text-align: left;">String</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: left;">Progressive_Change_2030_H1</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1.0</td><td style = "text-align: left;">UC</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: left;">2030-06-30T23:00:00</td><td style = "text-align: right;">60</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: left;">Step_Change_2030_H1</td><td style = "text-align: right;">2</td><td style = "text-align: right;">1.0</td><td style = "text-align: left;">UC</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: left;">2030-06-30T23:00:00</td><td style = "text-align: right;">60</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: left;">Green_Energy_Exports_2030_H1</td><td style = "text-align: right;">3</td><td style = "text-align: right;">1.0</td><td style = "text-align: left;">UC</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: left;">2030-06-30T23:00:00</td><td style = "text-align: right;">60</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">4</td><td style = "text-align: left;">Progressive_Change_2030_H2</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1.0</td><td style = "text-align: left;">UC</td><td style = "text-align: left;">2030-07-01T00:00:00</td><td style = "text-align: left;">2030-12-31T23:00:00</td><td style = "text-align: right;">60</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">5</td><td style = "text-align: left;">Step_Change_2030_H2</td><td style = "text-align: right;">2</td><td style = "text-align: right;">1.0</td><td style = "text-align: left;">UC</td><td style = "text-align: left;">2030-07-01T00:00:00</td><td style = "text-align: left;">2030-12-31T23:00:00</td><td style = "text-align: right;">60</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: right;">6</td><td style = "text-align: left;">Green_Energy_Exports_2030_H2</td><td style = "text-align: right;">3</td><td style = "text-align: right;">1.0</td><td style = "text-align: left;">UC</td><td style = "text-align: left;">2030-07-01T00:00:00</td><td style = "text-align: left;">2030-12-31T23:00:00</td><td style = "text-align: right;">60</td></tr></tbody></table></div>
```

Every row uses a 60-minute (`tstep`) unit-commitment (`problem_type`)
block, and the `name` embeds the scenario and half so the rows stay
distinguishable once concatenated with other years:

````julia
tc.problem.name
````

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

`fill_problem_table_drange` is the newer `drange` mode described in the
package README as an alternative to whole-year mode. It takes explicit
`DateTime` bounds and only splits at the July 1 boundary if the window
actually straddles it — otherwise it emits a single block per scenario.

First, a window entirely inside the second half of a year (no split
expected, so 3 rows for 3 scenarios):

````julia
tc2, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc2,
    DateTime(2031, 7, 1, 0, 0, 0),
    DateTime(2031, 9, 30, 23, 0, 0),
)
tc2.problem.name
````

````
3-element Vector{String}:
 "Progressive_Change_01072031-30092031"
 "Step_Change_01072031-30092031"
 "Green_Energy_Exports_01072031-30092031"
````

Now a window that crosses July 1 — this should split into two blocks per
scenario (6 rows total), same as whole-year mode, but with the window
clipped to the requested start/end rather than the full half-year:

````julia
tc3, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc3,
    DateTime(2030, 4, 1, 0, 0, 0),
    DateTime(2030, 9, 30, 23, 0, 0),
)
tc3.problem[:, [:name, :dstart, :dend]]
````

```@raw html
<div><div style = "float: left;"><span>6×3 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">name</th><th style = "text-align: left;">dstart</th><th style = "text-align: left;">dend</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Progressive_Change_01042030-30062030</td><td style = "text-align: left;">2030-04-01T00:00:00</td><td style = "text-align: left;">2030-06-30T23:00:00</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Step_Change_01042030-30062030</td><td style = "text-align: left;">2030-04-01T00:00:00</td><td style = "text-align: left;">2030-06-30T23:00:00</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">Green_Energy_Exports_01042030-30062030</td><td style = "text-align: left;">2030-04-01T00:00:00</td><td style = "text-align: left;">2030-06-30T23:00:00</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Progressive_Change_01072030-30092030</td><td style = "text-align: left;">2030-07-01T00:00:00</td><td style = "text-align: left;">2030-09-30T23:00:00</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Step_Change_01072030-30092030</td><td style = "text-align: left;">2030-07-01T00:00:00</td><td style = "text-align: left;">2030-09-30T23:00:00</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">Green_Energy_Exports_01072030-30092030</td><td style = "text-align: left;">2030-07-01T00:00:00</td><td style = "text-align: left;">2030-09-30T23:00:00</td></tr></tbody></table></div>
```

Notice the first block's `dend` is clipped to 30 June (the boundary),
not 30 September, and the second block's `dstart` is clipped to 1 July —
confirming the split, rather than a single unclipped row, actually
happened.

## Step 4 — restrict to a subset of scenarios

Both helpers accept a `sce` keyword to build only a subset of AEMO's
three ISP scenarios, which is useful when a downstream study only cares
about, say, *Step Change*:

````julia
tc4, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_year(tc4, 2030; sce = [2])
tc4.problem.name
````

````
2-element Vector{String}:
 "Step_Change_2030_H1"
 "Step_Change_2030_H2"
````

## Summary

- `fill_problem_table_year` and `fill_problem_table_drange` both mutate
  a `PISPtimeConfig`'s `problem` `DataFrame` in place and share the same
  AEMO half-year (H1/H2, split at 1 July) convention.
- Whole-year mode always emits 2 halves per scenario; date-range mode
  only splits when the requested window actually crosses 1 July.
- Both are internal building blocks of `PISP.build_ISP24_datasets`, not
  public API most users would call directly — but understanding them is
  the fastest way to understand how PISP structures a "build" before any
  AEMO file is even read.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

