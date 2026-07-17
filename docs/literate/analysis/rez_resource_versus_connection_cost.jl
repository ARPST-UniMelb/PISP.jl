# # REZ resource potential versus connection cost
#
# This analysis asks whether Renewable Energy Zones (REZs) with larger workbook-derived resource potential also have higher expected connection cost, or whether resource potential and connection cost are effectively separate dimensions.
#
# The evidence comes from the AEMO 2024 ISP Inputs and Assumptions workbook at `data/2024/pisp-downloads/2024-isp-inputs-and-assumptions-workbook.xlsx`.
# The workbook sheets named most naturally for the question are not directly joinable: `Renewable Energy Zones` identifies REZ geography without numeric resource limits, while `REZ Costs forecast` gives named cost trajectories without REZ-level capacity figures.
# The evidence therefore uses `Build limits` for `total_resource_limit_mw` and `REZ Augmentations Options` for the primary option's `expected_cost_million`, joined by REZ identifier and name, all computed live on this page.
#
# No AEMO report-PDF page citation is currently verified for this specific workbook-derived join, so this page cites only the local workbook-derived evidence.

using CSV
using DataFrames
using XLSX
using Printf
using Statistics

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

EdaSupport.snapshot_metadata_line(REPO_ROOT; context = "2024 ISP Inputs and Assumptions workbook, Build limits + REZ Augmentations Options")

const SCRIPT_STEM = "11_rez_resource_vs_cost"
const DOWNLOADS = joinpath("data", "2024", "pisp-downloads")  # kept relative: this is the path form recorded below
const IASR_WORKBOOK = joinpath(DOWNLOADS, "2024-isp-inputs-and-assumptions-workbook.xlsx")
abs_path(relative_path) = joinpath(REPO_ROOT, relative_path)  # resolves a DOWNLOADS-relative path to an absolute location for reading

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

as_float(x::Missing) = missing
as_float(x::Real) = Float64(x)
nothing #hide

# A handful of "Build limits" cells hold text rather than a bare number: "-" (no value; confirmed against the sheet's own dash convention elsewhere) and "5696 (Note 14)" (N11's offshore-floating limit, with the sheet's own inline footnote reference kept in the cell). The footnote itself (row 65: "Values shown are as per modelled. If updated to the recently declared area ... values would change to 0 MW fixed capacity, and 4,452 MW floating capacity.") is a caveat about a boundary redeclaration, not a reason to distrust the modelled number -- so this uses the modelled 5696 MW figure and keeps the footnote text out of the parsed value.
function as_float(x::AbstractString)
    stripped = strip(x)
    stripped == "-" && return missing
    m = match(r"^-?[\d,]+\.?\d*", stripped)
    m === nothing && return missing
    return parse(Float64, replace(m.match, "," => ""))
end
nothing #hide

# "Build limits" sheet: two-row merged header (row 6 group labels, row 7 wind sub-labels), one row per REZ from row 8 to the last REZ row (before the "Notes" section). REZs with onshore wind data have High/Medium (MW) populated and Offshore columns missing, and vice versa for the two offshore-only REZs (S10, T4) -- confirmed by direct inspection.
function load_rez_resource_limits(matrix)
    rows = NamedTuple[]
    nrows = size(matrix, 1)
    for r in 8:nrows
        rez_id = matrix[r, 2]
        rez_id === missing && break  # "Notes" section starts once REZ ID runs out
        rez_id == "Notes" && break
        push!(
            rows,
            (
                rez_id = String(rez_id),
                rez_name = matrix[r, 3] === missing ? missing : String(matrix[r, 3]),
                region = matrix[r, 4] === missing ? missing : String(matrix[r, 4]),
                wind_high_mw = as_float(matrix[r, 7]),
                wind_medium_mw = as_float(matrix[r, 8]),
                wind_offshore_fixed_mw = as_float(matrix[r, 9]),
                wind_offshore_floating_mw = as_float(matrix[r, 10]),
                solar_mw = as_float(matrix[r, 11]),
            ),
        )
    end
    df = DataFrame(rows)
    ## A single wind-resource figure per REZ: onshore REZs use the more permissive of the two onshore land-use assumptions (Medium, always >= High in this sheet); the two offshore-only REZs (S10, T4) have High/Medium at 0 and carry their resource in the offshore columns instead, so those are added in (they are mutually exclusive with onshore in every row observed).
    df.wind_resource_mw = [
        coalesce(row.wind_medium_mw, 0.0) +
        coalesce(row.wind_offshore_fixed_mw, 0.0) +
        coalesce(row.wind_offshore_floating_mw, 0.0) for row in eachrow(df)
    ]
    df.total_resource_limit_mw = df.wind_resource_mw .+ [coalesce(v, 0.0) for v in df.solar_mw]
    return df
end
nothing #hide

# "REZ Augmentations Options" sheet: repeated region sub-header rows (bare region name, e.g. "QLD", with every other column missing) interleaved with REZ blocks. A genuine data row is any row where the Option column (6) is not missing; REZ ID/Name are only populated on an option's first row and must be forward-filled for that REZ's later options (e.g. Q1's "Option 2" row carries no REZ ID/Name of its own).
function load_rez_augmentation_options(matrix)
    rows = NamedTuple[]
    nrows = size(matrix, 1)
    current_id = missing
    current_name = missing
    for r in 12:nrows
        option = matrix[r, 4]
        option === missing && continue  # region sub-header or blank row
        option == "Option" && continue  # the header row repeats before every region block
        if matrix[r, 2] !== missing
            current_id = String(matrix[r, 2])
            current_name = matrix[r, 3] === missing ? missing : String(matrix[r, 3])
        end
        current_id === missing && continue
        push!(
            rows,
            (
                rez_id = current_id,
                rez_name = current_name,
                option = String(option),
                additional_capacity_mw = as_float(matrix[r, 6]),
                expected_cost_million = as_float(matrix[r, 7]),
                dollar_million_per_mw = as_float(matrix[r, 10]),
            ),
        )
    end
    return DataFrame(rows)
end
nothing #hide

# One representative option per REZ: the first-listed option in sheet order (typically labelled "Option 1"), the foundational augmentation that later options build on. Excludes any REZ whose first-listed option has no numeric capacity or cost of its own -- most such exclusions are a bare cross-reference to a shared subregional/group-constraint augmentation (e.g. "See NQ-CQ subregional augmentations"), but a few are a literal "Option 1" whose capacity/cost cells are themselves blank or non-numeric in the sheet.
function primary_option_per_rez(augmentation_options)
    rows = NamedTuple[]
    excluded = NamedTuple[]
    for key_df in groupby(augmentation_options, :rez_id)
        first_row = first(key_df)
        if first_row.additional_capacity_mw === missing || first_row.expected_cost_million === missing
            push!(excluded, (rez_id = first_row.rez_id, rez_name = first_row.rez_name, option = first_row.option))
            continue
        end
        push!(
            rows,
            (
                rez_id = first_row.rez_id,
                rez_name = first_row.rez_name,
                primary_option = first_row.option,
                additional_capacity_mw = first_row.additional_capacity_mw,
                expected_cost_million = first_row.expected_cost_million,
                dollar_million_per_mw = first_row.dollar_million_per_mw,
            ),
        )
    end
    return DataFrame(rows), DataFrame(excluded)
end

function pearson_correlation(x, y)
    n = length(x)
    mx, my = mean(x), mean(y)
    cov_xy = sum((x .- mx) .* (y .- my)) / (n - 1)
    sx, sy = std(x), std(y)
    return cov_xy / (sx * sy)
end

function rounded_columns(frame, columns; digits = 3)
    copy_frame = copy(frame)
    for column in columns
        copy_frame[!, column] = round.(copy_frame[!, column]; digits = digits)
    end
    return copy_frame
end
nothing #hide

# ## Step 1 — load and trim the "Build limits" and "REZ Augmentations Options" sheets

println("Workbook exists: ", isfile(abs_path(IASR_WORKBOOK)))
isfile(abs_path(IASR_WORKBOOK)) || error("IASR workbook not found at $IASR_WORKBOOK")

resource_matrix, augmentation_matrix = XLSX.openxlsx(abs_path(IASR_WORKBOOK)) do xf
    trim_sheet(xf["Build limits"][:]), trim_sheet(xf["REZ Augmentations Options"][:])
end
nothing #hide

# ## Step 2 — resource limits and augmentation options per REZ

resource_limits = load_rez_resource_limits(resource_matrix)
write_table(resource_limits, SCRIPT_STEM, "rez_resource_limits")
println("REZ resource-limit rows (Build limits sheet): ", nrow(resource_limits))
markdown_table(first(resource_limits, 8))

#-

augmentation_options = load_rez_augmentation_options(augmentation_matrix)
write_table(augmentation_options, SCRIPT_STEM, "rez_augmentation_options")
println("REZ augmentation-option rows (REZ Augmentations Options sheet): ", nrow(augmentation_options))
markdown_table(first(augmentation_options, 8))

# ## Step 3 — primary option per REZ and the resource-vs-cost join

primary_options, excluded = primary_option_per_rez(augmentation_options)
write_table(excluded, SCRIPT_STEM, "rez_augmentation_excluded")
println("REZs with a usable primary (first-listed) option: ", nrow(primary_options))
println("REZs excluded (first-listed option has no standalone numeric capacity/cost -- a cross-reference to a shared augmentation, or a named option with blank/non-numeric figures): ", nrow(excluded))
markdown_table(excluded)

#-

joined = innerjoin(resource_limits, primary_options, on = [:rez_id, :rez_name])
joined_row_count = nrow(joined)
write_table(joined, SCRIPT_STEM, "rez_resource_vs_cost")
println("Joined REZs (resource limit + primary augmentation option): ", joined_row_count)
markdown_table(first(joined, 8))

# ## Step 4 — zero-resource exclusion, correlation, and cost-efficiency ranking
#
# One REZ (N12, Illawarra) carries a genuine 0 MW total resource limit in this workbook (both wind and solar limits are 0) -- a real modelled value, not a parsing artifact, confirmed by direct inspection of the sheet. It is excluded from the correlation and cost-per-MW ranking (undefined/infinite ratio) and reported separately rather than dropped silently.

zero_resource_rez = filter(:total_resource_limit_mw => iszero, joined)
zero_resource_exclusion_count = nrow(zero_resource_rez)
zero_resource_exclusion_count > 0 && write_table(zero_resource_rez, SCRIPT_STEM, "rez_zero_resource_limit_excluded")
joined = filter(:total_resource_limit_mw => (v -> v > 0), joined)
markdown_table(zero_resource_rez[:, [:rez_id, :rez_name, :total_resource_limit_mw, :expected_cost_million]])

#-

correlation = pearson_correlation(joined.total_resource_limit_mw, joined.expected_cost_million)
correlation_summary = DataFrame(
    method = ["Pearson correlation"],
    coefficient = [correlation],
    usable_row_count = [nrow(joined)],
    zero_resource_exclusion_count = [zero_resource_exclusion_count],
    joined_row_count = [joined_row_count],
    source_column_x = ["total_resource_limit_mw"],
    source_column_y = ["expected_cost_million"],
)
write_table(correlation_summary, SCRIPT_STEM, "rez_resource_cost_correlation_summary")
markdown_table(correlation_summary)

#-

joined.cost_per_resource_mw = joined.expected_cost_million ./ joined.total_resource_limit_mw
ranking = sort(joined, :cost_per_resource_mw)
ranking = select(ranking, [:rez_id, :rez_name, :total_resource_limit_mw, :expected_cost_million, :dollar_million_per_mw, :cost_per_resource_mw])
write_table(ranking, SCRIPT_STEM, "rez_cost_efficiency_ranking")
nrow(ranking)

# Lowest cost per MW of workbook-derived resource potential:

markdown_table(first(rounded_columns(ranking, [:cost_per_resource_mw]; digits = 4), 6))

# Highest cost per MW of workbook-derived resource potential:

markdown_table(last(rounded_columns(ranking, [:cost_per_resource_mw]; digits = 4), 6))

# ## Interpreting the evidence

coefficient = only(correlation_summary.coefficient)
usable_rows = only(correlation_summary.usable_row_count)
joined_rows = only(correlation_summary.joined_row_count)
zero_exclusions = only(correlation_summary.zero_resource_exclusion_count)
most_cost_efficient = first(ranking)
least_cost_efficient = last(ranking)
largest_expected_cost = ranking[argmax(ranking.expected_cost_million), :]

@printf(
    "Pearson coefficient %.3f from %d usable rows (%d joined rows, %d zero-resource exclusion).\n",
    coefficient,
    usable_rows,
    joined_rows,
    zero_exclusions,
)
@printf(
    "Largest expected cost: %s (%s), \$%.0fM.\n",
    largest_expected_cost.rez_id,
    largest_expected_cost.rez_name,
    largest_expected_cost.expected_cost_million,
)
@printf(
    "Most cost-efficient: %s (%s), %.4f \$M per MW of resource.\n",
    most_cost_efficient.rez_id,
    most_cost_efficient.rez_name,
    most_cost_efficient.cost_per_resource_mw,
)
@printf(
    "Least cost-efficient: %s (%s), %.4f \$M per MW of resource.\n",
    least_cost_efficient.rez_id,
    least_cost_efficient.rez_name,
    least_cost_efficient.cost_per_resource_mw,
)

# A Pearson coefficient of 0.016 across 22 usable REZ rows is effectively zero for this workbook-derived join: the REZs with the highest resource potential do not also tend to have the highest primary-option expected connection cost.
# The join contains 23 rows before ratio/correlation filtering, and N12 (Illawarra) is the single excluded zero-resource row; it remains visible in the evidence because its `0 MW` resource limit is part of the workbook-derived data and makes a finite cost-per-resource ratio undefined.
# N4 (Broken Hill) has the largest expected cost at \$5,098M, while T4 (North Tasmania Coast) is the most cost-efficient joined REZ at about \$0.0051M per MW of resource.
# N8 (Cooma-Monaro) is the least cost-efficient joined REZ at \$1.0100M per MW of resource.
#
# The main limitation is source structure: this is not a direct join between `Renewable Energy Zones` and `REZ Costs forecast`, because those sheets do not contain the numeric fields needed for the question.
# The result should therefore be interpreted as a workbook-derived comparison between REZ resource limits and first-listed standalone augmentation-option cost, not as a complete cost-benefit assessment of every possible augmentation pathway.
