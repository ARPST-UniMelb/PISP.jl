# Domain concepts

PISP represents the ISP as a connected data model rather than as a collection of independent CSV files.
The central distinction is between **assets**, which retain stable identities and mostly static parameters, and **schedules**, which describe how selected asset quantities change with scenario and time.

## Dataset relationships

```text
                         +----------------+
                         |      Bus       |
                         +----------------+
                           ^      ^      ^
                           |      |      |
             +-------------+      |      +-------------+
             |                    |                    |
        +---------+          +-----------+         +-------+
        | Demand  |          | Generator |         |  ESS  |
        +---------+          +-----------+         +-------+
             ^                    ^                    ^
             |                    |                    |
          +-----+          schedule tables      schedule tables
          | DER |                 |
          +-----+                 v
             ^              scenario and time
             |
       schedule tables

Bus <---------------------- Line ----------------------> Bus
                               ^
                               |
                         schedule tables
```

The identifiers in the static tables provide the joins:

- `Demand.id_bus`, `Generator.id_bus`, and `ESS.id_bus` attach assets to a bus.
- `DER.id_dem` attaches a demand-side resource to a demand node, which then identifies its bus.
- `Line.id_bus_from` and `Line.id_bus_to` connect two buses.
- Each schedule uses the corresponding asset identifier together with `scenario` and `date`.

## Modelling role of each static table

### `Bus`

A PISP bus is an aggregated ISP sub-region, not an electrical busbar in a nodal network model.
The table provides the common spatial index used by demand, generation, storage, and transmission corridors.
Its representative coordinates support regional identification and visualisation; they do not define detailed network geometry.

### `Demand`

A demand row represents a load node attached to a PISP bus.
The static row preserves identity, location, and demand-related flags, while `Demand_load_sched` provides the time-varying load used for a selected scenario and trace.
Separating the node from its load profile allows the same asset identity to be retained across many planning periods.

### `DER`

The `DER` table represents demand-side participation and EV-related quantities linked to demand nodes.
It is narrower than the general power-system meaning of distributed energy resources: rooftop PV is represented in `Generator`, and storage is represented in `ESS`.
`DER_pred_sched` carries the time-varying predicted quantity associated with each DER row.

### `Generator`

A generator row represents an existing unit, an aggregated renewable resource, or a future build-out asset used within the planning horizon.
The static table records identity, technology, connection, capacity-related fields, costs, outage inputs, and unit-commitment parameters.
Schedules then describe quantities that can change with planning year or trace, including maximum output, available unit count, and hydro inflow.

### `ESS`

An `ESS` row represents a battery, pumped-storage asset, or other storage resource connected to a bus.
The static table distinguishes discharge power, charging power, energy capacity, efficiency, reliability, and service attributes.
Separate schedules can change discharge power, charging power, energy capacity, unit count, and inflow without replacing the asset row.

### `Line`

A line row represents an aggregated transfer corridor or augmentation option between two PISP buses.
It is a planning-level connection rather than a detailed AC branch model.
Forward and reverse capacity schedules allow transfer limits to change across the study horizon while preserving the corridor identity.

## Why static tables and schedules are separate

```text
static row     = asset identity + stable parameters
schedule row   = scenario + timestamp + changing value
complete state = static row + applicable schedule overlays
```

!!! note "Why use schedule overlays?"
    Repeating every asset field for every hour would duplicate large amounts of unchanged information and make scenario comparisons harder.
    PISP instead stores stable information once and writes schedules only for quantities that vary.
    This design also makes the source of a change explicit: the static asset remains the same while the scheduled quantity changes.

[Output tables](@ref) lists the current static and schedule tables, output names, identifier columns, and relationships.

A missing schedule row does not necessarily mean that an asset is absent.
It can mean that the static value already applies, that no change was scheduled for that period, or that trace-dependent schedules were intentionally not written.

## Scenario model

The `scenarios` keyword to `build_ISP24_datasets` selects the package-defined scenario IDs. Several source files use different labels for the same scenario, so PISP reconciles those labels and retains numeric scenario IDs in exported schedules.

[Parameters and mappings](@ref) lists the current public scenario names and source-specific labels.

## Planning years, date ranges, and the 1 July split

PISP can build output by planning year or by explicit date range:

| Mode | Keyword | Output schedule tag | Split behaviour |
|---|---|---|---|
| Planning year | `years = [year]` | `schedule-<year>` | Creates January-June and July-December problem blocks for each scenario. |
| Date range | `drange = [(start, end)]` | `schedule-DDMMYYYY-DDMMYYYY` | Splits only when the requested range crosses 1 July. |

The split aligns problem blocks with source inputs organised by Australian financial year.
Static tables are still written once per build folder; the split affects the scenario/time blocks used to populate schedules.

## Trace year and probability of exceedance

Two build arguments determine important time-varying inputs: `reftrace` selects the reference weather trace, and `poe` selects the demand probability-of-exceedance series.

For `reftrace = 4006`, PISP maps each financial year to a selected historical weather year.
The mapping is part of the scenario/time definition, not merely a filename convention.
Comparisons that ignore the paired weather year can mix planning-year effects with weather-year effects.
See [Parameters and mappings](@ref) for the full map.

## NEM bus and area model

PISP represents the East Coast Australian system through package-defined ISP sub-regional buses and NEM market areas. [Parameters and mappings](@ref) lists the current bus names, representative coordinates, and area relationships.

This representation is suitable for aggregated planning studies and data preparation.
It does not contain intra-sub-region topology, bus voltages, detailed line impedances, or the constraints required for a nodal AC network model.

## Solar and wind classification

When aggregating variable renewable generation from PISP output, classify rows by `Generator.tech`, not by `Generator.fuel` alone.
Technology labels preserve distinctions such as rooftop PV and utility-scale PV that can be lost in a broader fuel grouping.
The [Working with PISP-generated outputs](@ref) tutorial uses case-insensitive `pv` or `solar` matches for solar and `wind` for wind.

## See also

- [Output tables](@ref) documents the exported filenames, join keys, and value units.
- [Parameters and mappings](@ref) records the trace-year map, bus constants, and technology-specific assumptions.
- [Assumptions and scope](@ref) explains the limits of the aggregated network and static reliability treatment.
