# Renders a Tables.jl-compatible table as a Markdown pipe table.
# Literate captures this MIME instead of DataFrames' richer HTML representation.
struct MarkdownTable
    text::String
end

Base.show(io::IO, ::MIME"text/markdown", table::MarkdownTable) =
    print(io, table.text)
Base.show(io::IO, ::MIME"text/plain", table::MarkdownTable) =
    print(io, table.text)

struct RawMarkdown
    markdown::String
end

Base.show(io::IO, ::MIME"text/markdown", value::RawMarkdown) =
    print(io, value.markdown)

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

function markdown_cell(value; nothing_text = "")
    text = value === nothing ? nothing_text : string(value)
    return replace(text, "\n" => " ", "\r" => "", "|" => "\\|")
end

function markdown_items(values; nothing_text = "")
    isempty(values) && return "—"
    return join(
        ("`$(markdown_cell(value; nothing_text = nothing_text))`" for value in values),
        ", ",
    )
end

function markdown_table(
    headers::AbstractVector,
    rows;
    alignment = fill(:left, length(headers)),
    nothing_text = "",
)
    length(alignment) == length(headers) || error("Table alignment does not match the columns")
    separators = Dict(
        :left => ":---",
        :right => "---:",
        :centre => ":---:",
        :l => ":---",
        :r => "---:",
        :c => ":---:",
    )
    all(item -> haskey(separators, item), alignment) ||
        error("Unsupported Markdown alignment")
    cell(value) = markdown_cell(value; nothing_text = nothing_text)

    lines = String[]
    push!(lines, "| " * join(cell.(headers), " | ") * " |")
    push!(lines, "| " * join((separators[item] for item in alignment), " | ") * " |")
    for row in rows
        length(row) == length(headers) || error("Table row does not match the headers")
        push!(lines, "| " * join(cell.(row), " | ") * " |")
    end
    return MarkdownTable(join(lines, "\n"))
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
