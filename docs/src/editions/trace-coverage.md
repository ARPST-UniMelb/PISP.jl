# Trace coverage

The ISP source-data layer distinguishes trace families, report-backed meaning, local schemas, and coverage evidence.

PISP has executed, release-specific evidence for the ISP 2024 trace inputs.
The [supported editions](supported-editions.md) page records the ISP 2026 acquisition, parser-review, integration, and publication boundary.

| Trace aspect | ISP 2024 PISP evidence | ISP 2026 source boundary |
| --- | --- | --- |
| Trace families and layout | The validated inputs include demand, solar, and wind trace families. Solar and wind are organised by technology and reference year; demand is organised by state and scenario with one file per demand node. | The downloaded 2026 source includes trace archives, but no verified PISP.jl trace-family or layout contract is published. |
| Identifiers and trace selection | The 2024 reference identifies the composite trace `4006`, representative solar and wind site identifiers, and state/scenario/node demand identifiers. PISP uses release-specific mappings to select and consume these inputs. | The role of `4006` and the trace-selection identifiers in the 2026 material is not established by these docs. |
| Schema | Executed 4006 solar and wind samples each have `Year`, `Month`, and `Day` metadata columns followed by 48 half-hourly value columns. Demand traces use a distinct per-node file family. | No published PISP.jl trace contract defines the 2026 schema; under-review parser coverage remains unverified here. |
| Time coverage and resolution | The documented 4006 solar and wind samples span 2024-07-01 through 2052-06-30 and use a half-hourly value axis. The detailed validation records the checked files and dates. | No published PISP.jl coverage check or time-axis interpretation is available for the 2026 material. |
| Values and units | The documented solar and wind samples are capacity-factor traces; the validation records their sampled value range and distinguishes them from the demand trace family. | No published PISP.jl interpretation establishes units, scale, missing-value treatment, or capacity-factor semantics for the 2026 material. |
| Generated-data use | The ISP 2024 build uses its release-specific trace conventions when producing PISP schedules. | No integrated ISP 2026 dataset build or trace-derived output contract is documented. |

In this source context, a trace is a time series supplied to the detailed long-term model. The [2024 ISP PLEXOS Model Instructions, p. 7](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=7) describe demand, hydro, load-subtractor, solar, timeslice, and wind trace folders. The [2026 ISP PLEXOS Model Instructions, p. 7](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7) add DNSP, gas, and rooftop-PV folders to that list. The reports describe 14 historical reference years for 2024 ([p. 5](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5)) and 16 for 2026 ([p. 5](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5)); those report-backed counts do not establish that every local archive contains every expected trace.

The 2024 local demand filenames include `POE10` and `POE50`. The [2023 Inputs, Assumptions and Scenarios Report, p. 172](../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=172) defines POE as “probability of exceedance”, while the [2023 ISP Methodology, p. 39](../../../data/2024/pisp-reports/2023-isp-methodology.pdf#page=39) describes 10%, 50%, and sometimes 90% POE simulations and uses 10% POE demand profiles for capacity-outlook modelling. Filename labels are therefore kept separate from report-backed meaning. No 2026 PoE meaning or cross-edition equivalence is established here.

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
