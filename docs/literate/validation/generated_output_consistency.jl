# # PISP generated-output consistency
#
# PISP writes a static asset dataset (`Generator.csv`, `Demand.csv`, `Bus.csv`) alongside time-varying schedules (`Generator_pmax_sched.csv`, `Demand_load_sched.csv`) for one generated build. This page loads one such build, joins the static and schedule tables, and checks identifier coverage, schedule coverage, generator classification, and daily solar/wind/demand alignment, computed live on this page and written to `eda/tables/julia/06_pisp_outputs/` as evidence. It also builds the three PISP-output figures shown in the generated docs site.

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using Dates
using Printf
using Statistics
using Plots

gr();

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "06_pisp_outputs"
const OUT = normpath(get(
    ENV,
    "PISP_OUTPUT_ROOT",
    joinpath(REPO_ROOT, "data", "2024", "pisp-datasets", "out-ref4006-poe10", "csv"),
))
const SCHEDULE_TAG = get(ENV, "PISP_SCHEDULE_TAG", "schedule-2030")
const SCHEDULE_DIR = joinpath(OUT, SCHEDULE_TAG)

snapshot_metadata_line(REPO_ROOT; context = "$(SCHEDULE_TAG) generated PISP output (out-ref4006-poe10 build)")

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # no-op here since OUT/SCHEDULE_DIR are already absolute; kept for consistency with the other EDA pages

const AREA_NAMES = Dict(1 => "QLD", 2 => "NSW", 3 => "VIC", 4 => "TAS", 5 => "SA")
nothing #hide

# Schedule dates look like "2030-01-01T00:00:00.0"; this fallback handles the case where the column is read back as text rather than the DateTime CSV.jl already infers.
parse_schedule_datetime(s::AbstractString) = DateTime(replace(s, r"\.\d+$" => ""))
parse_schedule_datetime(d::DateTime) = d

is_solar_tech(tech) = occursin(r"PV|SOLAR"i, tech)
is_wind_tech(tech) = occursin(r"WIND"i, tech)

function append_relationship_diagnostics!(summary_rows, detail_rows, relationship, left_label, right_label, left_ids, right_ids)
    left_set = Set(skipmissing(left_ids))
    right_set = Set(skipmissing(right_ids))
    left_unmatched = sort(collect(setdiff(left_set, right_set)))
    right_unmatched = sort(collect(setdiff(right_set, left_set)))

    push!(
        summary_rows,
        (
            relationship = relationship,
            left_label = left_label,
            right_label = right_label,
            left_unique_ids = length(left_set),
            right_unique_ids = length(right_set),
            left_unmatched_ids = length(left_unmatched),
            right_unmatched_ids = length(right_unmatched),
        ),
    )

    for id in left_unmatched
        push!(detail_rows, (relationship = relationship, unmatched_side = left_label, id = string(id)))
    end
    for id in right_unmatched
        push!(detail_rows, (relationship = relationship, unmatched_side = right_label, id = string(id)))
    end
end
nothing #hide

# Capacity factor for solar and wind divides each generator's scheduled mean output by that generator's own scheduled maximum, not by the static `pmax` recorded in `Generator.csv`.
# The static field is not a reliable capacity reference for these generators: rooftop PV rows carry a fixed placeholder pmax (src/parsers/PISP-2024parser.jl:1070, `gen_pmax_distpv`), and utility-scale solar/wind rows record only currently operating capacity, which a future-year schedule can exceed once ISP-outlook build-out is reflected in the trace (`gen_pmax_wind`, ~1386 vs. ~1477 in the same file).
# SiennaNEM.jl, which builds unit-commitment models from this same PISP output, applies the same convention (src/read_data.jl:214-229, `update_system_data_bound!`) and calls the static pmax "dummy" for these generators (src/create_system.jl:342,368).
# See PISP.jl's own the generated Parameters and mappings page and docs/src/assumptions.md for the full caveat.
function capacity_factor_duration_frame(gen_pmax::DataFrame, gens::DataFrame, tech::AbstractString)
    ids = Set(gens.id_gen)

    sched = gen_pmax[in.(gen_pmax.id_gen, Ref(ids)), :]
    grouped = combine(groupby(sched, :id_gen), :value => mean => :mean_value, :value => maximum => :max_value)

    cf_values = Float64[]
    for row in eachrow(grouped)
        cf = row.mean_value / row.max_value
        isnan(cf) && continue
        push!(cf_values, cf)
    end
    sorted_desc = sort(cf_values; rev = true)
    return DataFrame(tech = tech, rank = 1:length(sorted_desc), capacity_factor = sorted_desc)
end

function build_dem_load_full(dem_load::DataFrame, dem_df::DataFrame, bus_df::DataFrame)
    area_map = Dict(row.id_bus => row.id_area for row in eachrow(bus_df))
    dem_load_full = innerjoin(dem_load, dem_df[:, [:id_dem, :id_bus]], on = :id_dem)
    dem_load_full.datetime = parse_schedule_datetime.(dem_load_full.date)
    dem_load_full.area = [area_map[b] for b in dem_load_full.id_bus]
    dem_load_full.area_name = [AREA_NAMES[a] for a in dem_load_full.area]
    return dem_load_full
end

function build_gen_pmax_ts(gen_pmax::DataFrame, gen_df::DataFrame)
    gen_pmax_ts = innerjoin(gen_pmax, gen_df[:, [:id_gen, :tech]], on = :id_gen)
    gen_pmax_ts.datetime = parse_schedule_datetime.(gen_pmax_ts.date)
    return gen_pmax_ts
end

function daily_tech_sum(gen_pmax_ts::DataFrame, tech_predicate)
    subset = gen_pmax_ts[tech_predicate.(gen_pmax_ts.tech), :]
    subset = transform(subset, :datetime => ByRow(Date) => :date_only)
    return combine(groupby(subset, :date_only), :value => sum => :total)
end
nothing #hide

# ## Step 1 — load the static asset tables and the 2030 schedule outputs
#
# `Generator.csv`, `Demand.csv`, and `Bus.csv` describe the static network; `Generator_pmax_sched.csv` and `Demand_load_sched.csv` under the `schedule-2030` tag describe the time-varying build for this generated dataset.

gen_df = CSV.read(abs_path(joinpath(OUT, "Generator.csv")), DataFrame)
dem_df = CSV.read(abs_path(joinpath(OUT, "Demand.csv")), DataFrame)
bus_df = CSV.read(abs_path(joinpath(OUT, "Bus.csv")), DataFrame)

gen_pmax = CSV.read(abs_path(joinpath(SCHEDULE_DIR, "Generator_pmax_sched.csv")), DataFrame)
dem_load = CSV.read(abs_path(joinpath(SCHEDULE_DIR, "Demand_load_sched.csv")), DataFrame)
nothing #hide

# ## Step 2 — record which output root and schedule directory were used
#
# The recorded paths are relative to the repository root so this evidence table stays comparable across machines and reproducible from any checkout.

build_metadata = DataFrame([
    (
        pisp_output_root = replace(relpath(OUT, REPO_ROOT), '\\' => '/'),
        schedule_tag = SCHEDULE_TAG,
        schedule_directory = replace(relpath(SCHEDULE_DIR, REPO_ROOT), '\\' => '/'),
    ),
])
write_table(build_metadata, SCRIPT_STEM, "build_metadata")
markdown_table(build_metadata)

# ## Step 3 — generator table shape and classification counts
#
# `Generator.csv` classifies each generator by `fuel` and by `tech`; these counts show which classifications are available for later technology-specific filtering.

println("=== Generator Table ===")
println("Shape: ", (nrow(gen_df), ncol(gen_df)))

generator_fuel_counts = combine(groupby(gen_df, :fuel), nrow => :count)
write_table(generator_fuel_counts, SCRIPT_STEM, "generator_fuel_counts")
markdown_table(generator_fuel_counts)

#-

generator_tech_counts = combine(groupby(gen_df, :tech), nrow => :count)
write_table(generator_tech_counts, SCRIPT_STEM, "generator_tech_counts")
markdown_table(generator_tech_counts)

# ## Step 4 — schedule shapes and time coverage
#
# The two schedule tables share the same long-format layout (one row per identifier per timestamp); their row/column shapes and represented time interval describe the extent of this generated build.

println("\n=== Generator_pmax_sched ===")
println("Shape: ", (nrow(gen_pmax), ncol(gen_pmax)))
println("\n=== Demand_load_sched ===")
println("Shape: ", (nrow(dem_load), ncol(dem_load)))

schedule_shapes = DataFrame([
    (schedule = "Generator_pmax_sched", n_rows = nrow(gen_pmax), n_cols = ncol(gen_pmax)),
    (schedule = "Demand_load_sched", n_rows = nrow(dem_load), n_cols = ncol(dem_load)),
])
write_table(schedule_shapes, SCRIPT_STEM, "schedule_shapes")
markdown_table(schedule_shapes)

#-

schedule_time_coverage_rows = NamedTuple[]
for (schedule_name, schedule) in [
    ("Generator_pmax_sched", gen_pmax),
    ("Demand_load_sched", dem_load),
]
    timestamps = parse_schedule_datetime.(schedule.date)
    push!(
        schedule_time_coverage_rows,
        (
            schedule = schedule_name,
            first_timestamp = minimum(timestamps),
            last_timestamp = maximum(timestamps),
            unique_timestamps = length(unique(timestamps)),
            unique_days = length(unique(Date.(timestamps))),
        ),
    )
end
schedule_time_coverage = DataFrame(schedule_time_coverage_rows)
write_table(schedule_time_coverage, SCRIPT_STEM, "schedule_time_coverage")
markdown_table(schedule_time_coverage)

# ## Step 5 — join coverage between schedules, static tables, and the bus table
#
# Each relationship below compares one schedule or static identifier column against the identifier column it should join against, recording how many identifiers are unmatched on either side.

join_summary_rows = NamedTuple[]
join_detail_rows = NamedTuple[]

append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "generator schedule to static generator",
    "Generator_pmax_sched.id_gen",
    "Generator.id_gen",
    gen_pmax.id_gen,
    gen_df.id_gen,
)
append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "demand schedule to static demand",
    "Demand_load_sched.id_dem",
    "Demand.id_dem",
    dem_load.id_dem,
    dem_df.id_dem,
)
append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "generator bus to bus table",
    "Generator.id_bus",
    "Bus.id_bus",
    gen_df.id_bus,
    bus_df.id_bus,
)
append_relationship_diagnostics!(
    join_summary_rows,
    join_detail_rows,
    "demand bus to bus table",
    "Demand.id_bus",
    "Bus.id_bus",
    dem_df.id_bus,
    bus_df.id_bus,
)

join_coverage = DataFrame(join_summary_rows)
write_table(join_coverage, SCRIPT_STEM, "join_coverage")
markdown_table(join_coverage)

#-

unmatched_ids = isempty(join_detail_rows) ? DataFrame(relationship = String[], unmatched_side = String[], id = String[]) : DataFrame(join_detail_rows)
write_table(unmatched_ids, SCRIPT_STEM, "unmatched_ids")
markdown_table(unmatched_ids)

# ## Step 6 — identify the solar and wind generators
#
# Solar and wind generators are identified from `Generator.tech` using the same case-insensitive pattern match used throughout this page.

solar_gens = gen_df[is_solar_tech.(gen_df.tech), :]
wind_gens = gen_df[is_wind_tech.(gen_df.tech), :]
println("\nSolar generators: ", nrow(solar_gens))
println("Wind generators: ", nrow(wind_gens))

solar_wind_generator_counts = DataFrame([
    (category = "solar", n_generators = nrow(solar_gens)),
    (category = "wind", n_generators = nrow(wind_gens)),
])
write_table(solar_wind_generator_counts, SCRIPT_STEM, "solar_wind_generator_counts")
markdown_table(solar_wind_generator_counts)

#-

solar_wind_tech_counts_solar = combine(groupby(solar_gens, :tech), nrow => :count)
solar_wind_tech_counts_solar.category .= "solar"
solar_wind_tech_counts_wind = combine(groupby(wind_gens, :tech), nrow => :count)
solar_wind_tech_counts_wind.category .= "wind"
solar_wind_tech_counts = vcat(solar_wind_tech_counts_solar, solar_wind_tech_counts_wind)[:, [:category, :tech, :count]]
write_table(solar_wind_tech_counts, SCRIPT_STEM, "solar_wind_tech_counts")
markdown_table(solar_wind_tech_counts)

# ## Step 7 — annual mean pmax per generator
#
# This is a plain per-generator annual mean of the scheduled pmax series, unrelated to the capacity-factor denominator question addressed next.

solar_ids = Set(solar_gens.id_gen)
wind_ids = Set(wind_gens.id_gen)

sol_sched = gen_pmax[in.(gen_pmax.id_gen, Ref(solar_ids)), :]
wind_sched = gen_pmax[in.(gen_pmax.id_gen, Ref(wind_ids)), :]

sol_annual = combine(groupby(sol_sched, :id_gen), :value => mean => :mean_pmax)
sol_annual.tech .= "solar"
wind_annual = combine(groupby(wind_sched, :id_gen), :value => mean => :mean_pmax)
wind_annual.tech .= "wind"

annual_mean_pmax = vcat(sol_annual, wind_annual)[:, [:tech, :id_gen, :mean_pmax]]
write_table(annual_mean_pmax, SCRIPT_STEM, "annual_mean_pmax")
markdown_table(annual_mean_pmax)

# ## Step 8 — capacity factor duration curve
#
# Each generator's capacity factor is its scheduled mean output divided by its own scheduled maximum (see the caveat documented on `capacity_factor_duration_frame` above); generators are then ranked in descending capacity-factor order within each technology.

capacity_factor_duration = vcat(
    capacity_factor_duration_frame(gen_pmax, solar_gens, "solar"),
    capacity_factor_duration_frame(gen_pmax, wind_gens, "wind"),
)
write_table(capacity_factor_duration, SCRIPT_STEM, "capacity_factor_duration")
markdown_table(capacity_factor_duration)

# ## Step 9 — demand by area
#
# The demand schedule is joined to the static `Demand` table to obtain each demand node's bus, then to `Bus` to obtain its NEM area, before summing to a daily total per area. The full daily series (1825 rows: 5 NEM areas x 365 days) is written to `demand_by_area_daily.csv`; the table below summarises it per area.

dem_load_full = build_dem_load_full(dem_load, dem_df, bus_df)

dem_load_full.date_only = Date.(dem_load_full.datetime)
demand_by_area_daily = combine(groupby(dem_load_full, [:date_only, :area_name]), :value => sum => :total_demand_mw)
rename!(demand_by_area_daily, :date_only => :date)
write_table(demand_by_area_daily, SCRIPT_STEM, "demand_by_area_daily")

demand_by_area_summary = combine(
    groupby(demand_by_area_daily, :area_name),
    :total_demand_mw => mean => :mean_daily_mw,
    :total_demand_mw => minimum => :min_daily_mw,
    :total_demand_mw => maximum => :max_daily_mw,
)
markdown_table(demand_by_area_summary)

# ## Step 10 — daily solar, wind, and demand aggregates in GW
#
# Generator schedules are joined to generator technology before summing solar and wind pmax separately by day; the demand schedule's daily total, already joined above, is combined alongside them and converted from MW to GW. The full daily series (one row per calendar date) is written to `daily_solar_wind_demand_gw.csv`; the page displays only the first 10 rows as a representative sample.

gen_pmax_ts = build_gen_pmax_ts(gen_pmax, gen_df)

sol_daily = daily_tech_sum(gen_pmax_ts, is_solar_tech)
wind_daily = daily_tech_sum(gen_pmax_ts, is_wind_tech)
dem_daily_ts = combine(groupby(dem_load_full, :date_only), :value => sum => :total_demand)

daily_joined = innerjoin(
    innerjoin(sol_daily, wind_daily, on = :date_only, makeunique = true, renamecols = "_solar" => "_wind"),
    dem_daily_ts,
    on = :date_only,
)
sort!(daily_joined, :date_only)
daily_gw = DataFrame(
    date = daily_joined.date_only,
    solar_gw = daily_joined.total_solar ./ 1000,
    wind_gw = daily_joined.total_wind ./ 1000,
    demand_gw = daily_joined.total_demand ./ 1000,
)
write_table(daily_gw, SCRIPT_STEM, "daily_solar_wind_demand_gw")
markdown_table(first(daily_gw, 10))

# ## Step 11 — hourly pmax profile for the first 30 days
#
# Restricting to the first 30 scheduled days and grouping scheduled pmax by hour of day gives a representative diurnal shape for solar and wind generators. The full per-generator profile (792 rows) is written to `hourly_pmax_profile.csv`; the table below averages across generators within each technology to show the fleet-level diurnal shape, and Step 15 plots the per-generator profile for up to 5 generators of each technology.

cutoff30 = minimum(Date.(gen_pmax_ts.datetime)) + Day(29)
subset30 = gen_pmax_ts[Date.(gen_pmax_ts.datetime) .<= cutoff30, :]

sol_subset = subset30[is_solar_tech.(subset30.tech), :]
sol_subset = transform(sol_subset, :datetime => ByRow(hour) => :hour)
sol_profile = combine(groupby(sol_subset, [:id_gen, :hour]), :value => mean => :mean_pmax)
sol_profile.tech .= "solar"

wind_subset = subset30[is_wind_tech.(subset30.tech), :]
wind_subset = transform(wind_subset, :datetime => ByRow(hour) => :hour)
wind_profile = combine(groupby(wind_subset, [:id_gen, :hour]), :value => mean => :mean_pmax)
wind_profile.tech .= "wind"

hourly_pmax_profile = vcat(sol_profile, wind_profile)[:, [:tech, :id_gen, :hour, :mean_pmax]]
write_table(hourly_pmax_profile, SCRIPT_STEM, "hourly_pmax_profile")

hourly_pmax_profile_fleet_mean = combine(
    groupby(hourly_pmax_profile, [:tech, :hour]),
    :mean_pmax => mean => :fleet_mean_pmax,
)
markdown_table(hourly_pmax_profile_fleet_mean)

# ## Step 12 — VRE-vs-demand and demand-distribution summaries
#
# The first summary describes the scale and correlation of daily VRE (solar + wind) generation against daily demand; the second describes the distribution of daily demand alone.

vre_daily = daily_gw.solar_gw .+ daily_gw.wind_gw
demand_daily = daily_gw.demand_gw
vre_vs_demand_summary = DataFrame([(
    n_days = nrow(daily_gw),
    mean_demand_gw = mean(demand_daily),
    mean_vre_gw = mean(vre_daily),
    min_demand_gw = minimum(demand_daily),
    max_demand_gw = maximum(demand_daily),
    min_vre_gw = minimum(vre_daily),
    max_vre_gw = maximum(vre_daily),
    corr_demand_vre = cor(demand_daily, vre_daily),
)])
write_table(vre_vs_demand_summary, SCRIPT_STEM, "vre_vs_demand_summary")
markdown_table(vre_vs_demand_summary)

#-

demand_distribution_summary = DataFrame([(
    n = length(dem_daily_ts.total_demand),
    mean_mw = mean(dem_daily_ts.total_demand),
    std_mw = std(dem_daily_ts.total_demand),
    min_mw = minimum(dem_daily_ts.total_demand),
    max_mw = maximum(dem_daily_ts.total_demand),
    median_mw = median(dem_daily_ts.total_demand),
)])
write_table(demand_distribution_summary, SCRIPT_STEM, "demand_distribution_summary")
markdown_table(demand_distribution_summary)

# ## Step 13 — figure: PISP outputs overview
#
# A 2x2 overview: annual mean pmax per solar generator, annual mean pmax per wind generator, daily total demand by NEM area, and the capacity-factor duration curve for solar and wind. The per-generator pmax panels use horizontal-line scatter plots rather than `Plots.jl` bar charts, a plotting-library workaround with no effect on the underlying values.

sol_annual_sorted = sort(combine(groupby(sol_sched, :id_gen), :value => mean => :mean_pmax), :mean_pmax)
wind_annual_sorted = sort(combine(groupby(wind_sched, :id_gen), :value => mean => :mean_pmax), :mean_pmax)

p_sol_bar = scatter(sol_annual_sorted.mean_pmax, 1:nrow(sol_annual_sorted),
                    title="Solar Generators — Annual Mean pmax (MW)", xlabel="PMax (MW)", ylabel="",
                    legend=false, grid=true, gridalpha=0.3, markersize=0,
                    yticks=(1:nrow(sol_annual_sorted), string.(sol_annual_sorted.id_gen)))
for i in 1:nrow(sol_annual_sorted)
    plot!(p_sol_bar, [0, sol_annual_sorted.mean_pmax[i]], [i, i], color=:orange, alpha=0.7, label="")
end

p_wind_bar = scatter(wind_annual_sorted.mean_pmax, 1:nrow(wind_annual_sorted),
                     title="Wind Generators — Annual Mean pmax (MW)", xlabel="PMax (MW)", ylabel="",
                     legend=false, grid=true, gridalpha=0.3, markersize=0,
                     yticks=(1:nrow(wind_annual_sorted), string.(wind_annual_sorted.id_gen)))
for i in 1:nrow(wind_annual_sorted)
    plot!(p_wind_bar, [0, wind_annual_sorted.mean_pmax[i]], [i, i], color=:steelblue, alpha=0.7, label="")
end

area_map_plot = Dict(row.id_bus => row.id_area for row in eachrow(bus_df))
dem_load_full_plot = innerjoin(dem_load, dem_df[:, [:id_dem, :id_bus]], on = :id_dem)
dem_load_full_plot.datetime = parse_schedule_datetime.(dem_load_full_plot.date)
dem_load_full_plot.area = [area_map_plot[b] for b in dem_load_full_plot.id_bus]
dem_load_full_plot.area_name = [AREA_NAMES[a] for a in dem_load_full_plot.area]
dem_load_full_plot.date_only = Date.(dem_load_full_plot.datetime)
dem_daily_area = combine(groupby(dem_load_full_plot, [:date_only, :area_name]), :value => sum => :total_demand_mw)

p_demand = plot(title="Daily Total Demand (MW) by NEM Area", xlabel="Date", ylabel="Demand (MW)",
                legend=:topright, grid=true, gridalpha=0.3)
for area in sort(unique(dem_daily_area.area_name))
    area_data = filter(row -> row.area_name == area, dem_daily_area)
    plot!(p_demand, area_data.date_only, area_data.total_demand_mw, label=area, linewidth=1, alpha=0.7)
end

sol_cf_grouped = combine(groupby(sol_sched, :id_gen), :value => mean => :mean_val, :value => maximum => :max_val)
wind_cf_grouped = combine(groupby(wind_sched, :id_gen), :value => mean => :mean_val, :value => maximum => :max_val)

sol_cf_vals = Float64[]
for row in eachrow(sol_cf_grouped)
    cf = row.mean_val / row.max_val
    isnan(cf) || push!(sol_cf_vals, cf)
end
sol_cf_sorted = sort(sol_cf_vals; rev=true)

wind_cf_vals = Float64[]
for row in eachrow(wind_cf_grouped)
    cf = row.mean_val / row.max_val
    isnan(cf) || push!(wind_cf_vals, cf)
end
wind_cf_sorted = sort(wind_cf_vals; rev=true)

p_cf = plot(sol_cf_sorted, label="Solar CF", color=:orange, linewidth=1.5, alpha=0.7,
            title="Capacity Factor Duration Curve (2030)", xlabel="Generator Rank", ylabel="Capacity Factor",
            legend=:topright, grid=true, gridalpha=0.3)
plot!(p_cf, wind_cf_sorted, label="Wind CF", color=:steelblue, linewidth=1.5, alpha=0.7)

p_overview = plot(p_sol_bar, p_wind_bar, p_demand, p_cf, layout=(2,2), size=(1200, 1000), left_margin=8Plots.mm, top_margin=8Plots.mm)

savefig(p_overview, figure_path(SCRIPT_STEM, "06_pisp_outputs_overview.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "06_pisp_outputs_overview.png"), "06_pisp_outputs_overview.png")
nothing #hide

# ![PISP outputs overview: annual mean pmax by generator for solar and wind, daily demand by NEM area, and the solar/wind capacity-factor duration curve](06_pisp_outputs_overview.png)

# ## Step 14 — figure: solar and wind PMax versus total demand over time
#
# Daily solar PMax, wind PMax, and total demand, each summed across generators/nodes and expressed in GW, plotted over the full scheduled horizon.

gen_pmax_ts_plot = innerjoin(gen_pmax, gen_df[:, [:id_gen, :tech]], on = :id_gen)
gen_pmax_ts_plot.datetime = parse_schedule_datetime.(gen_pmax_ts_plot.date)
gen_pmax_ts_plot.date_only = Date.(gen_pmax_ts_plot.datetime)

sol_daily_ts = combine(groupby(gen_pmax_ts_plot[is_solar_tech.(gen_pmax_ts_plot.tech), :], :date_only), :value => sum => :total)
wind_daily_ts = combine(groupby(gen_pmax_ts_plot[is_wind_tech.(gen_pmax_ts_plot.tech), :], :date_only), :value => sum => :total)
dem_daily_ts_plot = combine(groupby(dem_load_full_plot, :date_only), :value => sum => :total_demand)

p_ts = plot(size=(1200, 600), title="2030 — Daily Aggregate: Solar PMax, Wind PMax, Total Demand",
           xlabel="Date", ylabel="GW", legend=:topright, grid=true, gridalpha=0.3, left_margin=8Plots.mm)
plot!(p_ts, sol_daily_ts.date_only, sol_daily_ts.total ./ 1000, label="Solar PMax (GW)", color=:orange, linewidth=1, alpha=0.7)
plot!(p_ts, wind_daily_ts.date_only, wind_daily_ts.total ./ 1000, label="Wind PMax (GW)", color=:steelblue, linewidth=1, alpha=0.7)
plot!(p_ts, dem_daily_ts_plot.date_only, dem_daily_ts_plot.total_demand ./ 1000, label="Total Demand (GW)", color=:grey, linewidth=1, alpha=0.7)

savefig(p_ts, figure_path(SCRIPT_STEM, "06_solar_wind_vs_demand_ts.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "06_solar_wind_vs_demand_ts.png"), "06_solar_wind_vs_demand_ts.png")
nothing #hide

# ![Daily solar PMax, wind PMax, and total demand over the scheduled horizon, each in GW](06_solar_wind_vs_demand_ts.png)

# ## Step 15 — figure: PISP detailed
#
# A second 2x2 detail view: hourly pmax profile (first 30 days) for up to 5 solar generators, the same for up to 5 wind generators, a VRE-vs-demand scatter with a 1:1 reference line, and the daily demand distribution histogram.

cutoff = minimum(Date.(gen_pmax_ts_plot.datetime)) + Day(29)
subset30_plot = filter(row -> Date(row.datetime) <= cutoff, gen_pmax_ts_plot)

sol_subset_plot = subset30_plot[is_solar_tech.(subset30_plot.tech), :]
sol_subset_plot = transform(sol_subset_plot, :datetime => ByRow(hour) => :hour)
sol_profile_plot = combine(groupby(sol_subset_plot, [:id_gen, :hour]), :value => mean => :mean_pmax)
sort!(sol_profile_plot, :id_gen)

wind_subset_plot = subset30_plot[is_wind_tech.(subset30_plot.tech), :]
wind_subset_plot = transform(wind_subset_plot, :datetime => ByRow(hour) => :hour)
wind_profile_plot = combine(groupby(wind_subset_plot, [:id_gen, :hour]), :value => mean => :mean_pmax)
sort!(wind_profile_plot, :id_gen)

p_detailed = plot(layout=(2,2), size=(1200, 1000), left_margin=8Plots.mm, top_margin=8Plots.mm)

top_sol_gens = unique(sol_profile_plot.id_gen)[1:min(5, length(unique(sol_profile_plot.id_gen)))]
for gid in top_sol_gens
    gdata = filter(row -> row.id_gen == gid, sol_profile_plot)
    plot!(p_detailed[1], gdata.hour, gdata.mean_pmax, label="Solar Gen $gid", linewidth=1.5)
end
plot!(p_detailed[1], title="Solar PMax: Hourly Profile (mean of first 30 days)", xlabel="Hour", ylabel="PMax (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

top_wind_gens = unique(wind_profile_plot.id_gen)[1:min(5, length(unique(wind_profile_plot.id_gen)))]
for gid in top_wind_gens
    gdata = filter(row -> row.id_gen == gid, wind_profile_plot)
    plot!(p_detailed[2], gdata.hour, gdata.mean_pmax, label="Wind Gen $gid", linewidth=1.5)
end
plot!(p_detailed[2], title="Wind PMax: Hourly Profile (mean of first 30 days)", xlabel="Hour", ylabel="PMax (MW)",
      legend=:topright, grid=true, gridalpha=0.3)

vre_scatter = daily_gw.solar_gw .+ daily_gw.wind_gw
scatter!(p_detailed[3], daily_gw.demand_gw, vre_scatter, markersize=2, alpha=0.3, color=:purple, label="", legend=false)
plot!(p_detailed[3], [0, maximum(daily_gw.demand_gw)], [0, maximum(daily_gw.demand_gw)],
      label="1:1", color=:black, linestyle=:dash, alpha=0.3, linewidth=1)
plot!(p_detailed[3], title="VRE Generation vs Total Demand (2030)", xlabel="Demand (GW)", ylabel="VRE Solar+Wind (GW)",
      grid=true, gridalpha=0.3, legend=false)

histogram!(p_detailed[4], dem_daily_ts_plot.total_demand, bins=50, alpha=0.6, color=:grey, legend=false)
plot!(p_detailed[4], title="Daily Total Demand Distribution (2030)", xlabel="Demand (MW)", ylabel="",
      grid=true, gridalpha=0.3, legend=false)

savefig(p_detailed, figure_path(SCRIPT_STEM, "06_pisp_detailed.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "06_pisp_detailed.png"), "06_pisp_detailed.png")
nothing #hide

# ![PISP detailed view: hourly pmax profiles for solar and wind generators, VRE-vs-demand scatter, and daily demand distribution](06_pisp_detailed.png)

# ## Summary
#
# - Static asset tables and 2030 schedule outputs join cleanly for this generated build, with identifier coverage and schedule time coverage recorded above and any unmatched identifiers listed in `unmatched_ids`.
# - Solar and wind generator classification, annual mean pmax, and capacity-factor duration curves are all computed live above, following the capacity-factor denominator convention documented on `capacity_factor_duration_frame`.
# - The three figures — outputs overview, solar/wind-vs-demand time series, and the detailed 2x2 view — are all built on this page from the same joined tables shown above.
# - This page writes its full evidence tables to `eda/tables/julia/06_pisp_outputs/*.csv`; four of them — `build_metadata`, `join_coverage`, `schedule_time_coverage`, and `unmatched_ids` — are this page's own diagnostics with no prior baseline to compare against.
