using PISP
using Dates

# Configure file paths 
function default_data_paths()
    datapath = normpath(@__DIR__, "..", "..", "data-download-v2")
    return (
        ispdata19   = normpath(datapath, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx"),
        ispdata24   = normpath(datapath, "2024-isp-inputs-and-assumptions-workbook.xlsx"),
        profiledata = normpath(datapath, "traces/"),
        outlookdata = normpath(datapath, "Core"),
        outlookAEMO = normpath(datapath, "Auxiliary/CapacityOutlook2024_Condensed.xlsx"),
        vpp_cap     = normpath(datapath, "Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx"),
        vpp_ene     = normpath(datapath, "Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx"),
        ispmodel    = normpath(datapath, "2024 ISP Model")
    )
end

function fill_problem_table_year(tc::PISPtimeConfig, year::Int)
    # Generate date blocks from 2025 to 2035, with periods starting 01/01 and 01/07
    date_blocks = PISP.OrderedDict()
    block_id = 1
    
    # First block: January 1 to June 30
    dstart_jan = DateTime(year, 1, 1, 0, 0, 0)
    dend_jan = DateTime(year, 6, 30, 23, 0, 0)
    date_blocks[block_id] = (dstart_jan, dend_jan, year)
    block_id += 1
    
    # Second block: July 1 to December 31
    dstart_jul = DateTime(year, 7, 1, 0, 0, 0)
    dend_jul = DateTime(year, 12, 31, 23, 0, 0)
    date_blocks[block_id] = (dstart_jul, dend_jul, year)
    block_id += 1

    # Create problem entries for each scenario and each date block
    row_id = 1
    for (block_num, (dstart, dend, year)) in date_blocks
        for sc in keys(PISP.ID2SCE)
            pbname = "$(PISP.ID2SCE[sc])_$(year)_$(month(dstart) == 1 ? "H1" : "H2")" # H1 for first half, H2 for second half   
            arr = [row_id, replace(pbname, " " => "_"), sc, 1, "UC", dstart, dend, 60]
            push!(tc.problem, arr)
            row_id += 1
        end
    end
end

# for year in 2025:2035
# 1. Instantiate data containers and build problem table with desired time blocks.
data_paths = default_data_paths()
tc, ts, tv = PISP.initialise_time_structures();
# PISP.populate_time_config!(tc, PISP.fill_problem_example)
fill_problem_table_year(tc, 2025)

# 2. Load all time-static elements (buses, lines, generators, ESS/DER info).
STATIC_PARAMS = PISP.populate_time_static!(tc, ts, tv, data_paths, refyear=4006);

# 3. Use static parameters (STATIC_PARAMS) to derive time-varying schedules (Solar PV, Wind, Demand, etc).
PISP.populate_time_varying!(tc, ts, tv, data_paths, STATIC_PARAMS, refyear=4006);

# 4. Export results to CSV and Arrow for downstream tools.
PISP.write_time_data(ts, tv;
    csv_static_path     = "out-v10/csv",
    csv_varying_path    = "out-v10/csv/schedule-$(year)",
    arrow_static_path   = "out-v10/arrow",
    arrow_varying_path  = "out-v10/arrow/schedule-$(year)",
    write_static        = true,
    write_varying       = true,
)
# end