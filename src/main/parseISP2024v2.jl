using PISP
using DataFrames
using Dates
using XLSX
using CSV

# Initialise DataFrames
tc = PISPtimeConfig();
ts = PISPtimeStatic();
tv = PISPtimeVarying();

# ======================================== #
# FILE PATHS    
# ======================================== #
datapath    = normpath(@__DIR__, "..", "..", "data");
ispdata19   = normpath(datapath, "2019InputandAssumptionsworkbookv13Dec19.xlsx");
ispdata24   = normpath(datapath, "2024 ISP Inputs and Assumptions workbook.xlsx");
profiledata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/Traces/";
outlookdata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/2024 ISP generation and storage outlook/Core";
outlookAEMO = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/CapacityOutlook_2024_ISP_melted_CDP14.xlsx";
vpp_cap     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Capacity.xlsx";
vpp_ene     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Energy.xlsx";

# ============================================ #
# ===== == Fill tables with information  ====== #
# ============================================ #
PISP.problem_table(tc);
PISP.bus_table(ts); 
PISP.dem_load(tc, ts, tv, profiledata);

txdata = PISP.line_table(ts, tv, ispdata24);
PISP.line_sched_table(tc, tv, txdata);
PISP.line_invoptions(ts, ispdata24);

SYNC4, GENERATORS, PS = PISP.generator_table(ts, ispdata19, ispdata24);
PISP.gen_n_sched_table(tv, SYNC4, GENERATORS);
PISP.gen_retirements(ts, tv);
PISP.gen_pmax_distpv(tc,  ts, tv, profiledata);
PISP.gen_pmax_solar(tc,   ts, tv, ispdata24, outlookdata, outlookAEMO, profiledata);
PISP.gen_pmax_wind(tc,    ts, tv, ispdata24, outlookdata, outlookAEMO, profiledata);

PISP.ess_tables(ts, tv, PS, ispdata24);
PISP.ess_vpps(tc, ts, tv, vpp_cap, vpp_ene);
# ============================================ #
# write 
# ============================================ #
PISP.PISPwritedataCSV(ts, "out")
PISP.PISPwritedataCSV(tv, "out/schedule-1w-new")

PISP.PISPwritedataArrow(ts, "out-arrow")
PISP.PISPwritedataArrow(tv, "out-arrow/schedule-1w-new")

