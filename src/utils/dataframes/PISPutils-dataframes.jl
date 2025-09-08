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



