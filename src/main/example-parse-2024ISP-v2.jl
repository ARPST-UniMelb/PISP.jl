using PISP

# Configure file paths 
function default_data_paths()
    datapath = normpath(@__DIR__, "..", "..", "data")
    return (
        ispdata19   = normpath(datapath, "2019InputandAssumptionsworkbookv13Dec19.xlsx"),
        ispdata24   = normpath(datapath, "2024 ISP Inputs and Assumptions workbook.xlsx"),
        profiledata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/Traces/",
        outlookdata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/2024 ISP generation and storage outlook/Core",
        outlookAEMO = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/CapacityOutlook_2024_ISP_melted_CDP14.xlsx",
        vpp_cap     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Capacity.xlsx",
        vpp_ene     = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/Storage/StorageOutlook_Energy.xlsx",
        dsp_data    = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/CapacityOutlook/2024ISP_DSP.xlsx",
    )
end


# 1. Instantiate data containers and build problem table with desired time blocks.
data_paths = default_data_paths()
tc, ts, tv = PISP.initialise_time_structures();
PISP.populate_time_config!(tc, PISP.fill_problem_example)

# 2. Load all time-static elements (buses, lines, generators, ESS/DER info).
STATIC_PARAMS = PISP.populate_time_static!(tc, ts, tv, data_paths);

# 3. Use static parameters (STATIC_PARAMS) to derive time-varying schedules (Solar PV, Wind, Demand, etc).
PISP.populate_time_varying!(tc, ts, tv, data_paths, STATIC_PARAMS)

# 4. Export results to CSV and Arrow for downstream tools.
PISP.write_time_data(ts, tv;
    csv_static_path     = "out-v2/csv",
    csv_varying_path    = "out-v2/csv/schedule",
    arrow_static_path   = "out-v2/arrow",
    arrow_varying_path  = "out-v2/arrow/schedule",
    write_static        = true,
    write_varying       = true,
)