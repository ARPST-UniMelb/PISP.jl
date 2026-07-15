module ISPReportDownloader

    using HTTP
    using PISP.PISPScrapperUtils: DEFAULT_FILE_HEADERS

    export ISPReportTarget,
        ReportDownloadFailure,
        ReportDownloadResult,
        download_report_targets

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

    struct ReportDownloadFailure
        target::ISPReportTarget
        error::String
    end

    struct ReportDownloadResult
        paths::Vector{String}
        failures::Vector{ReportDownloadFailure}
    end

    const PDF_SIGNATURE = UInt8[0x25, 0x50, 0x44, 0x46, 0x2d] # %PDF-

    function download_report_targets(targets::AbstractVector{ISPReportTarget};
                                     outdir::AbstractString,
                                     overwrite::Bool = false,
                                     throttle_seconds::Union{Nothing,Real} = nothing,
                                     download_function::Function = download_report_file)
        throttle_seconds !== nothing && throttle_seconds < 0 &&
            throw(ArgumentError("throttle_seconds must be non-negative."))

        paths = String[]
        failures = ReportDownloadFailure[]
        for target in targets
            try
                path, downloaded = download_report_target(target;
                                                           outdir = outdir,
                                                           overwrite = overwrite,
                                                           download_function = download_function)
                push!(paths, path)
                downloaded && throttle_seconds !== nothing && sleep(throttle_seconds)
            catch err
                push!(failures, ReportDownloadFailure(target, sprint(showerror, err)))
                @warn "Failed to download ISP report; continuing with later targets" target = target.key exception = (err, catch_backtrace())
            end
        end

        return ReportDownloadResult(paths, failures)
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
        isfile(path) || return false
        filesize(path) >= length(PDF_SIGNATURE) || return false
        return open(path, "r") do io
            read(io, length(PDF_SIGNATURE)) == PDF_SIGNATURE
        end
    end

    function create_temporary_path(destination_dir::AbstractString)
        path, io = mktemp(destination_dir; cleanup = false)
        close(io)
        return path
    end

end
