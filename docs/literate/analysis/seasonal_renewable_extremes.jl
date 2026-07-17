# # Examining seasonal renewable extremes
#
# Mean capacity factors do not describe the persistence, timing, or profile of low-output conditions. This page loads the underlying half-hourly solar and wind traces directly, then builds grouped summer comparisons, candidate multi-day low-output events, and detailed solar profiles for adverse days.
#
# The analysis uses one Victorian solar location and one Victorian wind location. Its event definitions are exploratory and should not be treated as a system-wide adequacy criterion.

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Statistics
using Plots

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "04_seasonal_extremes"
const TRACES = joinpath("data", "2024", "pisp-downloads", "Traces")

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)

const HH_COLS_SOL = string.(1:48)
const HH_COLS_WIND = [lpad(i, 2, '0') for i in 1:48]

# Known hot vs cool (La Nina) Australian historical summers.
const HOT_SUMMERS = [2019, 2013, 2017, 2015, 2023]
const COOL_SUMMERS = [2011, 2016, 2020, 2022]

const SOLAR_LOC = "Bannerton_SAT"
const WIND_LOC = "DUNDWF1"

function add_datetime!(df::DataFrame)
    df.datetime = Date.(df.Year, df.Month, df.Day)
    return df
end

function load_trace(tech, yr, loc)
    file = joinpath(TRACES, "$(tech)_$(yr)", "$(loc)_RefYear$(yr).csv")
    isfile(abs_path(file)) || return nothing
    df = CSV.read(abs_path(file), DataFrame)
    add_datetime!(df)
    return df
end

row_mean(df::DataFrame, cols) = [mean(row[col] for col in cols) for row in eachrow(df)]
nothing #hide

# A simple trailing rolling mean: the first `window - 1` entries have no full window of preceding values yet, so they are left `missing`.
function rolling_mean(values, window)
    n = length(values)
    result = Vector{Union{Missing, Float64}}(missing, n)
    for i in window:n
        result[i] = mean(values[(i - window + 1):i])
    end
    return result
end

# Pushes one candidate event (>= 3 consecutive below-threshold calendar days) covering summer-filtered positions s_pos:e_pos into rows, computed from real calendar-day duration rather than array position, so it cannot span a non-summer gap.
function push_low_output_event!(rows, s_pos, e_pos, dates, daily, tech, yr)
    duration = (dates[e_pos] - dates[s_pos]).value + 1
    duration >= 3 || return nothing
    vals = view(daily, s_pos:e_pos)
    push!(
        rows,
        NamedTuple{(:year, :start, :end, :duration, :min_cf, :mean_cf, :tech)}(
            (
                yr,
                Dates.format(dates[s_pos], "yyyy-mm-dd"),
                Dates.format(dates[e_pos], "yyyy-mm-dd"),
                duration,
                minimum(vals),
                mean(vals),
                tech,
            ),
        ),
    )
    return nothing
end

# Finds candidate multi-day low-output events within one technology/location/year's summer (Dec/Jan/Feb) days. A "December" row and a "January/February" row are both selected by the summer month filter, but a single reference-year trace file lists them roughly 9 months apart in calendar time (Jan-Feb near the top of the file, December near the bottom), so this only extends a run across two summer-filtered rows when their calendar dates are exactly one day apart -- otherwise it closes the current run and starts a new one, so an event can never silently bridge the excluded March-November gap.
function low_output_events_for(tech, loc, hh_cols, threshold, yr)
    df = load_trace(tech, yr, loc)
    df === nothing && return NamedTuple[]
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    any(summer_mask) || return NamedTuple[]

    summer = df[summer_mask, :]
    dates = summer.datetime
    daily = row_mean(summer, hh_cols)
    below = daily .< threshold
    n = length(below)

    rows = NamedTuple[]
    run_start = below[1] ? 1 : nothing
    for i in 2:n
        contiguous = (dates[i] - dates[i - 1]) == Day(1)
        if run_start !== nothing && (!below[i] || !contiguous)
            push_low_output_event!(rows, run_start, i - 1, dates, daily, tech, yr)
            run_start = nothing
        end
        if below[i] && run_start === nothing
            run_start = i
        end
    end
    run_start !== nothing && push_low_output_event!(rows, run_start, n, dates, daily, tech, yr)
    return rows
end

snapshot_metadata_line(
    REPO_ROOT;
    context = "2024 ISP raw trace downloads (data/2024/pisp-downloads/Traces), historical years 2011-2023, hot/cool summers fixed by HOT_SUMMERS/COOL_SUMMERS",
)

# ## Step 1 — hot vs cool summer solar profile summary
#
# For each historical hot or cool summer, this computes the mean daily capacity factor across December/January/February and summarises it with its own spread and range.

rows = NamedTuple[]
for (season_type, year_list) in (("Hot Summers", HOT_SUMMERS), ("Cool Summers", COOL_SUMMERS))
    for yr in year_list
        df = load_trace("solar", yr, SOLAR_LOC)
        df === nothing && continue
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        vals = row_mean(df[summer_mask, :], HH_COLS_SOL)
        push!(
            rows,
            (
                season_type = season_type,
                year = yr,
                n_days = length(vals),
                mean_daily_cf = mean(vals),
                std_daily_cf = std(vals),
                min_daily_cf = minimum(vals),
                max_daily_cf = maximum(vals),
            ),
        )
    end
end

hot_cool_summer_solar_summary = DataFrame(rows)
write_table(hot_cool_summer_solar_summary, SCRIPT_STEM, "hot_cool_summer_solar_summary")
markdown_table(hot_cool_summer_solar_summary)

# ## Step 2 — candidate multi-day low-output events
#
# An event is a run of consecutive summer calendar days whose daily mean capacity factor stays below the technology's threshold for at least 3 days; a run never bridges the excluded March-November gap between a summer's December and the following January/February. The full event-by-event table is written to `eda/tables/julia/04_seasonal_extremes/low_output_events.csv`; the page instead shows a compact per-technology-per-year summary of how many candidate events were found and how long they lasted.

rows = NamedTuple[]
for (tech, loc, hh_cols, threshold) in (
    ("solar", SOLAR_LOC, HH_COLS_SOL, 0.1),
    ("wind", WIND_LOC, HH_COLS_WIND, 0.15),
)
    for yr in 2011:2023
        append!(rows, low_output_events_for(tech, loc, hh_cols, threshold, yr))
    end
end

low_output_events = DataFrame(rows)
write_table(low_output_events, SCRIPT_STEM, "low_output_events")

low_output_event_summary = if isempty(low_output_events)
    DataFrame()
else
    sort(
        combine(
            groupby(low_output_events, [:tech, :year]),
            nrow => :n_events,
            :duration => minimum => :min_duration,
            :duration => (x -> round(mean(x), digits = 1)) => :mean_duration,
            :duration => maximum => :max_duration,
        ),
        [:tech, :year],
    )
end
markdown_table(low_output_event_summary)

# ## Step 3 — worst solar day and half-hourly profile
#
# The summary identifies the selected adverse day for each year, while the profile table retains the intraday shape needed to understand whether the low-output metric is broad or confined to a short interval.

worst_rows = NamedTuple[]
for yr in 2011:2023
    df = load_trace("solar", yr, SOLAR_LOC)
    df === nothing && continue
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    any(summer_mask) || continue
    summer = df[summer_mask, :]
    daily = row_mean(summer, HH_COLS_SOL)
    worst_pos = argmin(daily)  # first occurrence on ties
    push!(
        worst_rows,
        (
            year = yr,
            date = Dates.format(summer.datetime[worst_pos], "yyyy-mm-dd"),
            cf = daily[worst_pos],
            is_hot_summer = yr in HOT_SUMMERS ? 1 : 0,
        ),
    )
end

worst_solar_day_summary = DataFrame(worst_rows)
write_table(worst_solar_day_summary, SCRIPT_STEM, "worst_solar_day_summary")
markdown_table(worst_solar_day_summary)

#-

rows = NamedTuple[]
if !isempty(worst_rows)
    best_idx = argmin([r.cf for r in worst_rows])
    worst = worst_rows[best_idx]
    yr = worst.year
    worst_date = Date(worst.date, "yyyy-mm-dd")
    df = load_trace("solar", yr, SOLAR_LOC)
    if df !== nothing
        mask = df.datetime .== worst_date
        if any(mask)
            row_idx = findfirst(mask)
            half_hours = collect(0.5:0.5:24.0)
            for (hh, col) in zip(half_hours, HH_COLS_SOL)
                push!(rows, (year = yr, date = worst.date, half_hour = hh, cf = df[row_idx, col]))
            end
        end
    end
end

worst_solar_day_profile = DataFrame(rows)
write_table(worst_solar_day_profile, SCRIPT_STEM, "worst_solar_day_profile")
markdown_table(worst_solar_day_profile)

# ## Step 4 — 2019 monthly and Black Summer detail
#
# The monthly table provides a calendar context for the detailed summer series. It uses a two-stage aggregation: per half-hourly column, compute that column's mean/std across the days in the month, then average those 48 per-column values into one monthly figure. The three-day rolling value in the daily series below is descriptive and should not be interpreted as a dispatch or storage requirement without a separate system model.

df = load_trace("solar", 2019, SOLAR_LOC)
rows = NamedTuple[]
if df !== nothing
    for m in 1:12
        mask = df.Month .== m
        if any(mask)
            sub = df[mask, :]
            col_means = [mean(sub[!, col]) for col in HH_COLS_SOL]
            col_stds = [std(sub[!, col]) for col in HH_COLS_SOL]
            push!(rows, (month = m, mean_cf = mean(col_means), std_cf = mean(col_stds)))
        else
            push!(rows, (month = m, mean_cf = 0.0, std_cf = 0.0))
        end
    end
end

monthly_cf_2019_summary = DataFrame(rows)
write_table(monthly_cf_2019_summary, SCRIPT_STEM, "monthly_cf_2019_summary")
markdown_table(monthly_cf_2019_summary)

#-

# The `RefYear2019` trace reuses the 2019 (Black Summer) historical weather pattern across the entire projected planning horizon, not just the single 2018-19 season, so the daily series below has one row per summer day in every simulated year. The table previews the first 15 rows; the complete series is written to `eda/tables/julia/04_seasonal_extremes/black_summer_2019_daily_cf.csv`.

df = load_trace("solar", 2019, SOLAR_LOC)
rows = NamedTuple[]
if df !== nothing
    summer_mask = in.(df.Month, Ref((12, 1, 2)))
    summer = df[summer_mask, :]
    daily = row_mean(summer, HH_COLS_SOL)
    rolling3 = rolling_mean(daily, 3)
    for (i, d) in enumerate(summer.datetime)
        push!(rows, (date = Dates.format(d, "yyyy-mm-dd"), daily_mean_cf = daily[i], rolling3_cf = rolling3[i]))
    end
end

black_summer_2019_daily_cf = DataFrame(rows)
write_table(black_summer_2019_daily_cf, SCRIPT_STEM, "black_summer_2019_daily_cf")
markdown_table(first(black_summer_2019_daily_cf, 15))

# ## Step 5 — hot vs cool summer solar profiles (figure)
#
# Each panel overlays every year in the group as a thin line with its own 3-day rolling mean drawn on top, so persistent dips stand out from single-day noise.

plots_hot_cool = []
let
    for (season_type, year_list, color) in [("Hot Summers", HOT_SUMMERS, :darkred), ("Cool Summers", COOL_SUMMERS, :steelblue)]
        p = plot(legend=false, size=(1400, 400))
        for yr in year_list
            df = load_trace("solar", yr, SOLAR_LOC)
            df === nothing && continue
            summer_mask = in.(df.Month, Ref((12, 1, 2)))
            any(summer_mask) || continue
            summer = df[summer_mask, :]
            daily = [mean(skipmissing(Vector(summer[i, HH_COLS_SOL]))) for i in 1:nrow(summer)]
            rolling3 = rolling_mean(daily, 3)
            plot!(p, summer.datetime, daily, linewidth=0.5, alpha=0.6, color=color, label="$yr")
            plot!(p, summer.datetime, rolling3, linewidth=1.5, color=:black, alpha=0.8, label="")
        end
        plot!(p, title="Solar $(SOLAR_LOC) — $(season_type) Daily Mean CF", ylabel="Daily Mean CF",
              ylim=(0, 0.5), grid=true, gridalpha=0.3)
        push!(plots_hot_cool, p)
    end
end
p_hc = plot(plots_hot_cool..., layout=(2,1), size=(1400, 800),
            left_margin=5Plots.mm, bottom_margin=5Plots.mm)
savefig(p_hc, figure_path(SCRIPT_STEM, "04_hot_vs_cool_summer_solar.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "04_hot_vs_cool_summer_solar.png"), "04_hot_vs_cool_summer_solar.png")
nothing #hide

# ![Daily mean solar capacity factor across historical hot summers versus cool summers](04_hot_vs_cool_summer_solar.png)

# ## Step 6 — low-output events overview (figure)
#
# A 2x2 grid: event-duration histograms for solar and wind low-output events, a bar chart of each year's worst solar day sorted by capacity factor, and the half-hourly profile of the single worst solar day across all years.

solar_low_events = []
wind_low_events = []
worst_solar_days_data = Dict()

let
    for yr in 2011:2023
        df = load_trace("solar", yr, SOLAR_LOC)
        df === nothing && continue
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        daily = [mean(skipmissing(Vector(summer[i, HH_COLS_SOL]))) for i in 1:nrow(summer)]

        events = low_output_events_for("solar", SOLAR_LOC, HH_COLS_SOL, 0.1, yr)
        for row in events
            push!(solar_low_events, row.duration)
        end

        worst_pos = argmin(daily)
        worst_solar_days_data[yr] = (date = summer.datetime[worst_pos], cf = daily[worst_pos])
    end
end

let
    for yr in 2011:2023
        df = load_trace("wind", yr, WIND_LOC)
        df === nothing && continue
        summer_mask = in.(df.Month, Ref((12, 1, 2)))
        any(summer_mask) || continue
        summer = df[summer_mask, :]
        daily = [mean(skipmissing(Vector(summer[i, HH_COLS_WIND]))) for i in 1:nrow(summer)]

        events = low_output_events_for("wind", WIND_LOC, HH_COLS_WIND, 0.15, yr)
        for row in events
            push!(wind_low_events, row.duration)
        end
    end
end

p_sol_hist = histogram(solar_low_events, bins=1:maximum(solar_low_events)+1, color=:darkorange, alpha=0.7,
                        legend=false, title="Solar $(SOLAR_LOC) — Duration of Low-Output Events (≥3 days)",
                        xlabel="Consecutive Days Below Threshold", ylabel="Count", grid=true, gridalpha=0.3)

p_wind_hist = histogram(wind_low_events, bins=1:maximum(wind_low_events)+1, color=:steelblue, alpha=0.7,
                         legend=false, title="Wind $(WIND_LOC) — Duration of Low-Output Events (≥3 days)",
                         xlabel="Consecutive Days Below Threshold", ylabel="Count", grid=true, gridalpha=0.3)
nothing #hide

worst_yrs = collect(keys(worst_solar_days_data))
sort!(worst_yrs, by = yr -> worst_solar_days_data[yr].cf)
worst_cfs = [worst_solar_days_data[yr].cf for yr in worst_yrs]
worst_colors = [yr in HOT_SUMMERS ? :darkred : :steelblue for yr in worst_yrs]
p_worst_days = bar(string.(worst_yrs), worst_cfs, color=worst_colors, alpha=0.7, legend=false,
                    title="Solar $(SOLAR_LOC) — Worst Summer Day by Year (sorted by CF)",
                    ylabel="Daily Mean CF", grid=true, gridalpha=0.3)
nothing #hide

if !isempty(worst_rows)
    best_idx = argmin([r.cf for r in worst_rows])
    worst = worst_rows[best_idx]
    yr = worst.year
    worst_date = Date(worst.date, "yyyy-mm-dd")
    df = load_trace("solar", yr, SOLAR_LOC)
    if df !== nothing
        mask = df.datetime .== worst_date
        if any(mask)
            row_idx = findfirst(mask)
            half_hours = collect(0.5:0.5:24.0)
            hh_vals = Vector(df[row_idx, HH_COLS_SOL])
            p_worst_profile = plot(half_hours, hh_vals, linewidth=2, marker=:circle, markersize=3,
                                    color=:darkred, legend=false,
                                    title="Worst Solar Day: $(worst.date) (CF=$(round(worst.cf, digits=3)))",
                                    xlabel="Hour", ylabel="Capacity Factor", ylim=(0, 1),
                                    grid=true, gridalpha=0.3)
        else
            p_worst_profile = plot(legend=false)
        end
    else
        p_worst_profile = plot(legend=false)
    end
else
    p_worst_profile = plot(legend=false)
end

p_low_out = plot(p_sol_hist, p_wind_hist, p_worst_days, p_worst_profile, layout=(2,2), size=(1400, 1000),
                  left_margin=5Plots.mm, bottom_margin=5Plots.mm)
savefig(p_low_out, figure_path(SCRIPT_STEM, "04_low_output_events.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "04_low_output_events.png"), "04_low_output_events.png")
nothing #hide

# ![Low-output event durations, worst-day ranking, and the worst day's half-hourly profile](04_low_output_events.png)

# ## Step 7 — 2019 monthly CF (figure)
#
# The bar chart reads back the monthly summary table written in Step 4, so the plot uses exactly the same aggregation as the table.

monthly_table_path = table_path(SCRIPT_STEM, "monthly_cf_2019_summary")
if isfile(monthly_table_path)
    monthly_df = CSV.read(monthly_table_path, DataFrame)
    month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    p_monthly = bar(month_labels, monthly_df.mean_cf, yerror=monthly_df.std_cf, color=:darkorange, alpha=0.6,
                    edgecolor=:black, legend=false,
                    title="Solar $(SOLAR_LOC) 2019 — Monthly Mean CF ± Std",
                    xlabel="Month", ylabel="Mean Capacity Factor", grid=true, gridalpha=0.3, size=(1200, 500),
                    left_margin=5Plots.mm, bottom_margin=5Plots.mm)
    savefig(p_monthly, figure_path(SCRIPT_STEM, "04_monthly_cf_2019.png"))
    EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "04_monthly_cf_2019.png"), "04_monthly_cf_2019.png")
end
nothing #hide

# ![Solar monthly mean capacity factor for 2019 with standard deviation error bars](04_monthly_cf_2019.png)

# ## Step 8 — Summer 2019 Black Summer (figure)
#
# The daily mean capacity factor across December 2018/January-February 2019, with its 3-day rolling mean overlaid, showing the persistence of the low-output stretch during the Black Summer period.

df_2019 = load_trace("solar", 2019, SOLAR_LOC)
if df_2019 !== nothing
    summer_2019 = df_2019[in.(df_2019.Month, Ref((12, 1, 2))), :]
    daily = [mean(skipmissing(Vector(summer_2019[i, HH_COLS_SOL]))) for i in 1:nrow(summer_2019)]
    rolling3 = rolling_mean(daily, 3)
    p_black = plot(summer_2019.datetime, daily, linewidth=0.5, color=:darkorange, alpha=0.7, legend=false)
    plot!(p_black, summer_2019.datetime, rolling3, linewidth=2, color=:darkred, label="")
    plot!(p_black, title="Solar $(SOLAR_LOC) — Summer 2019 (Black Summer)", ylabel="Daily Mean CF",
          ylim=(0, 0.5), grid=true, gridalpha=0.3, size=(1600, 500),
          left_margin=5Plots.mm, bottom_margin=5Plots.mm)
    savefig(p_black, figure_path(SCRIPT_STEM, "04_summer_2019_black_summer.png"))
    EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "04_summer_2019_black_summer.png"), "04_summer_2019_black_summer.png")
end
nothing #hide

# ![Summer 2019 (Black Summer) daily mean solar capacity factor with 3-day rolling mean](04_summer_2019_black_summer.png)

# ## Summary
#
# - Hot and cool historical summers show visibly different daily mean solar capacity factor spreads once each year's series is overlaid with its own 3-day rolling mean.
# - The multi-day low-output event table reports real calendar-day durations for each technology and year, split at any gap in summer coverage so an event can never bridge the excluded March-November months.
# - The 2019 monthly summary and Black Summer daily series both come from the same two-stage aggregation described in Step 4.
