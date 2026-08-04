# Trace coverage

The ISP model releases use trace files for demand, renewable generation,
hydro, gas, distributed resources, and seasonal time slices.
The files are organised differently in ISP 2024 and ISP 2026.

| Trace aspect | ISP 2024 | ISP 2026 |
| --- | --- | --- |
| Trace families | Demand, hydro, load-subtractor, solar, timeslice, and wind folders. | Demand, DNSP, gas, hydro, load-subtractor, rooftop-PV, solar, timeslice, and wind folders. |
| Scenario layout | Demand and model-side traces use the 2024 scenario and source naming conventions. | Model-side traces are grouped under Accelerated Transition, Slower Growth, and Step Change scenario directories. |
| Renewable traces | Solar and wind files are organised by technology, project, and reference year. | Solar and wind are separate project-level archives with `RefYear5000` in the filenames. |
| Half-hourly schema | Solar and wind samples use `Year`, `Month`, `Day`, and columns `01` to `48`. Demand uses a separate per-node file family. | Demand, DNSP, rooftop-PV, load-subtractor, solar, and wind files use `Year`, `Month`, `Day`, and columns `01` to `48`. |
| Daily schema | Hydro inflow and annual-energy files use release-specific daily structures. | Gas files use a daily `Value` field, while daily hydro files use `Inflows`. |
| Reference years | The Model Instructions describe 14 historical reference years and the package also uses the composite `4006` convention. | The Model Instructions describe 16 historical reference years; the released renewable filenames use `RefYear5000`. |
| Demand POE | The 2024 demand filenames use `POE10` and `POE50`, selected through the package `poe` argument. | The 2025 reports describe 10%, 50%, and sometimes 90% POE simulations. |

Within the ISP 2024 demand folders, `*_OPSO_MODELLING_PVLITE.csv` supplies
operational demand net of PV-lite profiles, while `*_PV_TOT.csv` supplies
distributed or rooftop-PV schedules.
The ISP 2026 model archive separates demand and rooftop-PV traces into
independent folders.

The [2024 ISP PLEXOS Model Instructions, p. 7](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=7)
describe demand, hydro, load-subtractor, solar, timeslice, and wind trace
folders.
The [2026 ISP PLEXOS Model Instructions, p. 7](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=7)
add DNSP, gas, and rooftop-PV folders.
The reports describe 14 historical reference years for 2024
([p. 5](../../../data/2024/pisp-reports/2024-isp-plexos-model-instructions.pdf#page=5))
and 16 for 2026
([p. 5](../../../data/2026/pisp-reports/2026-isp-plexos-model-instructions.pdf#page=5)).

The [2023 Inputs, Assumptions and Scenarios Report, p. 172](../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=172)
defines POE as probability of exceedance.
The [2023 ISP Methodology, p. 39](../../../data/2024/pisp-reports/2023-isp-methodology.pdf#page=39)
describes 10%, 50%, and sometimes 90% POE simulations and uses 10% POE demand
profiles for capacity-outlook modelling.
The [2025 Inputs, Assumptions and Scenarios Report, p. 234](../../../data/2026/pisp-reports/2025-inputs-assumptions-and-scenarios-report.pdf#page=234)
and [2025 ISP Methodology, p. 40](../../../data/2026/pisp-reports/2025-isp-methodology.pdf#page=40)
use the same abbreviation for the 2026 release.

[Domain concepts](../concepts.md) explains the ISP 2024 `reftrace` and `poe`
selectors.
The [ISP 2024 workbook and trace structure](../generated/isp2024/validation/workbook-and-trace-structure.md)
page gives the 2024 workbook selections, model folders, trace patterns, keys,
fields, and units.
The [ISP 2026 source-data reference](../generated/isp2026/reference/source-data.md)
and [workbook and trace structure](../generated/isp2026/validation/workbook-and-trace-structure.md)
pages give the 2026 folders, file patterns, keys, and fields.

Cross-edition trace work must align identifiers, reference-year meaning, time
axes, units, coverage, and missing-value treatment explicitly.
