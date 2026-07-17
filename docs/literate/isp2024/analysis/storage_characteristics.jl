# # ISP 2024: PHES and battery storage characteristics
#
# This analysis asks what storage-duration, efficiency, and build-limit information is actually available for battery storage and pumped hydro energy storage (PHES) in the IASR workbook's "Storage properties" and "Build limits - PHES" sheets, and where those two storage classes are not directly comparable.
#
# The evidence comes from the AEMO 2024 ISP Inputs and Assumptions workbook at `data/2024/pisp-downloads/2024-isp-inputs-and-assumptions-workbook.xlsx`, computed live on this page.
# The workbook gives battery round-trip efficiency directly, but the PHES block gives only "Pumping efficiency" -- not round-trip efficiency. "BOTN - Cethana" in "Build limits - PHES" is a named option column, not a duration class like the 8hrs/24hrs/48hrs columns.
#
# No AEMO report-PDF page citation is currently verified for this question, so this page cites only the local workbook-derived evidence.

using CSV
using DataFrames
using Printf
using XLSX

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

const SCRIPT_STEM = "isp2024_12_storage_characteristics"
const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")
const DOWNLOADS = relpath(ISP2024_PROFILE.download_root, REPO_ROOT)  # kept relative: this is the path form recorded below
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

source_string(x::Missing) = ""
source_string(x) = string(x)

function numeric_or_missing(x)
    x === missing && return missing
    x isa Real && return Float64(x)
    s = strip(string(x))
    isempty(s) && return missing
    lowercase(s) == "not applicable" && return missing
    m = match(r"^-?[\d,]+\.?\d*", s)
    m === nothing && return missing
    return parse(Float64, replace(m.match, "," => ""))
end

function property_row_lookup(matrix, row_range, property_label)
    for r in row_range
        matrix[r, 2] === property_label && return r
    end
    error("Could not locate property row \"$property_label\"")
end

function battery_properties(storage_matrix)
    tech_cols = 3:7
    unit_col = 8
    property_rows = Dict(
        "Maximum power1" => property_row_lookup(storage_matrix, 5:13, "Maximum power1"),
        "Energy capacity2" => property_row_lookup(storage_matrix, 5:13, "Energy capacity2"),
        "Round trip efficiency (aggregated)3" => property_row_lookup(storage_matrix, 5:13, "Round trip efficiency (aggregated)3"),
        "Charge efficiency (utility)" => property_row_lookup(storage_matrix, 5:13, "Charge efficiency (utility)"),
        "Discharge efficiency (utility)" => property_row_lookup(storage_matrix, 5:13, "Discharge efficiency (utility)"),
        "Round trip efficiency (utility)" => property_row_lookup(storage_matrix, 5:13, "Round trip efficiency (utility)"),
        "Annual degradation (utility)" => property_row_lookup(storage_matrix, 5:13, "Annual degradation (utility)"),
        "Allowable max state of charge" => property_row_lookup(storage_matrix, 5:13, "Allowable max state of charge"),
        "Allowable min state of charge" => property_row_lookup(storage_matrix, 5:13, "Allowable min state of charge"),
    )

    rows = NamedTuple[]
    for c in tech_cols
        technology = String(storage_matrix[4, c])
        max_power = numeric_or_missing(storage_matrix[property_rows["Maximum power1"], c])
        energy_capacity = numeric_or_missing(storage_matrix[property_rows["Energy capacity2"], c])
        duration = (max_power === missing || energy_capacity === missing || max_power == 0) ? missing : energy_capacity / max_power
        push!(
            rows,
            (
                technology_label = technology,
                maximum_power_source_value = source_string(storage_matrix[property_rows["Maximum power1"], c]),
                maximum_power_units = source_string(storage_matrix[property_rows["Maximum power1"], unit_col]),
                energy_capacity_source_value = source_string(storage_matrix[property_rows["Energy capacity2"], c]),
                energy_capacity_units = source_string(storage_matrix[property_rows["Energy capacity2"], unit_col]),
                duration_hours_from_energy_to_power = duration,
                round_trip_efficiency_aggregated_source_value = source_string(storage_matrix[property_rows["Round trip efficiency (aggregated)3"], c]),
                round_trip_efficiency_aggregated_pct = numeric_or_missing(storage_matrix[property_rows["Round trip efficiency (aggregated)3"], c]),
                charge_efficiency_utility_source_value = source_string(storage_matrix[property_rows["Charge efficiency (utility)"], c]),
                charge_efficiency_utility_pct = numeric_or_missing(storage_matrix[property_rows["Charge efficiency (utility)"], c]),
                discharge_efficiency_utility_source_value = source_string(storage_matrix[property_rows["Discharge efficiency (utility)"], c]),
                discharge_efficiency_utility_pct = numeric_or_missing(storage_matrix[property_rows["Discharge efficiency (utility)"], c]),
                round_trip_efficiency_utility_source_value = source_string(storage_matrix[property_rows["Round trip efficiency (utility)"], c]),
                round_trip_efficiency_utility_pct = numeric_or_missing(storage_matrix[property_rows["Round trip efficiency (utility)"], c]),
                annual_degradation_utility_pct = numeric_or_missing(storage_matrix[property_rows["Annual degradation (utility)"], c]),
                allowable_max_state_of_charge_pct = numeric_or_missing(storage_matrix[property_rows["Allowable max state of charge"], c]),
                allowable_min_state_of_charge_pct = numeric_or_missing(storage_matrix[property_rows["Allowable min state of charge"], c]),
                buildable_capacity_status = "unavailable in general Build limits sheet",
            ),
        )
    end
    return DataFrame(rows)
end

function generation_and_pump_capacity(value)
    value === missing && return (missing, missing)
    value isa Real && return (Float64(value), missing)
    s = string(value)
    gen_match = match(r"([\d,]+\.?\d*)\s*\(generation\)", s)
    pump_match = match(r"([\d,]+\.?\d*)\s*\(pump\)", s)
    if gen_match !== nothing || pump_match !== nothing
        gen = gen_match === nothing ? missing : parse(Float64, replace(gen_match.captures[1], "," => ""))
        pump = pump_match === nothing ? missing : parse(Float64, replace(pump_match.captures[1], "," => ""))
        return (gen, pump)
    end
    return (numeric_or_missing(value), missing)
end

function phes_scheme_properties(storage_matrix)
    scheme_cols = 3:10
    installed_row = property_row_lookup(storage_matrix, 24:26, "Installed capacity3")
    storage_row = property_row_lookup(storage_matrix, 24:26, "Storage capacity")
    pumping_row = property_row_lookup(storage_matrix, 24:26, "Pumping efficiency")
    unit_col = 11

    rows = NamedTuple[]
    for c in scheme_cols
        scheme = storage_matrix[23, c]
        scheme === missing && continue
        generation_mw, pump_mw = generation_and_pump_capacity(storage_matrix[installed_row, c])
        storage_value = numeric_or_missing(storage_matrix[storage_row, c])
        storage_units = source_string(storage_matrix[storage_row, unit_col])
        duration = lowercase(storage_units) == "hours" ? storage_value : missing
        derivation = lowercase(storage_units) == "hours" ?
            "source storage-capacity row is already in hours; no MWh/MW conversion applied" :
            "duration not derived because storage-capacity units are not hours and no compatible energy/power pair is available"
        push!(
            rows,
            (
                scheme_label = String(scheme),
                installed_capacity_source_value = source_string(storage_matrix[installed_row, c]),
                installed_generation_capacity_mw = generation_mw,
                installed_pump_capacity_mw = pump_mw,
                storage_capacity_source_value = source_string(storage_matrix[storage_row, c]),
                storage_capacity_units = storage_units,
                duration_hours = duration,
                duration_derivation_method = derivation,
                pumping_efficiency_source_value = source_string(storage_matrix[pumping_row, c]),
                pumping_efficiency_pct = numeric_or_missing(storage_matrix[pumping_row, c]),
                round_trip_efficiency_status = "unavailable in inspected Storage properties source; Pumping efficiency is not round-trip efficiency",
            ),
        )
    end
    return DataFrame(rows)
end

function phes_build_limits(build_matrix)
    rows = NamedTuple[]
    for r in 10:size(build_matrix, 1)
        name = build_matrix[r, 2]
        name === missing && break
        name == "Notes:" && break
        push!(
            rows,
            (
                name = String(name),
                isp_subregion = source_string(build_matrix[r, 3]),
                region = source_string(build_matrix[r, 4]),
                phes_8hrs_storage_mw = numeric_or_missing(build_matrix[r, 5]),
                phes_24hrs_storage_mw = numeric_or_missing(build_matrix[r, 6]),
                phes_48hrs_storage_mw = numeric_or_missing(build_matrix[r, 7]),
                botn_cethana_mw = numeric_or_missing(build_matrix[r, 8]),
                botn_cethana_category_kind = "named/scheme-specific column, not a duration class",
            ),
        )
    end
    return DataFrame(rows)
end

function comparison_summary(battery_df, phes_df, build_limits_df)
    utility_rte = collect(skipmissing(battery_df.round_trip_efficiency_utility_pct))
    agg_rte = collect(skipmissing(battery_df.round_trip_efficiency_aggregated_pct))
    battery_durations = collect(skipmissing(battery_df.duration_hours_from_energy_to_power))
    phes_durations = collect(skipmissing(phes_df.duration_hours))
    phes_buildable_total = sum(coalesce.(build_limits_df.phes_8hrs_storage_mw, 0.0)) +
        sum(coalesce.(build_limits_df.phes_24hrs_storage_mw, 0.0)) +
        sum(coalesce.(build_limits_df.phes_48hrs_storage_mw, 0.0)) +
        sum(coalesce.(build_limits_df.botn_cethana_mw, 0.0))

    rows = [
        (
            storage_class = "Battery storage (utility)",
            source_basis = "Storage properties: Battery properties",
            duration_basis = "Energy capacity divided by Maximum power; technology labels already encode 1hr/2hrs/4hrs/8hrs storage",
            duration_range_hours = @sprintf("%.1f-%.1f", minimum(battery_durations[1:4]), maximum(battery_durations[1:4])),
            round_trip_efficiency_status = @sprintf("available as Round trip efficiency (utility): %.0f-%.0f%%", minimum(utility_rte), maximum(utility_rte)),
            pumping_efficiency_status = "not applicable to battery rows",
            buildable_capacity_status = "unavailable: general Build limits has no battery buildable-capacity field",
            headline_note = "Battery characteristics are technology-property assumptions, not regional build limits.",
        ),
        (
            storage_class = "Virtual Power Plants (aggregated ESS)",
            source_basis = "Storage properties: Battery properties",
            duration_basis = "Energy capacity divided by Maximum power for the aggregated ESS row",
            duration_range_hours = @sprintf("%.1f", battery_durations[end]),
            round_trip_efficiency_status = isempty(agg_rte) ? "unavailable" : @sprintf("available as Round trip efficiency (aggregated): %.0f%%", first(agg_rte)),
            pumping_efficiency_status = "not applicable to battery rows",
            buildable_capacity_status = "unavailable: general Build limits has no battery buildable-capacity field",
            headline_note = "The aggregated ESS row has aggregated RTE while utility battery rows have utility RTE.",
        ),
        (
            storage_class = "Pumped Hydro Energy Storage schemes",
            source_basis = "Storage properties: Pumped hydro properties",
            duration_basis = "Storage capacity row is in hours in the inspected source; no MWh/MW conversion applied",
            duration_range_hours = @sprintf("%.1f-%.1f", minimum(phes_durations), maximum(phes_durations)),
            round_trip_efficiency_status = "unavailable: inspected source gives Pumping efficiency only, not round-trip efficiency",
            pumping_efficiency_status = @sprintf("available as Pumping efficiency: %.0f-%.0f%%", minimum(skipmissing(phes_df.pumping_efficiency_pct)), maximum(skipmissing(phes_df.pumping_efficiency_pct))),
            buildable_capacity_status = @sprintf("available for PHES only in Build limits - PHES: %.0f MW total across 8hr/24hr/48hr plus BOTN - Cethana", phes_buildable_total),
            headline_note = "PHES scheme properties and PHES subregional build limits are separate keyed tables and are not force-joined.",
        ),
        (
            storage_class = "BOTN - Cethana",
            source_basis = "Build limits - PHES",
            duration_basis = "Named/scheme-specific build-limit column; not treated as a duration class",
            duration_range_hours = "not a duration-class column",
            round_trip_efficiency_status = "unavailable in inspected source",
            pumping_efficiency_status = "Cethana has Pumping efficiency in Storage properties, but that is not round-trip efficiency",
            buildable_capacity_status = @sprintf("available as named column: %.0f MW", sum(coalesce.(build_limits_df.botn_cethana_mw, 0.0))),
            headline_note = "BOTN - Cethana is retained separately from 8hrs/24hrs/48hrs PHES categories.",
        ),
    ]
    return DataFrame(rows)
end

function phes_concentration(build_limits_df)
    total_8 = sum(coalesce.(build_limits_df.phes_8hrs_storage_mw, 0.0))
    total_24 = sum(coalesce.(build_limits_df.phes_24hrs_storage_mw, 0.0))
    total_48 = sum(coalesce.(build_limits_df.phes_48hrs_storage_mw, 0.0))
    total_botn = sum(coalesce.(build_limits_df.botn_cethana_mw, 0.0))
    grand_total = total_8 + total_24 + total_48 + total_botn

    rows = NamedTuple[]
    for (category, kind, total) in [
        ("8hrs storage", "duration class", total_8),
        ("24hrs storage", "duration class", total_24),
        ("48hrs storage", "duration class", total_48),
        ("BOTN - Cethana", "named/scheme-specific column", total_botn),
    ]
        push!(
            rows,
            (
                concentration_axis = "category",
                label = category,
                region = "",
                isp_subregion = "",
                category_kind = kind,
                phes_8hrs_storage_mw = category == "8hrs storage" ? total : 0.0,
                phes_24hrs_storage_mw = category == "24hrs storage" ? total : 0.0,
                phes_48hrs_storage_mw = category == "48hrs storage" ? total : 0.0,
                botn_cethana_mw = category == "BOTN - Cethana" ? total : 0.0,
                total_phes_build_limit_mw = total,
                share_of_total_phes_build_limit_pct = grand_total == 0 ? missing : total / grand_total * 100,
            ),
        )
    end

    for row in eachrow(build_limits_df)
        subtotal = coalesce(row.phes_8hrs_storage_mw, 0.0) + coalesce(row.phes_24hrs_storage_mw, 0.0) + coalesce(row.phes_48hrs_storage_mw, 0.0) + coalesce(row.botn_cethana_mw, 0.0)
        push!(
            rows,
            (
                concentration_axis = "isp_subregion",
                label = row.name,
                region = row.region,
                isp_subregion = row.isp_subregion,
                category_kind = "subregional total across duration classes plus named BOTN - Cethana column",
                phes_8hrs_storage_mw = coalesce(row.phes_8hrs_storage_mw, 0.0),
                phes_24hrs_storage_mw = coalesce(row.phes_24hrs_storage_mw, 0.0),
                phes_48hrs_storage_mw = coalesce(row.phes_48hrs_storage_mw, 0.0),
                botn_cethana_mw = coalesce(row.botn_cethana_mw, 0.0),
                total_phes_build_limit_mw = subtotal,
                share_of_total_phes_build_limit_pct = grand_total == 0 ? missing : subtotal / grand_total * 100,
            ),
        )
    end
    return sort(DataFrame(rows), [:concentration_axis, order(:total_phes_build_limit_mw, rev = true), :label])
end
nothing #hide

# ## Step 1 — load and trim the "Storage properties" and "Build limits - PHES" sheets

println("Workbook exists: ", isfile(abs_path(IASR_WORKBOOK)))
isfile(abs_path(IASR_WORKBOOK)) || error("IASR workbook not found at $IASR_WORKBOOK")

storage_matrix, phes_limit_matrix = XLSX.openxlsx(abs_path(IASR_WORKBOOK)) do xf
    trim_sheet(xf["Storage properties"][:]), trim_sheet(xf["Build limits - PHES"][:])
end
println("Trimmed \"Storage properties\" sheet shape: ", size(storage_matrix))
println("Trimmed \"Build limits - PHES\" sheet shape: ", size(phes_limit_matrix))
nothing #hide

# ## Step 2 — battery and PHES scheme properties

battery_df = battery_properties(storage_matrix)
write_table(battery_df, SCRIPT_STEM, "battery_properties")
markdown_table(battery_df)

#-

phes_scheme_df = phes_scheme_properties(storage_matrix)
write_table(phes_scheme_df, SCRIPT_STEM, "phes_scheme_properties")
markdown_table(phes_scheme_df)

# ## Step 3 — PHES regional build limits

phes_limits_df = phes_build_limits(phes_limit_matrix)
write_table(phes_limits_df, SCRIPT_STEM, "phes_build_limits")
markdown_table(phes_limits_df)

# ## Step 4 — storage-class comparison summary

comparison_df = comparison_summary(battery_df, phes_scheme_df, phes_limits_df)
write_table(comparison_df, SCRIPT_STEM, "storage_class_availability_summary")
markdown_table(comparison_df)

# ## Step 5 — regional and category concentration of PHES build limits

concentration_df = phes_concentration(phes_limits_df)
write_table(concentration_df, SCRIPT_STEM, "phes_regional_category_concentration")
markdown_table(concentration_df)

# ## Interpreting the evidence

total_phes_build_limit = sum(coalesce.(phes_limits_df.phes_8hrs_storage_mw, 0.0)) +
    sum(coalesce.(phes_limits_df.phes_24hrs_storage_mw, 0.0)) +
    sum(coalesce.(phes_limits_df.phes_48hrs_storage_mw, 0.0)) +
    sum(coalesce.(phes_limits_df.botn_cethana_mw, 0.0))
category_rows = filter(:concentration_axis => ==("category"), concentration_df)
subregion_rows = filter(:concentration_axis => ==("isp_subregion"), concentration_df)
top_category = first(category_rows)
top_subregion = first(subregion_rows)

@printf("Battery rows: %d; PHES scheme rows: %d; PHES build-limit rows: %d\n", nrow(battery_df), nrow(phes_scheme_df), nrow(phes_limits_df))
@printf("Total PHES build limit: %.0f MW\n", total_phes_build_limit)
@printf("Largest PHES category: %s (%.0f MW, %.1f%% of total)\n", top_category.label, top_category.total_phes_build_limit_mw, top_category.share_of_total_phes_build_limit_pct)
@printf("Largest PHES ISP sub-region: %s/%s (%.0f MW, %.1f%% of total)\n", top_subregion.region, top_subregion.isp_subregion, top_subregion.total_phes_build_limit_mw, top_subregion.share_of_total_phes_build_limit_pct)
println("PHES round-trip efficiency: unavailable in inspected source; pumping efficiency is reported separately.")
println("Battery buildable capacity: unavailable in general Build limits; not fabricated.")

# Battery storage and PHES are not directly comparable on every axis: batteries carry a directly reported round-trip efficiency while PHES schemes report only pumping efficiency, and only PHES has a subregional buildable-capacity figure in the general Build limits sheet -- battery buildable capacity is unavailable there and is not fabricated above.
# "BOTN - Cethana" is a named, scheme-specific build-limit column and is kept separate from the 8hrs/24hrs/48hrs PHES duration classes rather than folded into them.
