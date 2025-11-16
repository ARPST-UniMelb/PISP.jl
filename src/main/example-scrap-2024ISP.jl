using PISP.ISPTraceDownloader
using PISP.ISPFileDownloader

page_url = get(ENV, "ISP_PAGE_URL", ISPTraceDownloader.DEFAULT_PAGE_URL)
# outdir   = get(ENV, "ISP_TRACES_OUTDIR", ISPTraceDownloader.DEFAULT_OUTDIR)
outdir = normpath(@__DIR__, "..", "..", "downloads-test", "traces")
throttle_env = get(ENV, "ISP_DOWNLOAD_THROTTLE", "")
throttle     = isempty(throttle_env) ? nothing : parse(Float64, throttle_env)

options = DownloadOptions(; outdir            = outdir,
                            confirm_overwrite = true,
                            skip_existing     = false,
                            throttle_seconds  = throttle);

filenames = download_isp24_traces(; page_url = page_url, options = options);
println("Finished. Saved $(length(filenames)) files in $(outdir).")

using PISP.ISPFileDownloader


single_files = download_all_isp_files(
    options = FileDownloadOptions(
        outdir = "scrapped/custom/ISP-files",
        confirm_overwrite = false,   # optional tweaks
        skip_existing = true,
    ),
)