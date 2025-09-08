using PISP
using Dates

# Initialise DataFrames
tc = PISPtimeConfig();
ts = PISPtimeStatic();
tv = PISPtimeVarying();

# ======================================== #
# Data file paths   
# ======================================== #
datapath    = normpath(@__DIR__, "..", "..", "data"); # Adjust this path as needed
ispdata19   = normpath(datapath, "2019InputandAssumptionsworkbookv13Dec19.xlsx");
ispdata24   = normpath(datapath, "2024 ISP Inputs and Assumptions workbook.xlsx");
profiledata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/Traces/";
outlookdata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/2024 ISP generation and storage outlook/Core";
outlookAEMO = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/CapacityOutlook_2024_ISP_melted_CDP14.xlsx";
vpp_cap     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Capacity.xlsx";
vpp_ene     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Energy.xlsx";

# ================================================ #
#  Define dates and scenarios for data collection  #
# ================================================ #
# --> Example of problem table
# `name`          : Name of the study/case
# `scenario`      : Scenario id as per ID2SCE dictionary in PISPparameters.jl
# `weight`        : Weight of the scenario
# `problem_type`  : UC (unit commitment) - just for reference
# `dstart`        : Start date of the study [to generate only the corresponding traces]
# `dend`          : End date of the study [to generate only the corresponding traces]
# `tstep`         : Time step in minutes
# ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#  Row │ id     name                    scenario  weight   problem_type  dstart               dend                 tstep |
#      │ Int64  String                  Int64     Float64  String        DateTime             DateTime             Int64 |
# ─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#    1 │     1  Progressive_Change_1           1      1.0  UC            2025-01-01T00:00:00  2025-01-07T23:00:00     60 |
#    2 │     2  Step_Change_2                  2      1.0  UC            2025-01-08T00:00:00  2025-01-14T23:00:00     60 |
#    3 │     3  Green_Energy_Exports_3         3      1.0  UC            2025-01-15T00:00:00  2025-01-21T23:00:00     60 |
# ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

function fill_problem_table(tc::PISPtimeConfig)
    start_date = DateTime(2025, 1, 1, 0, 0, 0)
    step_ = Day(7) 
    nblocks = 3 # 1 block per scenario to be called in the following loop [this is just an example]
    date_blocks = PISP.OrderedDict()
    ref_year = 2025

    for i in 1:nblocks
        dstart = start_date + (i-1) * step_
        dend = dstart + Day(6) + Hour(23)

        if month(dend) >= 07 && month(dstart) <= 6
            dend = DateTime(year(dstart), month(dstart), 30, 23, 0, 0)
        end

        if i>1 && day(date_blocks[i-1][2]) == 30 && month(date_blocks[i-1][2]) == 6
            dstart = DateTime(year(dstart), month(dstart), 1, 0, 0, 0)
        end

        date_blocks[i] = (dstart, dend)
    end

    i = 1
    for sc in keys(PISP.ID2SCE)
        pbname = "$(PISP.ID2SCE[sc])_$(i)"
        nd_yr = ref_year
        dstart = DateTime(nd_yr, month(date_blocks[i][1]), day(date_blocks[i][1]), 0, 0, 0)
        dend   = DateTime(nd_yr, month(date_blocks[i][2]), day(date_blocks[i][2]), 23, 0, 0)
        arr = [i, replace(pbname," "=> "_"), sc, 1, "UC", dstart, dend, 60]
        push!(tc.problem, arr)
        i = i + 1
    end
end

fill_problem_table(tc);
# ============================================ #
# ======= Fill tables with information  ====== #
# ============================================ #
PISP.bus_table(ts); 
PISP.dem_load(tc, ts, tv, profiledata);

txdata = PISP.line_table(ts, tv, ispdata24);
PISP.line_sched_table(tc, tv, txdata);
PISP.line_invoptions(ts, ispdata24);

SYNC4, GENERATORS, PS = PISP.generator_table(ts, ispdata19, ispdata24);
PISP.gen_n_sched_table(tv, SYNC4, GENERATORS);
PISP.gen_retirements(ts, tv);
PISP.gen_pmax_distpv(tc, ts, tv, profiledata);
PISP.gen_pmax_solar(tc, ts, tv, ispdata24, outlookdata, outlookAEMO, profiledata);
PISP.gen_pmax_wind(tc, ts, tv, ispdata24, outlookdata, outlookAEMO, profiledata);

PISP.ess_tables(ts, tv, PS, ispdata24);
PISP.ess_vpps(tc, ts, tv, vpp_cap, vpp_ene);
# ============================================ #
# Write dataframes in CSV and Arrow formats 
# ============================================ #
# CSV format
PISP.PISPwritedataCSV(ts, "out")                    # Time-static data
PISP.PISPwritedataCSV(tv, "out/schedule-1w-new")    # Time-varying data (schedules)

# Arrow format
PISP.PISPwritedataArrow(ts, "out-arrow")                    # Time-static data
PISP.PISPwritedataArrow(tv, "out-arrow/schedule-1w-new")    # Time-varying data (schedules)