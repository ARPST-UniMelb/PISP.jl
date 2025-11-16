using PISP
using PISP.ISPTraceDownloader
using PISP.ISPFileDownloader
using PISP.PISPScrapperUtils

throttle_env = get(ENV, "ISP_DOWNLOAD_THROTTLE", "")
traces_options = FileDownloadOptions(outdir            = normpath(@__DIR__, "..", "..", "downloads", "traces"),
                            confirm_overwrite = true,
                            skip_existing     = false,
                            throttle_seconds  = isempty(throttle_env) ? nothing : parse(Float64, throttle_env));


isp24_workbook  = download_isp24_inputs_workbook(options = FileDownloadOptions(outdir = "downloads/ISP-files", confirm_overwrite = false, skip_existing = true)) # 2024 IASR workbook
isp19_workbook  = download_isp19_inputs_workbook(options = FileDownloadOptions(outdir = "downloads/ISP-files", confirm_overwrite = false, skip_existing = true)) # 2019 IASR workbook
isp24_model     = download_isp24_model_archive(options   = FileDownloadOptions(outdir = "downloads/ISP-files", confirm_overwrite = false, skip_existing = true)) # PLEXOS model
isp24_outlook   = download_isp24_outlook(options         = FileDownloadOptions(outdir = "downloads/ISP-files", confirm_overwrite = false, skip_existing = true)) # Generation and Storage Outlook
isp24_traces    = download_isp24_traces(options          = traces_options)
