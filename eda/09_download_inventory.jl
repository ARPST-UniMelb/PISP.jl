#!/usr/bin/env julia

using CSV
using DataFrames
using Printf

const SCRIPT_STEM = "09_download_inventory"
const DOWNLOAD_ROOT = joinpath("data", "2024", "pisp-downloads")
const TABLE_ROOT = joinpath(@__DIR__, "tables")
const MAX_TREE_DEPTH = 3
const MAX_TREE_CHILDREN_PER_DIR = 3

function table_dir(script_stem; producer = "julia", root = TABLE_ROOT)
    path = joinpath(root, producer, script_stem)
    mkpath(path)
    return path
end

function table_path(script_stem, table_name; producer = "julia", root = TABLE_ROOT)
    filename = endswith(table_name, ".csv") ? table_name : "$(table_name).csv"
    return joinpath(table_dir(script_stem; producer = producer, root = root), filename)
end

function write_table(frame::DataFrame, script_stem, table_name; producer = "julia", root = TABLE_ROOT)
    path = table_path(script_stem, table_name; producer = producer, root = root)
    CSV.write(path, frame; missingstring = "")
    println("Saved table: ", path)
    return path
end

to_forward_slashes(path) = replace(path, "\\" => "/")

function lowercase_extension(name)
    ext = lowercase(splitext(name)[2])
    return isempty(ext) ? "" : ext[2:end]
end

# Single recursive walk of the download tree that produces both a flat file
# inventory (every depth) and a depth-limited directory-tree listing, so the
# tree structure does not need a second filesystem walk.
function walk_download_root(root; max_tree_depth = MAX_TREE_DEPTH, max_children_per_dir = MAX_TREE_CHILDREN_PER_DIR)
    files = NamedTuple[]
    tree_rows = NamedTuple[]

    for (dirpath, dirnames, filenames) in walkdir(root)
        filter!(name -> !startswith(name, "."), dirnames)
        filter!(name -> !startswith(name, "."), filenames)
        rel_dir = dirpath == root ? "" : to_forward_slashes(relpath(dirpath, root))
        dir_depth = isempty(rel_dir) ? 0 : length(splitpath(rel_dir))
        child_depth = dir_depth + 1

        if child_depth <= max_tree_depth
            for name in sort(dirnames)
                push!(
                    tree_rows,
                    (depth = child_depth, parent_relative_path = rel_dir, name = name, kind = "directory"),
                )
            end
            ## Depth alone does not bound how many files sit in one directory
            ## (e.g. a single Traces/<tech>_<year>/ folder holds hundreds of
            ## per-location trace CSVs); cap the listed files per directory so
            ## the rendered tree stays readable, and record how many were
            ## omitted rather than silently truncating.
            sorted_filenames = sort(filenames)
            shown_filenames = first(sorted_filenames, min(length(sorted_filenames), max_children_per_dir))
            for name in shown_filenames
                push!(
                    tree_rows,
                    (depth = child_depth, parent_relative_path = rel_dir, name = name, kind = "file"),
                )
            end
            omitted = length(sorted_filenames) - length(shown_filenames)
            if omitted > 0
                push!(
                    tree_rows,
                    (
                        depth = child_depth,
                        parent_relative_path = rel_dir,
                        name = "... ($(omitted) more file$(omitted == 1 ? "" : "s") omitted)",
                        kind = "note",
                    ),
                )
            end
        end

        for filename in sort(filenames)
            full_path = joinpath(dirpath, filename)
            rel_path = isempty(rel_dir) ? filename : rel_dir * "/" * filename
            push!(
                files,
                (
                    relative_path = rel_path,
                    size_bytes = filesize(full_path),
                    extension = lowercase_extension(filename),
                    depth = length(splitpath(rel_path)),
                ),
            )
        end
    end

    return files, tree_rows
end

function summarize_extensions(files)
    counts = Dict{String, Int}()
    bytes = Dict{String, Int}()
    for f in files
        counts[f.extension] = get(counts, f.extension, 0) + 1
        bytes[f.extension] = get(bytes, f.extension, 0) + f.size_bytes
    end
    exts = sort(collect(keys(counts)))
    rows = [(extension = ext, file_count = counts[ext], total_bytes = bytes[ext]) for ext in exts]
    return DataFrame(rows)
end

# One row per immediate child of the download root, whether a file or a
# directory. Directory rows aggregate recursively over `files`; a plain
# file's own extension is not repeated in `extensions` since that column
# describes what is found *under* an entry, not the entry itself.
function summarize_top_level(root, files)
    rows = NamedTuple[]
    for name in sort(filter(n -> !startswith(n, "."), readdir(root)))
        full_path = joinpath(root, name)
        if isdir(full_path)
            prefix = name * "/"
            matching = filter(f -> startswith(f.relative_path, prefix), files)
            total_bytes = isempty(matching) ? 0 : sum(f.size_bytes for f in matching)
            exts = sort(unique(f.extension for f in matching if !isempty(f.extension)))
            push!(
                rows,
                (
                    name = name,
                    kind = "directory",
                    file_count = length(matching),
                    total_bytes = total_bytes,
                    extensions = join(exts, ","),
                ),
            )
        else
            push!(
                rows,
                (
                    name = name,
                    kind = "file",
                    file_count = 1,
                    total_bytes = filesize(full_path),
                    extensions = "",
                ),
            )
        end
    end
    return DataFrame(rows)
end

function print_summary(root, files, top_level)
    total_files = length(files)
    total_bytes = isempty(files) ? 0 : sum(f.size_bytes for f in files)
    println("=== DOWNLOAD INVENTORY SUMMARY ===")
    println("Root: ", root)
    println("Total files: ", total_files)
    println(@sprintf("Total size: %.2f MB (%d bytes)", total_bytes / (1024^2), total_bytes))
    println("Top-level entries: ", nrow(top_level))
    for row in eachrow(top_level)
        println(
            @sprintf(
                "  %-45s %-10s %6d files  %10.2f MB",
                row.name, row.kind, row.file_count, row.total_bytes / (1024^2)
            )
        )
    end
end

function write_snapshot_metadata(root, files)
    total_bytes = isempty(files) ? 0 : sum(file.size_bytes for file in files)
    metadata = DataFrame([
        (
            download_root = root,
            total_files = length(files),
            total_bytes = total_bytes,
            tree_depth = MAX_TREE_DEPTH,
            max_files_per_directory = MAX_TREE_CHILDREN_PER_DIR,
        ),
    ])
    write_table(metadata, SCRIPT_STEM, "snapshot_metadata")
end

function main()
    isdir(DOWNLOAD_ROOT) || error(
        "expected local download tree at \"$DOWNLOAD_ROOT\"; " *
        "run the PISP downloader to populate " *
        "data/2024/pisp-downloads/ before regenerating eda/$(SCRIPT_STEM).jl evidence",
    )

    files, tree_rows = walk_download_root(DOWNLOAD_ROOT)
    top_level = summarize_top_level(DOWNLOAD_ROOT, files)
    extensions = summarize_extensions(files)

    write_table(DataFrame(files), SCRIPT_STEM, "file_inventory")
    write_table(top_level, SCRIPT_STEM, "top_level_summary")
    write_table(extensions, SCRIPT_STEM, "extension_summary")
    write_table(DataFrame(tree_rows), SCRIPT_STEM, "directory_tree")
    write_snapshot_metadata(DOWNLOAD_ROOT, files)

    print_summary(DOWNLOAD_ROOT, files, top_level)

    println("\nDone.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
