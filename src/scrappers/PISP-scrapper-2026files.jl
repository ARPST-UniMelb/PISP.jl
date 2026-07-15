module ISP2026FileDownloader

    using PISP.PISPScrapperUtils: DEFAULT_FILE_HEADERS, download_file

    struct ISPFileTarget
        key::Symbol
        title::String
        url::String
        filename::String
        subdir::String
    end

    ISPFileTarget(key::Symbol,
                  title::AbstractString,
                  url::AbstractString;
                  filename::AbstractString,
                  subdir::AbstractString = "") =
        ISPFileTarget(key, String(title), String(url), String(filename), String(subdir))

    const DEFAULT_FILES_OUTDIR = "scrapped/ISP_reference_files"

    # Solar and wind traces are direct archives for the 2026 release, unlike the
    # HTML-discovered trace links used by the 2024 downloader.
    const ISP_FILE_TARGETS = ISPFileTarget[
        ISPFileTarget(:isp26_inputs,
                      "2026 ISP Inputs and Assumptions workbook",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-inputs-and-assumptions-workbook.xlsm?rev=de6f5853cd5e4d5cbb06bc90bdf0e378&sc_lang=en";
                      filename = "2026-isp-inputs-and-assumptions-workbook.xlsm"),
        ISPFileTarget(:isp26_ev_support,
                      "2025 IASR EV workbook referenced by the final 2026 ISP workbook",
                      "https://aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2024/2025-iasr-scenarios/final-docs/AEMO-2025-IASR-EV-workbook";
                      filename = "aemo-2025-iasr-ev-workbook.xlsx"),
        ISPFileTarget(:isp26_outlook,
                      "2026 ISP generation and storage outlook",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/supporting-materials/2026-isp-generation-and-storage-outlook.zip?rev=b64eda28a46b4d3eb3e4b3cbafea3f84&sc_lang=en";
                      filename = "2026-isp-generation-and-storage-outlook.zip",
                      subdir = "zip"),
        ISPFileTarget(:isp26_model,
                      "2026 ISP Model",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-model.zip?rev=78bfcf05ad414a8f9ba01f6a7c329fc2&sc_lang=en";
                      filename = "2026-isp-model.zip",
                      subdir = "zip"),
        ISPFileTarget(:isp26_solar_traces,
                      "2026 ISP Solar traces",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-solar-traces.zip?rev=3ad06155b7b94628bc77b90efe94588e&sc_lang=en";
                      filename = "2026-isp-solar-traces.zip",
                      subdir = "zip/Traces"),
        ISPFileTarget(:isp26_wind_traces,
                      "2026 ISP Wind traces",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2026/isp-model/2026-isp-wind-traces.zip?rev=73674cd5bc6b4b7fbbc7d0e68ee0bc7c&sc_lang=en";
                      filename = "2026-isp-wind-traces.zip",
                      subdir = "zip/Traces"),
    ]

    isp_file_targets() = copy(ISP_FILE_TARGETS)

    """
        download_isp2026_files(; outdir = "scrapped/ISP_reference_files", overwrite = false, throttle_seconds = nothing)

    Download the six direct 2026 ISP source assets. Existing files are retained unless
    `overwrite = true`. This downloader does not extract archives or derive trace data.
    """
    function download_isp2026_files(; outdir::AbstractString = DEFAULT_FILES_OUTDIR,
                                    overwrite::Bool = false,
                                    throttle_seconds::Union{Nothing,Real} = nothing,
                                    download_function::Function = download_file)
        return download_isp_files(ISP_FILE_TARGETS;
                                  outdir = outdir,
                                  overwrite = overwrite,
                                  throttle_seconds = throttle_seconds,
                                  download_function = download_function)
    end

    function download_isp_files(targets::AbstractVector{ISPFileTarget};
                                outdir::AbstractString = DEFAULT_FILES_OUTDIR,
                                overwrite::Bool = false,
                                throttle_seconds::Union{Nothing,Real} = nothing,
                                download_function::Function = download_file)
        throttle_seconds !== nothing && throttle_seconds < 0 &&
            throw(ArgumentError("throttle_seconds must be non-negative."))

        saved_paths = String[]
        for target in targets
            destination = joinpath(outdir, target.subdir, target.filename)
            try
                mkpath(dirname(destination))
                isdir(destination) && throw(ArgumentError("destination is a directory: $(destination)"))

                if !overwrite && isfile(destination)
                    push!(saved_paths, destination)
                    continue
                end

                download_function(target.url, destination; headers = DEFAULT_FILE_HEADERS)
                isfile(destination) || throw(ArgumentError("download function did not create the destination file."))
                throttle_seconds !== nothing && sleep(throttle_seconds)
                push!(saved_paths, destination)
            catch err
                throw(ErrorException("Failed to download ISP source $(target.key) ($(target.title)) from $(target.url): $(sprint(showerror, err))"))
            end
        end

        return saved_paths
    end

end
