module ISPReportDownloader

    using HTTP
    using PISP.PISPScrapperUtils: DEFAULT_FILE_HEADERS

    struct ISPReportTarget
        key::Symbol
        title::String
        filename::String
        url::String
    end

    ISPReportTarget(key::Symbol,
                    title::AbstractString,
                    filename::AbstractString,
                    url::AbstractString) =
        ISPReportTarget(key, String(title), String(filename), String(url))

    const DEFAULT_REPORTS_OUTDIR = "data/pisp-reports"
    const PDF_SIGNATURE = UInt8[0x25, 0x50, 0x44, 0x46, 0x2d] # %PDF-

    const ISP_REPORT_TARGETS = ISPReportTarget[
        ISPReportTarget(:plexos_model_instructions,
                        "2024 ISP PLEXOS Model Instructions",
                        "2024-isp-plexos-model-instructions.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en"),
        ISPReportTarget(:integrated_system_plan,
                        "2024 Integrated System Plan",
                        "2024-integrated-system-plan.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-integrated-system-plan-isp.pdf?la=en"),
        ISPReportTarget(:iasr_2023,
                        "2023 Inputs, Assumptions and Scenarios Report",
                        "2023-inputs-assumptions-and-scenarios-report.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2023/2023-inputs-assumptions-and-scenarios-report.pdf?la=en"),
        ISPReportTarget(:iasr_2023_addendum,
                        "Addendum to the 2023 Inputs Assumptions and Scenarios Report",
                        "addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2023/addendum-to-2023-inputs-assumptions-and-scenarios-report.pdf?la=en"),
        ISPReportTarget(:isp_methodology_2023,
                        "ISP Methodology (30 June 2023)",
                        "2023-isp-methodology.pdf",
                        "https://www.aemo.com.au/-/media/files/stakeholder_consultation/consultations/nem-consultations/2023/isp-methodology-2023/isp-methodology_june-2023.pdf?la=en"),
        ISPReportTarget(:appendix_a2_generation_storage,
                        "A2 Generation and Storage Development Opportunities",
                        "a2-generation-and-storage-development-opportunities.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a2-generation-and-storage-development-opportunities.pdf?la=en"),
        ISPReportTarget(:appendix_a3_rez,
                        "A3 Renewable Energy Zones",
                        "a3-renewable-energy-zones.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a3-renewable-energy-zones.pdf?rev=12a046694eac41dc99031c43bbce35e0&sc_lang=en"),
        ISPReportTarget(:appendix_a4_operability,
                        "A4 System Operability",
                        "a4-system-operability.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a4-system-operability.pdf?la=en"),
        ISPReportTarget(:appendix_a6_cost_benefit,
                        "A6 Cost Benefit Analysis",
                        "a6-cost-benefit-analysis.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a6-cost-benefit-analysis.pdf?la=en"),
        ISPReportTarget(:appendix_a7_security,
                        "A7 System Security",
                        "a7-system-security.pdf",
                        "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/appendices/a7-system-security.pdf?la=en"),
    ]

    isp_report_targets() = copy(ISP_REPORT_TARGETS)

    """
        download_isp_reports(; outdir = "data/pisp-reports", overwrite = false, throttle_seconds = nothing)

    Download the ten selected 2024 ISP report PDFs from AEMO. Existing valid PDFs are
    retained unless `overwrite = true`; invalid existing files are re-downloaded.
    """
    function download_isp_reports(; outdir = "data/pisp-reports",
                                  overwrite = false,
                                  throttle_seconds = nothing)
        return download_report_targets(ISP_REPORT_TARGETS;
                                       outdir = outdir,
                                       overwrite = overwrite,
                                       throttle_seconds = throttle_seconds)
    end

    function download_report_targets(targets::AbstractVector{ISPReportTarget};
                                     outdir::AbstractString = DEFAULT_REPORTS_OUTDIR,
                                     overwrite::Bool = false,
                                     throttle_seconds::Union{Nothing,Real} = nothing,
                                     download_function::Function = download_report_file)
        throttle_seconds !== nothing && throttle_seconds < 0 &&
            throw(ArgumentError("throttle_seconds must be non-negative."))

        saved_paths = String[]
        for target in targets
            path, downloaded = download_report_target(target;
                                                       outdir = outdir,
                                                       overwrite = overwrite,
                                                       download_function = download_function)
            push!(saved_paths, path)
            downloaded && throttle_seconds !== nothing && sleep(throttle_seconds)
        end

        return saved_paths
    end

    function download_report_target(target::ISPReportTarget;
                                    outdir::AbstractString,
                                    overwrite::Bool,
                                    download_function::Function)
        destination = joinpath(outdir, target.filename)
        temporary_path = nothing

        try
            mkpath(dirname(destination))
            isdir(destination) && throw(ArgumentError("destination is a directory: $(destination)"))

            if !overwrite && is_valid_pdf(destination)
                return destination, false
            end

            temporary_path = create_temporary_path(dirname(destination))
            download_function(target.url, temporary_path; headers = DEFAULT_FILE_HEADERS)
            is_valid_pdf(temporary_path) ||
                throw(ArgumentError("downloaded payload is not a non-empty PDF."))

            # The temporary file is in the destination directory, so mv uses a rename before any fallback.
            mv(temporary_path, destination; force = true)
            return destination, true
        catch err
            throw(ErrorException("Failed to download ISP report $(target.key) ($(target.title)) from $(target.url): $(sprint(showerror, err))"))
        finally
            temporary_path !== nothing && ispath(temporary_path) && rm(temporary_path; force = true)
        end
    end

    function download_report_file(url::AbstractString,
                                  destination::AbstractString;
                                  headers::Vector{Pair{String,String}} = DEFAULT_FILE_HEADERS)
        response = HTTP.get(url; headers = headers, status_exception = false)
        response.status == 200 || throw(ArgumentError("HTTP GET returned status $(response.status)."))

        open(destination, "w") do io
            write(io, response.body)
        end
        return destination
    end

    function is_valid_pdf(path::AbstractString)
        try
            isfile(path) || return false
            filesize(path) >= length(PDF_SIGNATURE) || return false
            return open(path, "r") do io
                read(io, length(PDF_SIGNATURE)) == PDF_SIGNATURE
            end
        catch
            return false
        end
    end

    function create_temporary_path(destination_dir::AbstractString)
        path, io = mktemp(destination_dir; cleanup = false)
        close(io)
        return path
    end

end
