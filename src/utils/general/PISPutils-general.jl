function default_data_paths(;filepath=@__DIR__)
    return (
        ispdata19   = normpath(filepath, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx"),
        ispdata24   = normpath(filepath, "2024-isp-inputs-and-assumptions-workbook.xlsx"),
        ispmodel    = normpath(filepath, "2024 ISP Model"),
        profiledata = normpath(filepath, "Traces/"),
        outlookdata = normpath(filepath, "Core"),
        outlookAEMO = normpath(filepath, "Auxiliary/CapacityOutlook2024_Condensed.xlsx"),
        vpp_cap     = normpath(filepath, "Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx"),
        vpp_ene     = normpath(filepath, "Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx"),
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

function build_ISP24_datasets(; 
    downloadpath::AbstractString = normpath(@__DIR__, "../../", "data-download"),
    poe::Integer = 10,
    reftrace::Integer = 2011,
    years::AbstractVector{<:Integer} = [2025],
    output_name::AbstractString = "out", # Output folder name
    output_root::Union{Nothing,AbstractString} = nothing,
    write_csv::Bool = true,
    write_arrow::Bool = true,
    download_from_AEMO::Bool = true,
)
    if any(y -> y < 2025 || y > 2050, years)
        throw(ArgumentError("Years must be between 2025 and 2050 (got $(years))."))
    end

    data_paths = PISP.default_data_paths(filepath=downloadpath)

    # Download/extract/build inputs once
    PISP.build_pipeline(data_root = downloadpath, poe = poe, download_files = download_from_AEMO)

    base_name = "$(output_name)-ref$(reftrace)-poe$(poe)"

    for year in years
        tc, ts, tv = PISP.initialise_time_structures()
        @time fill_problem_table_year(tc, year)
        @time static_params = PISP.populate_time_static!(ts, tv, data_paths; refyear = reftrace, poe = poe)
        @info "Populating time-varying data from ISP 2024 - POE $(poe) - reference weather trace $(reftrace) - planning year $(year) ..."
        @time PISP.populate_time_varying!(tc, ts, tv, data_paths, static_params; refyear = reftrace, poe = poe)

        @time PISP.write_time_data(ts, tv;
            csv_static_path    = "$(base_name)/csv",
            csv_varying_path   = "$(base_name)/csv/schedule-$(year)",
            arrow_static_path  = "$(base_name)/arrow",
            arrow_varying_path = "$(base_name)/arrow/schedule-$(year)",
            write_static       = true,
            write_varying      = true,
            output_root        = output_root,
            write_csv          = write_csv,
            write_arrow        = write_arrow,
        )
    end
end
