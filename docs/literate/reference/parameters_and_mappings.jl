# # Parameters and mappings
#
# PISP uses package-defined identifiers and mappings to reconcile source files that do not share one canonical naming system. The tables below list the current scenario, bus, area, weather-year, and reliability-field mappings.

using PISP
using DataFrames
using Dates

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
scenario_mappings

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
bus_area_mappings

# ## Reference trace 4006 weather-year mapping
#
# The composite trace maps each financial-year interval to a historical weather year. Repeated historical years are part of the mapping and should be considered when comparing planning periods.

weather_year_mapping = DataFrame([
    (
        financial_year_start = Date(window[1]),
        financial_year_end = Date(window[2]),
        weather_year = parse(Int, weather_year),
    )
    for (window, weather_year) in PISP.WEATHER_YEARS_ISP
])
sort!(weather_year_mapping, :financial_year_start)
weather_year_mapping

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
reliability_schema

# ## Using the mappings
#
# Scenario labels, source-specific aliases, bus assignments, weather-year mappings, technology groupings, retirement schedules, and build-out templates are modelling inputs rather than incidental filenames. Changes to these mappings can change generated datasets without any change to the downloaded source files.
#
# Rooftop PV and utility-scale renewable capacity fields require special care. The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator. See [Assumptions and scope](@ref).
