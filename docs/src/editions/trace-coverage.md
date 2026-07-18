# Trace coverage

PISP has executed, release-specific evidence for the ISP 2024 trace inputs.
For ISP 2026, PISP.jl supports source download and archive extraction, while parser development is under review and not yet integrated into PISP.jl's documented workflow.
No ISP 2026 trace contract is yet integrated into PISP.jl or supported by published trace validation.
The [supported editions](supported-editions.md) page is the detailed status authority.

| Trace aspect | ISP 2024 PISP evidence | ISP 2026 PISP boundary |
| --- | --- | --- |
| Trace families and layout | The validated inputs include demand, solar, and wind trace families. Solar and wind are organised by technology and reference year; demand is organised by state and scenario with one file per demand node. | PISP.jl downloads and can extract the 2026 trace archives. No PISP.jl trace-family or layout contract is yet integrated or published. |
| Identifiers and trace selection | The 2024 reference identifies the composite trace `4006`, representative solar and wind site identifiers, and state/scenario/node demand identifiers. PISP uses release-specific mappings to select and consume these inputs. | No ISP 2026 trace-selection rule, identifier mapping, or parameter table is yet integrated into PISP.jl. The role of `4006` in the 2026 material is not established by these docs. |
| Schema | Executed 4006 solar and wind samples each have `Year`, `Month`, and `Day` metadata columns followed by 48 half-hourly value columns. Demand traces use a distinct per-node file family. | No PISP.jl parser or trace contract yet defines the 2026 schema. Under-review parser coverage is unverified here. |
| Time coverage and resolution | The documented 4006 solar and wind samples span 2024-07-01 through 2052-06-30 and use a half-hourly value axis. The detailed validation records the checked files and dates. | No published PISP.jl coverage check or time-axis interpretation is available for the 2026 trace material. |
| Values and units | The documented solar and wind samples are capacity-factor traces; the validation records their sampled value range and distinguishes them from the demand trace family. | No published PISP.jl interpretation establishes units, scale, missing-value treatment, or capacity-factor semantics for the 2026 trace material. |
| Generated-data use | The ISP 2024 build uses its release-specific trace conventions when producing PISP schedules. | No ISP 2026 dataset build or generated trace-derived output contract is yet integrated into PISP.jl. |

In this source context, a trace is a time series supplied to the detailed
long-term model. The 2024 PLEXOS Model Instructions describe demand, hydro,
load-subtractor, solar, timeslice, and wind trace folders (physical p. 7).
The 2026 instructions add DNSP, gas, and rooftop-PV folders to that list
(physical p. 7). The reports describe 14 historical reference years for 2024
and 16 for 2026 (physical p. 5); those report-backed counts do not establish
that every local archive contains every expected trace.

The 2024 local demand filenames include `POE10` and `POE50`. The 2023 Inputs,
Assumptions and Scenarios Report defines POE as “probability of exceedance”
(physical p. 172), while the 2023 ISP Methodology describes 10%, 50%, and
sometimes 90% POE simulations and uses 10% POE demand profiles for capacity-
outlook modelling (physical p. 39). Filename labels are therefore kept
separate from report-backed meaning. No 2026 PoE meaning or cross-edition
equivalence is established here.

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
