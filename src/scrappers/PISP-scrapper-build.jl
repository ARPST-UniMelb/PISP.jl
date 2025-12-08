module ISPdatabuilder

    using PISP
    using PISP.ISPTraceDownloader
    using PISP.ISPFileDownloader
    using PISP.PISPScrapperUtils
    using XLSX
    using DataFrames
    using DataFrames: Not
    using Dates
    using Dates: Date, DateFormat
    using Tables
    using CSV

    export DATE_RANGES_REFYEARS,
        default_data_root,
        download_isp_assets,
        extract_downloads,
        build_capacity_outlook_aux,
        build_storage_outlook_aux,
        build_rez_capacity_aux,
        generate_refyear4006_traces,
        generate_refyear4006_demand_traces,
        build_refyear4006_traces,
        build_pipeline

    const DEFAULT_DATA_ROOT = normpath(@__DIR__, "..", "..", "data-download")

    default_data_root() = DEFAULT_DATA_ROOT
    # Ranges to build the 4006 trace 
    # The 4006 trace is based on the ISP model published by AEMO 
    # https://aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en
    const DATE_RANGES_REFYEARS = [
        (Date("2024-07-01"), Date("2025-06-30"), 2019),
        (Date("2025-07-01"), Date("2026-06-30"), 2020),
        (Date("2026-07-01"), Date("2027-06-30"), 2021),
        (Date("2027-07-01"), Date("2028-06-30"), 2022),
        (Date("2028-07-01"), Date("2029-06-30"), 2023),
        (Date("2029-07-01"), Date("2030-06-30"), 2015),
        (Date("2030-07-01"), Date("2031-06-30"), 2011),
        (Date("2031-07-01"), Date("2032-06-30"), 2012),
        (Date("2032-07-01"), Date("2033-06-30"), 2013),
        (Date("2033-07-01"), Date("2034-06-30"), 2014),
        (Date("2034-07-01"), Date("2035-06-30"), 2015),
        (Date("2035-07-01"), Date("2036-06-30"), 2016),
        (Date("2036-07-01"), Date("2037-06-30"), 2017),
        (Date("2037-07-01"), Date("2038-06-30"), 2018),
        (Date("2038-07-01"), Date("2039-06-30"), 2019),
        (Date("2039-07-01"), Date("2040-06-30"), 2020),
        (Date("2040-07-01"), Date("2041-06-30"), 2021),
        (Date("2041-07-01"), Date("2042-06-30"), 2022),
        (Date("2042-07-01"), Date("2043-06-30"), 2023),
        (Date("2043-07-01"), Date("2044-06-30"), 2015),
        (Date("2044-07-01"), Date("2045-06-30"), 2011),
        (Date("2045-07-01"), Date("2046-06-30"), 2012),
        (Date("2046-07-01"), Date("2047-06-30"), 2013),
        (Date("2047-07-01"), Date("2048-06-30"), 2014),
        (Date("2048-07-01"), Date("2049-06-30"), 2015),
        (Date("2049-07-01"), Date("2050-06-30"), 2016),
        (Date("2050-07-01"), Date("2051-06-30"), 2017),
        (Date("2051-07-01"), Date("2052-06-30"), 2018),
    ]

    function data_dirs(data_root::AbstractString = DEFAULT_DATA_ROOT)
        root = normpath(data_root)
        return (root = root,
                zip_root = normpath(root, "zip"),
                trace_zip_root = normpath(root, "zip", "Traces"),
                files_dest = root,
                traces_dest = normpath(root, "Traces"),
                outlook_core = normpath(root, "Core"),
                outlook_aux = normpath(root, "Auxiliary"))
    end

    function maybe_throttle(throttle_seconds::Union{Nothing,Real})
        throttle_seconds !== nothing && return throttle_seconds
        throttle_env = get(ENV, "ISP_DOWNLOAD_THROTTLE", "")
        return isempty(throttle_env) ? nothing : parse(Float64, throttle_env)
    end

    """
        download_isp_assets(; data_root, confirm_overwrite, skip_existing, throttle_seconds)

    Download ISP reference files and traces to the expected directory layout under `data_root`.
    Returns a named tuple with the downloaded paths and the options used.
    """
    function download_isp_assets(; data_root::AbstractString = DEFAULT_DATA_ROOT,
                                confirm_overwrite::Bool = true,
                                skip_existing::Bool = true,
                                throttle_seconds::Union{Nothing,Real} = nothing)
        dirs = data_dirs(data_root)
        traces_options = FileDownloadOptions(outdir = dirs.trace_zip_root,
                            confirm_overwrite = confirm_overwrite,
                            skip_existing = skip_existing,
                            throttle_seconds = maybe_throttle(throttle_seconds))
        files_options = FileDownloadOptions(outdir = dirs.root,
                            confirm_overwrite = confirm_overwrite,
                            skip_existing = skip_existing)
        files_options_zip = FileDownloadOptions(outdir = dirs.zip_root,
                            confirm_overwrite = confirm_overwrite,
                            skip_existing = skip_existing)

        isp24_inputs_path  = download_isp24_inputs_workbook(options = files_options)
        isp19_inputs_path  = download_isp19_inputs_workbook(options = files_options)
        isp24_model_path   = download_isp24_model_archive(options   = files_options_zip)
        isp24_outlook_path = download_isp24_outlook(options         = files_options_zip)
        downloaded_traces  = download_isp24_traces(options = traces_options)

        downloaded_files = [
            isp24_inputs_path,
            isp24_model_path,
            isp24_outlook_path,
            isp19_inputs_path,
        ]

        @info("Downloaded $(length(downloaded_files)) ISP reference files to $(files_options.outdir)")
        @info("Downloaded $(length(downloaded_traces)) ISP trace files to $(traces_options.outdir)")

        return (files = downloaded_files,
                traces = downloaded_traces,
                options = (files = files_options,
                           zip_files = files_options_zip,
                           trace = traces_options),
                dirs = dirs)
    end

    """
        extract_downloads(; data_root, overwrite, quiet)

    Extract every zip found under `data_root/zip` into the standard structure. Returns
    the extraction destinations along with the directory layout used.
    """
    function extract_downloads(; data_root::AbstractString = DEFAULT_DATA_ROOT,
                            overwrite::Bool = true,
                            quiet::Bool = true)
        dirs = data_dirs(data_root)

        @info "Extracting ISP files" src = dirs.zip_root dest = dirs.files_dest
        file_dirs = extract_all_zips(dirs.zip_root, dirs.files_dest; overwrite = overwrite, quiet = quiet)
        @info "Finished extracting $(length(file_dirs)) ISP files"

        @info "Extracting trace files" src = dirs.trace_zip_root dest = dirs.traces_dest
        trace_dirs = extract_all_zips(dirs.trace_zip_root, dirs.traces_dest; overwrite = overwrite, quiet = quiet)
        @info "Finished extracting $(length(trace_dirs)) trace files"

        return (file_dirs = file_dirs,
                trace_dirs = trace_dirs,
                dirs = dirs)
    end

    function build_capacity_outlook_aux(; data_root::AbstractString = DEFAULT_DATA_ROOT)
        dirs = data_dirs(data_root)
        outlook_core_path      = dirs.outlook_core
        outlook_auxiliary_path = dirs.outlook_aux
        mkpath(outlook_auxiliary_path)
        file_list       = readdir(outlook_core_path)
        all_capacities  = DataFrame[]
        for f in file_list
            if endswith(f, ".xlsx")
                file_path       = normpath(outlook_core_path, f)
                parts           = split(f, " - ")
                scenario_full   = length(parts) >= 2 ? strip(parts[2]) : ""
                capacity_df     = PISP.read_xlsx_with_header(file_path, "Capacity", "A3:AG5000")
                insertcols!(capacity_df, 2, :Scenario => fill(scenario_full, nrow(capacity_df)))
                capacity_df     = filter(row -> any(x -> x isa Number && !ismissing(x), row), capacity_df)
                push!(all_capacities, capacity_df)
            end
        end
        combined_capacity_df = isempty(all_capacities) ? DataFrame() : vcat(all_capacities...; cols = :union)
        combined_xlsx_path   = normpath(outlook_auxiliary_path, "CapacityOutlook_2024_ISP.xlsx")
        XLSX.writetable(combined_xlsx_path, Tables.columntable(combined_capacity_df); sheetname="CapacityOutlook_2024_ISP", overwrite=true)

        df_outlook = copy(combined_capacity_df)

        col_names = names(df_outlook)
        for col in col_names[6:end]
            col_str = String(col)
            if occursin("-", col_str)
                first_year = strip(split(col_str, '-')[1])
                new_date = Date(parse(Int, first_year), 7, 1)
                rename!(df_outlook, col => Symbol(Dates.format(new_date, DateFormat("yyyy-mm-dd"))))
            end
        end

        value_vars      = names(df_outlook)[6:end]
        df_melted       = stack(df_outlook, value_vars; variable_name = :date, value_name = :value)
        df_melted.date  = Date.(string.(df_melted.date), DateFormat("yyyy-mm-dd"))
        sort!(df_melted, [:Scenario, :Subregion, :Technology, :date])
        df_melted = filter(:CDP => ==("CDP14"), df_melted)
        sort!(df_melted, [:Scenario, :Subregion, :Technology, :date])
        output_melted_path = normpath(outlook_auxiliary_path, "CapacityOutlook2024_Condensed.xlsx")
        XLSX.writetable(output_melted_path, Tables.columntable(df_melted); sheetname="CapacityOutlook", overwrite=true)

        return (combined_path = combined_xlsx_path,
                condensed_path = output_melted_path,
                combined = combined_capacity_df,
                condensed = df_melted)
    end

    function build_storage_outlook_aux(; data_root::AbstractString = DEFAULT_DATA_ROOT)
        dirs = data_dirs(data_root)
        outlook_core_path      = dirs.outlook_core
        outlook_auxiliary_path = dirs.outlook_aux
        mkpath(outlook_auxiliary_path)
        file_list            = readdir(outlook_core_path)
        storage_energy_dfs   = DataFrame[]
        storage_capacity_dfs = DataFrame[]
        for f in file_list
            if endswith(f, ".xlsx")
                file_path     = normpath(outlook_core_path, f)
                parts         = split(f, " - ")
                scenario_full = length(parts) >= 2 ? strip(parts[2]) : ""

                energy_df = PISP.read_xlsx_with_header(file_path, "Storage Energy", "A3:AG5000")
                insertcols!(energy_df, 2, :Scenario => fill(scenario_full, nrow(energy_df)))
                energy_df = filter(row -> any(x -> x isa Number && !ismissing(x), row), energy_df)
                push!(storage_energy_dfs, energy_df)

                capacity_df = PISP.read_xlsx_with_header(file_path, "Storage Capacity", "A3:AG5000")
                insertcols!(capacity_df, 2, :Scenario => fill(scenario_full, nrow(capacity_df)))
                capacity_df = filter(row -> any(x -> x isa Number && !ismissing(x), row), capacity_df)
                push!(storage_capacity_dfs, capacity_df)
            end
        end

        combined_energy_df   = isempty(storage_energy_dfs) ? DataFrame() : vcat(storage_energy_dfs...; cols = :union)
        combined_capacity_df = isempty(storage_capacity_dfs) ? DataFrame() : vcat(storage_capacity_dfs...; cols = :union)

        storage_energy_path   = normpath(outlook_auxiliary_path, "StorageEnergyOutlook_2024_ISP.xlsx")
        storage_capacity_path = normpath(outlook_auxiliary_path, "StorageCapacityOutlook_2024_ISP.xlsx")
        scenario_labels = collect(keys(PISP.SCE))

        energy_sheets = Pair{String,Any}[]
        capacity_sheets = Pair{String,Any}[]
        for sc in scenario_labels
            sc_label = String(sc)
            sc_rows_energy = filter(:Scenario => ==(sc_label), combined_energy_df)
            sc_rows_capacity = filter(:Scenario => ==(sc_label), combined_capacity_df)

            push!(energy_sheets, sc_label => Tables.columntable(sc_rows_energy))
            push!(capacity_sheets, sc_label => Tables.columntable(sc_rows_capacity))
        end

        if isempty(energy_sheets)
            XLSX.writetable(storage_energy_path, Tables.columntable(combined_energy_df); sheetname="StorageEnergyOutlook_2024_ISP", overwrite=true)
        else
            XLSX.writetable(storage_energy_path, energy_sheets; overwrite=true)
        end

        if isempty(capacity_sheets)
            XLSX.writetable(storage_capacity_path, Tables.columntable(combined_capacity_df); sheetname="StorageCapacityOutlook_2024_ISP", overwrite=true)
        else
            XLSX.writetable(storage_capacity_path, capacity_sheets; overwrite=true)
        end

        return (energy_path = storage_energy_path,
                capacity_path = storage_capacity_path,
                energy = combined_energy_df,
                capacity = combined_capacity_df)
    end

    function read_rez_capacity(path::AbstractString)
        return PISP.read_xlsx_with_header(path, "REZ Generation Capacity", "A3:AG5000")
    end

    function build_rez_capacity_aux(; data_root::AbstractString = DEFAULT_DATA_ROOT)
        dirs = data_dirs(data_root)
        outlook_core_path      = dirs.outlook_core
        outlook_auxiliary_path = dirs.outlook_aux
        mkpath(outlook_auxiliary_path)
        rez_files = [
            "2024 ISP - Green Energy Exports - Core.xlsx",
            "2024 ISP - Progressive Change - Core.xlsx",
            "2024 ISP - Step Change - Core.xlsx",
        ]

        outputs = String[]
        for fname in rez_files
            src   = normpath(outlook_core_path, fname)
            df    = read_rez_capacity(src)
            dest  = normpath(outlook_auxiliary_path, replace(fname, ".xlsx" => "_REZCAP.xlsx"))
            XLSX.writetable(dest, Tables.columntable(df); sheetname = "REZ Generation Capacity", overwrite = true)
            push!(outputs, dest)
        end
        return outputs
    end

    function process_traces(path::AbstractString)
        df = CSV.read(path, DataFrame)
        df.date = Date.(df.Year, df.Month, df.Day)
        return df
    end

    function generate_refyear4006_traces(
        tech::AbstractString;
        traces_root::AbstractString = data_dirs().traces_dest,
        years = 2011:2023,
        verbose::Bool = false,
    )
        tech_dir = isdir(joinpath(traces_root, tech)) ? joinpath(traces_root, tech) : traces_root
        file_names = readdir(joinpath(tech_dir, "$(tech)_2011"))
        cleaned_file_names = replace.(file_names, "_RefYear2011.csv" => "")
        output_dir = joinpath(tech_dir, "$(tech)_4006")
        mkpath(output_dir)

        output_paths = String[]
        for cleaned_file_name in cleaned_file_names
            output_path = joinpath(output_dir, "$(cleaned_file_name)_RefYear4006.csv")
            if isfile(output_path)
                verbose && @info "Skipping existing 4006 trace" path = output_path
                push!(output_paths, output_path)
                continue
            end

            verbose && @info cleaned_file_name
            tech_traces = Dict(year => process_traces(joinpath(tech_dir, "$(tech)_$(year)", "$(cleaned_file_name)_RefYear$(year).csv")) for year in years)
            filtered_frames = DataFrame[]
            for (start_date, end_date, ref_year) in DATE_RANGES_REFYEARS
                df = tech_traces[ref_year]
                mask = (df.date .>= start_date) .& (df.date .<= end_date)
                push!(filtered_frames, df[mask, :])
            end
            df_out = vcat(filtered_frames...; cols = :union)
            if "date" in names(df_out)
                select!(df_out, Not("date"))
            end
            CSV.write(output_path, df_out)
            push!(output_paths, output_path)
        end

        return output_paths
    end

    function generate_refyear4006_demand_traces(
        tech::AbstractString;
        traces_root::AbstractString = data_dirs().traces_dest,
        region::AbstractString = "",
        scenario::AbstractString = "",
        years = 2011:2023,
        poe::Real = 10,
        verbose::Bool = false,
    )
        poe_int  = Int(poe)
        tech_dir = isdir(joinpath(traces_root, tech)) ? joinpath(traces_root, tech) : traces_root
        base_dir = joinpath(tech_dir, "$(tech)_$(region)_$(scenario)")
        base_name(y) = "$(region)_RefYear_$(y)_$(PISP.DEMSCE[scenario])_POE$(poe_int)"

        output_dir = joinpath(tech_dir, "$(tech)_$(region)_$(scenario)")
        mkpath(output_dir)

        dem_types    = ("OPSO_MODELLING_PVLITE", "PV_TOT")
        output_paths = String[]

        for dt in dem_types
            output_path = joinpath(output_dir, "$(region)_RefYear_4006_$(PISP.DEMSCE[scenario])_POE$(poe_int)_$(dt).csv")
            if isfile(output_path)
                verbose && @info "Skipping existing 4006 demand trace" path = output_path
                push!(output_paths, output_path)
                continue
            end

            tech_traces = Dict{Int,DataFrame}(y => process_traces(joinpath(base_dir, "$(base_name(y))_$(dt).csv")) for y in years)
            filtered_frames = DataFrame[]
            for (start_date, end_date, ref_year) in DATE_RANGES_REFYEARS
                df   = tech_traces[ref_year]
                mask = (df.date .>= start_date) .& (df.date .<= end_date)
                push!(filtered_frames, @view df[mask, :])
            end
            df_out = vcat(filtered_frames...; cols = :union)
            select!(df_out, Not("date"))
            CSV.write(output_path, df_out)
            push!(output_paths, output_path)
        end

        return output_paths
    end

    function build_refyear4006_traces(; data_root::AbstractString = DEFAULT_DATA_ROOT,
                                    years = 2011:2023,
                                    poe::Real = 10.0,
                                    verbose::Bool = false)
        dirs = data_dirs(data_root)
        solar_4006_paths = generate_refyear4006_traces("solar"; traces_root = dirs.traces_dest, years = years, verbose = verbose)
        wind_4006_paths  = generate_refyear4006_traces("wind"; traces_root = dirs.traces_dest, years = years, verbose = verbose)

        demand_outputs = Dict{Tuple{String,String},Vector{String}}()
        for region in keys(PISP.NEMBUSNAME)
            region_str = String(region)
            for scenario in keys(PISP.DEMSCE)
                scenario_str = String(scenario)
                demand_outputs[(region_str, scenario_str)] =
                    generate_refyear4006_demand_traces("demand"; traces_root = dirs.traces_dest,
                                                    region = region_str, scenario = scenario_str,
                                                    years = years, poe = poe, verbose = verbose)
            end
        end

        return (solar = solar_4006_paths,
                wind = wind_4006_paths,
                demand = demand_outputs,
                traces_root = dirs.traces_dest)
    end

    """
        build_pipeline(; kwargs...)

    Convenience wrapper that runs the full ISP data preparation pipeline:
    download assets, extract archives, build auxiliary outlook files, and
    assemble 4006 reference-year traces.
    """
    function build_pipeline(; data_root::AbstractString = DEFAULT_DATA_ROOT,
                        confirm_overwrite::Bool = true,
                        skip_existing::Bool = true,
                        throttle_seconds::Union{Nothing,Real} = nothing,
                        overwrite_extracts::Bool = true,
                        quiet_extracts::Bool = true,
                        download_files::Bool = true,
                        build_traces::Bool = true,
                        poe::Real = 10.0,
                        years = 2011:2023,
                        verbose_traces::Bool = false)
        downloads = download_files ?
            download_isp_assets(; data_root = data_root,
                            confirm_overwrite = confirm_overwrite,
                            skip_existing = skip_existing,
                            throttle_seconds = throttle_seconds) :
            nothing
        extraction = extract_downloads(; data_root = data_root,
                                    overwrite = overwrite_extracts,
                                    quiet = quiet_extracts)
        capacity   = build_capacity_outlook_aux(; data_root = data_root)
        storage    = build_storage_outlook_aux(; data_root = data_root)
        rez_aux    = build_rez_capacity_aux(; data_root = data_root)
        traces_4006 = build_traces ?
            build_refyear4006_traces(; data_root = data_root, years = years, poe = poe, verbose = verbose_traces) :
            nothing

        return (downloads = downloads,
                extraction = extraction,
                capacity_outlook = capacity,
                storage_outlook = storage,
                rez_capacity = rez_aux,
                traces_4006 = traces_4006);
    end

end
