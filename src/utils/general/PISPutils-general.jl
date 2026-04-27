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
        ispdata19          = normpath(filepath, "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx"),
        ispdata24          = normpath(filepath, "2024-isp-inputs-and-assumptions-workbook.xlsx"),
        iasr23_ev_workbook = normpath(filepath, "2023-iasr-ev-workbook.xlsx"),
        ispmodel           = normpath(filepath, "2024 ISP Model"),
        profiledata        = normpath(filepath, "Traces/"),
        outlookdata        = normpath(filepath, "Core"),
        outlookAEMO        = normpath(filepath, "Auxiliary/CapacityOutlook2024_Condensed.xlsx"),
        vpp_cap            = normpath(filepath, "Auxiliary/StorageCapacityOutlook_2024_ISP.xlsx"),
        vpp_ene            = normpath(filepath, "Auxiliary/StorageEnergyOutlook_2024_ISP.xlsx"),
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

function _to_datetime(d, bound::Symbol)
    dt = d isa DateTime ? d :
         d isa Date     ? DateTime(d) :
         DateTime(Date(string(d), dateformat"dd-mm-yyyy"))
    bound === :end ? DateTime(year(dt), month(dt), day(dt), 23, 0, 0) :
                     DateTime(year(dt), month(dt), day(dt),  0, 0, 0)
end

"""
    fill_problem_table_drange(tc, dstart, dend; sce = keys(PISP.ID2SCE))

Populate `tc.problem` for an arbitrary date range. If the range crosses the
July 1 half-year boundary it is automatically split into two blocks (H1/H2),
matching the structure used by `fill_problem_table_year`. One problem row per
block per scenario is created with a 60-minute time step, unit weight, and
problem type `"UC"`.

# Arguments
- `tc::PISPtimeConfig`: Target time-configuration container mutated in place.
- `dstart::DateTime`: Start of the date range (inclusive, at 00:00:00).
- `dend::DateTime`: End of the date range (inclusive, at 23:00:00).

# Keyword Arguments
- `sce`: Iterable of scenario IDs to include (defaults to all `PISP.ID2SCE` keys).
"""
function fill_problem_table_drange(tc::PISPtimeConfig, dstart::DateTime, dend::DateTime; sce=keys(PISP.ID2SCE))
    july1 = DateTime(year(dstart), 7, 1, 0, 0, 0)
    blocks = if dstart < july1 && dend >= july1
        [(dstart, DateTime(year(dstart), 6, 30, 23, 0, 0)),
         (july1, dend)]
    else
        [(dstart, dend)]
    end

    row_id = 1
    for (ds, de) in blocks
        for sc in sce
            start_str = Dates.format(ds, "ddmmyyyy")
            end_str   = Dates.format(de, "ddmmyyyy")
            pbname = replace("$(PISP.ID2SCE[sc])_$(start_str)-$(end_str)", " " => "_")
            push!(tc.problem, [row_id, pbname, sc, 1, "UC", ds, de, 60])
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
- `years::Union{Nothing,AbstractVector{<:Integer}} = nothing`: Planning years to
  build (must be within 2025–2050). Defaults to `[2025]` when neither `years`
  nor `drange` is given. Mutually exclusive with `drange`.
- `drange::Union{Nothing,AbstractVector} = nothing`: Alternative to `years`. An
  array of 2-tuples `(start, end)` where each element may be a `Date`,
  `DateTime`, or `AbstractString` in `"DD-MM-YYYY"` format. One problem entry
  is created per tuple per scenario. Ranges crossing July 1 are automatically
  split into two half-year blocks. Output folders are named
  `schedule-DDMMYYYY-DDMMYYYY`. Mutually exclusive with `years`.
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
    years::Union{Nothing,AbstractVector{<:Integer}} = nothing,
    drange::Union{Nothing,AbstractVector} = nothing,
    output_name::AbstractString = "out",
    output_root::Union{Nothing,AbstractString} = nothing,
    write_csv::Bool = true,
    write_arrow::Bool = true,
    download_from_AEMO::Bool = true,
    scenarios::AbstractVector{<:Int64} = keys(PISP.ID2SCE),
)
    if years !== nothing && drange !== nothing
        throw(ArgumentError("Only one of `years` or `drange` may be specified, not both."))
    end
    if years === nothing && drange === nothing
        throw(ArgumentError("At least one of `years` or `drange` must be specified."))
    end
    if years !== nothing && any(y -> y < 2025 || y > 2050, years)
        throw(ArgumentError("Years must be between 2025 and 2050 (got $(years))."))
    end

    data_paths = PISP.default_data_paths(filepath=downloadpath)

    # Download/extract/build inputs once
    PISP.build_pipeline(data_root = downloadpath, poe = poe, download_files = download_from_AEMO, overwrite_extracts = false)

    base_name = "$(output_name)-ref$(reftrace)-poe$(poe)"

    items = years !== nothing ? years : drange
    mode  = years !== nothing ? :year : :drange

    for item in items
        tc, ts, tv = PISP.initialise_time_structures()

        if mode === :year
            fill_problem_table_year(tc, item, sce=scenarios)
            tag = string(item)
        else
            (raw_start, raw_end) = item
            ds = _to_datetime(raw_start, :start)
            de = _to_datetime(raw_end,   :end)
            fill_problem_table_drange(tc, ds, de, sce=scenarios)
            tag = "$(Dates.format(ds, "ddmmyyyy"))-$(Dates.format(de, "ddmmyyyy"))"
        end

        static_params = PISP.populate_time_static!(ts, tv, data_paths; refyear = reftrace, poe = poe)
        @info "Populating time-varying data from ISP 2024 - POE $(poe) - reference weather trace $(reftrace) - schedule $(tag) ..."
        PISP.populate_time_varying!(tc, ts, tv, data_paths, static_params; refyear = reftrace, poe = poe)

        PISP.write_time_data(ts, tv;
            csv_static_path    = "$(base_name)/csv",
            csv_varying_path   = "$(base_name)/csv/schedule-$(tag)",
            arrow_static_path  = "$(base_name)/arrow",
            arrow_varying_path = "$(base_name)/arrow/schedule-$(tag)",
            write_static       = true,
            write_varying      = true,
            output_root        = output_root,
            write_csv          = write_csv,
            write_arrow        = write_arrow,
        )
    end
end
