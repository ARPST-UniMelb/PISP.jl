using PISP
using PISP.ISPTraceDownloader
using PISP.ISPFileDownloader
using PISP.PISPScrapperUtils
# ================================================ # 
# Download traces
# ================================================ # 
throttle_env = get(ENV, "ISP_DOWNLOAD_THROTTLE", "")

# ================================================ # 
# Download options
# ================================================ # 
# Download options for traces 
traces_options = FileDownloadOptions(outdir            = normpath(@__DIR__, "..", "..", "data-download/zip", "traces"),
                        confirm_overwrite = true,
                        skip_existing     = false,
                        throttle_seconds  = isempty(throttle_env) ? nothing : parse(Float64, throttle_env));
# Download options for excel files
files_options = FileDownloadOptions(outdir = normpath(@__DIR__, "..", "..", "data-download"),
                        confirm_overwrite = true,
                        skip_existing     = false);
# Download options for zip files
files_options_zip = FileDownloadOptions(outdir = normpath(@__DIR__, "..", "..", "data-download/zip"),
                        confirm_overwrite = true,
                        skip_existing     = false);

# Download ISP files and collect paths
isp24_inputs_path       = download_isp24_inputs_workbook(options = files_options)
isp19_inputs_path       = download_isp19_inputs_workbook(options = files_options)
isp24_model_path        = download_isp24_model_archive(options   = files_options_zip)
isp24_outlook_path      = download_isp24_outlook(options         = files_options_zip)
# Download ISP traces
downloaded_traces       = download_isp24_traces(options = traces_options)

downloaded_files = [
    isp24_inputs_path,
    isp24_model_path,
    isp24_outlook_path,
    isp19_inputs_path,
]

@info("Downloaded $(length(downloaded_files)) ISP reference files to $(files_options.outdir)")
@info("Downloaded $(length(downloaded_traces)) ISP trace archives to $(traces_options.outdir)")

# ================================================ # 
# Extract downloaded files
# ================================================ #
root            = normpath(@__DIR__, "..", "..", "data-download"); # Folder of downloaded files
zip_root        = joinpath(root, "zip"); # Folder with zip files
trace_zip_root  = joinpath(zip_root, "traces"); # Folder with trace zip files

# Location where files are going to be extracted
files_dest      = root;
traces_dest     = joinpath(root, "traces");

@info "Extracting ISP files" src = zip_root dest = files_dest
file_dirs = extract_all_zips(zip_root, files_dest; overwrite = true, quiet = true)
@info "Finished extracting ISP files" count = length(file_dirs)

@info "Extracting trace archives" src = trace_zip_root dest = traces_dest
trace_dirs = extract_all_zips(trace_zip_root, traces_dest; overwrite = true, quiet = true)
@info "Finished extracting trace archives" count = length(trace_dirs)

# ================================================ # 
# Generate auxiliary files
# ================================================ #
using XLSX
using DataFrames
using CSV
using Dates
using Tables
# ================================================ #
# Generating CapacityOutlook_2024_ISP.csv
# ================================================ #
datapath               = normpath(@__DIR__, "..", "..", "data-download")
outlook_core_path      = normpath(datapath,"2024-isp-generation-and-storage-outlook/Core")
outlook_auxiliary_path = normpath(datapath,"2024-isp-generation-and-storage-outlook/Auxiliary")
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
combined_csv_path    = normpath(outlook_auxiliary_path, "CapacityOutlook_2024_ISP.csv")
CSV.write(combined_csv_path, combined_capacity_df)
# ================================================ #
# Generating the capacity for the CDP 14 scenario
# outlookAEMO = normpath(datapath, "CapacityOutlook/CapacityOutlook_2024_ISP_melted_CDP14.xlsx")
# ================================================ #
# Build melted CapacityOutlook_2024_ISP DataFrame and save CDP14 version
outlook_combined_path = combined_csv_path
df_outlook = DataFrame(CSV.File(outlook_combined_path))

# Rename yearly columns (e.g., "2025-26") to a July 1 date string (e.g., "2025-07-01")
col_names = names(df_outlook)
for col in col_names[6:end]
    col_str = String(col)
    if occursin("-", col_str)
        first_year = strip(split(col_str, '-')[1])
        new_date = Dates.Date(parse(Int, first_year), 7, 1)
        rename!(df_outlook, col => Symbol(Dates.format(new_date, DateFormat("yyyy-mm-dd"))))
    end
end

value_vars      = names(df_outlook)[6:end]
df_melted       = stack(df_outlook, value_vars; variable_name = :date, value_name = :value)
df_melted.date  = Dates.Date.(string.(df_melted.date), Dates.DateFormat("yyyy-mm-dd"))
sort!(df_melted, [:Scenario, :Subregion, :Technology, :date])
df_melted = filter(:CDP => ==("CDP14"), df_melted)
sort!(df_melted, [:Scenario, :Subregion, :Technology, :date])
mkpath(outlook_auxiliary_path)
output_melted_path = normpath(outlook_auxiliary_path, "CapacityOutlook2024_Condensed.csv")
CSV.write(output_melted_path, df_melted)

# ================================================ #
# Storage energy and capacity outlook
# ================================================ #
# modify code here
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
XLSX.writetable(storage_energy_path, Tables.columntable(combined_energy_df); sheetname="StorageEnergyOutlook_2024_ISP", overwrite=true)
XLSX.writetable(storage_capacity_path, Tables.columntable(combined_capacity_df); sheetname="StorageCapacityOutlook_2024_ISP", overwrite=true)

# vpp_cap     = normpath(datapath, "CapacityOutlook/Storage/StorageOutlook_Capacity.xlsx")
# vpp_ene     = normpath(datapath, "CapacityOutlook/Storage/StorageOutlook_Energy.xlsx")
dsp_data    = normpath(datapath, "CapacityOutlook/2024ISP_DSP.xlsx") #This should be directly taken from the ISP data
