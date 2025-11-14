using CSV
using DataFrames
function weather_years_df(d::Dict)
    parse_date(x) = x isa Date ? x : Date(x, dateformat"yyyy-mm-dd")
    rows = [(parse_date(s), parse_date(e), string(v)) for ((s,e), v) in d]
    return sort!(DataFrame(rows, [:start_date, :end_date, :label]), :start_date)
end

function monthly_to_hourly(df::DataFrame; date_col::Symbol=:exact_date, value_col::Symbol=:value)
    n = nrow(df)
    # hours per row (days in month * 24)
    HOURS_PER_DAY = 24
    hours_per_row = Dates.daysinmonth.(df[!, date_col]) .* HOURS_PER_DAY
    total_hours = sum(hours_per_row)

    dates_out  = Vector{DateTime}(undef, total_hours)
    values_out = Vector{Float64}(undef, total_hours)

    pos = 1
    for i in 1:n
        dt0 = DateTime(df[i, date_col])       # start at midnight on the 1st
        h   = hours_per_row[i]
        v   = Float64(df[i, value_col]) / h  # hourly value
        for off in 0:h-1
            dates_out[pos]  = dt0 + Hour(off)
            values_out[pos] = v
            pos += 1
        end
    end

    return DataFrame(date = dates_out, value = values_out)
end

function expand_yearly_to_hourly(df_energy)
    n = nrow(df_energy)
    hourly_dates = DateTime[]
    hourly_limits = Float64[]

    for i in 1:n
        start_dt = df_energy.date[i]
        stop_dt = i < n ? df_energy.date[i + 1] : start_dt + Year(1)
        hours = collect(start_dt:Hour(1):stop_dt - Hour(1))
        append!(hourly_dates, hours)
        append!(hourly_limits, fill(df_energy.HourlyLimit[i], length(hours)))
    end

    return DataFrame(date = hourly_dates, HourlyLimit = hourly_limits)
end

function build_hourly_snowy(
    ispdata24;
    weather_years = PISP.WEATHER_YEARS,
    sheet_name = "Hydro Scheme Inflows",
    cell_range = "B34:N47",
)
    monthly_cols = Symbol.([:Jul, :Aug, :Sep, :Oct, :Nov, :Dec, :Jan, :Feb, :Mar, :Apr, :May, :Jun])
    month_map = Dict(
        "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6,
        "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12,
    )

    weather_df = weather_years_df(weather_years)

    data = PISP.read_xlsx_with_header(ispdata24, sheet_name, cell_range)
    rename!(data, Symbol("Reference Year (FYE)") => :ref_year)

    monthly_lookup = select(data, :ref_year => ByRow(string) => :label, monthly_cols...)

    weather_df = leftjoin(weather_df, monthly_lookup, on = :label)

    keep_cols = Not([:start_date, :end_date, :label])
    long = stack(weather_df, keep_cols, variable_name = :month, value_name = :value)

    month_str = strip.(string.(long.month))
    month_num = get.(Ref(month_map), month_str, missing)

    if any(ismissing, month_num)
        bad = unique(month_str[ismissing.(month_num)])
        throw(ArgumentError("Unexpected month names: $bad"))
    end

    year_vec = ifelse.(month_num .>= 7, year.(long.start_date), year.(long.end_date))
    long[!, :exact_date] = Date.(year_vec, month_num, 1)

    sort!(long, [:start_date, :exact_date])

    hourly_input = select(long, [:exact_date, :value])
    return monthly_to_hourly(hourly_input)
end
