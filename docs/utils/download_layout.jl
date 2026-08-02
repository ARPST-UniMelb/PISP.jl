Base.@kwdef struct DownloadLayout
    edition::String
    download_root::String
    outlook_directories::Vector{String}
    source_archives::Vector{String}
end

const EXCLUDED_TOP_LEVEL_DIRECTORIES = Set([
    "Auxiliary",
    "Traces",
    "manifests",
    "zip",
])

is_archive_junk(name::AbstractString) =
    name == "__MACOSX" || name == ".DS_Store" || startswith(name, "._") || startswith(name, ".")

is_model_directory(name::AbstractString) = endswith(lowercase(strip(name)), "isp model")

function outlook_directories(download_root::AbstractString)
    isdir(download_root) || error("download root does not exist: $download_root")

    directories = String[]
    for name in readdir(download_root)
        is_archive_junk(name) && continue
        name in EXCLUDED_TOP_LEVEL_DIRECTORIES && continue
        is_model_directory(name) && continue
        isdir(joinpath(download_root, name)) || continue
        push!(directories, name)
    end

    return sort!(directories)
end

function source_archives(download_root::AbstractString)
    archive_root = joinpath(download_root, "zip")
    isdir(archive_root) || error("source archive directory does not exist: $archive_root")

    archives = String[]
    for name in readdir(archive_root)
        is_archive_junk(name) && continue
        path = joinpath(archive_root, name)
        isfile(path) || continue
        endswith(lowercase(name), ".zip") || continue
        push!(archives, name)
    end

    return sort!(archives)
end

function inspect_download_layout(edition::AbstractString, download_root::AbstractString)
    return DownloadLayout(
        edition = String(edition),
        download_root = normpath(download_root),
        outlook_directories = outlook_directories(download_root),
        source_archives = source_archives(download_root),
    )
end
