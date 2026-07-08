```@meta
EditURL = "../../literate/pisp_outputs_validation.jl"
```

Generated from `docs/literate/pisp_outputs_validation.jl` — regenerate
with `julia --project=docs docs/render_literate.jl`.

**Local data precondition.** Unlike `problem_table.jl`, this tutorial is
not data-free: regenerating it requires a local AEMO/PISP data build at
`data/pisp-datasets/out-ref4006-poe10/csv/` (including its
`schedule-2030/` subdirectory) to already exist on disk. That build is
not produced by this repository's normal test/CI path — it is a local
artifact of running `PISP.build_ISP24_datasets` against AEMO inputs. If
it is missing, `docs/render_literate.jl` reports a clear, named error
instead of a cryptic `CSV.read` failure deep in this file. This does not
weaken `docs/make.jl`'s own hermetic-build guarantee: `make.jl` never
calls Literate and never touches this data, regardless of how many
tutorials exist here.

# Validating PISP-produced outputs against demand

This is a Literate.jl source file. It is meant to be processed with
`Literate.markdown` to produce a runnable, rendered walkthrough — it is
not meant to be read only as raw Julia.

It is a Julia port of the core analysis in `eda/06_pisp_outputs.py`
(ported 2026-07-08, not a line-for-line translation — the Python source
has some real duplication in it, see that file's own history). It ports
one representative piece: the summary prints that inspect PISP's own
generated `Generator`/`Demand`/`Bus` tables and `schedule-2030` output,
plus the single cleanest, most directly output-validating figure from
that script — the daily aggregate solar PMax / wind PMax / total demand
time-series comparison (`fig2` in the Python source). The other two
multi-panel figures in `eda/06_pisp_outputs.py` (annual-mean-pmax bars;
hourly-profile/duration-curve/scatter grid) are not ported here.

`GKSwstype` must be set before `Plots`/GR initialize — `render_literate.jl`
runs non-interactively (no display attached), and without this GR's
default workstation type tries to open an interactive Qt window
(`gksqt`) and the render step hangs waiting on it instead of exiting once
the PNG is written. `"100"` is GR's null/offscreen workstation type.

````julia
ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Plots

gr();
````

**`@__DIR__` here is the *generated output* directory, not this source
file's own directory — verified empirically while implementing this
tutorial, not assumed.** Literate.jl executes tutorial code with both
`@__DIR__` and `pwd()` set to its output directory
(`docs/src/generated/`), not the location of this `.jl` source
(`docs/literate/`), so that relative paths in the *generated* page work
from where that page actually lives. `DATA_ROOT` below is therefore
computed relative to `docs/src/generated/`, three levels up to the
repository root, not two.

The trailing `;` below suppresses auto-display of this block's last
value — `DATA_ROOT`/`SCHEDULE_DIR` are absolute paths on whichever
machine last regenerated this page, not something that should end up
baked into committed, reviewable Markdown.

````julia
const DATA_ROOT = joinpath(
    @__DIR__, "..", "..", "..",
    "data", "pisp-datasets", "out-ref4006-poe10", "csv",
)
const SCHEDULE_DIR = joinpath(DATA_ROOT, "schedule-2030");
````

## Step 1 — load the static output tables

`Generator.csv`, `Demand.csv`, and `Bus.csv` are the static NEM-schema-like
tables PISP writes for every build: one row per generator/demand
node/bus.

````julia
gen_df = CSV.read(joinpath(DATA_ROOT, "Generator.csv"), DataFrame)
dem_df = CSV.read(joinpath(DATA_ROOT, "Demand.csv"), DataFrame)
bus_df = CSV.read(joinpath(DATA_ROOT, "Bus.csv"), DataFrame)

println("=== Generator Table ===")
println("Shape: ", size(gen_df))
println("Columns: ", names(gen_df))
````

````
=== Generator Table ===
Shape: (124, 48)
Columns: ["id_gen", "name", "alias", "fuel", "tech", "type", "capacity", "forate", "fullout", "partialout", "derate", "mttrfull", "mttrpart", "id_bus", "pmin", "pmax", "rup", "rdw", "investment", "active", "cvar", "cfuel", "cvom", "cfom", "co2", "slope", "hrate", "pfrmax", "g", "inertia", "ffr", "pfr", "res2", "res3", "powerfactor", "latitude", "longitude", "n", "contingency", "down_time", "up_time", "last_state", "last_state_period", "last_state_output", "start_up_cost", "shut_down_cost", "start_up_time", "shut_down_time"]

````

Fuel and tech types, most common first (mirrors the Python source's
`value_counts()`):

````julia
fuel_counts = sort(combine(groupby(gen_df, :fuel), nrow => :count), :count; rev = true)
````

```@raw html
<div><div style = "float: left;"><span>7×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">fuel</th><th style = "text-align: left;">count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String15" style = "text-align: left;">String15</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Natural Gas</td><td style = "text-align: right;">37</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Hydro</td><td style = "text-align: right;">30</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">Solar</td><td style = "text-align: right;">22</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Coal</td><td style = "text-align: right;">15</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Wind</td><td style = "text-align: right;">11</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">Diesel</td><td style = "text-align: right;">7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">Hydrogen</td><td style = "text-align: right;">2</td></tr></tbody></table></div>
```

````julia
tech_counts = sort(combine(groupby(gen_df, :tech), nrow => :count), :count; rev = true)
````

```@raw html
<div><div style = "float: left;"><span>13×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">tech</th><th style = "text-align: left;">count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Reservoir</td><td style = "text-align: right;">28</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">OCGT</td><td style = "text-align: right;">28</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">12</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Wind</td><td style = "text-align: right;">11</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">10</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">CCGT</td><td style = "text-align: right;">9</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">Black Coal QLD</td><td style = "text-align: right;">8</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">Diesel</td><td style = "text-align: right;">7</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">Black Coal NSW</td><td style = "text-align: right;">4</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">Brown Coal VIC</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">Run-of-River</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">Hydrogen-based gas turbines</td><td style = "text-align: right;">2</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">Brown Coal</td><td style = "text-align: right;">1</td></tr></tbody></table></div>
```

## Step 2 — load the schedule-2030 output

`Generator_pmax_sched.csv` and `Demand_load_sched.csv` are PISP's
time-varying schedule tables: PMax generator by generator, and demand
load node by node, for the 2030 planning year.

````julia
gen_pmax = CSV.read(joinpath(SCHEDULE_DIR, "Generator_pmax_sched.csv"), DataFrame)
dem_load = CSV.read(joinpath(SCHEDULE_DIR, "Demand_load_sched.csv"), DataFrame)

println("\n=== Generator_pmax_sched ===")
println("Shape: ", size(gen_pmax))
println("Columns: ", names(gen_pmax))
````

````

=== Generator_pmax_sched ===
Shape: (289083, 5)
Columns: ["id", "id_gen", "scenario", "date", "value"]

````

A `println` and a richly-displayed (`DataFrame`) value are kept in
separate code cells below — confirmed empirically while implementing
this tutorial that Literate.jl silently drops a cell's plain stdout
output whenever that same cell's *last* statement is a value with its
own rich HTML display (as every `DataFrame` has here, under
`Literate.DocumenterFlavor()`), rather than showing both. First five
rows, for a look at the actual columns:

````julia
first(gen_pmax, 5)
````

```@raw html
<div><div style = "float: left;"><span>5×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">id</th><th style = "text-align: left;">id_gen</th><th style = "text-align: left;">scenario</th><th style = "text-align: left;">date</th><th style = "text-align: left;">value</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: right;">78</td><td style = "text-align: right;">1</td><td style = "text-align: left;">2044-07-01T00:00:00</td><td style = "text-align: right;">106.0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: right;">78</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2044-07-01T00:00:00</td><td style = "text-align: right;">106.0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: right;">78</td><td style = "text-align: right;">3</td><td style = "text-align: left;">2044-07-01T00:00:00</td><td style = "text-align: right;">106.0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">4</td><td style = "text-align: right;">92</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: right;">0.0</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">5</td><td style = "text-align: right;">92</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T01:00:00</td><td style = "text-align: right;">0.0</td></tr></tbody></table></div>
```

````julia
println("\n=== Demand_load_sched ===")
println("Shape: ", size(dem_load))
````

````

=== Demand_load_sched ===
Shape: (105120, 5)

````

````julia
first(dem_load, 5)
````

```@raw html
<div><div style = "float: left;"><span>5×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">id</th><th style = "text-align: left;">id_dem</th><th style = "text-align: left;">scenario</th><th style = "text-align: left;">date</th><th style = "text-align: left;">value</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Dates.DateTime" style = "text-align: left;">DateTime</th><th title = "Float64" style = "text-align: left;">Float64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T00:00:00</td><td style = "text-align: right;">749.427</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: right;">2</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T01:00:00</td><td style = "text-align: right;">717.852</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: right;">3</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T02:00:00</td><td style = "text-align: right;">674.352</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: right;">4</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T03:00:00</td><td style = "text-align: right;">649.815</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: right;">5</td><td style = "text-align: right;">1</td><td style = "text-align: right;">2</td><td style = "text-align: left;">2030-01-01T04:00:00</td><td style = "text-align: right;">641.313</td></tr></tbody></table></div>
```

## Step 3 — map generators to buses/areas, and find solar/wind generators

`Bus.csv` carries an `id_area` per bus; joining it onto `Generator.csv`
via `id_bus` gives every generator a NEM area. Solar and wind generators
are identified the same way the Python source does — a case-insensitive
substring match on `tech` (`"PV"`/`"SOLAR"` for solar, `"WIND"` for
wind), not an exact `fuel` match, since `tech` is the finer-grained
column PISP actually uses to distinguish rooftop PV from utility-scale
PV.

````julia
area_map = Dict(zip(bus_df.id_bus, bus_df.id_area))
gen_df.area = [area_map[b] for b in gen_df.id_bus]
const AREA_NAMES = Dict(1 => "QLD", 2 => "NSW", 3 => "VIC", 4 => "TAS", 5 => "SA")
gen_df.area_name = [AREA_NAMES[a] for a in gen_df.area]

is_solar(tech) = occursin(r"pv|solar"i, tech)
is_wind(tech) = occursin(r"wind"i, tech)

solar_gens = filter(:tech => is_solar, gen_df)
wind_gens = filter(:tech => is_wind, gen_df)

println("\nSolar generators: ", nrow(solar_gens))
println("Wind generators: ", nrow(wind_gens))
````

````

Solar generators: 22
Wind generators: 11

````

Same reason as Step 2 for splitting the cell here: `println` output and
a following richly-displayed `DataFrame` don't survive being in the
same code cell together.

````julia
solar_tech_counts = sort(
    combine(groupby(solar_gens, :tech), nrow => :count), :count; rev = true,
)
````

```@raw html
<div><div style = "float: left;"><span>2×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">tech</th><th style = "text-align: left;">count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">RoofPV</td><td style = "text-align: right;">12</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">LargePV</td><td style = "text-align: right;">10</td></tr></tbody></table></div>
```

````julia
wind_tech_counts = sort(
    combine(groupby(wind_gens, :tech), nrow => :count), :count; rev = true,
)
````

```@raw html
<div><div style = "float: left;"><span>1×2 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">tech</th><th style = "text-align: left;">count</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "InlineStrings.String31" style = "text-align: left;">String31</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Wind</td><td style = "text-align: right;">11</td></tr></tbody></table></div>
```

## Step 4 — reconstruct the demand-side data prep `fig2` depends on

`fig2` in the Python source reuses two intermediate frames built earlier
in that script rather than being self-contained: `dem_load_full` (demand
load filtered to the ids that actually appear in `Demand.csv`) and a
generator-side merge that attaches `tech` onto every `Generator_pmax_sched`
row so it can be split into solar/wind subsets. Both are rebuilt here
rather than assumed, since this is a rewrite, not a literal translation.

````julia
dem_load_full = filter(:id_dem => in(Set(dem_df.id_dem)), dem_load)
dem_load_full.day = Date.(dem_load_full.date)

gen_pmax_ts = innerjoin(gen_pmax, select(gen_df, [:id_gen, :tech]); on = :id_gen)
gen_pmax_ts.day = Date.(gen_pmax_ts.date)

sol_pmax_ts = filter(:tech => is_solar, gen_pmax_ts)
wind_pmax_ts = filter(:tech => is_wind, gen_pmax_ts)
````

`wind_pmax_ts` above is left unbound from display on purpose: it has one
row per (wind generator, hourly timestep) for the whole 2030 year
(tens of thousands of rows) — the same class of "don't let the last
statement in a code block auto-display" caution as the plot object
below, just for a large `DataFrame` instead of a `Plot`.

## Step 5 — daily aggregate solar PMax, wind PMax, and total demand

Sum every generator's PMax (respectively, every demand node's load) within
each calendar day, in MW, then convert to GW for the plot — the same
aggregation `fig2` performs in the Python source.

````julia
sol_daily = sort(combine(groupby(sol_pmax_ts, :day), :value => sum => :value), :day)
wind_daily = sort(combine(groupby(wind_pmax_ts, :day), :value => sum => :value), :day)
dem_daily = sort(combine(groupby(dem_load_full, :day), :value => sum => :value), :day)

println(
    "\nDaily aggregate series length — solar: ", nrow(sol_daily),
    ", wind: ", nrow(wind_daily),
    ", demand: ", nrow(dem_daily),
)
````

````

Daily aggregate series length — solar: 365, wind: 365, demand: 365

````

## Step 6 — plot and save

The figure is saved directly to `docs/src/generated/`, alongside where
`docs/render_literate.jl` writes this file's own rendered Markdown.
Since `@__DIR__` here already *is* that output directory (see the note
above), the save path is just `@__DIR__` plus a filename — no `..`
needed. The Markdown image link just below uses that same bare filename,
since it too resolves relative to the generated `.md` file's own
location — both are the same relative frame here, which is itself the
thing worth double-checking rather than assuming, since it is easy to
assume `@__DIR__` means "this source file's directory" and get it wrong
in exactly the way this comment now documents.

````julia
fig = plot(
    sol_daily.day, sol_daily.value ./ 1000;
    label = "Solar PMax (GW)", color = :darkorange, linewidth = 1, alpha = 0.8,
)
plot!(
    fig, wind_daily.day, wind_daily.value ./ 1000;
    label = "Wind PMax (GW)", color = :steelblue, linewidth = 1, alpha = 0.8,
)
plot!(
    fig, dem_daily.day, dem_daily.value ./ 1000;
    label = "Total Demand (GW)", color = :grey, linewidth = 1, alpha = 0.8,
)
xlabel!(fig, "Date")
ylabel!(fig, "GW")
title!(fig, "2030 — Daily Aggregate: Solar PMax, Wind PMax, Total Demand")

const FIGURE_PATH = joinpath(@__DIR__, "pisp_outputs_validation-timeseries.png")
savefig(fig, FIGURE_PATH)
````

![2030 daily aggregate solar PMax, wind PMax, and total demand](pisp_outputs_validation-timeseries.png)

## Summary

- PISP's `schedule-2030` build carries hourly PMax schedules only for the
  generators whose output actually varies within a year — in this build,
  the solar and wind fleet (the `Solar tech breakdown`/`Wind tech
  breakdown` counts above) — everything else keeps a single static `pmax`
  in `Generator.csv`.
- Daily aggregate solar and wind PMax track the expected seasonal pattern
  against total demand across the 2030 calendar year, in GW.
- This tutorial validates PISP's own generated output against its own
  static tables (`Generator`/`Demand`/`Bus`); it does not compare against
  the raw AEMO capacity-factor traces the Python source also inspects —
  that comparison, and the other two multi-panel figures, stay
  Python-only for now.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

