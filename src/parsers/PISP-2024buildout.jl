"""
    read_buildout_table(filepath; sheetname) → (static_data, tvarying_data)

Parse a buildout schedule workbook sheet and return two DataFrames:
- `static_data`:   columns (name, subregion, tech, capacity) — one row per unique name
- `tvarying_data`: columns (name, subregion, year, n)         — one row per (name, year)

`name` is `uppercase(tech * "_" * subregion)`.
"""
function read_buildout_table(filepath::AbstractString; sheetname::AbstractString="buildout_1")
    raw = XLSX.openxlsx(filepath) do xf
        data = XLSX.getdata(xf[sheetname])
        DataFrame(data[2:end, :], Symbol.(vec(data[1, :])))
    end

    raw.tech      = String.(raw.tech)
    raw.subregion = String.(raw.subregion)
    raw.year      = Int64.(raw.year)
    raw.capacity  = Float64.(raw.capacity)
    raw.n         = Int64.(raw.n)
    raw.name      = uppercase.(raw.tech .* "_" .* raw.subregion) .* "_NEW"

    static_data   = unique(select(raw, :name, :subregion, :tech, :capacity))
    tvarying_data = select(raw, :name, :subregion, :year, :n)

    return static_data, tvarying_data
end
