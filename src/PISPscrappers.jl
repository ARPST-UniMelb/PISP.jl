include("scrappers/PISP-scrapper-utils.jl")
include("scrappers/PISP-scrapper-2024traces.jl")
include("scrappers/PISP-scrapper-2024files.jl")
include("scrappers/PISP-scrapper-report-core.jl")
include("scrappers/PISP-scrapper-2024reports.jl")
include("scrappers/PISP-scrapper-2026reports.jl")
include("scrappers/PISP-scrapper-2026files.jl")
include("scrappers/PISP-scrapper-build.jl")
using .ISPdatabuilder: build_pipeline
using .ISP2026FileDownloader: download_isp2026_files as download_isp2026_assets

function download_ISP24_reports(; outdir = ISP2024ReportDownloader.DEFAULT_REPORTS_OUTDIR,
                                overwrite = false,
                                throttle_seconds = nothing)
    ISP2024ReportDownloader.download_reports(; outdir = outdir,
                                              overwrite = overwrite,
                                              throttle_seconds = throttle_seconds)
    return nothing
end

function download_ISP26_reports(; outdir = ISP2026ReportDownloader.DEFAULT_REPORTS_OUTDIR,
                                overwrite = false,
                                throttle_seconds = nothing)
    ISP2026ReportDownloader.download_reports(; outdir = outdir,
                                              overwrite = overwrite,
                                              throttle_seconds = throttle_seconds)
    return nothing
end

export build_pipeline,
    download_ISP24_reports,
    download_ISP26_reports,
    download_isp2026_assets
