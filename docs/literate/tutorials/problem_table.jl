# # Building a `PISPtimeConfig` problem table
#
# PISP starts each build by constructing a **problem table**: one row for each scenario/time block that the rest of the pipeline will populate. This table is small, but it determines how later static and schedule tables are grouped.
#
# The examples below use the real helper functions that populate the table. They do not download AEMO data; all outputs come from in-memory date arithmetic and package constants.

using PISP
using Dates

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

# ## Step 1 — start with an empty problem table
#
# `PISP.initialise_time_structures()` returns three containers. The first, `tc::PISPtimeConfig`, owns the `problem` table.

tc, _ts, _tv = PISP.initialise_time_structures()
markdown_table(tc.problem)

# The table schema comes from `MOD_PROBLEM` in `src/datamodel/PISPdata-config.jl`.

names(tc.problem)

# ## Step 2 — fill a whole planning year
#
# `fill_problem_table_year` splits a planning year into January-June and July-December blocks. With all three ISP scenarios, this produces 6 rows.

PISP.fill_problem_table_year(tc, 2030)
markdown_table(tc.problem)

# The generated names encode scenario and half-year so later schedules remain distinguishable.

tc.problem.name

# ## Step 3 — fill an arbitrary date range
#
# `fill_problem_table_drange` accepts explicit `DateTime` bounds. A range that stays on one side of 1 July produces one block per scenario.

tc2, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc2,
    DateTime(2031, 7, 1, 0, 0, 0),
    DateTime(2031, 9, 30, 23, 0, 0),
)
tc2.problem.name

# A range that crosses 1 July is clipped into two blocks per scenario.

tc3, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_drange(
    tc3,
    DateTime(2030, 4, 1, 0, 0, 0),
    DateTime(2030, 9, 30, 23, 0, 0),
)
markdown_table(tc3.problem[:, [:name, :dstart, :dend]])

# The first block ends at 30 June and the second starts at 1 July.

# ## Step 4 — restrict to one scenario
#
# Both helpers accept `sce` when a study only needs a subset of the three ISP scenarios.

tc4, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_year(tc4, 2030; sce = [2])
tc4.problem.name

# ## Summary
#
# - Whole-year mode always creates two half-year blocks per scenario.
# - Date-range mode splits only when the requested range crosses 1 July.
# - The problem table is the first scenario/time index used by `PISP.build_ISP24_datasets` before AEMO input files are parsed.
