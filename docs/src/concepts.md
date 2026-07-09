# Domain concepts

This page collects a handful of domain conventions that recur across PISP's build options and output tables, so they have one place to be looked up rather than being re-derived from tutorial code each time.

## AEMO's three ISP scenarios and the financial-year half split

Every PISP build is organised around AEMO's three 2024 Integrated System Plan scenarios — *Progressive Change*, *Step Change*, and *Green Energy Exports* — selectable via the `scenarios` keyword of `build_ISP24_datasets` (default: all three).

Independently of scenario, PISP also splits each calendar year into two halves — January–June and July–December — because that 1 July boundary is where some of the underlying AEMO input files themselves change. Building a whole planning year always produces one block per scenario per half (so 3 scenarios × 2 halves = 6 blocks for a full year); building an arbitrary date range only splits at 1 July if the requested window actually straddles it.

## Reference trace and probability-of-exceedance defaults

Two build-time parameters control which AEMO weather/demand trace year is used:

- `reftrace` selects the reference weather year trace: an individual historical year (2011–2023), or `4006`, which is the trace associated with the ISP's Optimal Development Path (ODP) — the default used across PISP's own build examples.
- `poe` selects the demand probability-of-exceedance level: 10% or 50%, i.e. how likely the modelled demand is to be exceeded in a given year.

Both are ordinary keyword arguments to `build_ISP24_datasets`; there is no separate "recommended" value baked into the parsing logic beyond the 4006 default used in PISP's own examples and documentation.

## Area map and the solar/wind classification rule

Every bus in PISP's `Bus` table carries an `id_area`, mapping it onto one of the five NEM market areas (QLD, NSW, VIC, TAS, SA); joining that onto `id_bus` in the `Generator`, `ESS`, or `Demand` tables (or `id_bus_from`/`id_bus_to` in `Line`) assigns every other row an area as well.

When classifying generators as solar or wind — for example, to aggregate fleet-wide output — match on the `tech` column with a case-insensitive substring search (`"pv"`/`"solar"` for solar, `"wind"` for wind), not an exact match on `fuel`. `tech` is the finer-grained column PISP actually uses to distinguish, for example, rooftop PV from utility-scale PV, so a `tech`-based match captures distinctions a `fuel`-based match would collapse.

## Static tables vs. hourly schedules

Every PISP table has a static row per asset, but only some assets also get an hourly time-varying schedule. In a typical PISP build, generator output schedules (`Generator_pmax_sched`) exist only for the assets whose output genuinely varies within a year — chiefly the solar and wind fleet — while every other generator keeps a single static `pmax` value in the `Generator` table itself. The same static/schedule split applies to the other schedule tables PISP produces (demand load, ESS state-of-charge limits, line ratings, DER prediction): a table only gets a schedule counterpart where the underlying AEMO input is itself time-varying: this is also the practical rule for interpreting PISP's output — before joining in a schedule table, check whether the asset in question actually has rows in it, or whether its static value in the corresponding time-static table is already the complete picture.
