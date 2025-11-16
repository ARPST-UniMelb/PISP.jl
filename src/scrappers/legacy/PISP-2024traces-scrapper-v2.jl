# using HTTP
# using Gumbo
# using Cascadia
# using Downloads
# using Printf
# using Gumbo: HTMLText

# const PAGE_URL = "https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp"
# const OUTDIR   = "scrapped/ISP_2024_traces" 

# # Filter patterns: only keep links for demand / solar / wind traces
# function is_trace_link(href::AbstractString)
#     h = lowercase(href)
#     return occursin("isp_demand_traces_", h) ||
#            occursin("isp_solar_traces_", h)  ||
#            occursin("isp_wind_traces_", h)
# end

# println("Fetching page:\n  $PAGE_URL")
# resp = HTTP.get(PAGE_URL; headers = ["User-Agent" => "JuliaISPDownloader/1.0"])
# html = String(resp.body)

# parsed = parsehtml(html)

# selector = Selector("div.field-link a")
# anchors = collect(eachmatch(selector, parsed.root))

# struct TraceLink
#     text::String
#     href::String
# end

# trace_links = TraceLink[]


# function inner_html(node)
#     io = IOBuffer()
#     for child in node.children
#         print(io, child)
#     end
#     return String(take!(io))
# end

# for a in anchors
#     attrs = a.attributes
#     href  = get(attrs, "href", nothing)
#     href === nothing && continue

#     # Normalise to absolute URL
#     if !startswith(href, "http")
#         href = "https://aemo.com.au" * href
#     end

#     # Filter by href content
#     is_trace_link(href) || continue

#     text = strip(inner_html(a))
#     push!(trace_links, TraceLink(text, href))
# end

# println("Kept $(length(trace_links)) ISP trace links after filtering.")

# if isempty(trace_links)
#     println("No trace links found — check selector/filter or page structure.")
#     exit(0)
# end
# """
#     sanitize_filename(s::AbstractString) -> String

# Replace spaces with underscores and strip characters that are problematic
# in filenames (/, , :, *, ?, ", <, >, |).
# """
# function sanitize_filename(s::AbstractString)
#     s = replace(s, ' ' => '_')
#     s = replace(s, r"[\/\\:\*\?\"<>\|]" => "_")
#     strip(s)
# end

# """
#     download_AEMO(url, dest)

# Download from AEMO, sending browser-like headers to avoid 403 responses.
# Writes the body to `dest`. Throws an error if all attempts fail.
# """
# function download_AEMO(url::AbstractString, dest::AbstractString)
#     # You can tweak headers if needed
#     headers = [
#         "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
#         "Accept"          => "*/*",
#         "Referer"         => "https://aemo.com.au/",
#         "Accept-Language" => "en-AU,en;q=0.9",
#         "Connection"      => "keep-alive",
#     ]

#     # Try with HTTP.jl first
#     resp = HTTP.get(url; headers=headers)

#     if resp.status == 200
#         open(dest, "w") do io
#             write(io, resp.body)
#         end
#         return
#     end

#     # If HTTP.jl fails with something like 403/500, log and optionally fall back
#     @warn "HTTP.get failed with status $(resp.status); trying Downloads.download" url

#     # Fallback (often still 403, but cheap to try)
#     Downloads.download(url, dest)
# end

# # === MAIN LOOP ================================================================

# function ask_yes_no(prompt::AbstractString; default::Bool = false)
#     suffix = default ? " [Y/n]: " : " [y/N]: "
#     while true
#         print(prompt, suffix)
#         flush(stdout)
#         resp = try
#             readline()
#         catch err
#             err isa EOFError && return default
#             rethrow(err)
#         end
#         resp = lowercase(strip(resp))
#         if isempty(resp)
#             return default
#         elseif resp in ("y", "yes")
#             return true
#         elseif resp in ("n", "no")
#             return false
#         else
#             println("    Please answer 'y' or 'n'.")
#         end
#     end
# end

# function confirm_overwrite(path::AbstractString)
#     println("⚠️  File already exists: $(path) \n")
#     return ask_yes_no("Replace it?"; default = false)
# end

# function confirm_skip_existing()
#     println("⚠️  Multiple files have been kept so far.")
#     return ask_yes_no("Skip replacing any existing files for the rest of this run?"; default = false)
# end

# # Clear any stray newline left in the REPL buffer before the first prompt.
# function drain_pending_stdin()
#     isatty(stdin) || return
#     try
#         while bytesavailable(stdin) > 0
#             read(stdin, UInt8)
#         end
#     catch
#         # best effort only — ignore terminals that do not support bytesavailable
#     end
# end


# # drain_pending_stdin()

# for (i, tl) in enumerate(trace_links)
#     # Safely handle possible `nothing` in text
#     raw_text = isnothing(tl.text) ? "" : String(tl.text)

#     # Prefer the anchor text (e.g. "ISP Wind Traces r2019.zip") for the filename.
#     # If empty, fall back to the last part of the URL.
#     base =
#         !isempty(raw_text) ? raw_text :
#         split(String(tl.href), "/")[end]

#     base = sanitize_filename(base)

#     # Ensure .zip extension (defensive, even though text usually has it)
#     if !endswith(lowercase(base), ".zip")
#         base *= ".zip"
#     end

#     filename = @sprintf("%02d_%s", i, base)
#     dest = joinpath(OUTDIR, filename)

#     println("[$i/$(length(trace_links))] Downloading:")
#     println("  Text : ", tl.text)
#     println("  URL  : ", tl.href)
#     println("  File : ", dest, "\n")

#     if isfile(dest)
#         if skip_existing
#             println("  ↺ Skipping (global no-replace enabled).\n")
#             push!(filenames, filename)
#             continue
#         end

#         if !confirm_overwrite(dest)
#             nonreplace_count += 1
#             if nonreplace_count > 2 && !skip_prompted
#                 skip_existing = confirm_skip_existing()
#                 skip_prompted = true
#                 if skip_existing
#                     println("  ↺ Global no-replace enabled. Existing files will be kept.\n")
#                     push!(filenames, filename)
#                     continue
#                 end
#             end

#             println("  ↺ Skipping (keeping existing file).\n")
#             push!(filenames, filename)
#             continue
#         end
#     end

#     try
#         download_AEMO(String(tl.href), dest)
#         println("  ✅ Done\n")
#     catch e
#         @warn "  ❌ Failed to download $(tl.href)" exception = e
#     end

#     push!(filenames, filename)

#     # Optional: small delay to be gentle with the server
#     # sleep(0.5)
# end

# function download_isp24_traces()
#     filenames = String[];
#     skip_existing = false;
#     skip_prompted = false;
#     nonreplace_count = 0;

#     for (i, tl) in enumerate(trace_links)
#         # Safely handle possible `nothing` in text
#         raw_text = isnothing(tl.text) ? "" : String(tl.text)

#         # Prefer the anchor text (e.g. "ISP Wind Traces r2019.zip") for the filename.
#         # If empty, fall back to the last part of the URL.
#         base =
#             !isempty(raw_text) ? raw_text :
#             split(String(tl.href), "/")[end]

#         base = sanitize_filename(base)

#         # Ensure .zip extension (defensive, even though text usually has it)
#         if !endswith(lowercase(base), ".zip")
#             base *= ".zip"
#         end

#         filename = @sprintf("%02d_%s", i, base)
#         dest = joinpath(OUTDIR, filename)

#         println("[$i/$(length(trace_links))] Downloading:")
#         println("  Text : ", tl.text)
#         println("  URL  : ", tl.href)
#         println("  File : ", dest, "\n")

#         if isfile(dest)
#             if skip_existing
#                 println("  ↺ Skipping (global no-replace enabled).\n")
#                 push!(filenames, filename)
#                 continue
#             end

#             if !confirm_overwrite(dest)
#                 nonreplace_count += 1
#                 if nonreplace_count > 2 && !skip_prompted
#                     skip_existing = confirm_skip_existing()
#                     skip_prompted = true
#                     if skip_existing
#                         println("  ↺ Global no-replace enabled. Existing files will be kept.\n")
#                         push!(filenames, filename)
#                         continue
#                     end
#                 end

#                 println("  ↺ Skipping (keeping existing file).\n")
#                 push!(filenames, filename)
#                 continue
#             end
#         end

#         try
#             download_AEMO(String(tl.href), dest)
#             println("  ✅ Done\n")
#         catch e
#             @warn "  ❌ Failed to download $(tl.href)" exception = e
#         end

#         push!(filenames, filename)

#         # Optional: small delay to be gentle with the server
#         # sleep(0.5)
#     end
# end

# download_isp24_traces()