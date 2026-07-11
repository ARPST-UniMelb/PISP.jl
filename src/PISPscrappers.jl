include("scrappers/PISP-scrapper-utils.jl")
include("scrappers/PISP-scrapper-2024traces.jl")
include("scrappers/PISP-scrapper-2024files.jl")
include("scrappers/PISP-scrapper-2024reports.jl")
include("scrappers/PISP-scrapper-build.jl")
using .ISPdatabuilder: build_pipeline
using .ISPReportDownloader: download_isp_reports
export build_pipeline, download_isp_reports
