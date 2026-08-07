# # ISP 2026: Source data
#
# ISP 2026 source material is organised across the inputs and assumptions
# workbook, the electric-vehicle workbook, generation and storage outlooks,
# scenario models, and trace collections.
# This reference lists the files, selections, keys, fields, and units used to
# describe those sources.

using DataFrames
using TOML

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))
include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const SOURCE_MAP_PATH = joinpath(REPO_ROOT, "docs", "config", "isp2026-source-specs.toml")
const SOURCE_MAP = TOML.parsefile(SOURCE_MAP_PATH)

lineage_ids = reduce(vcat, values(SOURCE_MAP["lineage"]))
length(lineage_ids) == 80 || error("the ISP 2026 source index must contain 80 entries")
length(unique(lineage_ids)) == 80 || error("the ISP 2026 source index must contain unique entries")

function source_name(id)
    name = titlecase(replace(replace(id, "isp2026-" => ""), "-" => " "))
    return replace(
        name,
        "Ev" => "EV",
        "Rez" => "REZ",
        "Dsp" => "DSP",
        "Dnsp" => "DNSP",
        "Pv" => "PV",
        "Cdp" => "CDP",
    )
end

source_rows = DataFrame(map(
    filter(source -> source["group"] != "Known source boundaries", SOURCE_MAP["source"]),
) do source
    (
        source = source_name(source["id"]),
        group = source["group"],
        path = source["path"],
        selection = source["selection"],
        keys = source["keys"],
        fields_units = source["fields_units"],
    )
end)

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
# The 2026 PLEXOS Model Instructions describe the scenario models and the
# demand, renewable-generation, gas, DNSP, seasonal-timeslice, and
# load-subtractor traces supplied with the release
# ([p. 5](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5) and [p. 7](../../../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7)).
# The tables below identify the file or pattern, the selected worksheet or
# folder, the keys, and the fields and units recorded for each source.

# ## Inputs and assumptions workbook
#
# The workbook covers generation, storage, reliability, retirement, network,
# renewable energy zones, hydro, demand-side participation, rooftop PV,
# data-centre demand, distribution networks, hybrid-site limits, and fuel and
# gas assumptions.

inputs_rows = filter(row -> row.group == "Inputs and assumptions workbook", source_rows)
reader_table(inputs_rows)
#-

# ## Electric-vehicle workbook
#
# The 2025 IASR EV workbook contains vehicle numbers, annual consumption,
# charging shares, and weekday and weekend charging profiles.

vehicle_rows = filter(row -> row.group == "2025 IASR EV workbook", source_rows)
reader_table(vehicle_rows)
#-

# ## Generation and storage outlook
#
# Core and sensitivity workbooks provide generation capacity, storage power,
# storage energy, renewable-energy-zone capacity, and development-path tables.
# `Available CDPs` includes `CDP4 (ODP)`, consistent with AEMO's identification
# of CDP 4 as the 2026 ODP ([2026 ISP Cost Benefit Analysis, p. 162](../../../../../data/2026/pisp-reports/a6-cost-benefit-analysis.pdf#page=162)).

outlook_rows = filter(row -> row.group == "Generation and storage outlook", source_rows)
reader_table(outlook_rows)
#-

# ## Model and trace files
#
# Scenario models and trace collections provide demand, DNSP, gas, hydro,
# load-subtractor, rooftop-PV, solar, wind, and reference-year time series.

trace_rows = filter(
    row -> row.group in ("Model trace folders", "Separate renewable trace archives"),
    source_rows,
)
reader_table(trace_rows)
#-

# ## Compare editions
#
# The [raw-source comparison](../../comparison/analyses/raw-source-comparison.md)
# compares worksheet selections, fields, units, and source-family changes.
# The [model archive comparison](../../comparison/analyses/model-archive-comparison.md)
# compares scenario directories, model files, and trace folders.
