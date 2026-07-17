# Trace coverage

PISP has executed, release-specific evidence for the ISP 2024 trace inputs.
It has acquisition support, but no parsed trace model, for ISP 2026 material.
The two releases therefore do not yet share a PISP trace contract.

| Trace aspect | ISP 2024 PISP evidence | ISP 2026 PISP boundary |
| --- | --- | --- |
| Trace families and layout | The validated inputs include demand, solar, and wind trace families. Solar and wind are organised by technology and reference year; demand is organised by state and scenario with one file per demand node. | The downloader obtains solar and wind trace archives only. PISP has not established their extracted layout, trace families, or identifiers. |
| Identifiers and trace selection | The 2024 reference identifies the composite trace `4006`, representative solar and wind site identifiers, and state/scenario/node demand identifiers. PISP uses release-specific mappings to select and consume these inputs. | PISP has no 2026 trace-selection rule, identifier mapping, or parameter table. The role of `4006` in the 2026 material is unknown. |
| Schema | Executed 4006 solar and wind samples each have `Year`, `Month`, and `Day` metadata columns followed by 48 half-hourly value columns. Demand traces use a distinct per-node file family. | No PISP parser inspects or defines a 2026 schema. Column names, identifier fields, metadata, and file relationships are unknown to PISP. |
| Time coverage and resolution | The documented 4006 solar and wind samples span 2024-07-01 through 2052-06-30 and use a half-hourly value axis. The detailed validation records the checked files and dates. | No PISP coverage check or time-axis interpretation exists for the downloaded 2026 archives. |
| Values and units | The documented solar and wind samples are capacity-factor traces; the validation records their sampled value range and distinguishes them from the demand trace family. | PISP has not parsed the 2026 values, so its units, scale, missing-value treatment, and capacity-factor interpretation are unknown. |
| Generated-data use | The ISP 2024 build uses its release-specific trace conventions when producing PISP schedules. | PISP has no 2026 trace parser, dataset build, or generated trace-derived output. |

The [ISP 2024 trace data availability and structure](../generated/isp2024/validation/trace-coverage-and-schema.md)
page is the detailed evidence for the checked 2024 files, schema, identifiers,
coverage, and sample values.
The [ISP 2024 parameters and mappings](../generated/isp2024/reference/parameters-and-mappings.md)
page records the package-defined weather-year and source-label conventions used
with those inputs.

Any cross-release trace study needs an explicit, source-backed crosswalk for
trace identifiers, weather-year meaning, time axis, units, coverage, and
missing-data treatment.
Archive availability alone does not establish any of those relationships.
