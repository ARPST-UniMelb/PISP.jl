module ISPTraceDownloader

    using HTTP
    using Gumbo
    using Cascadia
    using Printf
    using PISP.PISPScrapperUtils: DEFAULT_FILE_HEADERS,
        FileDownloadOptions,
        download_file,
        interactive_overwrite_prompt,
        prompt_skip_existing

    export TraceLink,
        FileDownloadOptions,
        DownloadOptions,
        fetch_trace_links,
        download_traces,
        download_isp24_traces

    const DEFAULT_PAGE_URL = "https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp"
    const DEFAULT_OUTDIR   = "scrapped/ISP_2024_traces"
    const TRACE_SELECTOR   = Selector("div.field-link a")
    const DEFAULT_PAGE_HEADERS = ["User-Agent" => "JuliaISPDownloader/1.0"]

    struct TraceLink
        text::String
        href::String
    end

    function default_trace_download_options(; outdir::AbstractString = DEFAULT_OUTDIR,
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

    const DownloadOptions = FileDownloadOptions

    function fetch_trace_links(; page_url::AbstractString = DEFAULT_PAGE_URL,
                            selector::Selector = TRACE_SELECTOR,
                            filter_fn = is_trace_link)
        html   = fetch_html(page_url)
        parsed = parsehtml(html)
        anchors = collect(eachmatch(selector, parsed.root))
        links = TraceLink[]
        for a in anchors
            href = get(a.attributes, "href", nothing)
            href === nothing && continue
            absolute = normalize_href(String(href))
            filter_fn(absolute) || continue
            text = strip(inner_html(a))
            push!(links, TraceLink(text, absolute))
        end
        return links
    end

    function download_traces(trace_links::Vector{TraceLink};
                            options::FileDownloadOptions = default_trace_download_options(),
                            overwrite_policy::Function = interactive_overwrite_prompt)
        isempty(trace_links) && return String[]
        mkpath(options.outdir)
        filenames = String[]
        skip_existing = options.skip_existing
        skip_prompted = false
        nonreplace_count = 0

        for (i, tl) in enumerate(trace_links)
            filename = filename_for(tl, i)
            dest = joinpath(options.outdir, filename)

            println("[$i/$(length(trace_links))] Downloading")
            println("  Filename    : ", tl.text)
            println("  Source URL  : ", tl.href)
            println("  Destination : ", dest, "\n")

            if isfile(dest)
                if skip_existing
                    println("  ↺ Skipping (required file is already downloaded).\n")
                    push!(filenames, filename)
                    continue
                elseif options.confirm_overwrite && !overwrite_policy(dest)
                    nonreplace_count += 1
                    if nonreplace_count > 2 && !skip_prompted
                        skip_existing = prompt_skip_existing()
                        skip_prompted = true
                        if skip_existing
                            println("  ↺ Global no-replace enabled. Existing files will be kept.\n")
                            push!(filenames, filename)
                            continue
                        end
                    end
                    println("  ↺ Keeping existing file.\n")
                    push!(filenames, filename)
                    continue
                end
            end

            try
                download_file(tl.href, dest; headers = options.file_headers)
                println("  ✅ Done\n")
            catch err
                @warn "  ❌ Failed to download $(tl.href)" exception = err
            end

            options.throttle_seconds === nothing || sleep(options.throttle_seconds)
            push!(filenames, filename)
        end

        return filenames
    end

    function download_isp24_traces(; page_url::AbstractString = DEFAULT_PAGE_URL,
                                options::FileDownloadOptions = default_trace_download_options())
        links = fetch_trace_links(page_url = page_url)
        println("Kept $(length(links)) ISP trace links after filtering.")
        isempty(links) && return String[]
        return download_traces(links; options = options)
    end

    # --- helpers -----------------------------------------------------------------

    function fetch_html(url::AbstractString)
        resp = HTTP.get(url; headers = DEFAULT_PAGE_HEADERS)
        resp.status == 200 || error("Failed to fetch $(url); status=$(resp.status)")
        return String(resp.body)
    end

    function normalize_href(href::AbstractString)
        return startswith(href, "http") ? href : "https://aemo.com.au" * href
    end

    function inner_html(node)
        io = IOBuffer()
        for child in node.children
            print(io, child)
        end
        return String(take!(io))
    end

    function is_trace_link(href::AbstractString)
        h = lowercase(href)
        return occursin("isp_demand_traces_", h) ||
            occursin("isp_solar_traces_", h)  ||
            occursin("isp_wind_traces_", h)
    end

    function sanitize_filename(s::AbstractString)
        cleaned = replace(s, ' ' => '_')
        cleaned = replace(cleaned, r"[\/\\:\*\?\"<>\|]" => "_")
        return strip(cleaned)
    end

    function filename_for(tl::TraceLink, idx::Integer)
        raw = isempty(strip(tl.text)) ? split(tl.href, "/")[end] : tl.text
        base = sanitize_filename(raw)
        endswith(lowercase(base), ".zip") || (base *= ".zip")
        return @sprintf("%02d_%s", idx, base)
    end

end
