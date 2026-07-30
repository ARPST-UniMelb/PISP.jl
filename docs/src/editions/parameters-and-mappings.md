# Parameters and mappings

The PISP transformation layer applies package mappings, constants, classifications, and source-field dependencies.

PISP's implemented mapping layer is specific to the ISP 2024 workflow.
It combines source-derived workbook fields with package-defined identifiers,
aliases, classifications, and constants that make those fields usable in the
PISP data model.
PISP.jl can download and extract the ISP 2026 workbooks and archives, but no ISP 2026 source-sheet dependency or field interpretation is yet integrated into its documented workflow.
The [supported editions](supported-editions.md) page records that acquisition and integration boundary.

## How to read parameter provenance

- **Report-defined mappings** encode a relationship stated in an AEMO report. The detailed mapping page identifies the report and shows the current PISP representation.
- **Workbook-derived values** are read from named workbook sheets, ranges, or build-out columns by the parser.
- **Package-defined defaults** come from PISP parameter dictionaries and are applied when the workbook does not provide a complete output row.
- **Unverified provenance** means that the current code supplies a value, but its original external source is not established in the package documentation. Such a value remains usable as a PISP default without being attributed to an unsupported source.

| Mapping or parameter layer | ISP 2024 PISP evidence |
| --- | --- |
| Scenario identifiers and source labels | Scenario IDs `1`, `2`, and `3` identify Progressive Change, Step Change, and Green Energy Exports. The problem-table and build-out paths use those IDs, while package mappings connect the names to hydro-inflow and demand-trace source labels. |
| Areas and bus aliases | Twelve package bus aliases (`NQ`, `CQ`, `GG`, `SQ`, `NNSW`, `CNSW`, `SNW`, `SNSW`, `VIC`, `TAS`, `CSA`, and `SESA`) map to the five model areas QLD, NSW, VIC, TAS, and SA. The reference records each display name, area ID, and representative coordinates. |
| REZ mapping | The 2024 parser links Renewable Energy Zone IDs and names to ISP sub-regions and uses those relationships when deriving renewable capacity and schedule inputs. |
| Weather years and trace conventions | `PISP.ISPdatabuilder.DATE_RANGES_REFYEARS` maps each 2024 planning financial-year interval to a historical weather year and is consumed when the composite solar, wind, and demand trace `4006` files are built; repeated weather years are part of that release-specific convention. |
| Technology and asset classifications | Package parameter files classify generation, hydro, storage, and build-out inputs. Generated generator data exposes `fuel` and `tech` classifications; the mapping layer also supplies technology-specific source and trace conventions. |
| Source-sheet dependencies | The solar and wind routines read `Existing Gen Data Summary` (`B11:K297`) for operating-capacity figures and `Renewable Energy Zones` (`B7:G50`) for REZ-to-bus assignment in the 2024 ISP Inputs and Assumptions workbook. They also use release-specific outlook material for capacity development. |
| Aliases and hard-coded values | Scenario, hydro, demand, bus, area, generator, storage, trace-file, retirement, and build-out mappings are package-defined modelling inputs. They include aliases and constants that reconcile source names with PISP identifiers. |

## Provenance and interpretation

The [ISP 2024 parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md)
page provides the detailed, code-derived scenario, bus, area, weather-year, and
reliability-field tables. Its weather-year table is tied to the 2024 ISP PLEXOS
model instructions, while the sheet dependencies identify the 2024 workbook
fields consumed by the parser.

The [ISP 2024 build-out defaults](../generated/isp2024/reference/buildout-defaults.md) page separates workbook fields, generated identities, calculations, placeholders, and package template values for optional generator and storage additions.

The [ISP 2024 hydro parameters and constants](../generated/isp2024/reference/hydro-parameters-and-constants.md) page lists the package values used to assign hydro traces, annual energy limits, hydrological years, and Snowy inflows.

These package-defined values are modelling inputs rather than incidental
filenames. A change to a mapping can change generated datasets even when the
downloaded source files are unchanged. See [Assumptions and scope](../assumptions.md)
for technology-specific capacity caveats and [Trace coverage](trace-coverage.md)
for the release-specific trace boundary.

PISP.jl does not document an integrated mapping layer that establishes how ISP 2026 labels, scenarios, geography, REZs, technologies, source sheets, or trace conventions relate to the ISP 2024 model.
A comparison therefore requires release-specific source evidence and an explicit crosswalk; the [comparison guide](comparison.md) lists the required categories.
