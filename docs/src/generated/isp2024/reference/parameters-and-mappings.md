```@meta
EditURL = "../../../../literate/isp2024/reference/parameters_and_mappings.jl"
```

# ISP 2024: Parameters and mappings

PISP combines values published by AEMO with package-defined identifiers, defaults, aliases, and source-to-output mappings.
The distinction matters because a downloaded workbook can remain unchanged while a package convention changes the generated dataset.
The tables separate these authorities and present the general mappings shared across the ISP 2024 workflow.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames
using Dates

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

coverage = PISPDocUtils.coverage_document(REPO_ROOT)
parameter_families = PISPDocUtils.coverage_table(coverage, "parameter_family")
mapping_families = PISPDocUtils.coverage_table(coverage, "mapping_family")

length(unique(parameter_families.id)) == nrow(parameter_families) || error("parameter-family IDs must be unique")
length(unique(mapping_families.id)) == nrow(mapping_families) || error("mapping-family IDs must be unique")
````

```@raw html
</details>
```

## AEMO values and PISP conventions

AEMO source values remain attributable to the workbook, model archive, report, or CSV that publishes them.
PISP conventions are maintained in package parameter files, parser-local mappings, or user-controlled build-out inputs.
Parsed representations are mechanical normalisations or runtime joins derived from those sources rather than independent external facts.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
classification_roles = DataFrame([
    (
        classification = PISPDocUtils.friendly_classification("aemo_raw_source"),
        authority = "AEMO publication",
        meaning = "A value or record read directly from an AEMO workbook, model CSV, or report-backed source.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("parsed_representation"),
        authority = "PISP transformation",
        meaning = "A normalised label, runtime lookup, or join derived from source records.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("pisp_generated_intermediate"),
        authority = "PISP preprocessing",
        meaning = "An Auxiliary workbook generated from AEMO outlook workbooks and consumed by the parser.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("package_convention"),
        authority = "PISP package",
        meaning = "A maintained identifier, default, alias, allocation rule, or source-file convention.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("user_input"),
        authority = "PISP user",
        meaning = "An optional build-out or other value supplied when the workflow is run.",
    ),
    (
        classification = PISPDocUtils.friendly_classification("pisp_output"),
        authority = "PISP data model",
        meaning = "A generated table, field, or schema contract exposed to dataset users.",
    ),
])
PISPDocUtils.markdown_table(classification_roles)
````

```@raw html
</details>
```

| **classification** | **authority** | **meaning** |
|:--|:--|:--|
| AEMO raw source | AEMO publication | A value or record read directly from an AEMO workbook, model CSV, or report-backed source. |
| Parsed representation | PISP transformation | A normalised label, runtime lookup, or join derived from source records. |
| PISP-generated intermediate | PISP preprocessing | An Auxiliary workbook generated from AEMO outlook workbooks and consumed by the parser. |
| PISP package convention | PISP package | A maintained identifier, default, alias, allocation rule, or source-file convention. |
| User input | PISP user | An optional build-out or other value supplied when the workflow is run. |
| PISP output | PISP data model | A generated table, field, or schema contract exposed to dataset users. |


## Parameter-file ownership

`PISPparameters.jl` includes six parameter files.
The table pairs each file with the subject page that explains how its values and conventions affect the package workflow.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
parameter_owners = select(
    parameter_families,
    :source_path => ByRow(basename) => :parameter_file,
    :family,
    :classification,
    :owner => :canonical_page_id,
    :notes,
)
parameter_owners.classification = PISPDocUtils.friendly_classification.(parameter_owners.classification)
PISPDocUtils.markdown_table(parameter_owners)
````

```@raw html
</details>
```

| **parameter\_file** | **family** | **classification** | **canonical\_page\_id** | **notes** |
|:--|:--|:--|:--|:--|
| general2024ISP.jl | scenario, geography, bus, area, source labels, and weather-year identifiers | PISP package convention | isp2024-parameters-and-mappings | Canonical package identifiers used across the 2024 pipeline. |
| retirements2024ISP.jl | retirement reductions and reviewed retirement overrides | PISP package convention | shared-source-generator-reliability-retirement | Package-defined retirement adjustments applied after source parsing. |
| ess2024ISP.jl | battery and pumped-hydro defaults | PISP package convention | shared-source-existing-generation-storage | Static storage records that supplement or normalise source data. |
| gens2024ISP.jl | generator unit, fuel-type, and trace-file mappings | PISP package convention | shared-source-existing-generation-storage | Generation identifiers and source-file naming conventions. |
| hydro2024ISP.jl | hydro files, constraints, weather years, dam shares, and groupings | PISP package convention | shared-source-hydro-inflows | Hydro source-file and allocation conventions. |
| buildout2024ISP.jl | generator and storage build-out templates | PISP package convention | isp2024-buildout-defaults | Complete default records used when a user requests optional build-outs. |


## Mapping-family ownership

The mapping ledger covers source downloads, scenarios, geography, generation, storage, retirement, reliability, renewable energy zones, demand-side participation, electric vehicles, hydro, optional build-outs, and output schemas.
Package conventions and parsed representations are listed separately because only the former are maintained as project choices.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
mapping_owner_summary = combine(
    groupby(mapping_families, [:classification, :owner]),
    nrow => :mapping_families,
)
sort!(mapping_owner_summary, [:classification, :owner])
mapping_owner_summary.classification = PISPDocUtils.friendly_classification.(mapping_owner_summary.classification)
PISPDocUtils.markdown_table(mapping_owner_summary)
````

```@raw html
</details>
```

| **classification** | **owner** | **mapping\_families** |
|:--|:--|--:|
| Excluded trace material | editions/trace-coverage.md | 1 |
| PISP package convention | isp2024-buildout-defaults | 2 |
| PISP package convention | isp2024-data-sources | 1 |
| PISP package convention | isp2024-output-tables | 2 |
| PISP package convention | shared-source-demand-side-participation | 2 |
| PISP package convention | shared-source-electric-vehicles | 4 |
| PISP package convention | shared-source-existing-generation-storage | 4 |
| PISP package convention | shared-source-hydro-inflows | 1 |
| PISP package convention | shared-source-renewable-energy-zones | 2 |
| Parsed representation | shared-source-demand-distributed-resources | 1 |
| Parsed representation | shared-source-electric-vehicles | 5 |
| Parsed representation | shared-source-existing-generation-storage | 5 |
| Parsed representation | shared-source-hydro-inflows | 3 |
| Parsed representation | shared-source-network-transmission | 1 |
| User input | isp2024-buildout-defaults | 1 |


```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
mapping_inventory = select(
    mapping_families,
    :family,
    :classification,
    :owner => :canonical_page_id,
    :source_path,
)
sort!(mapping_inventory, [:classification, :canonical_page_id, :family])
mapping_inventory.classification = PISPDocUtils.friendly_classification.(mapping_inventory.classification)
PISPDocUtils.markdown_table(mapping_inventory)
````

```@raw html
</details>
```

| **family** | **classification** | **canonical\_page\_id** | **source\_path** |
|:--|:--|:--|:--|
| trace years to processed trace tables | Excluded trace material | editions/trace-coverage.md | src/scrappers/PISP-scrapper-build.jl |
| battery duration labels | PISP package convention | isp2024-buildout-defaults | src/parsers/PISP-2024buildout.jl |
| user build-out technology labels | PISP package convention | isp2024-buildout-defaults | src/parsers/PISP-2024buildout.jl |
| fixed source-download keys and metadata | PISP package convention | isp2024-data-sources | src/scrappers/PISP-scrapper-2024files.jl |
| output table aliases | PISP package convention | isp2024-output-tables | src/utils/writing/PISPutils-writing.jl |
| schema declarations to Julia types | PISP package convention | isp2024-output-tables | src/utils/mappers/PISPutils-mappers.jl |
| DSP price-band identifiers | PISP package convention | shared-source-demand-side-participation | src/parsers/PISP-2024parser.jl |
| scenario/region/season DSP ranges | PISP package convention | shared-source-demand-side-participation | src/parsers/PISP-2024parser.jl |
| EV number worksheet to output field | PISP package convention | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| EV scenario name to package ID | PISP package convention | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| EV state name to NEM code | PISP package convention | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| EV vehicle types to demand categories | PISP package convention | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| generator-unit aliases | PISP package convention | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| technology cost-curve slopes | PISP package convention | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| technology emissions fallbacks | PISP package convention | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| technology inertia constants | PISP package convention | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| hydro scheme groups | PISP package convention | shared-source-hydro-inflows | src/parsers/PISP-2024parser.jl |
| scenario to candidate development path for solar | PISP package convention | shared-source-renewable-energy-zones | src/parsers/PISP-2024parser.jl |
| scenario to candidate development path for wind | PISP package convention | shared-source-renewable-energy-zones | src/parsers/PISP-2024parser.jl |
| bus IDs to demand records | Parsed representation | shared-source-demand-distributed-resources | src/parsers/PISP-2024parser.jl |
| EV output tables by vehicle number field | Parsed representation | shared-source-electric-vehicles | src/parsers/PISP-2024parser.jl |
| EV worksheet tables by source name | Parsed representation | shared-source-electric-vehicles | src/parsers/PISP-2024parser.jl |
| bus IDs to demand records | Parsed representation | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| bus names to bus IDs | Parsed representation | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| demand and DER relationship lookups | Parsed representation | shared-source-electric-vehicles | src/utils/dataframes/PISPutils-df-evs-2024.jl |
| month labels to calendar months | Parsed representation | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| solar source names to trace names | Parsed representation | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| solar source rows to generated IDs | Parsed representation | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| storage source rows to generated IDs | Parsed representation | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| wind source rows to generated IDs | Parsed representation | shared-source-existing-generation-storage | src/parsers/PISP-2024parser.jl |
| hydro generator IDs to row numbers | Parsed representation | shared-source-hydro-inflows | src/parsers/PISP-2024parser.jl |
| inflow files to generator groups | Parsed representation | shared-source-hydro-inflows | src/parsers/PISP-2024parser.jl |
| month labels to calendar months | Parsed representation | shared-source-hydro-inflows | src/utils/dataframes/PISPutils-df-hydro.jl |
| named interconnector reliability rows | Parsed representation | shared-source-network-transmission | src/parsers/PISP-2024parser.jl |
| scenario IDs to optional build-out names | User input | isp2024-buildout-defaults | src/main/pipeline-add-buildouts.jl |


## Scenario identifiers and source labels

The problem-table and build-out paths iterate `PISP.ID2SCE` to create rows for the package's three scenario IDs.
The hydro parser uses `PISP.HYDROSCE` to select PLEXOS hydro labels, while the 4006 demand builder uses `PISP.DEMSCE` in source and output filenames.
These mappings therefore affect generated data rather than serving only as display labels.

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
PISPDocUtils.markdown_table(scenario_mappings)
````

```@raw html
</details>
```

| **scenario\_id** | **scenario\_name** | **hydro\_label** | **demand\_trace\_label** |
|--:|:--|:--|:--|
| 1 | Progressive Change | NetZero2050 | PROGRESSIVE\_CHANGE |
| 2 | Step Change | StepChange | STEP\_CHANGE |
| 3 | Green Energy Exports | HydrogenSuperpower | HYDROGEN\_EXPORT |


## Bus and area constants

The bus constants provide the package's stable spatial identifiers, display names, area assignments, and representative coordinates.
Source rows are assigned to these identifiers during parsing, so the aliases are part of the PISP data contract rather than AEMO workbook values.

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
PISPDocUtils.markdown_table(bus_area_mappings)
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

The composite trace maps each financial-year interval to a historical reference year.
Repeated historical years are part of the mapping and should be considered when comparing planning periods.

AEMO explains the rolling-reference-year method in the [2024 ISP PLEXOS Model Instructions, p. 5](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5).
The Reference Year and VRE Reference Year sequence is in Table 1 of the [2024 ISP PLEXOS Model Instructions, p. 6](../../../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=6); the table's Hydrological Reference Year is a distinct sequence.
PISP stores the ending year of each report range: AEMO's `2018-19` reference year, for example, is represented as `2019` for the interval from 1 July 2024 through 30 June 2025.

The 4006 solar, wind, and demand builders consume `PISP.ISPdatabuilder.DATE_RANGES_REFYEARS`.
The current implementation does not parse this mapping from the 2024 Inputs and Assumptions workbook.

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
PISPDocUtils.markdown_table(weather_year_mapping)
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

PISP's static schemas distinguish full outages, partial outages, derating, repair time, and state-dependent output where the asset table supports them.
The AEMO reliability and retirement source records that populate these fields are described in [Generator reliability and retirement](../../shared/source-material/generator-reliability-and-retirement.md) and [Network and transmission assumptions](../../shared/source-material/network-and-transmission.md).

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
PISPDocUtils.markdown_table(reliability_schema)
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

Scenario labels, source-specific aliases, bus assignments, weather-year mappings, technology groupings, retirement schedules, and build-out templates are modelling inputs rather than incidental filenames.
Changes to these mappings can change generated datasets without any change to the downloaded source files.

Optional build-out technology labels select complete PISP generator or storage templates.
See [ISP 2024 build-out defaults](buildout-defaults.md) for the field-level values, calculated fields, placeholders, and override rules.

Rooftop PV and utility-scale renewable capacity fields require special care.
The time-varying schedule is the relevant maximum-output series for solar and wind; the static `pmax` field is not a universal capacity-factor denominator.
See [Assumptions and scope](@ref).

Shared [AEMO ISP source coverage and ownership](../../shared/source-material/coverage-and-ownership.md) pages describe the workbook selections for operating capacity, storage, renewable energy zones, and other source subjects.
This page covers package-defined parameters and mappings.

