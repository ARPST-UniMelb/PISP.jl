const CLASSIFICATION_LABELS = Dict(
    "aemo_raw_source" => "AEMO raw source",
    "parsed_representation" => "Parsed representation",
    "pisp_generated_intermediate" => "PISP-generated intermediate",
    "package_convention" => "PISP package convention",
    "user_input" => "User input",
    "pisp_output" => "PISP output",
    "excluded_trace_material" => "Excluded trace material",
)

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

compact_path(path::AbstractString, root::AbstractString) = replace(relpath(path, root), '\\' => '/')

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

function read_workbook_inventory(workbook_paths::AbstractVector{<:Pair})
    return DataFrame([
        (
            edition = String(label),
            workbook = basename(path),
            worksheet_count = XLSX.openxlsx(path) do workbook
                length(XLSX.sheetnames(workbook))
            end,
            size_mib = round(filesize(path) / 1024^2; digits = 1),
        )
        for (label, path) in workbook_paths
    ])
end

function read_outlook_inventory(directory::AbstractString, edition::AbstractString)
    files = sort(filter(path -> endswith(lowercase(path), ".xlsx"), readdir(directory; join = true)))
    return DataFrame([
        (
            edition = String(edition),
            group = outlook_group(basename(path)),
            scenario_or_sensitivity = outlook_label(basename(path)),
            workbook = basename(path),
            worksheet_count = XLSX.openxlsx(path) do workbook
                length(XLSX.sheetnames(workbook))
            end,
        )
        for path in files
    ])
end

function read_sheet_dimensions(workbook_path::AbstractString, sheets::AbstractVector{<:AbstractString})
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


function coverage_document(repo_root::AbstractString)
    path = joinpath(repo_root, "docs", "config", "source-material-coverage.toml")
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
