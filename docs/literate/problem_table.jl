# # Building a `PISPtimeConfig` problem table
#
# This is a Literate.jl source file. It is meant to be processed with
# `Literate.markdown` (or `Literate.notebook`) to produce a runnable,
# rendered walkthrough — it is not meant to be read only as raw Julia.
#
# PISP builds ISP-2024-based power system datasets around a small set of
# scenario/time containers. Before any static or time-varying table is
# filled in, PISP first needs a **problem table**: one row per
# "sub-problem" that the rest of the pipeline will populate data for,
# where a sub-problem is a (scenario, time window) pair.
#
# AEMO's ISP scenarios are the *Progressive Change*, *Step Change*, and
# *Green Energy Exports* futures (`PISP.ID2SCE`). PISP additionally splits
# each calendar year into two Australian financial-year halves — January
# to June (H1) and July to December (H2) — because that is the boundary
# some of the underlying AEMO input files change on.
#
# This walkthrough exercises the two real helpers that build that table:
# `PISP.fill_problem_table_year` (whole calendar years, split at
# the H1/H2 boundary) and `PISP.fill_problem_table_drange`
# (an arbitrary date window, split at the boundary only if it actually
# crosses one). Both live in `src/utils/general/PISPutils-general.jl` and
# are used internally by `PISP.build_ISP24_datasets` — the package's single
# public entry point described in the README — to seed
# `tc.problem` before the rest of the build pipeline runs.
#
# No AEMO downloads or private data are required for this example: the
# `PISPtimeConfig` container starts out as an empty, schema-typed
# `DataFrame` (see `PISP.schema_to_dataframe`), and these two helpers only
# do in-memory date arithmetic and `DataFrame` row insertion.

using PISP
using Dates

# ## Step 1 — an empty problem table
#
# `PISP.initialise_time_structures()` returns three fresh containers; we
# only need the first one, `tc::PISPtimeConfig`, which owns the `problem`
# table.

tc, _ts, _tv = PISP.initialise_time_structures()
tc.problem

# The columns come straight from the `MOD_PROBLEM` schema
# (`src/datamodel/PISPdata-config.jl`): an `id`, a human-readable `name`,
# the `scenario` id, a `weight`, a `problem_type` tag (`"UC"` for unit
# commitment), the `dstart`/`dend` window, and a `tstep` in minutes.

names(tc.problem)

# ## Step 2 — fill a whole planning year
#
# `fill_problem_table_year` splits the given year at the July 1 boundary
# and writes one row per (scenario, half) pair — 3 scenarios × 2 halves =
# 6 rows for a full year.

PISP.fill_problem_table_year(tc, 2030)
tc.problem

# Every row uses a 60-minute (`tstep`) unit-commitment (`problem_type`)
# block, and the `name` embeds the scenario and half so the rows stay
# distinguishable once concatenated with other years:

tc.problem.name

# ## Step 3 — fill an arbitrary date range
#
# `fill_problem_table_drange` is the newer `drange` mode described in the
# package README as an alternative to whole-year mode. It takes explicit
# `DateTime` bounds and only splits at the July 1 boundary if the window
# actually straddles it — otherwise it emits a single block per scenario.
#
# First, a window entirely inside the second half of a year (no split
# expected, so 3 rows for 3 scenarios):

tc2, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc2,
    DateTime(2031, 7, 1, 0, 0, 0),
    DateTime(2031, 9, 30, 23, 0, 0),
)
tc2.problem.name

# Now a window that crosses July 1 — this should split into two blocks per
# scenario (6 rows total), same as whole-year mode, but with the window
# clipped to the requested start/end rather than the full half-year:

tc3, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc3,
    DateTime(2030, 4, 1, 0, 0, 0),
    DateTime(2030, 9, 30, 23, 0, 0),
)
tc3.problem[:, [:name, :dstart, :dend]]

# Notice the first block's `dend` is clipped to 30 June (the boundary),
# not 30 September, and the second block's `dstart` is clipped to 1 July —
# confirming the split, rather than a single unclipped row, actually
# happened.

# ## Step 4 — restrict to a subset of scenarios
#
# Both helpers accept a `sce` keyword to build only a subset of AEMO's
# three ISP scenarios, which is useful when a downstream study only cares
# about, say, *Step Change*:

tc4, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_year(tc4, 2030; sce = [2])
tc4.problem.name

# ## Summary
#
# - `fill_problem_table_year` and `fill_problem_table_drange` both mutate
#   a `PISPtimeConfig`'s `problem` `DataFrame` in place and share the same
#   AEMO half-year (H1/H2, split at 1 July) convention.
# - Whole-year mode always emits 2 halves per scenario; date-range mode
#   only splits when the requested window actually crosses 1 July.
# - Both are internal building blocks of `PISP.build_ISP24_datasets`, not
#   public API most users would call directly — but understanding them is
#   the fastest way to understand how PISP structures a "build" before any
#   AEMO file is even read.
