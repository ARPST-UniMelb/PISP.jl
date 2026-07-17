# Output data model

PISP's documented output contract applies to the ISP 2024 build.
The build can write CSV and Arrow representations of static asset tables and time-varying schedule tables.

Static tables provide the identities and comparatively stable attributes of buses, demand nodes, distributed energy resources, generators, energy-storage systems, and transmission corridors.
Schedule tables record selected quantities that vary with scenario and time.
The relevant identifiers, scenario fields, and date fields are part of the relationship between a schedule and its static table.

The [ISP 2024 output tables](../generated/isp2024/reference/output-tables.md) page is the authoritative reference for exported filenames, columns, units, and join rules.
The [domain concepts](../concepts.md) page explains why static rows and schedule rows are kept separate.

No equivalent ISP 2026 output contract is provided by PISP.
A cross-release analysis must define and validate a 2026 data model before comparing it with these 2024 outputs.
