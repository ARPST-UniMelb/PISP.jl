# Excel file to DataFrame.
function xlsx2df(xf)
    m = xf[1,1:end]
    df = DataFrame(xf[2:end,1:end],:auto)
    rename!(df, Symbol.(m))
    return df
end

function cross(name::String, map, list)
    for tup in map 
        if name in tup 
            inter = intersect(tup, list)
            if length(inter) > 0 return true, inter[1] end
        end
    end
    return false, ""
end

function parseif(list)
    for i in eachindex(list)
        if typeof(list[i]) == String
            list[i] = parse(Float64, list[i])
        end
    end
    return list
end

function read_xlsx_with_header(filepath::AbstractString,
                               sheetname::AbstractString,
                               range::AbstractString;
                               makeunique::Bool=true)

    # Read the raw range
    rawdata = XLSX.readdata(filepath, sheetname, range)

    # Extract and clean header row
    raw_header = rawdata[1, :]
    #transform each element in the raw_header to string
    for i in eachindex(raw_header)
        if typeof(raw_header[i]) != String
            raw_header[i] = string(raw_header[i])
        end
    end
    clean_header = [
        (ismissing(h) || h == "") ? "Column_$(i)" : String(h)
        for (i, h) in enumerate(raw_header)
    ]
    colnames = Symbol.(clean_header)

    # Remaining rows as data
    rows = rawdata[2:end, :]

    # Build DataFrame
    return DataFrame(rows, colnames; makeunique=makeunique)
end

function _resolved_xlsx_location(
    spec::XlsxSourceSpec;
    worksheet::AbstractString = spec.worksheet,
    cell_range = spec.cell_range,
)
    resolved_worksheet = String(strip(String(worksheet)))
    isempty(resolved_worksheet) &&
        throw(ArgumentError("Resolved worksheet must not be empty for source $(spec.id)."))

    cell_range === nothing &&
        throw(ArgumentError("Source $(spec.id) does not define a cell range."))
    resolved_range = String(strip(String(cell_range)))
    is_valid_excel_range(resolved_range) ||
        throw(ArgumentError("Invalid Excel range `$(resolved_range)` for source $(spec.id)."))

    return resolved_worksheet, resolved_range
end

function validate_source_columns(table, spec::SourceSpec)
    isempty(spec.columns) && return table
    available = Set(string.(names(table)))
    missing_columns = [
        column.name for column in spec.columns
        if column.required && !(column.name in available)
    ]
    isempty(missing_columns) || throw(ArgumentError(
        "Source $(spec.id) is missing required columns: $(join(missing_columns, ", ")).",
    ))
    return table
end

function read_xlsx_rows(
    filepath::AbstractString,
    spec::XlsxSourceSpec;
    worksheet::AbstractString = spec.worksheet,
    cell_range = spec.cell_range,
)
    resolved_worksheet, resolved_range = _resolved_xlsx_location(
        spec;
        worksheet = worksheet,
        cell_range = cell_range,
    )
    return XLSX.readdata(filepath, resolved_worksheet, resolved_range)
end

function read_xlsx_with_header(
    filepath::AbstractString,
    spec::XlsxSourceSpec;
    worksheet::AbstractString = spec.worksheet,
    cell_range = spec.cell_range,
    makeunique::Bool = true,
    validate_columns::Bool = false,
)
    resolved_worksheet, resolved_range = _resolved_xlsx_location(
        spec;
        worksheet = worksheet,
        cell_range = cell_range,
    )
    table = read_xlsx_with_header(
        filepath,
        resolved_worksheet,
        resolved_range;
        makeunique = makeunique,
    )
    return validate_columns ? validate_source_columns(table, spec) : table
end

function read_csv_source(
    filepath::AbstractString,
    spec::CsvSourceSpec;
    validate_columns::Bool = false,
    kwargs...
)
    table = CSV.File(filepath; kwargs...) |> DataFrame
    return validate_columns ? validate_source_columns(table, spec) : table
end

"""
    schema_to_dataframe(schema::OrderedDict{String,String})
    Convert a schema (SQL-like column definitions) into an empty DataFrame with correct Julia column types.
"""
function schema_to_dataframe(schema::OrderedDict{String,String})
    names = Symbol[]
    cols  = Vector{AbstractVector}()
    for (col, decl) in schema
        # find the Julia type
        jtype = nothing
        for (sql, jt) in SQL2JL
            if occursin(sql, decl)
                jtype = jt
                break
            end
        end
        jtype === nothing && error("Unknown type in schema: $decl")

        push!(names, Symbol(col))
        push!(cols, Vector{jtype}())  # empty column
    end
    return DataFrame(cols, names)
end


