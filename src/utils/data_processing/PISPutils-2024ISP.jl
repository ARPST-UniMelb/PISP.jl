function lead2year(str)
        if str == "Long" return 8
        elseif str == "Short" return 2
        elseif str == "Medium" return 4
        elseif str == "" return 4
        else return 4 end
end

flow2num(str) = str == "NA" ? 0.0 : parse(Float64,replace(str, "," => ""))

inv2num(str) = str[1] == "Non-network option costs to be provided by interested parties" || str[1] == "Anticipated project." ? 9999.0 : (length(str)<6 ? parse(Float64,replace(str[1], "," => "")) : parse(Float64,replace(str[1], "," => "")) + parse(Float64,replace(str[3], "," => "")))


function fiscal_year(year)
        # Given a year in the format "YYYY-YY", return the fiscal year starting in July 1st.
        y = split(year, "-")
        return DateTime(parse(Int, y[1]), 7, 1)
end