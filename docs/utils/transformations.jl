using CSV
using DataFrames
using Dates
using PrettyTables
using Statistics

const TABLE_ROOT = normpath(joinpath(@__DIR__, "..", "src", "tables"))
const FIGURE_ROOT = normpath(joinpath(@__DIR__, "..", "src", "figures"))

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

function figure_dir(script_stem; producer = "julia", root = FIGURE_ROOT)
    path = joinpath(root, producer, script_stem)
    mkpath(path)
    return path
end

function figure_path(script_stem, figure_name; producer = "julia", root = FIGURE_ROOT)
    filename = endswith(figure_name, ".png") ? figure_name : "$(figure_name).png"
    return joinpath(figure_dir(script_stem; producer = producer, root = root), filename)
end

# Copies a canonical figure next to the Documenter-generated Markdown page, but only when running through docs/render_literate.jl (which sets ParseISP_LITERATE_OUTPUT_DIR).
# When a Literate source is run standalone, this env var is unset and there is no generated Markdown for an embedded copy to sit next to, so this is a no-op — nothing is ever written beside the Literate source itself.
function embed_figure(canonical_path, figure_name)
    output_dir = get(ENV, "ParseISP_LITERATE_OUTPUT_DIR", nothing)
    output_dir === nothing && return nothing
    embedded_path = joinpath(normpath(output_dir), figure_name)
    cp(canonical_path, embedded_path; force = true)
    return embedded_path
end

"""Trim trailing all-missing rows and columns from an XLSX sheet matrix."""
function trim_sheet(matrix)
    nrows, ncols = size(matrix)
    last_row = 0
    for row in 1:nrows
        any(value -> value !== missing, view(matrix, row, :)) && (last_row = row)
    end
    last_col = 0
    for column in 1:ncols
        any(value -> value !== missing, view(matrix, :, column)) && (last_col = column)
    end
    (last_row == 0 || last_col == 0) && return Matrix{Any}(undef, 0, 0)
    return matrix[1:last_row, 1:last_col]
end

function add_datetime!(frame::DataFrame)
    frame.datetime = Date.(frame.Year, frame.Month, frame.Day)
    return frame
end

row_mean(frame::DataFrame, columns) =
    [mean(row[column] for column in columns) for row in eachrow(frame)]

"""Return a trailing mean, leaving the first `window - 1` values as `missing`."""
function rolling_mean(values, window)
    result = Vector{Union{Missing, Float64}}(missing, length(values))
    for index in window:length(values)
        result[index] = mean(values[(index - window + 1):index])
    end
    return result
end
