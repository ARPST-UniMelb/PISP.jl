# Generated from `docs/literate/pisp_outputs_validation.jl` — regenerate
# with `julia --project=docs docs/render_literate.jl`.
#
# **Local data precondition.** Unlike `problem_table.jl`, this tutorial is
# not data-free: regenerating it requires a local AEMO/PISP data build at
# `data/pisp-datasets/out-ref4006-poe10/csv/` (including its
# `schedule-2030/` subdirectory) to already exist on disk. That build is
# not produced by this repository's normal test/CI path — it is a local
# artifact of running `PISP.build_ISP24_datasets` against AEMO inputs. If
# it is missing, `docs/render_literate.jl` reports a clear, named error
# instead of a cryptic `CSV.read` failure deep in this file. This does not
# weaken `docs/make.jl`'s own hermetic-build guarantee: `make.jl` never
# calls Literate and never touches this data, regardless of how many
# tutorials exist here.
#
# # Validating PISP-produced outputs against demand
#
# This is a Literate.jl source file. It is meant to be processed with
# `Literate.markdown` to produce a runnable, rendered walkthrough — it is
# not meant to be read only as raw Julia.
#
# It is a Julia port of the core analysis in `eda/06_pisp_outputs.py`
# (ported 2026-07-08, not a line-for-line translation — the Python source
# has some real duplication in it, see that file's own history). It ports
# one representative piece: the summary prints that inspect PISP's own
# generated `Generator`/`Demand`/`Bus` tables and `schedule-2030` output,
# plus the single cleanest, most directly output-validating figure from
# that script — the daily aggregate solar PMax / wind PMax / total demand
# time-series comparison (`fig2` in the Python source). The other two
# multi-panel figures in `eda/06_pisp_outputs.py` (annual-mean-pmax bars;
# hourly-profile/duration-curve/scatter grid) are not ported here.

# `GKSwstype` must be set before `Plots`/GR initialize — `render_literate.jl`
# runs non-interactively (no display attached), and without this GR's
# default workstation type tries to open an interactive Qt window
# (`gksqt`) and the render step hangs waiting on it instead of exiting once
# the PNG is written. `"100"` is GR's null/offscreen workstation type.
ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Plots

gr();

# **`@__DIR__` here is the *generated output* directory, not this source
# file's own directory — verified empirically while implementing this
# tutorial, not assumed.** Literate.jl executes tutorial code with both
# `@__DIR__` and `pwd()` set to its output directory
# (`docs/src/generated/`), not the location of this `.jl` source
# (`docs/literate/`), so that relative paths in the *generated* page work
# from where that page actually lives. `DATA_ROOT` below is therefore
# computed relative to `docs/src/generated/`, three levels up to the
# repository root, not two.

# The trailing `;` below suppresses auto-display of this block's last
# value — `DATA_ROOT`/`SCHEDULE_DIR` are absolute paths on whichever
# machine last regenerated this page, not something that should end up
# baked into committed, reviewable Markdown.

const DATA_ROOT = joinpath(
    @__DIR__, "..", "..", "..",
    "data", "pisp-datasets", "out-ref4006-poe10", "csv",
)
const SCHEDULE_DIR = joinpath(DATA_ROOT, "schedule-2030");

# ## Step 1 — load the static output tables
#
# `Generator.csv`, `Demand.csv`, and `Bus.csv` are the static NEM-schema-like
# tables PISP writes for every build: one row per generator/demand
# node/bus.

gen_df = CSV.read(joinpath(DATA_ROOT, "Generator.csv"), DataFrame)
dem_df = CSV.read(joinpath(DATA_ROOT, "Demand.csv"), DataFrame)
bus_df = CSV.read(joinpath(DATA_ROOT, "Bus.csv"), DataFrame)

println("=== Generator Table ===")
println("Shape: ", size(gen_df))
println("Columns: ", names(gen_df))

# Fuel and tech types, most common first (mirrors the Python source's
# `value_counts()`):

fuel_counts = sort(combine(groupby(gen_df, :fuel), nrow => :count), :count; rev = true)

#-

tech_counts = sort(combine(groupby(gen_df, :tech), nrow => :count), :count; rev = true)

# ## Step 2 — load the schedule-2030 output
#
# `Generator_pmax_sched.csv` and `Demand_load_sched.csv` are PISP's
# time-varying schedule tables: PMax generator by generator, and demand
# load node by node, for the 2030 planning year.

gen_pmax = CSV.read(joinpath(SCHEDULE_DIR, "Generator_pmax_sched.csv"), DataFrame)
dem_load = CSV.read(joinpath(SCHEDULE_DIR, "Demand_load_sched.csv"), DataFrame)

println("\n=== Generator_pmax_sched ===")
println("Shape: ", size(gen_pmax))
println("Columns: ", names(gen_pmax))

# A `println` and a richly-displayed (`DataFrame`) value are kept in
# separate code cells below — confirmed empirically while implementing
# this tutorial that Literate.jl silently drops a cell's plain stdout
# output whenever that same cell's *last* statement is a value with its
# own rich HTML display (as every `DataFrame` has here, under
# `Literate.DocumenterFlavor()`), rather than showing both. First five
# rows, for a look at the actual columns:

#-

first(gen_pmax, 5)

#-

println("\n=== Demand_load_sched ===")
println("Shape: ", size(dem_load))

#-

first(dem_load, 5)

# ## Step 3 — map generators to buses/areas, and find solar/wind generators
#
# `Bus.csv` carries an `id_area` per bus; joining it onto `Generator.csv`
# via `id_bus` gives every generator a NEM area. Solar and wind generators
# are identified the same way the Python source does — a case-insensitive
# substring match on `tech` (`"PV"`/`"SOLAR"` for solar, `"WIND"` for
# wind), not an exact `fuel` match, since `tech` is the finer-grained
# column PISP actually uses to distinguish rooftop PV from utility-scale
# PV.

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

# Same reason as Step 2 for splitting the cell here: `println` output and
# a following richly-displayed `DataFrame` don't survive being in the
# same code cell together.

#-

solar_tech_counts = sort(
    combine(groupby(solar_gens, :tech), nrow => :count), :count; rev = true,
)

#-

wind_tech_counts = sort(
    combine(groupby(wind_gens, :tech), nrow => :count), :count; rev = true,
)

# ## Step 4 — reconstruct the demand-side data prep `fig2` depends on
#
# `fig2` in the Python source reuses two intermediate frames built earlier
# in that script rather than being self-contained: `dem_load_full` (demand
# load filtered to the ids that actually appear in `Demand.csv`) and a
# generator-side merge that attaches `tech` onto every `Generator_pmax_sched`
# row so it can be split into solar/wind subsets. Both are rebuilt here
# rather than assumed, since this is a rewrite, not a literal translation.

dem_load_full = filter(:id_dem => in(Set(dem_df.id_dem)), dem_load)
dem_load_full.day = Date.(dem_load_full.date)

gen_pmax_ts = innerjoin(gen_pmax, select(gen_df, [:id_gen, :tech]); on = :id_gen)
gen_pmax_ts.day = Date.(gen_pmax_ts.date)

sol_pmax_ts = filter(:tech => is_solar, gen_pmax_ts)
wind_pmax_ts = filter(:tech => is_wind, gen_pmax_ts)
nothing #hide

# `wind_pmax_ts` above is left unbound from display on purpose: it has one
# row per (wind generator, hourly timestep) for the whole 2030 year
# (tens of thousands of rows) — the same class of "don't let the last
# statement in a code block auto-display" caution as the plot object
# below, just for a large `DataFrame` instead of a `Plot`.

# ## Step 5 — daily aggregate solar PMax, wind PMax, and total demand
#
# Sum every generator's PMax (respectively, every demand node's load) within
# each calendar day, in MW, then convert to GW for the plot — the same
# aggregation `fig2` performs in the Python source.

sol_daily = sort(combine(groupby(sol_pmax_ts, :day), :value => sum => :value), :day)
wind_daily = sort(combine(groupby(wind_pmax_ts, :day), :value => sum => :value), :day)
dem_daily = sort(combine(groupby(dem_load_full, :day), :value => sum => :value), :day)

println(
    "\nDaily aggregate series length — solar: ", nrow(sol_daily),
    ", wind: ", nrow(wind_daily),
    ", demand: ", nrow(dem_daily),
)

# ## Step 6 — plot and save
#
# The figure is saved directly to `docs/src/generated/`, alongside where
# `docs/render_literate.jl` writes this file's own rendered Markdown.
# Since `@__DIR__` here already *is* that output directory (see the note
# above), the save path is just `@__DIR__` plus a filename — no `..`
# needed. The Markdown image link just below uses that same bare filename,
# since it too resolves relative to the generated `.md` file's own
# location — both are the same relative frame here, which is itself the
# thing worth double-checking rather than assuming, since it is easy to
# assume `@__DIR__` means "this source file's directory" and get it wrong
# in exactly the way this comment now documents.

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
nothing #hide

# ![2030 daily aggregate solar PMax, wind PMax, and total demand](pisp_outputs_validation-timeseries.png)

# ## Summary
#
# - PISP's `schedule-2030` build carries hourly PMax schedules only for the
#   generators whose output actually varies within a year — in this build,
#   the solar and wind fleet (the `Solar tech breakdown`/`Wind tech
#   breakdown` counts above) — everything else keeps a single static `pmax`
#   in `Generator.csv`.
# - Daily aggregate solar and wind PMax track the expected seasonal pattern
#   against total demand across the 2030 calendar year, in GW.
# - This tutorial validates PISP's own generated output against its own
#   static tables (`Generator`/`Demand`/`Bus`); it does not compare against
#   the raw AEMO capacity-factor traces the Python source also inspects —
#   that comparison, and the other two multi-panel figures, stay
#   Python-only for now.
