# # ISP 2024: Temperature-data coverage and climate-zone solar comparison
#
# Temperature can affect demand, renewable output, thermal ratings, and equipment reliability, but those effects are not automatically represented by a planning dataset. This page loads the 2024 ISP assumptions workbook, PISP's own 2024 ISP output files (`out-ref4006-poe10` schedule build), and 2019 climate-zone summer solar traces for selected climate-zone proxies, then builds the tables and figures that describe what temperature-related material is (and is not) present.
#
# No observed temperature time series is loaded, and no causal temperature-response model is estimated. Climate-zone comparisons are descriptive solar-trace comparisons, not direct measurements of thermal derating.

ENV["GKSwstype"] = "100"

using CSV
using DataFrames
using XLSX
using Printf
using Statistics
using Plots

gr();

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_05_temperature_analysis"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const TRACES = relpath(joinpath(ISP2024_PROFILE.download_root, "Traces"), REPO_ROOT)  # kept relative: this is the path form recorded in the tables below
const DOWNLOADS = relpath(ISP2024_PROFILE.download_root, REPO_ROOT)  # kept relative, same reason as TRACES
const OUTPUT_ROOT = ISP2024_PROFILE.output_root
OUTPUT_ROOT === nothing && error(
    "ISP 2024 profile does not define output_root; set PISP_DOCS_ISP2024_OUTPUT_ROOT to select a local output build.",
)
const SCHEDULE_TAG = ISP2024_PROFILE.schedule_tag
SCHEDULE_TAG === nothing && error(
    "ISP 2024 profile does not define schedule_tag; set PISP_DOCS_ISP2024_SCHEDULE_TAG to select a local schedule.",
)

abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a relative path above to an absolute file location for reading

const TEMP_KEYWORDS = ["temp", "heat", "thermal", "derate", "pv", "solar", "wind", "rooftop", "inverter"]
const HH_COLS_SOL = string.(1:48)
const CLIMATE_ZONES = [
    ("Hot_Inland", "Bomen_SAT"),
    ("Hot_SA", "Cultana_SAT"),
    ("Moderate_VIC", "Bannerton_SAT"),
    ("Cool_TAS", "Derby_SAT"),
]

is_keyword_match(name) = any(kw -> occursin(kw, lowercase(name)), TEMP_KEYWORDS)
is_rooftop_match(name) = occursin("rooftop", lowercase(name)) || occursin("rtpv", lowercase(name))
function is_reliability_match(name)
    lname = lowercase(name)
    return occursin("reliability", lname) || occursin("outage", lname) || occursin("generator", lname)
end
nothing #hide

# Trim a raw XLSX matrix down to the bounding box of non-missing cells. A worksheet's declared dimension (and hence XLSX.jl's `sheet[:]`) can report extra trailing all-empty rows/columns beyond the sheet's real content, so this drops trailing rows/columns that hold no value before reporting a sheet's shape. Verified against this workbook: e.g. "Rooftop PV" has a raw shape of (64, 35) but a trimmed shape of (62, 33) — rows 63-64 and columns 34-35 are entirely `missing`.
function trim_sheet(matrix)
    nrows, ncols = size(matrix)
    last_row = 0
    for r in 1:nrows
        if any(x -> x !== missing, view(matrix, r, :))
            last_row = r
        end
    end
    last_col = 0
    for c in 1:ncols
        if any(x -> x !== missing, view(matrix, :, c))
            last_col = c
        end
    end
    (last_row == 0 || last_col == 0) && return Matrix{Any}(undef, 0, 0)
    return matrix[1:last_row, 1:last_col]
end
nothing #hide

# A blank header cell gets a placeholder name using its 0-based column index.
function header_names(row)
    return [ismissing(v) ? "Unnamed: $(j - 1)" : string(v) for (j, v) in enumerate(row)]
end

function empty_df(schema::Vector{Pair{Symbol, DataType}})
    return DataFrame([name => Type[] for (name, Type) in schema]...)
end
nothing #hide

# ## Step 1 — inventory the ISP assumptions workbook's sheets
#
# The workbook lists all its worksheets; a keyword match identifies material for review, it does not by itself prove that a sheet contains a usable temperature dependency.

workbook_path = joinpath(DOWNLOADS, "2024-isp-inputs-and-assumptions-workbook.xlsx")
println("Workbook exists: ", isfile(abs_path(workbook_path)))

sheet_inventory_rows = NamedTuple[]
relevant_shape_rows = NamedTuple[]
rooftop_rows = NamedTuple[]
reliability_shape_rows = NamedTuple[]

if isfile(abs_path(workbook_path))
    XLSX.openxlsx(abs_path(workbook_path)) do xf
        sheet_names = XLSX.sheetnames(xf)
        println("\n=== ISP Assumptions Workbook Sheets ($(length(sheet_names))) ===")
        for (i, name) in enumerate(sheet_names)
            println(@sprintf("  %2d. %s", i, name))
        end

        println("\n=== Potentially Relevant Sheets ===")
        for name in sheet_names
            is_keyword_match(name) && println("  - ", name)
        end

        for (i, name) in enumerate(sheet_names)
            push!(
                sheet_inventory_rows,
                (
                    sheet_index = i,
                    sheet_name = name,
                    is_keyword_match = is_keyword_match(name) ? 1 : 0,
                    is_rooftop_match = is_rooftop_match(name) ? 1 : 0,
                    is_reliability_match = is_reliability_match(name) ? 1 : 0,
                ),
            )
        end

        relevant_sheets = [name for name in sheet_names if is_keyword_match(name)]

        for sheet in first(relevant_sheets, min(10, length(relevant_sheets)))
            m = trim_sheet(xf[sheet][:])
            n_rows, n_cols = size(m)
            println("\n--- Sheet: $sheet (shape: ($n_rows, $n_cols)) ---")
            push!(relevant_shape_rows, (sheet_name = sheet, n_rows = n_rows, n_cols = n_cols, read_ok = 1))
        end

        for sheet in sheet_names
            if is_rooftop_match(sheet)
                m = trim_sheet(xf[sheet][:])
                total_rows, n_cols = size(m)
                n_rows = max(total_rows - 1, 0)
                cols = total_rows > 0 ? header_names(m[1, :]) : String[]
                println("\n=== Rooftop PV Sheet ($sheet) ===")
                println("Columns: ", cols)
                push!(
                    rooftop_rows,
                    (
                        sheet_name = sheet,
                        n_rows = n_rows,
                        n_cols = n_cols,
                        columns_preview = join(cols[1:min(5, length(cols))], "|"),
                    ),
                )
            end
        end

        for sheet in sheet_names
            if is_reliability_match(sheet)
                m = trim_sheet(xf[sheet][:])
                n_rows, n_cols = size(m)
                println("\n=== Reliability Sheet: $sheet (shape: ($n_rows, $n_cols)) ===")
                push!(reliability_shape_rows, (sheet_name = sheet, n_rows = n_rows, n_cols = n_cols))
            end
        end
    end
end

workbook_sheet_inventory = isempty(sheet_inventory_rows) ?
    empty_df([:sheet_index => Int, :sheet_name => String, :is_keyword_match => Int, :is_rooftop_match => Int, :is_reliability_match => Int]) :
    DataFrame(sheet_inventory_rows)
write_table(workbook_sheet_inventory, SCRIPT_STEM, "workbook_sheet_inventory")
markdown_table(workbook_sheet_inventory)

#-

workbook_relevant_sheet_shapes = isempty(relevant_shape_rows) ?
    empty_df([:sheet_name => String, :n_rows => Int, :n_cols => Int, :read_ok => Int]) :
    DataFrame(relevant_shape_rows)
write_table(workbook_relevant_sheet_shapes, SCRIPT_STEM, "workbook_relevant_sheet_shapes")
markdown_table(workbook_relevant_sheet_shapes)

#-

workbook_rooftop_sheet_summary = isempty(rooftop_rows) ?
    empty_df([:sheet_name => String, :n_rows => Int, :n_cols => Int, :columns_preview => String]) :
    DataFrame(rooftop_rows)
write_table(workbook_rooftop_sheet_summary, SCRIPT_STEM, "workbook_rooftop_sheet_summary")
markdown_table(workbook_rooftop_sheet_summary)

#-

workbook_reliability_sheet_shapes = isempty(reliability_shape_rows) ?
    empty_df([:sheet_name => String, :n_rows => Int, :n_cols => Int]) :
    DataFrame(reliability_shape_rows)
write_table(workbook_reliability_sheet_shapes, SCRIPT_STEM, "workbook_reliability_sheet_shapes")
markdown_table(workbook_reliability_sheet_shapes)

# ## Step 2 — which temperature-related fields reach the PISP output dataset?
#
# The output inventory and generator-column table distinguish information present in the downloaded workbook from fields actually exported by PISP.

csv_dir = relpath(OUTPUT_ROOT, REPO_ROOT)
sched_dir = relpath(dirname(OUTPUT_ROOT), REPO_ROOT)

output_inventory_rows = NamedTuple[]
println("\n=== PISP Output Files ===")
if isdir(abs_path(csv_dir))
    for name in sort(filter(n -> endswith(lowercase(n), ".csv"), readdir(abs_path(csv_dir))))
        println("  CSV: ", name)
        push!(output_inventory_rows, (kind = "csv", name = name))
    end
end

if isdir(abs_path(sched_dir))
    for name in sort(filter(n -> startswith(n, "schedule-"), readdir(abs_path(sched_dir))))
        if isdir(abs_path(joinpath(sched_dir, name)))
            println("  Schedule: ", name)
            push!(output_inventory_rows, (kind = "schedule", name = name))
        end
    end
end

pisp_output_inventory = isempty(output_inventory_rows) ? empty_df([:kind => String, :name => String]) : DataFrame(output_inventory_rows)
write_table(pisp_output_inventory, SCRIPT_STEM, "pisp_output_inventory")
markdown_table(pisp_output_inventory)

#-

gen_path = joinpath(csv_dir, "Generator.csv")
generator_details_rows = NamedTuple[]
generator_temp_row = (generator_table_exists = 0, total_columns = missing, n_temp_columns = missing, temp_columns_list = "")

if isfile(abs_path(gen_path))
    gen_df = CSV.read(abs_path(gen_path), DataFrame)
    println("\n=== Generator Table (shape: $(size(gen_df))) ===")
    println("Columns: ", names(gen_df))

    is_solar(tech) = occursin(r"PV|SOLAR|DISTPV"i, tech)
    is_wind(tech) = occursin(r"WIND"i, tech)
    solar_gens = filter(row -> is_solar(row.tech), gen_df)
    wind_gens = filter(row -> is_wind(row.tech), gen_df)

    println("\nSolar generators: ", nrow(solar_gens))
    println("\nWind generators: ", nrow(wind_gens))

    for (category, subset) in (("solar", solar_gens), ("wind", wind_gens))
        for row in eachrow(subset)
            push!(
                generator_details_rows,
                (
                    category = category,
                    id_gen = row.id_gen,
                    name = row.name,
                    tech = row.tech,
                    forate = row.forate,
                    derate = row.derate,
                    pmin = row.pmin,
                    pmax = row.pmax,
                    n = row.n,
                ),
            )
        end
    end

    temp_cols = [col for col in names(gen_df) if any(kw -> occursin(kw, lowercase(col)), ["temp", "heat", "thermal"])]
    println("\nTemperature-related columns in Generator: ", temp_cols)
    generator_temp_row = (
        generator_table_exists = 1,
        total_columns = ncol(gen_df),
        n_temp_columns = length(temp_cols),
        temp_columns_list = join(temp_cols, "|"),
    )
end

generator_solar_wind_details = isempty(generator_details_rows) ?
    empty_df([:category => String, :id_gen => Int, :name => String, :tech => String, :forate => Float64, :derate => Float64, :pmin => Float64, :pmax => Float64, :n => Int]) :
    DataFrame(generator_details_rows)
write_table(generator_solar_wind_details, SCRIPT_STEM, "generator_solar_wind_details")
markdown_table(generator_solar_wind_details)

#-

generator_temperature_columns = DataFrame([generator_temp_row])
write_table(generator_temperature_columns, SCRIPT_STEM, "generator_temperature_columns")
markdown_table(generator_temperature_columns)

# ## Step 3 — how do selected climate-zone solar traces differ in summer?
#
# The zone labels are analytical groupings attached to representative sites. The summary describes summer solar capacity-factor distributions and does not isolate temperature from cloud, season, geography, or trace construction.

zone_summary_rows = NamedTuple[]
println("\n=== Solar CF by Climate Zone (Summer 2019) ===")
for (zone, loc) in CLIMATE_ZONES
    f = joinpath(TRACES, "solar_2019", "$(loc)_RefYear2019.csv")
    isfile(abs_path(f)) || continue
    df = CSV.read(abs_path(f), DataFrame)
    summer = filter(row -> row.Month in (12, 1, 2), df)
    nrow(summer) == 0 && continue

    daily = [mean(row[col] for col in HH_COLS_SOL) for row in eachrow(summer)]
    midday_cols = string.(24:35)
    midday = [mean(row[col] for col in midday_cols) for row in eachrow(summer)]

    mean_daily = mean(daily)
    mean_midday = mean(midday)
    min_midday = minimum(midday)
    p5_midday = quantile(midday, 0.05)

    println(
        @sprintf(
            "  %s (%s): mean_daily=%.3f, mean_midday=%.3f, min_midday=%.3f, p5_midday=%.3f",
            zone, loc, mean_daily, mean_midday, min_midday, p5_midday,
        ),
    )

    push!(
        zone_summary_rows,
        (
            zone = zone,
            location = loc,
            n_summer_days = nrow(summer),
            mean_daily_cf = mean_daily,
            mean_midday_cf = mean_midday,
            min_midday_cf = min_midday,
            p5_midday_cf = p5_midday,
        ),
    )
end

climate_zone_summer_cf_summary = isempty(zone_summary_rows) ?
    empty_df([:zone => String, :location => String, :n_summer_days => Int, :mean_daily_cf => Float64, :mean_midday_cf => Float64, :min_midday_cf => Float64, :p5_midday_cf => Float64]) :
    DataFrame(zone_summary_rows)
write_table(climate_zone_summer_cf_summary, SCRIPT_STEM, "climate_zone_summer_cf_summary")
markdown_table(climate_zone_summer_cf_summary)

# ## Step 4 — plot the summer daily capacity-factor distribution by climate zone
#
# Each climate zone's summer daily-mean capacity factor is drawn as an overlaid density histogram, showing how much the four representative sites overlap or diverge.

p1 = plot(legend=:topright, title="Summer 2019 — Daily Solar CF Distribution by Climate Zone",
          xlabel="Daily Mean Capacity Factor", ylabel="Density", size=(800, 600))
for (zone, loc) in CLIMATE_ZONES
    f = joinpath(TRACES, "solar_2019", "$(loc)_RefYear2019.csv")
    isfile(abs_path(f)) || continue
    df = CSV.read(abs_path(f), DataFrame)
    summer = filter(row -> row.Month in (12, 1, 2), df)
    nrow(summer) == 0 && continue
    daily = [mean(row[col] for col in HH_COLS_SOL) for row in eachrow(summer)]
    histogram!(p1, daily, bins=50, alpha=0.5, label="$(zone) ($(loc))", normalize=:pdf)
end
savefig(p1, figure_path(SCRIPT_STEM, "05_cf_by_climate_zone.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "05_cf_by_climate_zone.png"), "05_cf_by_climate_zone.png")
nothing #hide

# ![Summer daily solar capacity-factor distribution by climate zone](05_cf_by_climate_zone.png)

# ## Step 5 — plot midday capacity factor against daily mean capacity factor
#
# For each climate zone, midday-mean capacity factor is plotted against daily-mean capacity factor for every summer day, with a 1:1 reference line showing how far midday output sits above the daily average.

p2 = plot(layout=(2,2), figsize=(14,10), size=(1000, 800))
for (idx, (zone, loc)) in enumerate(CLIMATE_ZONES)
    f = joinpath(TRACES, "solar_2019", "$(loc)_RefYear2019.csv")
    isfile(abs_path(f)) || continue
    df = CSV.read(abs_path(f), DataFrame)
    summer = filter(row -> row.Month in (12, 1, 2), df)
    nrow(summer) == 0 && continue
    daily = [mean(row[col] for col in HH_COLS_SOL) for row in eachrow(summer)]
    midday = [mean(row[col] for col in string.(24:35)) for row in eachrow(summer)]
    scatter!(p2[idx], daily, midday, markersize=2, alpha=0.3, color=:orange, label="", legend=false)
    plot!(p2[idx], [0, 0.5], [0, 0.5], label="1:1", color=:black, linestyle=:dash, alpha=0.3, linewidth=1)
    plot!(p2[idx], title="$(zone) ($(loc))", xlabel="Daily Mean CF", ylabel="Midday Mean CF",
          xlim=(0, 0.5), ylim=(0, 0.8), grid=true, gridstyle=:dash, gridalpha=0.3)
end
savefig(p2, figure_path(SCRIPT_STEM, "05_midday_vs_daily_scatter.png"))
EdaSupport.embed_figure(figure_path(SCRIPT_STEM, "05_midday_vs_daily_scatter.png"), "05_midday_vs_daily_scatter.png")
nothing #hide

# ![Midday capacity factor against daily mean capacity factor by climate zone](05_midday_vs_daily_scatter.png)

# ## Summary
#
# - The ISP assumptions workbook and PISP's own output files contain some temperature-, derating-, and reliability-adjacent fields, but a keyword match only flags material for review, it does not establish a usable temperature dependency.
# - No observed temperature series is loaded here; the climate-zone comparison is a descriptive summer solar-trace comparison across four representative sites, not a measurement of thermal derating.
