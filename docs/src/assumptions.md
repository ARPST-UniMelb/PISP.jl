# Assumptions and scope

PISP produces structured datasets from ISP inputs. It does not solve a power-system optimisation problem, validate the economic plausibility of the resulting case, or certify that every input remains current with AEMO's latest published revision.

## Package boundary

`build_ISP24_datasets` downloads or reads ISP inputs, applies PISP's parsing and mapping rules, and writes static and time-varying tables. The package does not run economic dispatch, security-constrained unit commitment, capacity expansion, production-cost modelling, or power flow.

The `problem_type = "UC"` value in the internal problem table describes the intended downstream study type. It is not evidence that PISP has solved a unit-commitment problem.

## Network representation

PISP uses an aggregated 12-bus representation of the East Coast Australian power system. Each bus has one representative coordinate and belongs to one of the five NEM market areas. This is suitable for aggregated planning-data preparation, but it is not a nodal transmission model and does not contain intra-sub-region topology.

Line rows represent aggregated corridors and augmentation options. Downstream studies that need detailed AC network constraints, voltage behaviour, or intra-regional congestion must add or substitute a more detailed network model.

## Static reliability treatment

Forced-outage and repair quantities are static fields on output rows. PISP does not produce seasonal or year-by-year outage-rate schedules. A downstream model that needs time-varying reliability should treat PISP's reliability fields as baseline inputs and add its own temporal outage model.

Generator, ESS, and line outage fields are not uniform across asset classes. Do not assume that a field present in `Generator` is also present in `ESS` or `Line`.

## DER interpretation

The `DER` table is narrower than the colloquial meaning of distributed energy resources. In PISP output it represents demand-side participation and EV-related rows linked to demand nodes. Rooftop PV appears in `Generator`, and storage appears in `ESS`.

## Generator `pmax` is not a capacity-factor denominator for solar and wind

A generator's static `pmax`/`capacity` field on the `Generator` table should not be used to compute capacity factor for solar or wind generators. Rooftop PV rows carry a fixed placeholder value rather than a true capacity figure, and utility-scale solar/wind rows record only currently operating capacity, which a future-year schedule can legitimately exceed once ISP-outlook build-out is reflected in the trace (see Parameters for the source of both). The correct capacity reference for these technologies is each generator's own scheduled maximum over the period being studied, not the static field — the same convention a downstream Sienna-based production-cost tool (`SiennaNEM.jl`) already applies when consuming this same output.

## Data vintage and external validation

The parser and downloader target 2024 ISP material, with a targeted 2019 workbook input for selected thermal unit constraints and a 2023 IASR EV workbook input for EV-related data. PISP's source code identifies these files, but a reproducible study should still archive the exact downloaded files and record checksums.

Package constants such as bus coordinates, trace-year mappings, generator trace filename exceptions, hydro mappings, and buildout templates should be reviewed as modelling assumptions. Some of these values are code-derived or source-derived; others are pragmatic mappings needed to align published files with PISP's schema.

## Practical review checklist

Before using PISP output in a downstream study, check:

| Question | Why it matters |
|---|---|
| Which `reftrace`, `poe`, scenario IDs, and schedule tags were used? | They define the time-varying demand and VRE inputs. |
| Were the input files freshly downloaded or reused from an existing `downloadpath`? | Reused inputs may not match the intended source vintage. |
| Are `write_traces`, `check_exist_trace`, CSV, and Arrow settings consistent with the files being consumed? | Some schedules may be skipped intentionally. |
| Does the study require more network detail than the 12-bus representation? | PISP does not encode detailed nodal topology. |
| Are forced-outage, cost, efficiency, hydro, and buildout constants acceptable for the study? | These values can materially affect downstream optimisation or reliability results. |
| Are schedule values joined to the correct static table and scenario? | Schedule tables are overlays, not standalone assets. |
