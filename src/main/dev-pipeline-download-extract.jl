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
# get a list of files in data-download/outlook/Core
datapath = normpath(@__DIR__, "..", "..", "data-download")
outlook_core_path = normpath(datapath,"2024-isp-generation-and-storage-outlook/Core")
file_list = readdir(outlook_core_path)
for f in file_list
    if endswith(f, ".xlsx")
        file_path = normpath(outlook_core_path, f)
        println("Processing file: ", file_path)
        capacity_df = PISP.read_xlsx_with_header(file_path, "Capacity", "A3:XX5000")
        csv_path = replace(file_path, ".xlsx" => "_Capacity.csv")
        CSV.write(csv_path, capacity_df)
        # 
        println("Saved capacity data to: ", csv_path)
    end
end
# capacity_df = PISP.read_xlsx_with_header(file_path, "Capacity", "A3:XX5000")


outlookAEMO = normpath(datapath, "CapacityOutlook/CapacityOutlook_2024_ISP_melted_CDP14.xlsx")
vpp_cap     = normpath(datapath, "CapacityOutlook/Storage/StorageOutlook_Capacity.xlsx")
vpp_ene     = normpath(datapath, "CapacityOutlook/Storage/StorageOutlook_Energy.xlsx")
dsp_data    = normpath(datapath, "CapacityOutlook/2024ISP_DSP.xlsx")