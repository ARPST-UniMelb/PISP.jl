module ISPFileDownloader

    using PISP.PISPScrapperUtils: DEFAULT_FILE_HEADERS,
        FileDownloadOptions,
        download_file,
        interactive_overwrite_prompt,
        prompt_skip_existing

    export ISPFileTarget,
        FileDownloadOptions,
        isp_file_targets,
        download_isp_files,
        download_all_isp_files,
        download_isp24_inputs_workbook,
        download_isp24_model_archive,
        download_isp24_generation_storage_archive,
        download_isp24_outlook,
        download_isp19_inputs_workbook

    const DEFAULT_FILES_OUTDIR = "scrapped/ISP_reference_files"

    function default_file_download_options(; outdir::AbstractString = DEFAULT_FILES_OUTDIR,
                                            confirm_overwrite::Bool = true,
                                            skip_existing::Bool = false,
                                            throttle_seconds::Union{Nothing,Real} = nothing,
                                            file_headers::Vector{Pair{String,String}} = DEFAULT_FILE_HEADERS)
        return FileDownloadOptions(; outdir = outdir,
                                    confirm_overwrite = confirm_overwrite,
                                    skip_existing = skip_existing,
                                    throttle_seconds = throttle_seconds,
                                    file_headers = file_headers)
    end

    struct ISPFileTarget
        key::Symbol
        title::String
        url::String
        filename::Union{Nothing,String}
        subdir::Union{Nothing,String}
    end

    ISPFileTarget(key::Symbol, title::AbstractString, url::AbstractString;
                filename::Union{Nothing,AbstractString} = nothing,
                subdir::Union{Nothing,AbstractString} = nothing) =
        ISPFileTarget(key,
                      String(title),
                      String(url),
                      filename === nothing ? nothing : String(filename),
                      subdir === nothing ? nothing : String(subdir))

    const ISP_FILE_TARGETS = ISPFileTarget[
        ISPFileTarget(:isp24_inputs,
                      "2024 ISP Inputs and Assumptions workbook",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/2024-isp-inputs-and-assumptions-workbook.xlsx?rev=c75116cf5a834eeaa6b4ed68cff9b117&sc_lang=en";
                      filename = "2024-isp-inputs-and-assumptions-workbook.xlsx",
                      subdir = ""),
        ISPFileTarget(:isp24_model,
                      "2024 ISP Model",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-model.zip?rev=3b35a0a57f564ec88098985782d2932c&sc_lang=en";
                      filename = "2024-isp-model.zip",
                      subdir = ""),
        ISPFileTarget(:isp24_outlook,
                      "2024 ISP generation and storage outlook",
                      "https://www.aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-generation-and-storage-outlook.zip?rev=986359059f934cc0bbbd94d0b5280e68&sc_lang=en";
                      filename = "2024-isp-generation-and-storage-outlook.zip",
                      subdir = ""),
        ISPFileTarget(:isp19_inputs_v13,
                      "2019 input and assumptions workbook v1.3",
                      "https://www.aemo.com.au/-/media/files/electricity/nem/planning_and_forecasting/inputs-assumptions-methodologies/2019/2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx?rev=b6fb3a0d7bd849eea781e99f8c89544a&sc_lang=en";
                      filename = "2019-input-and-assumptions-workbook-v1-3-dec-19.xlsx",
                      subdir = "")
    ]

    const ISP_FILE_LOOKUP = Dict(target.key => target for target in ISP_FILE_TARGETS)

    isp_file_targets() = copy(ISP_FILE_TARGETS)

    function download_all_isp_files(; options::FileDownloadOptions = default_file_download_options())
        return download_isp_files(ISP_FILE_TARGETS; options = options)
    end

    download_isp24_inputs_workbook(; options::FileDownloadOptions = default_file_download_options()) =
        download_single_target(:isp24_inputs; options = options)

    download_isp24_model_archive(; options::FileDownloadOptions = default_file_download_options()) =
        download_single_target(:isp24_model; options = options)

    download_isp24_outlook(; options::FileDownloadOptions = default_file_download_options()) =
        download_single_target(:isp24_outlook; options = options)

    # download_isp24_outlook(; options::FileDownloadOptions = default_file_download_options()) =
    #     download_isp24_generation_storage_archive(; options = options)

    download_isp19_inputs_workbook(; options::FileDownloadOptions = default_file_download_options()) =
        download_single_target(:isp19_inputs_v13; options = options)

    function download_isp_files(targets::AbstractVector{ISPFileTarget};
                                options::FileDownloadOptions = default_file_download_options(),
                                overwrite_policy::Function = interactive_overwrite_prompt)
        isempty(targets) && return String[]
        saved_paths = String[]
        skip_existing = options.skip_existing
        skip_prompted = false
        nonreplace_count = 0

        for (idx, target) in enumerate(targets)
            dest_dir = target_outdir(target, options.outdir)
            mkpath(dest_dir)
            filename = destination_filename(target)
            dest = joinpath(dest_dir, filename)

            println("[$idx/$(length(targets))] Downloading")
            println("  Title: ", target.title)
            println("  URL  : ", target.url)
            println("  File : ", dest, "\n")

            if isfile(dest)
                if skip_existing
                    println("  ↺ Skipping file download (global no-replace enabled).\n")
                    push!(saved_paths, dest)
                    continue
                elseif options.confirm_overwrite && !overwrite_policy(dest)
                    nonreplace_count += 1
                    if nonreplace_count > 2 && !skip_prompted
                        skip_existing = prompt_skip_existing()
                        skip_prompted = true
                        if skip_existing
                            println("  ↺ Global no-replace enabled. Existing files will be kept.\n")
                            push!(saved_paths, dest)
                            continue
                        end
                    end
                    println("  ↺ Keeping existing file.\n")
                    push!(saved_paths, dest)
                    continue
                end
            end

            try
                download_file(target.url, dest; headers = options.file_headers)
                println("  ✅ Done\n")
            catch err
                @warn "  ❌ Failed to download $(target.url)" exception = err
            end

            options.throttle_seconds === nothing || sleep(options.throttle_seconds)
            push!(saved_paths, dest)
        end

        return saved_paths
    end

    function download_single_target(key::Symbol;
                                    options::FileDownloadOptions = default_file_download_options())
        target = get_target(key)
        paths = download_isp_files([target]; options = options)
        return isempty(paths) ? "" : paths[1]
    end

    function get_target(key::Symbol)
        return get(ISP_FILE_LOOKUP, key) do
            error("Unknown ISP file target $(key).")
        end
    end

    function target_outdir(target::ISPFileTarget, base::AbstractString)
        subdir = something(target.subdir, "")
        return isempty(subdir) ? base : joinpath(base, subdir)
    end

    function destination_filename(target::ISPFileTarget)
        return something(target.filename, filename_from_url(target.url))
    end

    function filename_from_url(url::AbstractString)
        stripped = split(url, '?'; limit = 2)[1]
        parts = split(stripped, '/')
        return parts[end]
    end

end
