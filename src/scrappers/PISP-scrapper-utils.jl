module PISPScrapperUtils

    using HTTP
    using Downloads

    export DEFAULT_FILE_HEADERS,
        FileDownloadOptions,
        download_file,
        interactive_overwrite_prompt,
        prompt_skip_existing,
        ask_yes_no

    const DEFAULT_FILE_HEADERS = Pair{String,String}[
        "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept"          => "*/*",
        "Referer"         => "https://aemo.com.au/",
        "Accept-Language" => "en-AU,en;q=0.9",
        "Connection"      => "keep-alive",
    ]

    struct FileDownloadOptions
        outdir::String
        confirm_overwrite::Bool
        skip_existing::Bool
        throttle_seconds::Union{Nothing,Real}
        file_headers::Vector{Pair{String,String}}
    end

    function FileDownloadOptions(; outdir::AbstractString,
                                confirm_overwrite::Bool = true,
                                skip_existing::Bool = false,
                                throttle_seconds::Union{Nothing,Real} = nothing,
                                file_headers::Vector{Pair{String,String}} = DEFAULT_FILE_HEADERS)
        return FileDownloadOptions(String(outdir), confirm_overwrite, skip_existing,
                                    throttle_seconds, file_headers)
    end

    function download_file(url::AbstractString, dest::AbstractString;
                            headers::Vector{Pair{String,String}} = DEFAULT_FILE_HEADERS)
        resp = HTTP.get(url; headers = headers)
        if resp.status == 200
            open(dest, "w") do io
                write(io, resp.body)
            end
            return dest
        end
        @warn "HTTP.get failed with status $(resp.status); trying Downloads.download" url
        Downloads.download(url, dest)
        return dest
    end

    function interactive_overwrite_prompt(path::AbstractString)
        println("⚠️  File already exists: $(path)")
        return ask_yes_no("Replace it?"; default = false)
    end

    function prompt_skip_existing()
        println("⚠️  Multiple files have been kept so far.")
        return ask_yes_no("Skip replacing any existing files for the rest of this run?"; default = false)
    end

    function ask_yes_no(prompt::AbstractString; default::Bool = false)
        suffix = default ? " [Y/n]: " : " [y/N]: "
        while true
            print(prompt, suffix)
            flush(stdout)
            resp = try
                readline()
            catch err
                err isa EOFError && return default
                rethrow(err)
            end
            resp = lowercase(strip(resp))
            isempty(resp) && return default
            resp in ("y", "yes") && return true
            resp in ("n", "no") && return false
            println("    Please answer 'y' or 'n'.")
        end
    end

end
