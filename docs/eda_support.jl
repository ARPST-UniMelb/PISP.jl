module EdaSupport

using CSV
using DataFrames
using Pkg
using PrettyTables

export TABLE_ROOT, FIGURE_ROOT, table_dir, table_path, write_table, figure_dir, figure_path, embed_figure, MarkdownTable, markdown_table

const TABLE_ROOT = joinpath(normpath(joinpath(@__DIR__, "..")), "eda", "tables")
const FIGURE_ROOT = joinpath(normpath(joinpath(@__DIR__, "..")), "eda", "figures")

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

# Copies a canonical figure next to the Documenter-generated Markdown page, but only when running through docs/render_literate.jl (which sets PISP_LITERATE_OUTPUT_DIR).
# When a Literate source is run standalone, this env var is unset and there is no generated Markdown for an embedded copy to sit next to, so this is a no-op — nothing is ever written beside the Literate source itself.
function embed_figure(canonical_path, figure_name)
    output_dir = get(ENV, "PISP_LITERATE_OUTPUT_DIR", nothing)
    output_dir === nothing && return nothing
    embedded_path = joinpath(normpath(output_dir), figure_name)
    cp(canonical_path, embedded_path; force = true)
    return embedded_path
end

# Renders a Tables.jl-compatible table (e.g. a DataFrame) as a Markdown pipe table via PrettyTables, exposed only as a `text/markdown` MIME show method.
# Literate captures this MIME over the richer `text/html` DataFrames representation, so the generated docs page gets a plain pipe table instead of an embedded HTML table.
# Column names are left as-is by default (this is EDA evidence for the user reading the source, not a polished report for an external reader), but callers may still pass any PrettyTables keyword (column_labels, formatters, alignment, ...) when a page needs one.
struct MarkdownTable
    text::String
end

Base.show(io::IO, ::MIME"text/markdown", table::MarkdownTable) =
    print(io, table.text)

# A literal, unescaped `$` in generated Markdown reads to Documenter as the start of inline Julia interpolation, which can fail the build (e.g. a "$/kW"-style column label or cell value).
# Escapes `$` as `\$` (respecting any existing backslash the value already carries) so currency-style labels and values pass through Documenter unchanged.
function escape_dollar_signs(text::AbstractString)
    output = IOBuffer()
    preceding_backslashes = 0
    for character in text
        if character == '\\'
            preceding_backslashes += 1
            continue
        end
        print(output, repeat("\\", preceding_backslashes))
        character == '$' && iseven(preceding_backslashes) && print(output, '\\')
        print(output, character)
        preceding_backslashes = 0
    end
    print(output, repeat("\\", preceding_backslashes))
    return String(take!(output))
end

function markdown_table(table; column_labels = names(table), kwargs...)
    escaped_labels = [escape_dollar_signs(string(label)) for label in column_labels]
    escape_formatter = (value, _row, _column) -> value isa AbstractString ? escape_dollar_signs(value) : value
    MarkdownTable(
        pretty_table(
            String,
            table;
            backend = :markdown,
            column_labels = escaped_labels,
            table_format = MarkdownTableFormat(compact_table = true),
            formatters = [escape_formatter],
            kwargs...,
        ),
    )
end

end # module EdaSupport
