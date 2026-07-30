```@meta
EditURL = "../../../../literate/isp2024/reference/parameters_and_mappings.jl"
```

# ISP 2024: Parameters and mappings

PISP uses package-defined identifiers and mappings to reconcile source files that do not share one canonical naming system. The tables below list the current scenario, bus, area, weather-year, and reliability-field mappings.
They focus on mappings with identified parser or builder roles, not an inventory of every constant in the package's parameter files.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames
using Dates

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "edition_profiles.jl"))
using .PISPDocsEditionProfiles

const ISP2024_PROFILE = edition_profile(REPO_ROOT, "2024")

include(joinpath(REPO_ROOT, "docs", "eda_support.jl"))
using .EdaSupport
````

```@raw html
</details>
```

## Scenario identifiers and source labels

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

| **scenario\_id** | **scenario\_name** | **hydro\_label** | **demand\_trace\_label** |
|--:|:--|:--|:--|
| 1 | Progressive Change | NetZero2050 | PROGRESSIVE\_CHANGE |
| 2 | Step Change | StepChange | STEP\_CHANGE |
| 3 | Green Energy Exports | HydrogenSuperpower | HYDROGEN\_EXPORT |


The problem-table and build-out paths iterate `PISP.ID2SCE` to create rows for the package's three scenario IDs. The hydro parser uses `PISP.HYDROSCE` to select PLEXOS hydro labels, while the 4006 demand builder uses `PISP.DEMSCE` in source and output filenames. These mappings therefore affect generated data rather than serving only as display labels.

## Bus and area constants

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

| **bus\_id** | **alias** | **name** | **area** | **area\_id** | **latitude** | **longitude** |
|--:|:--|:--|:--|--:|--:|--:|
| 1 | NQ | Northern Queensland | QLD | 1 | -17.7938 | 145.564 |
| 2 | CQ | Central Queensland | QLD | 1 | -22.8242 | 149.404 |
| 3 | GG | Gladstone Grid | QLD | 1 | -23.8429 | 151.249 |
| 4 | SQ | Southern Queensland | QLD | 1 | -27.4766 | 153.03 |
| 5 | NNSW | Northern New South Wales | NSW | 2 | -30.5047 | 151.652 |
| 6 | CNSW | Central New South Wales | NSW | 2 | -33.4833 | 150.158 |
| 7 | SNW | Sydney, Newcastle & Wollongong | NSW | 2 | -33.865 | 151.209 |
| 8 | SNSW | Southern New South Wales | NSW | 2 | -35.111 | 147.36 |
| 9 | VIC | Victoria | VIC | 3 | -37.7661 | 144.943 |
| 10 | TAS | Tasmania | TAS | 4 | -42.8806 | 147.325 |
| 11 | CSA | Central South Australia | SA | 5 | -34.8027 | 138.522 |
| 12 | SESA | South East South Australia | SA | 5 | -37.6047 | 140.837 |


## Reference trace 4006 weather-year mapping

The composite trace maps each financial-year interval to a historical reference year. Repeated historical years are part of the mapping and should be considered when comparing planning periods.

AEMO explains the rolling-reference-year method in the [2024 ISP PLEXOS Model Instructions, p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5). The Reference Year and VRE Reference Year sequence is in Table 1 of the [2024 ISP PLEXOS Model Instructions, p. 6](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=6); the table's Hydrological Reference Year is a distinct sequence. PISP stores the ending year of each report range: for example, AEMO's `2018-19` reference year is represented as `2019` for the interval from 1 July 2024 through 30 June 2025.

The 4006 solar, wind, and demand builders consume `PISP.ISPdatabuilder.DATE_RANGES_REFYEARS`; the current implementation does not parse this mapping from the 2024 Inputs and Assumptions workbook.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
weather_year_mapping = DataFrame([
    (
        financial_year_start = financial_year_start,
        financial_year_end = financial_year_end,
        reference_year_ending = reference_year_ending,
    )
    for (financial_year_start, financial_year_end, reference_year_ending) in PISP.ISPdatabuilder.DATE_RANGES_REFYEARS
])
markdown_table(weather_year_mapping)
````

```@raw html
</details>
```

| **financial\_year\_start** | **financial\_year\_end** | **reference\_year\_ending** |
|:--|:--|--:|
| 2024-07-01 | 2025-06-30 | 2019 |
| 2025-07-01 | 2026-06-30 | 2020 |
| 2026-07-01 | 2027-06-30 | 2021 |
| 2027-07-01 | 2028-06-30 | 2022 |
| 2028-07-01 | 2029-06-30 | 2023 |
| 2029-07-01 | 2030-06-30 | 2015 |
| 2030-07-01 | 2031-06-30 | 2011 |
| 2031-07-01 | 2032-06-30 | 2012 |
| 2032-07-01 | 2033-06-30 | 2013 |
| 2033-07-01 | 2034-06-30 | 2014 |
| 2034-07-01 | 2035-06-30 | 2015 |
| 2035-07-01 | 2036-06-30 | 2016 |
| 2036-07-01 | 2037-06-30 | 2017 |
| 2037-07-01 | 2038-06-30 | 2018 |
| 2038-07-01 | 2039-06-30 | 2019 |
| 2039-07-01 | 2040-06-30 | 2020 |
| 2040-07-01 | 2041-06-30 | 2021 |
| 2041-07-01 | 2042-06-30 | 2022 |
| 2042-07-01 | 2043-06-30 | 2023 |
| 2043-07-01 | 2044-06-30 | 2015 |
| 2044-07-01 | 2045-06-30 | 2011 |
| 2045-07-01 | 2046-06-30 | 2012 |
| 2046-07-01 | 2047-06-30 | 2013 |
| 2047-07-01 | 2048-06-30 | 2014 |
| 2048-07-01 | 2049-06-30 | 2015 |
| 2049-07-01 | 2050-06-30 | 2016 |
| 2050-07-01 | 2051-06-30 | 2017 |
| 2051-07-01 | 2052-06-30 | 2018 |


## Reliability fields represented in static schemas

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
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
````

```@raw html
</details>
```

| **asset\_table** | **fields** |
|:--|:--|
| Generator | forate, fullout, partialout, derate, mttrfull, mttrpart, last\_state\_output |
| ESS | fullout, partialout, mttrfull, mttrpart |
| Line | fullout, mttrfull |


## Using the mappings

Scenario labels, source-specific aliases, bus assignments, weather-year mappings, technology groupings, retirement schedules, and build-out templates are modelling inputs rather than incidental filenames. Changes to these mappings can change generated datasets without any change to the downloaded source files.

Optional build-out technology labels select complete PISP generator or storage templates. See [ISP 2024 build-out defaults](buildout-defaults.md) for the field-level values, calculated fields, placeholders, and override rules.

Rooftop PV and utility-scale renewable capacity fields require special care. The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator. See [Assumptions and scope](@ref).

Both `gen_pmax_wind` and `gen_pmax_solar` ([`src/parsers/PISP-2024parser.jl`](https://github.com/ARPST-UniMelb/PISP.jl/blob/main/src/parsers/PISP-2024parser.jl)) read the same two sheets of the 2024 ISP Inputs and Assumptions workbook: `Existing Gen Data Summary` (cell range `B11:K297`) for the operating-capacity figures, and `Renewable Energy Zones` (cell range `B7:G50`) for REZ-to-bus assignment.

