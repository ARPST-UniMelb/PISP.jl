# # ISP 2024: Building a problem table
#
# PISP starts each build by constructing a **problem table**: one row for each scenario/time block that the rest of the pipeline will populate.
# The table is small, but it determines how later static and schedule tables are grouped.
#
# ## Purpose and scope
#
# This tutorial explains the scenario and date blocks created before an ISP 2024 dataset build.
# The examples use the package's in-memory initialisation helpers and do not require source downloads.
#
# ## What the problem table controls
#
# Each row identifies a scenario, a start and end time, a problem type, and a model time step.
# It is an execution index created by PISP rather than a table supplied by AEMO.
# Later schedule tables use these scenario/time blocks to keep otherwise similar outputs distinguishable.

using PISP
using Dates
using DataFrames

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

# ## Problem-table schema
#
# `PISP.initialise_time_structures()` returns three containers. The first, `tc::PISPtimeConfig`, owns the `problem` table.

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

# The executable `tc.problem` table is empty at initialisation; the schema is defined by `MOD_PROBLEM` in `src/datamodel/PISPdata-config.jl` and populated by the selected scenario/time workflow.

# ## Whole-year blocks
#
# `fill_problem_table_year` splits a planning year into January-June and July-December blocks. With all three ISP scenarios, this produces 6 rows.

PISP.fill_problem_table_year(tc, 2030)
markdown_table(tc.problem)

# The generated names encode scenario and half-year so later schedules remain distinguishable.

tc.problem.name

# ## Explicit date ranges
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

# ## Scenario selection
#
# Both helpers accept `sce` when a study only needs a subset of the three ISP scenarios.

tc4, _, _ = PISP.initialise_time_structures()
PISP.fill_problem_table_year(tc4, 2030; sce = [2])
tc4.problem.name

# ## Validate the result
#
# - Whole-year mode creates two half-year blocks per selected scenario.
# - Date-range mode creates one block when the range stays on one side of 1 July and two blocks when it crosses that boundary.
# - The displayed `dstart` and `dend` values provide the boundary check: the first half ends at 30 June 23:00 and the second starts at 1 July 00:00.
# - Restricting `sce` changes the scenario rows without changing the half-year split.
#
# ## Next step
#
# `PISP.build_ISP24_datasets` constructs this scenario/time index internally before it parses the AEMO inputs and writes the static and schedule tables.
# Most users call the high-level builder; these helpers are useful when inspecting date partitioning or developing a custom workflow.
