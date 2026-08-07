# # ISP 2024: Source data
#
# ISP 2024 source material is organised across the inputs and assumptions
# workbook, the electric-vehicle workbook, generation and storage outlooks,
# scenario models, and trace collections.
# This reference lists the files, selections, keys, fields, and units used to
# describe those sources.

using DataFrames
using ParseISP

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const PROFILE = ParseISPDocUtils.edition_profile(REPO_ROOT, "2024")

function source_name(id)
    name = titlecase(replace(string(id), "_" => " "))
    return replace(
        name,
        "Ev" => "EV",
        "Rez" => "REZ",
        "Dsp" => "DSP",
        "Pv" => "PV",
    )
end

function source_group(row)
    workbook = row.workbook_or_pattern
    if row.source_format == "csv"
        return "Model and trace files"
    elseif occursin("2023-iasr-ev-workbook", workbook)
        return "Electric-vehicle workbook"
    elseif occursin("Core/", workbook)
        return "Generation and storage outlook"
    end
    return "Inputs and assumptions workbook"
end

function source_selection(row)
    row.source_format == "csv" && return row.workbook_or_pattern
    selection = isempty(row.cell_range) ? row.worksheet : "$(row.worksheet)!$(row.cell_range)"
    return selection
end

function fields_and_units(row)
    parts = String[]
    isempty(row.columns) || push!(parts, replace(row.columns, "; " => ", "))
    isempty(row.units) || push!(parts, replace(row.units, "; " => ", "))
    return isempty(parts) ? "See the named source selection" : join(parts, ". ")
end

source_rows = DataFrame([
    (
        source = source_name(row.id),
        group = source_group(row),
        path = row.workbook_or_pattern,
        selection = source_selection(row),
        keys = isempty(row.keys) ? "Defined by the selected table" : replace(row.keys, "; " => ", "),
        fields_units = fields_and_units(row),
    )
    for row in ParseISP.source_spec_rows(2024)
])

function reader_table(rows)
    table = select(
        rows,
        :source,
        [:path, :selection] => ByRow((path, selection) -> "$(path) — $(selection)") => :source_selection,
        :keys,
        :fields_units,
    )
    return ParseISPDocUtils.markdown_table(
        table;
        column_labels = ["Source", "File and selection", "Keys", "Fields and units"],
    )
end
nothing #hide

# ## How to read the tables
#
# The 2024 PLEXOS Model Instructions describe the scenario models and the
# demand, hydro, load-subtracter, solar, timeslice, and wind traces supplied
# with the release
# ([p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=7)).
# The tables below identify the file or pattern, the selected worksheet or
# folder, the keys, and the fields and units recorded for each source.

# ## Inputs and assumptions workbook
#
# The workbook covers generation, storage, reliability, retirement, network,
# renewable energy zones, hydro, demand-side participation, and supporting
# mappings.

inputs_rows = filter(row -> row.group == "Inputs and assumptions workbook", source_rows)
reader_table(inputs_rows)
#-

# ## Electric-vehicle workbook
#
# The 2023 IASR EV workbook contains vehicle numbers, charging shares, and
# weekday and weekend charging profiles.

vehicle_rows = filter(row -> row.group == "Electric-vehicle workbook", source_rows)
reader_table(vehicle_rows)
#-

# ## Generation and storage outlook
#
# Core outlook workbooks provide generation capacity, storage power, storage
# energy, and renewable-energy-zone capacity tables.

outlook_rows = filter(row -> row.group == "Generation and storage outlook", source_rows)
reader_table(outlook_rows)
#-

# ## Model and trace files
#
# Scenario models and trace collections provide demand, hydro, solar, wind,
# distributed-PV, and reference-year time series.

trace_rows = filter(row -> row.group == "Model and trace files", source_rows)
reader_table(trace_rows)
#-

# ## Compare editions
#
# The [raw-source comparison](../../comparison/analyses/raw-source-comparison.md)
# compares worksheet selections, fields, units, and source-family changes.
# The [model archive comparison](../../comparison/analyses/model-archive-comparison.md)
# compares scenario directories, model files, and trace folders.
