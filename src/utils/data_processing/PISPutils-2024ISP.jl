"""
    lead2year(str)

Translate textual lead-time classes from the ISP spreadsheets into the number of
years (e.g. "Long" => 8 years).
"""
function lead2year(str)
        if str == "Long" return 8
        elseif str == "Short" return 2
        elseif str == "Medium" return 4
        elseif str == "" return 4
        else return 4 end
end

"""
    flow2num(str)

Coerce a textual flow entry (often containing commas or NA) into a `Float64`
value so that line limits can be manipulated numerically.
"""
flow2num(str) = str == "NA" ? 0.0 : parse(Float64,replace(str, "," => ""))

"""
    inv2num(str)

Convert investment cost strings that may contain descriptive text or two-part
values into a single numeric estimate. Non-network placeholders are mapped to a
large value (9999.0) to highlight missing cost data.
"""
inv2num(str) = str[1] == "Non-network option costs to be provided by interested parties" || str[1] == "Anticipated project." ? 9999.0 : (length(str)<6 ? parse(Float64,replace(str[1], "," => "")) : parse(Float64,replace(str[1], "," => "")) + parse(Float64,replace(str[3], "," => "")))

"""
    fiscal_year(year)

Given a string like "2025-26", return a `DateTime` pointing to the start of the
fiscal year (1 July of the first year).
"""
function fiscal_year(year)
        # Given a year in the format "YYYY-YY", return the fiscal year starting in July 1st.
        y = split(year, "-")
        return DateTime(parse(Int, y[1]), 7, 1)
end

"""
    available_dsp(df_in)

Convert cumulative DSP availability bands into incremental values by differencing
each column. The first column (region/band identifiers) is preserved so the
output mirrors the input schema.
"""
function available_dsp(df_in)
    col1 = df_in[!, names(df_in)[1]]
    df   = df_in[!, 2:end]
    i=1
    for col in eachcol(df)
        v_diff = diff(col)
        v_diff = vcat(col[1], v_diff)
        df[!, i] = v_diff
        i+=1
    end
    df_new = hcat(col1, df)
    return df_new
end

"""
    inputDB_dsp(tv, df, der_ids, scenario; multiplier=1)

Transform DSP workbook data into DER load reduction entries and append them to
`tv.der_pred`. The helper handles seasonal dating (winter vs summer), scales each
band by `multiplier`, and maps bands onto supplied DER ids for the specified
scenario.
"""
function inputDB_dsp(tv, df, der_ids, scenario, multiplier=1)
    df = available_dsp(df)
    der_pred_sched = tv.der_pred
    idx = isempty(der_pred_sched) ? 1 : maximum(der_pred_sched.id) + 1
    for yr in names(df)[2:end]
        if length(yr) == 4      # winter
            date_cost = DateTime(parse(Int64,yr[1:4]))+Month(3)
        elseif length(yr) == 7  # summer
            date_cost = DateTime(parse(Int64,yr[1:4]))+Month(10)
        else
            error("wrong year format")
        end
        dsp_pmax = df[!, yr]
        for band in 1:5 # LOOP OVER DSP BANDS (FROM CHEAPER TO EXPENSIVE, including reliability response (RR))
            dsp_pred = dsp_pmax[band]*multiplier
            row_der_predmax_ched = [idx, der_ids[band], PISP.SCE[scenario], date_cost, dsp_pred]
            push!(tv.der_pred, row_der_predmax_ched)
            idx+=1
        end
    end
end
