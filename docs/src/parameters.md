# Parameters and mappings

This page records package constants and hard-coded mappings that affect generated datasets. They are part of PISP's data definition: users should treat them as assumptions to review, not as invisible implementation details.

## Scenario IDs

| ID | Scenario name | Hydro inflow label | Demand trace label |
|---:|---|---|---|
| 1 | Progressive Change | `NetZero2050` | `PROGRESSIVE_CHANGE` |
| 2 | Step Change | `StepChange` | `STEP_CHANGE` |
| 3 | Green Energy Exports | `HydrogenSuperpower` | `HYDROGEN_EXPORT` |

The code also contains a secondary `ID2SCE2` mapping that labels scenario 3 as `Hydrogen Export`. The public scenario mapping used by the build path is `ID2SCE`, where scenario 3 is `Green Energy Exports`.

## Bus and area constants

The 12-bus representation is defined in `src/parameters/general2024ISP.jl`.

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

For `reftrace = 4006`, PISP maps each financial year to a historical weather year. The code comment points to AEMO's 2024 ISP PLEXOS model instructions as the source for this mapping.

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

## Technology and asset mapping files

Several parameter files contain large dictionaries that map AEMO names, unit IDs, storage projects, hydro assets, buildout templates, and trace filenames onto PISP rows:

| File | Main role |
|---|---|
| `src/parameters/gens2024ISP.jl` | Existing generator unit mappings, fuel/technology groupings, and generator trace filename exceptions. |
| `src/parameters/ess2024ISP.jl` | Battery and pumped-storage mappings, including project coordinates/aliases and storage properties. |
| `src/parameters/hydro2024ISP.jl` | Hydro-specific mappings used by inflow logic. |
| `src/parameters/buildout2024ISP.jl` | Parameter templates for new-entrant BESS, pumped hydro, CCGT, and OCGT buildouts. |
| `src/parameters/retirements2024ISP.jl` | Retirement assumptions and mappings used by generator schedules. |

These files contain values that cannot be reconstructed from the output tables alone. When using PISP output for a study, review the relevant parameter file when the result depends on project naming, technology grouping, hydro treatment, storage classification, forced-outage parameters, or buildout templates.

## Rooftop PV `pmax` placeholder

Distributed (rooftop) PV generator rows (`RTPV_*`, `tech = "RoofPV"`) are written with a fixed `pmax` and `capacity` of `100.0` for every NEM subregion (`src/parsers/PISP-2024parser.jl`, `gen_pmax_distpv`). This value is a schema placeholder, not a real installed-capacity figure: the rooftop PV hourly trace for each subregion is read directly from AEMO's demand-side distributed-PV profile files and written to the schedule with no scaling relative to this placeholder. A downstream study that needs each subregion's true rooftop PV capacity should not read it from `Generator.pmax`/`Generator.capacity` for these rows.

## Generator `pmax` for utility-scale solar and wind

Utility-scale solar (`LargePV`) and wind generator rows record the sum of currently operating unit capacity for their subregion (`src/parsers/PISP-2024parser.jl`, `gen_pmax_wind` and the equivalent solar function), not any capacity growth planned for a future study year. A schedule built for a future planning year can draw on ISP outlook capacity that reflects planned build-out beyond what is currently operating, so a generator's scheduled output can legitimately exceed its static `Generator.pmax`/`Generator.capacity` value for that reason alone. See Assumptions for the capacity-factor implication.

## Forced-outage and reliability constants

Forced-outage fields are static output columns, not time-varying schedules. Their interpretation differs by asset class:

| Asset table | Outage fields |
|---|---|
| `Generator` | `forate`, `fullout`, `partialout`, `derate`, `mttrfull`, `mttrpart`. |
| `ESS` | `fullout`, `partialout`, `mttrfull`, `mttrpart`; no combined `forate` column. |
| `Line` | `fullout`, `mttrfull`; no partial-outage or derating fields. |

The generator `forate` is computed in code as `1 - (fullout + partialout * (1 - derate))`. Review the source tables and constants before treating these values as current AEMO reliability assumptions.
