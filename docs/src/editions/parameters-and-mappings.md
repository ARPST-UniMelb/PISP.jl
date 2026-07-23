# Parameters and mappings

PISP's implemented mapping layer is specific to the ISP 2024 workflow.
It combines source-derived workbook fields with package-defined identifiers,
aliases, classifications, and constants that make those fields usable in the
PISP data model.
The [supported editions](supported-editions.md) page records the separate ISP 2026 acquisition and integration boundary.

| Mapping or parameter layer | ISP 2024 PISP evidence | ISP 2026 PISP status |
| --- | --- | --- |
| Scenario identifiers and source labels | Scenario IDs `1`, `2`, and `3` identify Progressive Change, Step Change, and Green Energy Exports. Package mappings connect those names to hydro-inflow and demand-trace source labels. | No ISP 2026 scenario identifier, label, or source-name mapping is yet integrated into PISP.jl. |
| Areas and bus aliases | Twelve package bus aliases (`NQ`, `CQ`, `GG`, `SQ`, `NNSW`, `CNSW`, `SNW`, `SNSW`, `VIC`, `TAS`, `CSA`, and `SESA`) map to the five model areas QLD, NSW, VIC, TAS, and SA. The reference records each display name, area ID, and representative coordinates. | No ISP 2026 bus, area, or geographic crosswalk is yet integrated into PISP.jl. |
| REZ mapping | The 2024 parser links Renewable Energy Zone IDs and names to ISP sub-regions and uses those relationships when deriving renewable capacity and schedule inputs. | No ISP 2026 REZ-to-bus, REZ-to-area, or REZ-to-asset mapping is yet integrated into PISP.jl. |
| Weather years and trace conventions | `PISP.WEATHER_YEARS_ISP` maps each 2024 planning financial-year interval to a historical weather year for composite trace `4006`; repeated weather years are part of that release-specific convention. | No ISP 2026 weather-year map, trace-selection convention, or interpretation of `4006` is yet integrated into PISP.jl. |
| Technology and asset classifications | Package parameter files classify generation, hydro, storage, and build-out inputs. Generated generator data exposes `fuel` and `tech` classifications; the mapping layer also supplies technology-specific source and trace conventions. | No ISP 2026 technology classification, asset crosswalk, or generated schema is yet integrated into PISP.jl. |
| Source-sheet dependencies | The solar and wind routines read `Existing Gen Data Summary` (`B11:K297`) for operating-capacity figures and `Renewable Energy Zones` (`B7:G50`) for REZ-to-bus assignment in the 2024 ISP Inputs and Assumptions workbook. They also use release-specific outlook material for capacity development. | PISP.jl downloads and can extract the 2026 workbooks and archives, but no ISP 2026 sheet dependency or field interpretation is yet integrated into PISP.jl. |
| Aliases and hard-coded values | Scenario, hydro, demand, bus, area, generator, storage, trace-file, retirement, and build-out mappings are package-defined modelling inputs. They include aliases and constants that reconcile source names with PISP identifiers. | No ISP 2026 aliases, constants, or mapping tables are yet integrated into PISP.jl. |

## Provenance and interpretation

The [ISP 2024 parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md)
page provides the detailed, code-derived scenario, bus, area, weather-year, and
reliability-field tables. Its weather-year table is tied to the 2024 ISP PLEXOS
model instructions, while the sheet dependencies identify the 2024 workbook
fields consumed by the parser.

These package-defined values are modelling inputs rather than incidental
filenames. A change to a mapping can change generated datasets even when the
downloaded source files are unchanged. See [Assumptions and scope](../assumptions.md)
for technology-specific capacity caveats and [Trace coverage](trace-coverage.md)
for the release-specific trace boundary.

PISP.jl does not document an integrated mapping layer that establishes how ISP 2026 labels, scenarios, geography, REZs, technologies, source sheets, or trace conventions relate to the ISP 2024 model.
A comparison therefore requires release-specific source evidence and an explicit crosswalk; the [comparison guide](comparison.md) lists the required categories.
