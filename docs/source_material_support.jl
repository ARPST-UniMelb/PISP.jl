module PISPDocsSourceMaterialSupport

using CSV
using DataFrames
using TOML
using XLSX

export cells_table,
    compact_path,
    coverage_table,
    coverage_document,
    coverage_owner_summary,
    directory_workbook_inventory,
    fill_down!,
    first_matching_file,
    friendly_classification,
    nonempty_rows,
    sheet_dimension_table,
    sheet_names,
    workbook_inventory,
    worksheet_presence

const RANGE_WORKBOOK_CACHE = Dict{String, XLSX.XLSXFile}()

const CLASSIFICATION_LABELS = Dict(
    "aemo_raw_source" => "AEMO raw source",
    "parsed_representation" => "Parsed representation",
    "pisp_generated_intermediate" => "PISP-generated intermediate",
    "package_convention" => "PISP package convention",
    "user_input" => "User input",
    "pisp_output" => "PISP output",
    "excluded_trace_material" => "Excluded trace material",
)

is_blank(value) = ismissing(value) || value === nothing || (value isa AbstractString && isempty(strip(value)))

function range_workbook(workbook_path::AbstractString)
    path = abspath(workbook_path)
    return get!(RANGE_WORKBOOK_CACHE, path) do
        XLSX.openxlsx(path)
    end
end

function normalise_cell(value)
    is_blank(value) && return missing
    if value isa AbstractString
        text = strip(value)
        text = replace(
            text,
            raw"\u200b" => "",
            raw"\u00ad" => "",
            raw"\uad" => "",
            '\u200b' => "",
            '\u00ad' => "",
        )
        return strip(text)
    end
    return value
end

friendly_classification(value) = get(CLASSIFICATION_LABELS, String(value), String(value))

function fill_down!(table::DataFrame, columns::AbstractVector)
    for column in columns
        previous = missing
        for row in axes(table, 1)
            value = table[row, column]
            if ismissing(value)
                ismissing(previous) || (table[row, column] = previous)
            else
                previous = value
            end
        end
    end
    return table
end

function nonempty_rows(raw::AbstractMatrix)
    indices = [row for row in axes(raw, 1) if any(value -> !is_blank(value), raw[row, :])]
    isempty(indices) && return Matrix{Any}(undef, 0, size(raw, 2))
    return Matrix{Any}(normalise_cell.(raw[indices, :]))
end

function nonempty_columns(raw::AbstractMatrix)
    indices = [column for column in axes(raw, 2) if any(value -> !is_blank(value), raw[:, column])]
    isempty(indices) && return Matrix{Any}(undef, size(raw, 1), 0)
    return Matrix{Any}(raw[:, indices])
end

"""
    cells_table(workbook_path, sheet_name, cell_range, labels; columns=nothing, limit=nothing)

Read one explicit worksheet range as source evidence. The caller supplies reader-facing
column labels because many AEMO ranges use multi-row or merged headers. This helper does
not reproduce parser joins, mappings, or modelling decisions.
"""
function cells_table(
    workbook_path::AbstractString,
    sheet_name::AbstractString,
    cell_range::AbstractString,
    labels::AbstractVector{<:AbstractString};
    columns::Union{Nothing, AbstractVector{<:Integer}} = nothing,
    limit::Union{Nothing, Int} = nothing,
)
    raw = range_workbook(workbook_path)[sheet_name][cell_range]
    rows = nonempty_rows(raw)
    rows = columns === nothing ? nonempty_columns(rows) : rows[:, columns]
    size(rows, 2) == length(labels) || error(
        "selected range $sheet_name!$cell_range has $(size(rows, 2)) non-empty columns; " *
        "$(length(labels)) labels were supplied",
    )
    if limit !== nothing && size(rows, 1) > limit
        rows = rows[1:limit, :]
    end
    return DataFrame(rows, Symbol.(labels); makeunique = true)
end

compact_path(path::AbstractString, root::AbstractString) = replace(relpath(path, root), '\\' => '/')

function sheet_names(workbook_path::AbstractString)
    return XLSX.openxlsx(workbook_path) do workbook
        collect(XLSX.sheetnames(workbook))
    end
end

function sheet_dimension_table(workbook_path::AbstractString, sheets::AbstractVector{<:AbstractString})
    return XLSX.openxlsx(workbook_path) do workbook
        available = Set(XLSX.sheetnames(workbook))
        DataFrame([
            (
                worksheet = sheet,
                present = sheet in available,
                workbook_declared_dimension = sheet in available ? string(XLSX.get_dimension(workbook[sheet])) : "not present",
            )
            for sheet in sheets
        ])
    end
end

function worksheet_presence(
    workbook_paths::AbstractVector{<:Pair},
    sheets::AbstractVector{<:AbstractString},
)
    rows = NamedTuple[]
    for (label, path) in workbook_paths
        names = Set(sheet_names(path))
        for sheet in sheets
            push!(rows, (edition = String(label), worksheet = String(sheet), present = sheet in names))
        end
    end
    return DataFrame(rows)
end

function workbook_inventory(workbook_paths::AbstractVector{<:Pair})
    rows = NamedTuple[]
    for (label, path) in workbook_paths
        push!(rows, (
            edition = String(label),
            workbook = basename(path),
            worksheet_count = length(sheet_names(path)),
            size_mib = round(filesize(path) / 1024^2; digits = 1),
        ))
    end
    return DataFrame(rows)
end

function outlook_group(filename::AbstractString)
    occursin(" - Core.xlsx", filename) && return "Core"
    return "Sensitivity"
end

function outlook_label(filename::AbstractString)
    stem = splitext(filename)[1]
    pieces = split(stem, " - ")
    length(pieces) < 3 && return stem
    return outlook_group(filename) == "Core" ?
        join(pieces[2:end-1], " - ") :
        join(pieces[2:end], " - ")
end

function directory_workbook_inventory(directory::AbstractString, edition::AbstractString)
    files = sort(filter(path -> endswith(lowercase(path), ".xlsx"), readdir(directory; join = true)))
    return DataFrame([
        (
            edition = String(edition),
            group = outlook_group(basename(path)),
            scenario_or_sensitivity = outlook_label(basename(path)),
            workbook = basename(path),
            worksheet_count = length(sheet_names(path)),
        )
        for path in files
    ])
end

function first_matching_file(root::AbstractString, pattern::Regex)
    for (directory, _, files) in walkdir(root)
        for file in sort(files)
            occursin(pattern, file) && return joinpath(directory, file)
        end
    end
    error("no file matching $pattern was found under the selected source root")
end

function coverage_document(repo_root::AbstractString)
    path = joinpath(repo_root, "docs", "source-material-coverage.toml")
    isfile(path) || error("source-material coverage ledger not found: $path")
    return TOML.parsefile(path)
end

function coverage_table(document::AbstractDict, section::AbstractString)
    entries = get(document, section, Any[])
    isempty(entries) && return DataFrame()
    column_names = sort!(collect(Set(String(key) for entry in entries for key in keys(entry))))
    return DataFrame([
        Symbol(column) => [get(entry, column, missing) for entry in entries]
        for column in column_names
    ])
end

function coverage_owner_summary(document::AbstractDict, section::AbstractString)
    counts = combine(groupby(coverage_table(document, section), [:classification, :owner]), nrow => :items)
    sort!(counts, [:classification, :owner])
    return counts
end

end
