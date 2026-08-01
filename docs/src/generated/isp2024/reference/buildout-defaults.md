```@meta
EditURL = "../../../../literate/isp2024/reference/buildout_defaults.jl"
```

# ISP 2024: Build-out defaults

Optional build-out rows combine a small workbook contract with package-defined generator and storage defaults.
The workbook identifies the technology, subregion, capacity, build year, and unit count.
PISP supplies the remaining static-row values, generates identifiers and schedule keys, and computes capacity-dependent fields.

The tables below read the current PISP dictionaries and build-out mappings directly.
"Not defined in PISP" means that the active package supplies a value but does not define the field's meaning or unit.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils

const BUILDOUT_PARSER = joinpath(REPO_ROOT, "src", "parsers", "PISP-2024buildout.jl")
PISPDocUtils.validate_buildout_defaults_contract(BUILDOUT_PARSER)
````

```@raw html
</details>
```

## Source status

The build-out workbook supplies `tech`, `subregion`, `capacity`, `year`, and `n`. The parser generates or looks up identifiers and locations, calculates capacity-dependent fields, and obtains the remaining values from `PISP.params_buildout_bess` or `PISP.params_buildout_gen`.

Those template dictionaries are the current code authority for the displayed defaults. PISP does not encode an original external source for every numeric template value, so this page reports them as package-defined defaults rather than assigning an unsupported report or workbook citation. Fields labelled "Not defined in PISP" retain unverified meaning or units until a source or package contract establishes them.

## Supported workbook technology labels

A workbook label selects one PISP template. Storage labels also select the duration used to calculate `ESS.emax`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
reference_tables = PISPDocUtils.buildout_reference_tables()
PISPDocUtils.markdown_table(reference_tables.technology; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **buildout_label** | **output_table** | **template_key** | **duration_h** |
|:--|:--|:--|--:|
| `bess_1h` | ESS | `bess_1h` | 1.0 |
| `bess_2h` | ESS | `bess_2h` | 2.0 |
| `bess_4h` | ESS | `bess_4h` | 4.0 |
| `bess_8h` | ESS | `bess_8h` | 8.0 |
| `phsp_24h` | ESS | `phsp_24h` | 24.0 |
| `phsp_48h` | ESS | `phsp_48h` | 48.0 |
| `ccgt` | Generator | `ccgt` | missing |
| `ocgt_l` | Generator | `ocgt_large` | missing |
| `ocgt_s` | Generator | `ocgt_small` | missing |


## How a build-out row is assembled

PISP does not copy a complete static row from the workbook. Each output field has one of four origins: workbook input, generated or looked-up identity, an explicit calculation, or a package template.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.origins; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **output** | **field_group** | **rule** |
|:--|:--|:--|
| ESS static row | Workbook | `tech`, `subregion`, and `capacity` select, locate, and size the asset. |
| ESS static row | Generated or looked up | PISP generates `id_ess`, `name`, and `alias`, and resolves `id_bus` from the subregion. |
| ESS static row | Computed or explicit | `emax = duration_h × capacity`; `pmax = capacity`; `lmax = capacity`; coordinates are `0.0`. |
| ESS static row | Template | The 27 non-placeholder fields listed below come from `PISP.params_buildout_bess`. |
| ESS unit-count schedule | Workbook and generated | The workbook supplies `year` and `n`; PISP adds scenario IDs, row IDs, and `DateTime(year, 1, 1)`. |
| Generator static row | Workbook | `tech`, `subregion`, and `capacity` select, locate, and size the asset. |
| Generator static row | Generated or looked up | PISP generates `id_gen`, `name`, and `alias`, and resolves `id_bus` from the subregion. |
| Generator static row | Computed or explicit | `pmax = capacity`; coordinates are `0.0`. |
| Generator static row | Template | The 40 non-placeholder fields listed below come from `PISP.params_buildout_gen`. |
| Generator unit-count schedule | Workbook and generated | The workbook supplies `year` and `n`; PISP adds scenario IDs, row IDs, and `DateTime(year, 1, 1)`. |


## Template placeholders and their applied sources

`nothing` values in the raw template dictionaries are placeholders. The parser replaces or bypasses them using workbook values, generated identifiers, bus lookup, capacity calculations, or explicit coordinates.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.placeholders; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **output_table** | **field** | **applied_source** |
|:--|:--|:--|
| ESS | `alias` | Set equal to the generated name. |
| ESS | `capacity` | Read from the build-out workbook. |
| ESS | `emax` | Computed as duration in hours multiplied by workbook capacity. |
| ESS | `id_bus` | Looked up from the workbook subregion in the current bus table. |
| ESS | `id_ess` | Sequential identifier generated by PISP. |
| ESS | `latitude` | Set explicitly to `0.0` by the build-out parser. |
| ESS | `lmax` | Set to workbook capacity. |
| ESS | `longitude` | Set explicitly to `0.0` by the build-out parser. |
| ESS | `name` | Generated as `uppercase(tech * "_" * subregion) * "_NEW"`. |
| ESS | `pmax` | Set to workbook capacity. |
| Generator | `alias` | Set equal to the generated name. |
| Generator | `capacity` | Read from the build-out workbook. |
| Generator | `id_bus` | Looked up from the workbook subregion in the current bus table. |
| Generator | `id_gen` | Sequential identifier generated by PISP. |
| Generator | `latitude` | Set explicitly to `0.0` by the build-out parser. |
| Generator | `longitude` | Set explicitly to `0.0` by the build-out parser. |
| Generator | `name` | Generated as `uppercase(tech * "_" * subregion) * "_NEW"`. |
| Generator | `pmax` | Set to workbook capacity. |


## Storage defaults

These fields are written from the selected entry in `PISP.params_buildout_bess` to every new `ESS` static row.
The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

### Defaults shared by every storage template

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.ess_common; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **value** | **meaning** | **unit** |
|:--|--:|:--|:--|
| `investment` | 0.0 | Investment flag. | 0/1 flag |
| `active` | 1.0 | Active-status flag. | 0/1 flag |
| `eini` | 0.0 | Initial stored-energy level relative to `emax`. | fraction |
| `emin` | 0.0 | Minimum stored-energy level relative to `emax`. | fraction |
| `pmin` | 0.0 | Minimum discharging power per unit. | MW |
| `lmin` | 0.0 | Minimum charging input per unit. | MW |
| `partialout` | 0.0 | Partial forced-outage rate. | fraction of time |
| `mttrpart` | 1.0 | Mean time to repair after a partial outage. | h |
| `inertia` | 0.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `powerfactor` | 1.0 | Power-factor parameter. | ratio |
| `ffr` | 1.0 | Fast-frequency-response provision flag. | 0/1 flag |
| `pfr` | 0.0 | Primary-frequency-response provision flag. | 0/1 flag |
| `res2` | 1.0 | Secondary-reserve provision flag. | 0/1 flag |
| `res3` | 0.0 | Tertiary or regulation-reserve provision flag. | 0/1 flag |
| `fr_db` | 0.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `fr_ad` | 0.3 | Meaning not defined in PISP. | Not defined in PISP. |
| `fr_dt` | 0.05 | Meaning not defined in PISP. | Not defined in PISP. |
| `fr_frt` | 1000.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `fr_fr` | 70.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `n` | 0.0 | Static maximum unit-count field; the build-out schedule supplies the time-varying count. | units |
| `contingency` | 0.0 | Contingency-classification flag. | 0/1 flag |


### Defaults that vary by storage technology

Meaning and unit of each varying field:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.ess_varying_fields; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **meaning** | **unit** |
|:--|:--|:--|
| `tech` | Storage technology written to `ESS.tech`. | category |
| `type` | Storage-duration classification written to `ESS.type`. | category |
| `ch_eff` | Charging efficiency under PISP's stored-fraction convention. | fraction |
| `dch_eff` | Discharging efficiency under PISP's stored-fraction convention. | fraction |
| `fullout` | Full forced-outage rate. | fraction of time |
| `mttrfull` | Mean time to repair after a full outage. | h |


Value of each varying field by storage technology:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.ess_varying_values; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **buildout_label** | **tech** | **type** | **ch_eff** | **dch_eff** | **fullout** | **mttrfull** |
|:--|:--|:--|--:|--:|--:|--:|
| `bess_1h` | BESS | SHALLOW | 0.916515 | 0.916515 | 0.0225 | 48.0 |
| `bess_2h` | BESS | SHALLOW | 0.916515 | 0.916515 | 0.0225 | 48.0 |
| `bess_4h` | BESS | MEDIUM | 0.921954 | 0.921954 | 0.0225 | 48.0 |
| `bess_8h` | BESS | MEDIUM | 0.911043 | 0.911043 | 0.0225 | 48.0 |
| `phsp_24h` | PS | DEEP | 0.87178 | 0.87178 | 0.01 | 27.0 |
| `phsp_48h` | PS | DEEP | 0.87178 | 0.87178 | 0.01 | 27.0 |


## Generator defaults

These fields are written from the selected entry in `PISP.params_buildout_gen` to every new `Generator` static row.
The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

### Defaults shared by every generator template

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.gen_common; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **value** | **meaning** | **unit** |
|:--|:--|:--|:--|
| `fuel` | Natural Gas | Generator fuel category. | category |
| `partialout` | 0.0 | Partial forced-outage rate. | fraction of time |
| `derate` | 0.0 | Capacity derating during a partial outage. | fraction |
| `mttrpart` | 0.0 | Mean time to repair after a partial outage. | h |
| `rup` | 22.0 | Ramp-up capability. | MW/min |
| `rdw` | 22.0 | Ramp-down capability. | MW/min |
| `investment` | 0 | Investment flag. | 0/1 flag |
| `active` | 1 | Active-status flag. | 0/1 flag |
| `pfrmax` | 0.1 | Maximum headroom available for frequency response. | MW |
| `g` | 0.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `inertia` | 4.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `ffr` | 0 | Fast-frequency-response provision flag. | 0/1 flag |
| `pfr` | 1 | Primary-frequency-response provision flag. | 0/1 flag |
| `res2` | 1 | Secondary-reserve provision flag. | 0/1 flag |
| `res3` | 0 | Tertiary or regulation-reserve provision flag. | 0/1 flag |
| `powerfactor` | 0.85 | Power-factor parameter. | ratio |
| `n` | 0 | Static maximum unit-count field; the build-out schedule supplies the time-varying count. | units |
| `contingency` | 1 | Contingency-classification flag. | 0/1 flag |
| `last_state` | 0.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `last_state_period` | 0.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `last_state_output` | 0.0 | Meaning not defined in PISP. | Not defined in PISP. |
| `start_up_cost` | 0.0 | Startup cost. | \$ |
| `shut_down_cost` | 0.0 | Shutdown cost. | \$ |
| `start_up_time` | 0.0 | Time required to start a unit. | h |
| `shut_down_time` | 0.0 | Time required to shut down a unit. | h |


### Defaults that vary by generator technology

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
PISPDocUtils.markdown_table(reference_tables.gen_varying; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **meaning** | **unit** | **ccgt** | **ocgt_l** | **ocgt_s** |
|:--|:--|:--|:--|:--|:--|
| `tech` | Generator technology. | category | CCGT | OCGT | OCGT |
| `type` | Generator type or planning classification. | category | CCGT | OCGT | OCGT |
| `forate` | Aggregate availability factor after full- and partial-outage effects. | fraction | 0.965 | 0.98 | 0.98 |
| `fullout` | Full forced-outage rate. | fraction of time | 0.035 | 0.02 | 0.02 |
| `mttrfull` | Mean time to repair after a full outage. | h | 54.0 | 22.0 | 75.0 |
| `pmin` | Minimum power output per unit. | MW | 46.0 | 0.0 | 0.0 |
| `cvar` | Variable generation cost. | \$/MWh | 118.123 | 192.876 | 185.356 |
| `cfuel` | Fuel cost. | \$/GJ | 15.7488 | 16.9304 | 16.9304 |
| `cvom` | Variable operation and maintenance cost. | \$/MWh | 3.95641 | 7.80589 | 12.8316 |
| `cfom` | Fixed operation and maintenance cost parameter. | \$/MW/yr | 11655.4 | 10906.9 | 13473.2 |
| `co2` | Carbon-dioxide emissions intensity. | kgCO2/MWh | 173.502 | 266.905 | 248.812 |
| `slope` | Meaning not defined in PISP. | Not defined in PISP. | 0.4 | 0.6 | 0.6 |
| `hrate` | Generator heat rate. | GJ/MWh | 7.24923 | 10.9312 | 10.1902 |
| `down_time` | Minimum down time after shutdown. | h | 4.0 | 0.0 | 0.0 |
| `up_time` | Minimum up time after startup. | h | 4.0 | 0.0 | 0.0 |


## Override and derivation rules

The workbook cannot override template fields directly. Changing a template field requires changing PISP's build-out parameter dictionaries.
Capacity affects `capacity`, `pmax`, and, for storage, `lmax` and `emax`; subregion affects `id_bus`; year and `n` affect only the unit-count schedule.
Uniform mode applies one workbook sheet to every ISP scenario. Scenario-specific mode reads one sheet per scenario, unions static assets by generated name, and keeps each scenario's unit-count schedule separate.

See the [preprocessing workflow](../../../editions/isp2024-preprocessing.md) for the stage at which build-outs are inserted, [assumptions and scope](../../../assumptions.md) for the modelling boundary, and [output tables](output-tables.md) for the complete static and schedule schemas.

