# What PISP does and does not model

PISP is a **data parser and dataset builder**, not a power-system solver. Its dependencies (see `Project.toml`) are limited to data-handling and web-scraping packages — there is no linear/mixed-integer solver, no optimization layer, and no dispatch or unit-commitment engine anywhere in the package. `build_ISP24_datasets` reads AEMO's published ISP workbooks and traces, applies a fixed set of parsing and derivation rules, and writes out the resulting `Bus`/`Demand`/`DER`/`ESS`/`Generator`/`Line` tables and their time-varying schedules. It does not itself run an economic dispatch, a security-constrained unit commitment, or any other simulation against those tables — that is left entirely to whatever downstream tool consumes PISP's output. The `problem_type` column PISP writes into its internal problem table is a `"UC"` label describing the *kind* of study the output is intended for, not a computation PISP performs.

The list below covers the modelling choices and simplifications baked into PISP's output tables themselves, so a downstream user knows what is and isn't already captured before building a study on top of them.

## Network topology

PISP represents the East Coast Australian power system as **12 named ISP sub-regional buses** (Northern Queensland, Central Queensland, Gladstone Grid, Southern Queensland, Northern New South Wales, Central New South Wales, Sydney/Newcastle/Wollongong, Southern New South Wales, Victoria, Tasmania, Central South Australia, South East South Australia), each pinned to a single representative latitude/longitude. Those 12 buses are aggregated into **5 NEM market areas** (QLD, NSW, VIC, TAS, SA) via a fixed bus-to-area map. This is a single-node-per-sub-region aggregation: there is no finer-grained intra-sub-region topology, and the `Bus` table itself is built from a hardcoded package table rather than parsed out of an AEMO workbook at build time.

## Forced outages are static, not time-varying, and not modelled uniformly across asset types

Every forced-outage-related column PISP writes (`forate`, `fullout`, `partialout`, `derate`, `mttrfull`, `mttrpart`) is a single static value on the asset's row — none of PISP's time-varying schedule tables carries an outage rate, so a downstream user cannot recover a seasonal or year-by-year change in outage behaviour from PISP's output alone.

The three asset types that carry outage data do not carry the same fields:

- **Generator** rows carry a full `fullout`/`partialout`/`derate` triple and a single combined `forate`, computed once as `forate = 1 − (fullout + partialout × (1 − derate))`.
- **ESS** rows carry `fullout`/`partialout` but no `derate` and no combined `forate` column.
- **Line** rows carry only a single `fullout` (single-credible-contingency) value — no `partialout`, no `derate`.

## Input data vintage

PISP is built around AEMO's **2024** Integrated System Plan release: the parser, scraper, and pipeline entry point are all specific to that vintage, and there is no alternate-year parsing path. The one exception is a small, targeted read of a 2019-vintage Inputs and Assumptions workbook, used solely to source minimum up/minimum down times for a subset of older gas/coal generating units — this is a secondary input inside the 2024 pipeline, not a second supported input vintage.

## DER scope

The `DER` table represents **demand-side participation and electric-vehicle charging demand only** — it is not a general distributed-energy-resource category. Its rows come from exactly two sources: cost-banded demand-reduction offers attached to controllable demand nodes, and one electric-vehicle placeholder per bus. Other resources that might colloquially be called "DER" are represented elsewhere in PISP's schema instead: rooftop solar PV is written as its own row in the `Generator` table (technology `RoofPV`), not as a `DER` row, and behind-the-meter or grid-scale batteries are written to the `ESS` table.

## Unverifiable or out-of-scope claims

The above is what PISP's own code and schema establish. Two things this page deliberately does not claim:

- Whether PISP's static and derived values (forced-outage rates, efficiencies, and similar per-technology constants) match the *current* edition of AEMO's published inputs is not something the code alone can confirm — that depends on keeping the underlying AEMO workbooks up to date, which is outside PISP's own logic.
- This page describes categorical modelling choices, not every hardcoded numeric default in PISP's parameter files — there are many per-technology constants (efficiencies, outage rates, and similar) that are not individually catalogued here.
