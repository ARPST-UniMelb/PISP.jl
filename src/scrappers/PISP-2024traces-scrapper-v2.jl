using HTTP
using Gumbo
using Cascadia
using Downloads
using Printf

const PAGE_URL = "https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp"
const OUTDIR   = "scrapped/ISP_2024_traces" 

# Filter patterns: only keep links for demand / solar / wind traces
function is_trace_link(href::AbstractString)
    h = lowercase(href)
    return occursin("isp_demand_traces_", h) ||
           occursin("isp_solar_traces_", h)  ||
           occursin("isp_wind_traces_", h)
end

println("Fetching page:\n  $PAGE_URL")
resp = HTTP.get(PAGE_URL; headers = ["User-Agent" => "JuliaISPDownloader/1.0"])
html = String(resp.body)
# println("Parsing HTML…")
parsed = parsehtml(html)
# All <a> inside <div class="field-link">
selector = Selector("div.field-link a")
anchors = collect(eachmatch(selector, parsed.root))

# println("Found $(length(anchors)) <a> elements under div.field-link")


struct TraceLink
    text::String
    href::String
end

trace_links = TraceLink[]

using Gumbo: HTMLText

function inner_html(node)
    io = IOBuffer()
    for child in node.children
        print(io, child)
    end
    return String(take!(io))
end

for a in anchors
    attrs = a.attributes
    href  = get(attrs, "href", nothing)
    href === nothing && continue

    # Normalise to absolute URL
    if !startswith(href, "http")
        href = "https://aemo.com.au" * href
    end

    # Filter by href content
    is_trace_link(href) || continue

    text = strip(inner_html(a))
    push!(trace_links, TraceLink(text, href))
end

println("Kept $(length(trace_links)) ISP trace links after filtering.")

if isempty(trace_links)
    println("No trace links found — check selector/filter or page structure.")
    exit(0)
end
"""
    sanitize_filename(s::AbstractString) -> String

Replace spaces with underscores and strip characters that are problematic
in filenames (/, , :, *, ?, ", <, >, |).
"""
function sanitize_filename(s::AbstractString)
    s = replace(s, ' ' => '_')
    s = replace(s, r"[\/\\:\*\?\"<>\|]" => "_")
    strip(s)
end

"""
    download_AEMO(url, dest)

Download from AEMO, sending browser-like headers to avoid 403 responses.
Writes the body to `dest`. Throws an error if all attempts fail.
"""
function download_AEMO(url::AbstractString, dest::AbstractString)
    # You can tweak headers if needed
    headers = [
        "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Accept"          => "*/*",
        "Referer"         => "https://aemo.com.au/",
        "Accept-Language" => "en-AU,en;q=0.9",
        "Connection"      => "keep-alive",
    ]

    # Try with HTTP.jl first
    resp = HTTP.get(url; headers=headers)

    if resp.status == 200
        open(dest, "w") do io
            write(io, resp.body)
        end
        return
    end

    # If HTTP.jl fails with something like 403/500, log and optionally fall back
    @warn "HTTP.get failed with status $(resp.status); trying Downloads.download" url

    # Fallback (often still 403, but cheap to try)
    Downloads.download(url, dest)
end

# === MAIN LOOP ================================================================

# Assumes `trace_links` is an iterable of objects with fields `.href` and `.text`
# e.g., from a HTML parser.

for (i, tl) in enumerate(trace_links)
    # Safely handle possible `nothing` in text
    raw_text = isnothing(tl.text) ? "" : String(tl.text)

    # Prefer the anchor text (e.g. "ISP Wind Traces r2019.zip") for the filename.
    # If empty, fall back to the last part of the URL.
    base =
        !isempty(raw_text) ? raw_text :
        split(String(tl.href), "/")[end]

    base = sanitize_filename(base)

    # Ensure .zip extension (defensive, even though text usually has it)
    if !endswith(lowercase(base), ".zip")
        base *= ".zip"
    end

    filename = @sprintf("%02d_%s", i, base)
    dest = joinpath(OUTDIR, filename)

    println("[$i/$(length(trace_links))] Downloading:")
    println("  Text : ", tl.text)
    println("  URL  : ", tl.href)
    println("  File : ", dest)

    try
        download_AEMO(String(tl.href), dest)
        println("  ✅ Done\n")
    catch e
        @warn "  ❌ Failed to download $(tl.href)" exception = e
    end

    # Optional: small delay to be gentle with the server
    # sleep(0.5)
end
