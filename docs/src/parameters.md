# Parameters and mappings

PISP combines source-derived values with package-defined constants and reconciliation rules.
Those values are part of the dataset specification: they determine how published names become stable identifiers, how assets are assigned to regions and technologies, and how composite traces are paired with planning years.

!!! note "Why are some values hard-coded?"
    The AEMO source files do not use one shared identifier system across every workbook, archive, and trace family.
    PISP therefore defines a canonical representation and records the mappings required to populate it.
    These mappings should be reviewed as modelling assumptions rather than dismissed as temporary implementation details.

## Scenario IDs

| ID | Scenario name | Hydro inflow label | Demand trace label |
|---:|---|---|---|
| 1 | Progressive Change | `NetZero2050` | `PROGRESSIVE_CHANGE` |
| 2 | Step Change | `StepChange` | `STEP_CHANGE` |
| 3 | Green Energy Exports | `HydrogenSuperpower` | `HYDROGEN_EXPORT` |

Some legacy package logic uses `Hydrogen Export` as an alternate label for scenario 3.
Generated datasets use the public scenario name `Green Energy Exports` and the numeric scenario ID `3`.
Downstream code should prefer the numeric ID when joining or comparing schedules.

## Bus and area constants

The 12-bus representation gives all source families a common spatial index.
Each bus represents an ISP sub-region rather than a detailed electrical node.

| Bus ID | Alias | Name | Area | Latitude | Longitude |
|---:|---|---|---|---:|---:|
| 1 | `NQ` | Northern Queensland | QLD | -17.793850 | 145.563500 |
| 2 | `CQ` | Central Queensland | QLD | -22.824200 | 149.403610 |
| 3 | `GG` | Gladstone Grid | QLD | -23.842948 | 151.248803 |
| 4 | `SQ` | Southern Queensland | QLD | -27.476625 | 153.029934 |
| 5 | `NNSW` | Northern New South Wales | NSW | -30.504711 | 151.652465 |
| 6 | `CNSW` | Central New South Wales | NSW | -33.483300 | 150.157717 |
| 7 | `SNW` | Sydney, Newcastle & Wollongong | NSW | -33.865000 | 151.209444 |
| 8 | `SNSW` | Southern New South Wales | NSW | -35.110980 | 147.359907 |
| 9 | `VIC` | Victoria | VIC | -37.766053 | 144.943397 |
| 10 | `TAS` | Tasmania | TAS | -42.880556 | 147.325000 |
| 11 | `CSA` | Central South Australia | SA | -34.802680 | 138.521640 |
| 12 | `SESA` | South East South Australia | SA | -37.604700 | 140.837300 |

The five market areas are encoded as `QLD = 1`, `NSW = 2`, `VIC = 3`, `TAS = 4`, and `SA = 5`.

## Reference trace 4006 weather-year mapping

Reference trace `4006` is a composite planning trace.
It does not represent one historical weather year repeated across the horizon.
Instead, each financial year is paired with a selected historical year, based on AEMO's 2024 ISP PLEXOS model instructions (https://aemo.com.au/-/media/files/major-publications/isp/2024/supporting-materials/2024-isp-plexos-model-instructions.pdf?la=en, the same document `src/parameters/general2024ISP.jl`'s `WEATHER_YEARS_ISP` comment cites).
The specific page or table within that document has not yet been identified; this page currently traces the mapping to PISP's own source comment and the table below, not to a page number in AEMO's document.

| Financial-year window | Weather year |
|---|---:|
| 2024-07-01 to 2025-06-30 | 2019 |
| 2025-07-01 to 2026-06-30 | 2020 |
| 2026-07-01 to 2027-06-30 | 2021 |
| 2027-07-01 to 2028-06-30 | 2022 |
| 2028-07-01 to 2029-06-30 | 2023 |
| 2029-07-01 to 2030-06-30 | 2015 |
| 2030-07-01 to 2031-06-30 | 2011 |
| 2031-07-01 to 2032-06-30 | 2012 |
| 2032-07-01 to 2033-06-30 | 2013 |
| 2033-07-01 to 2034-06-30 | 2014 |
| 2034-07-01 to 2035-06-30 | 2015 |
| 2035-07-01 to 2036-06-30 | 2016 |
| 2036-07-01 to 2037-06-30 | 2017 |
| 2037-07-01 to 2038-06-30 | 2018 |
| 2038-07-01 to 2039-06-30 | 2019 |
| 2039-07-01 to 2040-06-30 | 2020 |
| 2040-07-01 to 2041-06-30 | 2021 |
| 2041-07-01 to 2042-06-30 | 2022 |
| 2042-07-01 to 2043-06-30 | 2023 |
| 2043-07-01 to 2044-06-30 | 2015 |
| 2044-07-01 to 2045-06-30 | 2011 |
| 2045-07-01 to 2046-06-30 | 2012 |
| 2046-07-01 to 2047-06-30 | 2013 |
| 2047-07-01 to 2048-06-30 | 2014 |
| 2048-07-01 to 2049-06-30 | 2015 |
| 2049-07-01 to 2050-06-30 | 2016 |
| 2050-07-01 to 2051-06-30 | 2017 |
| 2051-07-01 to 2052-06-30 | 2018 |

!!! note "Why does this mapping matter?"
    A result labelled by planning year can still reflect weather conditions from a different historical year.
    Scenario comparisons should therefore record both the planning period and the mapped weather year so changes are not attributed to the wrong cause.

## Asset and technology mapping families

PISP maintains several mapping families because names and classifications differ among the source artifacts:

| Mapping family | What it reconciles |
|---|---|
| Existing generators | Published unit names, unit IDs, fuel classes, technology labels, and trace filename exceptions. |
| Storage projects | Battery and pumped-storage names, aliases, coordinates, capacities, and service parameters. |
| Hydro assets | Hydro unit identities and the files used to construct inflow schedules. |
| Future build-out templates | Canonical parameter sets for new BESS, pumped hydro, CCGT, and OCGT rows. |
| Retirement assumptions | Unit retirement timing and the resulting generator availability schedules. |

These mappings contain information that cannot be reconstructed from the output tables alone.
A study that depends on technology grouping, project identity, hydro treatment, storage classification, forced-outage assumptions, or build-out templates should review the relevant mapping before accepting the generated rows.

## Rooftop PV `pmax` placeholder

Distributed rooftop PV rows (`RTPV_*`, `tech = "RoofPV"`) carry a fixed static `pmax` and `capacity` of `100.0` for every NEM sub-region.
This is a schema placeholder, not a measurement of installed rooftop PV capacity.
The hourly rooftop PV trace is written directly to the generator schedule and is not scaled relative to that placeholder.

A downstream study that needs installed capacity for rooftop PV should not use the static `Generator.pmax` or `Generator.capacity` fields for these rows.
Use an externally validated capacity source or a study-specific reconstruction instead.

## Utility-scale solar and wind `pmax`

Utility-scale solar (`LargePV`) and wind rows record the sum of currently operating capacity assigned to the sub-region.
Both technologies read the same two sheets of the 2024 ISP Inputs and Assumptions workbook: `Existing Gen Data Summary` (cell range `B11:K297`) for the operating-capacity figures, and `Renewable Energy Zones` (cell range `B7:G50`) for REZ-to-bus assignment.
A future-year schedule can incorporate additional ISP-outlook build-out and can therefore exceed the static `Generator.pmax` or `Generator.capacity` value without implying a parser error.

This distinction is why the static field is not a valid capacity-factor denominator for these technologies.
See [Assumptions and scope](@ref) for the downstream interpretation rule.

## Forced-outage and reliability constants

Forced-outage quantities are static output fields rather than time-varying schedules.
Their schemas differ by asset class:

| Asset table | Outage fields |
|---|---|
| `Generator` | `forate`, `fullout`, `partialout`, `derate`, `mttrfull`, `mttrpart`. |
| `ESS` | `fullout`, `partialout`, `mttrfull`, `mttrpart`; no combined `forate` column. |
| `Line` | `fullout`, `mttrfull`; no partial-outage or derating fields. |

For generators, the combined forced-outage rate is computed as:

```math
\mathrm{forate} = 1 - \left(\mathrm{fullout} + \mathrm{partialout}(1 - \mathrm{derate})\right)
```

Review the source vintage and package assumptions before treating these values as current reliability statistics.
PISP does not convert them into seasonal or chronological outage processes.

## See also

- [Data sources](@ref) distinguishes source-derived, code-derived, and mapped information.
- [Domain concepts](@ref) explains how the bus model, scenario IDs, and trace selection shape the dataset.
- [Assumptions and scope](@ref) identifies the modelling consequences of the rooftop PV, utility-scale VRE, network, and reliability conventions.
