# # Parameters and mappings
#
# PISP uses package-defined identifiers and mappings to reconcile source files that do not share one canonical naming system. The tables below list the current scenario, bus, area, weather-year, and reliability-field mappings.

using PISP
using DataFrames
using Dates

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport

# ## Scenario identifiers and source labels

scenario_mappings = DataFrame([
    (
        scenario_id = scenario_id,
        scenario_name = scenario_name,
        hydro_label = PISP.HYDROSCE[scenario_name],
        demand_trace_label = PISP.DEMSCE[scenario_name],
    )
    for (scenario_id, scenario_name) in PISP.ID2SCE
])
markdown_table(scenario_mappings)

# ## Bus and area constants

bus_aliases = collect(keys(PISP.NEMBUSNAME))
bus_area_mappings = DataFrame([
    (
        bus_id = index,
        alias = alias,
        name = PISP.NEMBUSNAME[alias],
        area = PISP.BUS2AREA[alias],
        area_id = PISP.STID[PISP.BUS2AREA[alias]],
        latitude = PISP.NEMBUSES[alias][1],
        longitude = PISP.NEMBUSES[alias][2],
    )
    for (index, alias) in enumerate(bus_aliases)
])
markdown_table(bus_area_mappings)

# ## Reference trace 4006 weather-year mapping
#
# The composite trace maps each financial-year interval to a historical weather year. Repeated historical years are part of the mapping and should be considered when comparing planning periods.
#
# The mapping is based on AEMO's 2024 ISP PLEXOS model instructions (https://aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en), the same document `PISP.WEATHER_YEARS_ISP`'s own source comment cites in `src/parameters/general2024ISP.jl`. The specific page or table within that document has not yet been identified; this page traces the mapping to that source comment and the table below, not to a page number in AEMO's document.

weather_year_mapping = DataFrame([
    (
        financial_year_start = Date(window[1]),
        financial_year_end = Date(window[2]),
        weather_year = parse(Int, weather_year),
    )
    for (window, weather_year) in PISP.WEATHER_YEARS_ISP
])
sort!(weather_year_mapping, :financial_year_start)
markdown_table(weather_year_mapping)

# ## Reliability fields represented in static schemas

function reliability_fields(table_name)
    schema = PISP.TABLES_POWERSYSTEM[table_name]
    names = [
        column
        for column in keys(schema)
        if occursin(r"forate|out|derate|mttr"i, column)
    ]
    return join(names, ", ")
end

reliability_schema = DataFrame([
    (asset_table = table_name, fields = reliability_fields(table_name))
    for table_name in ("Generator", "ESS", "Line")
])
markdown_table(reliability_schema)

# ## Using the mappings
#
# Scenario labels, source-specific aliases, bus assignments, weather-year mappings, technology groupings, retirement schedules, and build-out templates are modelling inputs rather than incidental filenames. Changes to these mappings can change generated datasets without any change to the downloaded source files.
#
# Rooftop PV and utility-scale renewable capacity fields require special care. The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator. See [Assumptions and scope](@ref).
#
# Both `gen_pmax_wind` and `gen_pmax_solar` (`src/parsers/PISP-2024parser.jl`) read the same two sheets of the 2024 ISP Inputs and Assumptions workbook: `Existing Gen Data Summary` (cell range `B11:K297`) for the operating-capacity figures, and `Renewable Energy Zones` (cell range `B7:G50`) for REZ-to-bus assignment.
