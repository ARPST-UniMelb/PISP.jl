# # ISP 2024: Parameters and mappings
#
# PISP uses package-defined identifiers and mappings to reconcile source files that do not share one canonical naming system. The tables below list the current scenario, bus, area, weather-year, and reliability-field mappings.

using PISP
using DataFrames
using Dates

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")

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
# The composite trace maps each financial-year interval to a historical reference year. Repeated historical years are part of the mapping and should be considered when comparing planning periods.
#
# AEMO explains the rolling-reference-year method in the [2024 ISP PLEXOS Model Instructions, p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5). The concrete sequence is in Table 1 of the [2024 ISP PLEXOS Model Instructions, p. 6](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=6). PISP stores the ending year of each report range: for example, AEMO's `2018-19` reference year is represented as `2019` for the interval from 1 July 2024 through 30 June 2025.
#
# The current implementation defines this mapping in `PISP.WEATHER_YEARS_ISP`; it does not parse the mapping from the 2024 Inputs and Assumptions workbook.

weather_year_mapping = DataFrame([
    (
        financial_year_start = Date(window[1]),
        financial_year_end = Date(window[2]),
        reference_year_ending = parse(Int, weather_year),
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
# Optional build-out technology labels select complete PISP generator or storage templates. See [ISP 2024 build-out defaults](buildout-defaults.md) for the field-level values, calculated fields, placeholders, and override rules.
#
# Rooftop PV and utility-scale renewable capacity fields require special care. The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator. See [Assumptions and scope](@ref).
#
# Both `gen_pmax_wind` and `gen_pmax_solar` ([`src/parsers/PISP-2024parser.jl`](https://github.com/ARPST-UniMelb/PISP.jl/blob/main/src/parsers/PISP-2024parser.jl)) read the same two sheets of the 2024 ISP Inputs and Assumptions workbook: `Existing Gen Data Summary` (cell range `B11:K297`) for the operating-capacity figures, and `Renewable Energy Zones` (cell range `B7:G50`) for REZ-to-bus assignment.
