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
static_tables
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>6×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">output_table</th><th style = "text-align: left;">container_field</th><th style = "text-align: left;">primary_id</th><th style = "text-align: left;">relationship_ids</th><th style = "text-align: left;">columns</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Bus</td><td style = "text-align: left;">bus</td><td style = "text-align: left;">id_bus</td><td style = "text-align: left;">id_area</td><td style = "text-align: left;">id_bus, name, alias, active, latitude, longitude, id_area</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">Demand</td><td style = "text-align: left;">dem</td><td style = "text-align: left;">id_dem</td><td style = "text-align: left;">id_bus</td><td style = "text-align: left;">id_dem, name, load_, id_bus, active, controllable, voll, contingency</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">ESS</td><td style = "text-align: left;">ess</td><td style = "text-align: left;">id_ess</td><td style = "text-align: left;">id_bus</td><td style = "text-align: left;">id_ess, name, alias, tech, type, capacity, investment, active, id_bus, ch_eff, dch_eff, eini, emin, emax, pmin, pmax, lmin, lmax, fullout, partialout, mttrfull, mttrpart, inertia, powerfactor, ffr, pfr, res2, res3, fr_db, fr_ad, fr_dt, fr_frt, fr_fr, longitude, latitude, n, contingency</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">Generator</td><td style = "text-align: left;">gen</td><td style = "text-align: left;">id_gen</td><td style = "text-align: left;">id_bus</td><td style = "text-align: left;">id_gen, name, alias, fuel, tech, type, capacity, forate, fullout, partialout, derate, mttrfull, mttrpart, id_bus, pmin, pmax, rup, rdw, investment, active, cvar, cfuel, cvom, cfom, co2, slope, hrate, pfrmax, g, inertia, ffr, pfr, res2, res3, powerfactor, latitude, longitude, n, contingency, down_time, up_time, last_state, last_state_period, last_state_output, start_up_cost, shut_down_cost, start_up_time, shut_down_time</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">Line</td><td style = "text-align: left;">line</td><td style = "text-align: left;">id_lin</td><td style = "text-align: left;">id_bus_from, id_bus_to</td><td style = "text-align: left;">id_lin, name, alias, tech, capacity, id_bus_from, id_bus_to, investment, active, r, x, rvcap, fwcap, fullout, mttrfull, voltage, segments, latitude, longitude, length, n, contingency</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">DER</td><td style = "text-align: left;">der</td><td style = "text-align: left;">id_der</td><td style = "text-align: left;">id_dem</td><td style = "text-align: left;">id_der, name, tech, id_dem, active, investment, capacity, reduct, pred_max, cost_red, n</td></tr></tbody></table></div>
```

## Schedule tables

Schedule tables carry scenario- and time-dependent values. The output filename is taken from the same `alt_names` mapping used by the CSV and Arrow writers.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
schedule_tables = container_inventory(schedule_container)
schedule_tables
````

```@raw html
</details>
```

```@raw html
<div><div style = "float: left;"><span>12×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">output_table</th><th style = "text-align: left;">container_field</th><th style = "text-align: left;">primary_id</th><th style = "text-align: left;">relationship_ids</th><th style = "text-align: left;">columns</th></tr><tr class = "columnLabelRow"><th class = "stubheadLabel" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th></tr></thead><tbody><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">Demand_load_sched</td><td style = "text-align: left;">dem_load</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_dem</td><td style = "text-align: left;">id, id_dem, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">ESS_emax_sched</td><td style = "text-align: left;">ess_emax</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_ess</td><td style = "text-align: left;">id, id_ess, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">ESS_lmax_sched</td><td style = "text-align: left;">ess_lmax</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_ess</td><td style = "text-align: left;">id, id_ess, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">ESS_n_sched</td><td style = "text-align: left;">ess_n</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_ess</td><td style = "text-align: left;">id, id_ess, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">ESS_pmax_sched</td><td style = "text-align: left;">ess_pmax</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_ess</td><td style = "text-align: left;">id, id_ess, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">ESS_inflow_sched</td><td style = "text-align: left;">ess_inflow</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_ess</td><td style = "text-align: left;">id, id_ess, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">Generator_n_sched</td><td style = "text-align: left;">gen_n</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_gen</td><td style = "text-align: left;">id, id_gen, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">Generator_pmax_sched</td><td style = "text-align: left;">gen_pmax</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_gen</td><td style = "text-align: left;">id, id_gen, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">Generator_inflow_sched</td><td style = "text-align: left;">gen_inflow</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_gen</td><td style = "text-align: left;">id, id_gen, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">Line_fwcap_sched</td><td style = "text-align: left;">line_fwcap</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_lin</td><td style = "text-align: left;">id, id_lin, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">Line_rvcap_sched</td><td style = "text-align: left;">line_rvcap</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_lin</td><td style = "text-align: left;">id, id_lin, scenario, date, value</td></tr><tr class = "dataRow"><td class = "rowLabel" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">DER_pred_sched</td><td style = "text-align: left;">der_pred</td><td style = "text-align: left;">id</td><td style = "text-align: left;">id_der</td><td style = "text-align: left;">id, id_der, scenario, date, value</td></tr></tbody></table></div>
```

## Output directory pattern

Static tables are written directly under a format directory such as `csv/` or `arrow/`. Time-varying tables are written under `schedule-<tag>/`, where the tag is either a planning year or an explicit date range.

A schedule is an overlay, not an independent asset inventory. Reconstruct a system state by selecting the required scenario and timestamp, joining the schedule to its static table, and replacing only the quantity represented by the schedule.

## Using the output tables

- Identifier columns define table relationships; row order does not.
- `scenario` and `date` are part of the schedule key even when an analysis displays only one scenario or period.
- Units follow the represented quantity: power and transfer limits are in MW, storage energy and inflow quantities are in MWh, and unit-count schedules are counts.
- Solar and wind schedule values should not be normalised by static `Generator.pmax` without applying the modelling convention described in [Assumptions and scope](@ref).

