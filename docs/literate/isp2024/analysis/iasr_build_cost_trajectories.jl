# # ISP 2024: IASR build-cost trajectories by technology
#
# This analysis asks how projected capital costs for the main VRE and storage technologies (utility-scale solar, onshore/offshore wind, battery storage) evolve across the projection years in the IASR "Build costs" sheet, and whether the annualized rate of cost decline differs materially by technology.
#
# The evidence comes from the AEMO 2024 ISP Inputs and Assumptions workbook at `data/2024/pisp-downloads/2024-isp-inputs-and-assumptions-workbook.xlsx`, sheet `Build costs`, computed live on this page.
#
# No AEMO report-PDF page citation is currently verified for this question, so this page cites only the local workbook-derived evidence.

using CSV
using DataFrames
using XLSX
using Printf
using Statistics

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_10_build_cost_trajectories"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const DOWNLOADS = relpath(ISP2024_PROFILE.download_root, REPO_ROOT)  # kept relative: this is the path form recorded below
const IASR_WORKBOOK = joinpath(DOWNLOADS, "2024-isp-inputs-and-assumptions-workbook.xlsx")
const SHEET_NAME = "Build costs"
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a DOWNLOADS-relative path to an absolute location for reading
nothing #hide

# Trim a raw XLSX matrix down to the bounding box of non-missing cells: this workbook's declared sheet dimension carries trailing all-missing rows/columns beyond its real content (this sheet reports max_row 1191 but its last populated row is 223).
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

# The sheet keyword-matches "utility-scale solar" to Large scale Solar PV only (not Solar Thermal, a distinct CSP technology), "onshore/offshore wind" to all 3 Wind rows, and "battery storage" to all 4 duration variants. Pumped hydro/BOTN rows are excluded here: they are pumped-hydro storage, the subject of the separate PHES-versus-battery storage characteristics page.
const TARGET_KEYWORDS = ["solar pv", "wind", "battery storage"]

is_target_technology(tech) = any(kw -> occursin(kw, lowercase(tech)), TARGET_KEYWORDS)
nothing #hide

# The sheet lays out one "Build cost by technology (\$/kW)" master table: a header row ("Technology", "Scenario", then one column per financial year), followed by 19 technologies x 6 scenarios in 6-row blocks, each block preceded by a repeated copy of the same header row and followed by a blank separator row. This locates that header by literal content rather than a hardcoded row number, since earlier rows on the sheet hold unrelated GenCost-scenario-mapping tables with their own, differently-shaped blocks.
function find_master_header_row(matrix)
    nrows = size(matrix, 1)
    for r in 1:nrows
        if isequal(matrix[r, 2], "Technology") && isequal(matrix[r, 3], "Scenario")
            return r
        end
    end
    error("Could not locate the \"Build cost by technology\" master header row in sheet \"$SHEET_NAME\"")
end

function year_columns(matrix, header_row)
    ncols = size(matrix, 2)
    years = String[]
    col_indices = Int[]
    for c in 4:ncols
        label = matrix[header_row, c]
        label === missing && continue
        push!(years, string(label))
        push!(col_indices, c)
    end
    return years, col_indices
end

function build_cost_long_table(matrix, header_row, years, col_indices)
    rows = NamedTuple[]
    nrows = size(matrix, 1)
    for r in (header_row + 1):nrows
        tech = matrix[r, 2]
        scenario = matrix[r, 3]
        (tech === missing || scenario === missing) && continue
        tech == "Technology" && continue  # repeated mini-header before each block
        for (year, c) in zip(years, col_indices)
            value = matrix[r, c]
            push!(
                rows,
                (
                    technology = String(tech),
                    scenario = String(scenario),
                    year = year,
                    cost_dollar_per_kw = value === missing ? missing : Float64(value),
                ),
            )
        end
    end
    return DataFrame(rows)
end
nothing #hide

# Per (technology, scenario): first/last available projection year and cost, the annualized (CAGR-style) decline rate between them, and the total percentage change -- directly answers whether the rate of decline differs materially by technology.
function decline_summary(long_table)
    rows = NamedTuple[]
    for key_df in groupby(long_table, [:technology, :scenario])
        complete = filter(:cost_dollar_per_kw => !ismissing, key_df)
        nrow(complete) < 2 && continue
        complete = sort(complete, :year)  # "YYYY-YY" financial-year labels sort correctly as strings
        first_row = first(complete)
        last_row = last(complete)
        n_years = nrow(complete) - 1
        first_cost = first_row.cost_dollar_per_kw
        last_cost = last_row.cost_dollar_per_kw
        cagr_pct = first_cost > 0 ? ((last_cost / first_cost)^(1 / n_years) - 1) * 100 : missing
        total_pct_change = first_cost > 0 ? (last_cost - first_cost) / first_cost * 100 : missing
        push!(
            rows,
            (
                technology = first_row.technology,
                scenario = first_row.scenario,
                first_year = first_row.year,
                last_year = last_row.year,
                first_cost_dollar_per_kw = first_cost,
                last_cost_dollar_per_kw = last_cost,
                annualized_decline_rate_pct = cagr_pct,
                total_pct_change_pct = total_pct_change,
            ),
        )
    end
    return DataFrame(rows)
end
nothing #hide

# ## Step 1 — load and trim the "Build costs" sheet

println("Workbook exists: ", isfile(abs_path(IASR_WORKBOOK)))
isfile(abs_path(IASR_WORKBOOK)) || error("IASR workbook not found at $IASR_WORKBOOK")

matrix = XLSX.openxlsx(abs_path(IASR_WORKBOOK)) do xf
    trim_sheet(xf[SHEET_NAME][:])
end
println("Trimmed \"$SHEET_NAME\" sheet shape: ", size(matrix))
nothing #hide

# ## Step 2 — locate the master build-cost table and its projection years

header_row = find_master_header_row(matrix)
years, col_indices = year_columns(matrix, header_row)
println("Master table header at row $header_row, ", length(years), " projection years: ", first(years), " .. ", last(years))
nothing #hide

# ## Step 3 — long-format build-cost table and target-technology filter
#
# All 19 technologies on the sheet are listed in `technology_match` for transparency; the analysis itself only follows the utility-scale solar, onshore/offshore wind, and battery-storage rows matched by `is_target_technology`. The full long-format target table (technology x scenario x year) is written as evidence; the table below previews only its first rows.

long_table = build_cost_long_table(matrix, header_row, years, col_indices)
all_technologies = unique(long_table.technology)
println("Technologies found (", length(all_technologies), "): ", join(all_technologies, ", "))

matched_technologies = filter(is_target_technology, all_technologies)
println("Target (solar/wind/battery) technologies matched (", length(matched_technologies), "): ", join(matched_technologies, ", "))

technology_match = DataFrame(
    technology = all_technologies,
    is_target_technology = [is_target_technology(t) ? 1 : 0 for t in all_technologies],
)
write_table(technology_match, SCRIPT_STEM, "technology_match")
markdown_table(technology_match)

#-

target_long = filter(:technology => is_target_technology, long_table)
write_table(target_long, SCRIPT_STEM, "build_cost_trajectory")
println("Target-technology long-format rows written as evidence: ", nrow(target_long))
markdown_table(first(target_long, 8))

# ## Step 4 — annualized decline rate by technology and scenario

decline = decline_summary(target_long)
decline = sort(decline, :annualized_decline_rate_pct)
write_table(decline, SCRIPT_STEM, "build_cost_decline_summary")
markdown_table(decline)

# ## Interpreting the evidence
#
# Every matched technology's build cost falls in every scenario, but the annualized decline rate spans roughly a 5.5x range across technologies and scenarios -- from about -0.78%/yr (Wind - offshore (fixed), GenCost Current Policies / Progressive Change) to about -4.30%/yr (Battery storage 8hrs storage, GenCost Global NZE by 2050 / Green Energy Exports).
# The fastest-declining technology is itself scenario-dependent, not fixed: in the two lower-decarbonization scenarios (GenCost Current Policies, Progressive Change), Large scale Solar PV declines fastest, ahead of every battery duration, with Wind - offshore (fixed) slowest; in the four higher-decarbonization scenarios (Global NZE post 2050, Global NZE by 2050, Green Energy Exports, Step Change), the longer-duration battery storage technologies decline fastest instead, with onshore Wind alone slowest in all four.
# So yes, the rate of cost decline differs materially by technology, but which technology declines fastest (and slowest) is a function of the decarbonization scenario assumed, not a single fixed ranking -- see `build_cost_decline_summary` above for the exact figures behind this claim.
