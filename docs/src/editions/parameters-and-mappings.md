# Parameters and mappings

ParseISP uses edition-specific mappings, constants, classifications, and
source-field relationships to turn AEMO source data into package identifiers
and output tables.

## Where values come from

- **Report-defined mappings** encode a relationship stated in an AEMO report. The detailed mapping page identifies the report and shows the current ParseISP representation.
- **Workbook-derived values** are read from named workbook sheets, ranges, or build-out columns by the parser.
- **Package-defined defaults** come from ParseISP parameter dictionaries and are applied when the workbook does not provide a complete output row.

| Mapping or parameter layer | ISP 2024 | ISP 2026 comparison work |
| --- | --- | --- |
| Scenario identifiers | IDs `1`, `2`, and `3` identify Progressive Change, Step Change, and Green Energy Exports, and the problem-table and build-out paths use those IDs. | Align Accelerated Transition, Slower Growth, and Step Change with the 2024 scenario lineage before reusing scenario IDs. |
| Areas and bus aliases | 12 package bus aliases map to the five model areas QLD, NSW, VIC, TAS, and SA. | Compare the 2026 model regions, subregions, DNSPs, and REZ identifiers with the 2024 geography. |
| REZ mapping | The parser links REZ IDs and names to ISP subregions and renewable capacity records. | Compare renamed REZs, retained identifiers, and changed worksheet fields. |
| Weather years and traces | `ParseISP.ISPdatabuilder.DATE_RANGES_REFYEARS` maps planning-year intervals to historical weather years and supports composite trace `4006`. | Align `RefYear5000`, scenario trace folders, and the 2026 report definition of historical reference years. |
| Technology and asset classifications | Parameter files classify generation, hydro, storage, and build-out inputs. | Compare technology names, storage categories, fuel fields, hybrid-site limits, and new source subjects. |
| Source-sheet dependencies | Package readers consume named 2024 workbook sheets and trace patterns. | Use the [ISP 2026 source-data reference](../generated/isp2026/reference/source-data.md) to define the corresponding files, selections, keys, fields, and units. |
| Defaults and aliases | Package constants reconcile source names with output identifiers and fill required fields. | Review each default against the 2026 source structure before carrying it into the new parser. |

## Detailed references

The [ISP 2024 parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md)
page provides the scenario, bus, area, weather-year, reliability-field, and
source-sheet tables used by the package.
The [ISP 2024 build-out defaults](../generated/isp2024/reference/buildout-defaults.md)
page describes workbook fields, generated identities, calculations, and
package template values for optional generator and storage additions.
The [ISP 2024 hydro parameters and constants](../generated/isp2024/reference/hydro-parameters-and-constants.md)
page lists the values used to assign hydro traces, annual energy limits,
hydrological years, and Snowy inflows.

The [source coverage and ownership](../generated/shared/source-material/coverage-and-ownership.md)
page links the maintained source selections and mapping families to their
subject pages.
The [raw-source comparison](../generated/comparison/analyses/raw-source-comparison.md)
shows the workbook and schema differences that require new or revised mappings
for ISP 2026.

```@meta
# A cross-edition mapping should be introduced only after the correspondingsource keys, units, categories, and modelling meaning have been aligned.
# No integrated mapping layer yet establishes how ISP 2026 labels, scenarios, geography, REZs, technologies, source sheets, or trace conventions relate to the ISP 2024 model. The [comparison guide](comparison.md) lists the required categories for that future crosswalk.
```
