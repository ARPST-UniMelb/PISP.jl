# Assumptions and scope

These assumptions apply to PISP's implemented ISP 2024 dataset-construction workflow.
[Supported ISP editions](editions/supported-editions.md) defines the separate ISP 2026 source-acquisition and integration boundary.

PISP produces structured ISP 2024 datasets from configured inputs.
It does not solve a power-system optimisation problem, validate the economic plausibility of the resulting case, or certify that every input remains current with AEMO's latest published revision.

The package therefore separates two responsibilities:

- PISP provides a reproducible transformation from its configured ISP 2024 sources and mappings to a documented dataset.
- The user decides whether the resulting representation and assumptions are valid for a particular study.

## Package boundary

`build_ISP24_datasets` downloads or reads ISP 2024 inputs, applies PISP's parsing and mapping rules, and writes static and time-varying tables.
The package does not run economic dispatch, security-constrained unit commitment, capacity expansion, production-cost modelling, or power flow.

The `problem_type = "UC"` value in the internal problem table describes the intended downstream study type. It is not evidence that PISP has solved a unit-commitment problem.

## Network representation

The ISP 2024 workflow uses a package-defined aggregated representation of the East Coast Australian power system.
Each bus has one representative coordinate and belongs to a NEM market area.
The bus and area inventory is listed in [ISP 2024 parameters and mappings](generated/isp2024/reference/parameters-and-mappings.md).
This representation is suitable for aggregated planning-data preparation, but it is not a nodal transmission model and does not contain intra-sub-region topology.

Line rows represent aggregated corridors and augmentation options. Downstream studies that need detailed AC network constraints, voltage behaviour, or intra-regional congestion must add or substitute a more detailed network model.

## Static reliability treatment

Forced-outage and repair quantities are static fields on ISP 2024 output rows.
PISP does not produce seasonal or year-by-year outage-rate schedules.
A downstream model that needs time-varying reliability should treat PISP's reliability fields as baseline inputs and add its own temporal outage model.

Generator, ESS, and line outage fields are not uniform across asset classes. Do not assume that a field present in `Generator` is also present in `ESS` or `Line`.

## DER interpretation

The `DER` table is narrower than the colloquial meaning of distributed energy resources.
In ISP 2024 PISP output it represents demand-side participation and EV-related rows linked to demand nodes.
Rooftop PV appears in `Generator`, and storage appears in `ESS`.

## Generator `pmax` is not a capacity-factor denominator for solar and wind

In the ISP 2024 output, a generator's static `pmax`/`capacity` field on the `Generator` table should not be used to compute capacity factor for solar or wind generators.
Rooftop PV rows carry a fixed placeholder value rather than a true capacity figure.
Utility-scale solar and wind rows record only currently operating capacity, which a future-year schedule can legitimately exceed once ISP-outlook build-out is reflected in the trace.
The correct capacity reference for these technologies is each generator's own scheduled maximum over the period being studied, not the static field.

## Data vintage and external validation

The ISP 2024 parser and downloader combine several source vintages.
[ISP 2024 data sources](generated/isp2024/reference/data-sources.md) lists the configured download targets and expected local inputs.
A reproducible study should still archive the exact downloaded files and record checksums.

Package constants such as bus coordinates, trace-year mappings, generator trace filename exceptions, hydro mappings, and buildout templates should be reviewed as modelling assumptions. Some of these values are code-derived or source-derived; others are pragmatic mappings needed to align published files with PISP's schema.

## Practical review checklist

Before using ISP 2024 PISP output in a downstream study, check:

| Question | Why it matters |
|---|---|
| Which `reftrace`, `poe`, scenario IDs, and schedule tags were used? | They define the time-varying demand and VRE inputs. |
| Were the input files freshly downloaded or reused from an existing `downloadpath`? | Reused inputs may not match the intended source vintage. |
| Are `write_traces`, `check_exist_trace`, CSV, and Arrow settings consistent with the files being consumed? | Some schedules may be skipped intentionally. |
| Does the study require more network detail than the aggregated PISP representation? | PISP does not encode detailed nodal topology. |
| Are forced-outage, cost, efficiency, hydro, and buildout constants acceptable for the study? | These values can materially affect downstream optimisation or reliability results. |
| Are schedule values joined to the correct static table and scenario? | Schedule tables are overlays, not standalone assets. |

## See also

- [Supported ISP editions](editions/supported-editions.md) distinguishes ISP 2026 source download and extraction, under-review parser development, PISP.jl integration, and published evidence.
- [Data sources](generated/isp2024/reference/data-sources.md) identifies the source vintages and reproducibility boundary.
- [Domain concepts](concepts.md) explains the aggregated network and static-versus-schedule data model.
- [Parameters and mappings](generated/isp2024/reference/parameters-and-mappings.md) records the hard-coded values and technology-specific exceptions that require review.
