"""
    default_data_paths(; filepath = @__DIR__)

Return the default ISP/IASR input locations as a named tuple, rooted at
`filepath` (defaults to the directory of this file). The tuple points to the
expected workbook filenames, the ISP model directory, trace folders, and
auxiliary outlook files required by the build pipeline.

# Keyword Arguments
- `filepath::AbstractString = @__DIR__`: Base directory that already contains
  the downloaded ISP data structure. Paths are combined using `normpath`.
"""
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

"""
    fill_problem_table_year(tc, year; sce = keys(PISP.ID2SCE))

Populate `tc.problem` with half-year blocks for each scenario in `sce`. For the
given `year`, two entries are created (Jan–Jun and Jul–Dec) with a 60-minute
time step, unit weight, and problem type `"UC"`.

# Arguments
- `tc::PISPtimeConfig`: Target time-configuration container mutated in place.
- `year::Int`: Calendar year to populate.

# Keyword Arguments
- `sce`: Iterable of scenario IDs to include (defaults to all `PISP.ID2SCE`
  keys).
"""
function fill_problem_table_year(tc::PISPtimeConfig, year::Int; sce=keys(PISP.ID2SCE))
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
        for sc in sce
            pbname = "$(PISP.ID2SCE[sc])_$(year)_$(month(dstart) == 1 ? "H1" : "H2")" # H1 for first half, H2 for second half   
            arr = [row_id, replace(pbname, " " => "_"), sc, 1, "UC", dstart, dend, 60]
            push!(tc.problem, arr)
            row_id += 1
        end
    end
end

"""
    build_ISP24_datasets(; kwargs...)

Download (optionally), assemble, and export ISP 2024 datasets for one or more
planning years. For each year it initializes fresh time structures, fills
static/varying tables from the ISP inputs, and writes CSV/Arrow outputs under
`output_root` with a name prefix reflecting the reference trace and POE.

# Keyword Arguments
- `downloadpath::AbstractString = normpath(@__DIR__, "../../", "data-download")`:
  Base directory holding (or receiving) ISP inputs.
- `poe::Integer = 10`: Probability of exceedance for demand (e.g., 10 or 50).
- `reftrace::Integer = 4006`: Reference weather trace ID (2011–2023 or 4006).
- `years::AbstractVector{<:Integer} = [2025]`: Planning years to build (must be
  within 2025–2050).
- `output_name::AbstractString = "out"`: Folder name prefix for outputs.
- `output_root::Union{Nothing,AbstractString} = nothing`: Optional root path for
  outputs; when `nothing`, uses relative paths.
- `write_csv::Bool = true`: Enable CSV exports.
- `write_arrow::Bool = true`: Enable Arrow exports.
- `download_from_AEMO::Bool = true`: Download ISP files before building when
  true; otherwise expects them to already be present.
- `scenarios::AbstractVector{<:Int64} = keys(PISP.ID2SCE)`: Scenario IDs to
  include in the build.
"""
function build_ISP24_datasets(; 
    downloadpath::AbstractString = normpath(@__DIR__, "../../", "data-download"),
    poe::Integer = 10,
    reftrace::Integer = 4006,
    years::AbstractVector{<:Integer} = [2025],
    output_name::AbstractString = "out", # Output folder name
    output_root::Union{Nothing,AbstractString} = nothing,
    write_csv::Bool = true,
    write_arrow::Bool = true,
    download_from_AEMO::Bool = true,
    scenarios::AbstractVector{<:Int64} = keys(PISP.ID2SCE),
)
    if any(y -> y < 2025 || y > 2050, years)
        throw(ArgumentError("Years must be between 2025 and 2050 (got $(years))."))
    end

    data_paths = PISP.default_data_paths(filepath=downloadpath)

    # Download/extract/build inputs once
    PISP.build_pipeline(data_root = downloadpath, poe = poe, download_files = download_from_AEMO, overwrite_extracts = false)

    base_name = "$(output_name)-ref$(reftrace)-poe$(poe)"

    for year in years
        tc, ts, tv = PISP.initialise_time_structures()
        fill_problem_table_year(tc, year, sce=scenarios)
        static_params = PISP.populate_time_static!(ts, tv, data_paths; refyear = reftrace, poe = poe)
        @info "Populating time-varying data from ISP 2024 - POE $(poe) - reference weather trace $(reftrace) - planning year $(year) ..."
        PISP.populate_time_varying!(tc, ts, tv, data_paths, static_params; refyear = reftrace, poe = poe)

        PISP.write_time_data(ts, tv;
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
