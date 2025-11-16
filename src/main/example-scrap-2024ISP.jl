using PISP
using PISP.ISPTraceDownloader
using PISP.ISPFileDownloader
using PISP.PISPScrapperUtils

throttle_env = get(ENV, "ISP_DOWNLOAD_THROTTLE", "")
traces_options = FileDownloadOptions(outdir            = normpath(@__DIR__, "..", "..", "data-download/zip", "traces"),
                        confirm_overwrite = true,
                        skip_existing     = false,
                        throttle_seconds  = isempty(throttle_env) ? nothing : parse(Float64, throttle_env));

files_options = FileDownloadOptions(outdir = normpath(@__DIR__, "..", "..", "data-download"),
                        confirm_overwrite = false,
                        skip_existing     = true);

files_options_zip = FileDownloadOptions(outdir = normpath(@__DIR__, "..", "..", "data-download/zip"),
                        confirm_overwrite = false,
                        skip_existing     = true);

isp24_inputs_path       = download_isp24_inputs_workbook(options = files_options)
isp19_inputs_path       = download_isp19_inputs_workbook(options = files_options)
isp24_model_path        = download_isp24_model_archive(options = files_options_zip)
isp24_gen_storage_path  = download_isp24_generation_storage_archive(options = files_options_zip)

downloaded_files = [
    isp24_inputs_path,
    isp24_model_path,
    isp24_gen_storage_path,
    isp19_inputs_path,
]
downloaded_traces = download_isp24_traces(options = traces_options)

println("Downloaded $(length(downloaded_files)) ISP reference files to $(files_options.outdir)")
println("Downloaded $(length(downloaded_traces)) ISP trace archives to $(traces_options.outdir)")
