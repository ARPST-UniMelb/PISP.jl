module EdaSupport

using CSV
using DataFrames
using Pkg
using PrettyTables

export TABLE_ROOT,
    FIGURE_ROOT,
    table_dir,
    table_path,
    write_table,
    figure_dir,
    figure_path,
    embed_figure,
    MarkdownTable,
    markdown_table,
    metric_value_table

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

# Renders a Tables.jl-compatible table as a Markdown pipe table.
# Literate captures this MIME instead of DataFrames' richer HTML representation.
struct MarkdownTable
    text::String
end

Base.show(io::IO, ::MIME"text/markdown", table::MarkdownTable) =
    print(io, table.text)

# A literal, unescaped `$` in generated Markdown starts Documenter interpolation.
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

function normalise_markdown_text(text::AbstractString)
    return escape_dollar_signs(replace(strip(text), r"\s*\n\s*" => " "))
end

function numeric_markdown_column(column)
    nonmissing_type = Base.nonmissingtype(eltype(column))
    nonmissing_type <: Number && return true
    nonmissing_type !== Any && return false

    observed = collect(skipmissing(column))
    return !isempty(observed) && all(value -> value isa Number, observed)
end

function infer_markdown_alignment(table::AbstractDataFrame)
    return [numeric_markdown_column(column) ? :r : :l for column in eachcol(table)]
end

function markdown_table(
    table;
    column_labels = nothing,
    alignment = nothing,
    formatters = (),
    kwargs...,
)
    render_table = table isa AbstractDataFrame ? table : DataFrame(table)
    resolved_labels = isnothing(column_labels) ? names(render_table) : column_labels
    resolved_alignment = isnothing(alignment) ? infer_markdown_alignment(render_table) : alignment
    escaped_labels = [normalise_markdown_text(string(label)) for label in resolved_labels]
    text_formatter = (value, _row, _column) ->
        value isa AbstractString ? normalise_markdown_text(value) : value
    additional_formatters = formatters isa Function ? [formatters] : collect(formatters)

    MarkdownTable(
        pretty_table(
            String,
            render_table;
            backend = :markdown,
            column_labels = escaped_labels,
            table_format = MarkdownTableFormat(compact_table = true),
            alignment = resolved_alignment,
            formatters = [text_formatter, additional_formatters...],
            kwargs...,
        ),
    )
end

function metric_value_table(metrics)
    pairs = collect(metrics)
    table = DataFrame(
        Metric = [first(pair) for pair in pairs],
        Value = [last(pair) for pair in pairs],
    )
    return markdown_table(table; alignment = [:l, :l])
end

end # module EdaSupport
