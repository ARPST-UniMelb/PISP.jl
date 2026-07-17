```@meta
EditURL = "../../../literate/reference/output_tables.jl"
```

# Output tables

A PISP build writes static asset tables once per build and time-varying schedule tables under one or more schedule directories. The tables below list the current output names, identifiers, relationships, and columns.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames

const REPO_ROOT = normpath(get(
    ENV,
    "PISP_DOCS_REPO_ROOT",
    joinpath(@__DIR__, "..", "..", ".."),
))

include(joinpath(REPO_ROOT, "eda", "eda_support.jl"))
using .EdaSupport

function container_inventory(container)
    rows = NamedTuple[]
    for field in fieldnames(typeof(container))
        table = getfield(container, field)
        table isa DataFrame || continue
        output_name = get(PISP.alt_names, field, string(field))
        columns = string.(names(table))
        id_columns = filter(name -> startswith(name, "id"), columns)
        relationship_ids = length(id_columns) > 1 ? id_columns[2:end] : String[]
        push!(
            rows,
            (
                output_table = output_name,
                container_field = string(field),
                primary_id = isempty(id_columns) ? "" : first(id_columns),
                relationship_ids = join(relationship_ids, ", "),
                columns = join(columns, ", "),
            ),
        )
    end
    return DataFrame(rows)
end

_tc, static_container, schedule_container = PISP.initialise_time_structures()
````

```@raw html
</details>
```

````
(PISP.PISPtimeConfig(0×8 DataFrame
 Row │ id     name    scenario  weight   problem_type  dstart    dend      tstep
     │ Int64  String  Int64     Float64  String        DateTime  DateTime  Int64
─────┴───────────────────────────────────────────────────────────────────────────), PISP.PISPtimeStatic(0×7 DataFrame
 Row │ id_bus  name    alias   active  latitude  longitude  id_area
     │ Int64   String  String  Bool    Float64   Float64    Int64
─────┴──────────────────────────────────────────────────────────────, 0×8 DataFrame
 Row │ id_dem  name    load_    id_bus  active  controllable  voll     contingency
     │ Int64   String  Float64  Int64   Bool    Bool          Float64  Bool
─────┴─────────────────────────────────────────────────────────────────────────────, 0×37 DataFrame
 Row │ id_ess  name    alias   tech    type    capacity  investment  active  id_bus  ch_eff   dch_eff  eini     emin     emax     pmin     pmax     lmin     lmax     fullout  partialout  mttrfull  mttrpart  inertia  powerfactor  ffr   pfr   res2  res3  fr_db    fr_ad    fr_dt    fr_frt   fr_fr    longitude  latitude  n      contingency
     │ Int64   String  String  String  String  Float64   Bool        Bool    Int64   Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64     Float64   Float64   Float64  Float64      Bool  Bool  Bool  Bool  Float64  Float64  Float64  Float64  Float64  Float64    Float64   Int64  Bool
─────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────, 0×48 DataFrame
 Row │ id_gen  name    alias   fuel    tech    type    capacity  forate   fullout  partialout  derate   mttrfull  mttrpart  id_bus  pmin     pmax     rup      rdw      investment  active  cvar     cfuel    cvom     cfom     co2      slope    hrate    pfrmax   g        inertia  ffr   pfr   res2  res3  powerfactor  latitude  longitude  n      contingency  down_time  up_time  last_state  last_state_period  last_state_output  start_up_cost  shut_down_cost  start_up_time  shut_down_time
     │ Int64   String  String  String  String  String  Float64   Float64  Float64  Float64     Float64  Float64   Float64   Int64   Float64  Float64  Float64  Float64  Bool        Bool    Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64  Float64  Bool  Bool  Bool  Bool  Float64      Float64   Float64    Int64  Bool         Float64    Float64  Float64     Float64            Float64            Float64        Float64         Float64        Float64
─────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────, 0×22 DataFrame
 Row │ id_lin  name    alias   tech    capacity  id_bus_from  id_bus_to  investment  active  r        x        rvcap    fwcap    fullout  mttrfull  voltage  segments  latitude  longitude  length   n      contingency
     │ Int64   String  String  String  Float64   Int64        Int64      Bool        Bool    Float64  Float64  Float64  Float64  Float64  Float64   Float64  Int64     String    String     Float64  Int64  Bool
─────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────, 0×11 DataFrame
 Row │ id_der  name    tech    id_dem  active  investment  capacity  reduct  pred_max  cost_red  n
     │ Int64   String  String  Int64   Bool    Bool        Float64   Bool    Float64   Float64   Int64
─────┴─────────────────────────────────────────────────────────────────────────────────────────────────), PISP.PISPtimeVarying(0×5 DataFrame
 Row │ id     id_dem  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_ess  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_ess  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_ess  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Int64
─────┴──────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_ess  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_ess  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_gen  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Int64
─────┴──────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_gen  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_gen  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_lin  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_lin  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────, 0×5 DataFrame
 Row │ id     id_der  scenario  date      value
     │ Int64  Int64   Int64     DateTime  Float64
─────┴────────────────────────────────────────────))
````

## Static asset tables

Static tables define asset identity and time-invariant attributes. Schedule rows should be joined back to these tables through the relationship identifier shown in the generated schema.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
static_tables = container_inventory(static_container)
markdown_table(static_tables)
````

```@raw html
</details>
```

| **output\_table** | **container\_field** | **primary\_id** | **relationship\_ids** | **columns** |
|--:|--:|--:|--:|--:|
| Bus | bus | id\_bus | id\_area | id\_bus, name, alias, active, latitude, longitude, id\_area |
| Demand | dem | id\_dem | id\_bus | id\_dem, name, load\_, id\_bus, active, controllable, voll, contingency |
| ESS | ess | id\_ess | id\_bus | id\_ess, name, alias, tech, type, capacity, investment, active, id\_bus, ch\_eff, dch\_eff, eini, emin, emax, pmin, pmax, lmin, lmax, fullout, partialout, mttrfull, mttrpart, inertia, powerfactor, ffr, pfr, res2, res3, fr\_db, fr\_ad, fr\_dt, fr\_frt, fr\_fr, longitude, latitude, n, contingency |
| Generator | gen | id\_gen | id\_bus | id\_gen, name, alias, fuel, tech, type, capacity, forate, fullout, partialout, derate, mttrfull, mttrpart, id\_bus, pmin, pmax, rup, rdw, investment, active, cvar, cfuel, cvom, cfom, co2, slope, hrate, pfrmax, g, inertia, ffr, pfr, res2, res3, powerfactor, latitude, longitude, n, contingency, down\_time, up\_time, last\_state, last\_state\_period, last\_state\_output, start\_up\_cost, shut\_down\_cost, start\_up\_time, shut\_down\_time |
| Line | line | id\_lin | id\_bus\_from, id\_bus\_to | id\_lin, name, alias, tech, capacity, id\_bus\_from, id\_bus\_to, investment, active, r, x, rvcap, fwcap, fullout, mttrfull, voltage, segments, latitude, longitude, length, n, contingency |
| DER | der | id\_der | id\_dem | id\_der, name, tech, id\_dem, active, investment, capacity, reduct, pred\_max, cost\_red, n |


## Schedule tables

Schedule tables carry scenario- and time-dependent values. The output filename is taken from the same `alt_names` mapping used by the CSV and Arrow writers.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
schedule_tables = container_inventory(schedule_container)
markdown_table(schedule_tables)
````

```@raw html
</details>
```

| **output\_table** | **container\_field** | **primary\_id** | **relationship\_ids** | **columns** |
|--:|--:|--:|--:|--:|
| Demand\_load\_sched | dem\_load | id | id\_dem | id, id\_dem, scenario, date, value |
| ESS\_emax\_sched | ess\_emax | id | id\_ess | id, id\_ess, scenario, date, value |
| ESS\_lmax\_sched | ess\_lmax | id | id\_ess | id, id\_ess, scenario, date, value |
| ESS\_n\_sched | ess\_n | id | id\_ess | id, id\_ess, scenario, date, value |
| ESS\_pmax\_sched | ess\_pmax | id | id\_ess | id, id\_ess, scenario, date, value |
| ESS\_inflow\_sched | ess\_inflow | id | id\_ess | id, id\_ess, scenario, date, value |
| Generator\_n\_sched | gen\_n | id | id\_gen | id, id\_gen, scenario, date, value |
| Generator\_pmax\_sched | gen\_pmax | id | id\_gen | id, id\_gen, scenario, date, value |
| Generator\_inflow\_sched | gen\_inflow | id | id\_gen | id, id\_gen, scenario, date, value |
| Line\_fwcap\_sched | line\_fwcap | id | id\_lin | id, id\_lin, scenario, date, value |
| Line\_rvcap\_sched | line\_rvcap | id | id\_lin | id, id\_lin, scenario, date, value |
| DER\_pred\_sched | der\_pred | id | id\_der | id, id\_der, scenario, date, value |


## Output directory pattern

Static tables are written directly under a format directory such as `csv/` or `arrow/`. Time-varying tables are written under `schedule-<tag>/`, where the tag is either a planning year or an explicit date range.

A schedule is an overlay, not an independent asset inventory. Reconstruct a system state by selecting the required scenario and timestamp, joining the schedule to its static table, and replacing only the quantity represented by the schedule.

## Using the output tables

- Identifier columns define table relationships; row order does not.
- `scenario` and `date` are part of the schedule key even when an analysis displays only one scenario or period.
- Units follow the represented quantity: power and transfer limits are in MW, storage energy and inflow quantities are in MWh, and unit-count schedules are counts.
- Solar and wind schedule values should not be normalised by static `Generator.pmax` without applying the modelling convention described in [Assumptions and scope](@ref).

