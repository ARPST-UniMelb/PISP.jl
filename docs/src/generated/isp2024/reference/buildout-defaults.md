```@meta
EditURL = "../../../../literate/isp2024/reference/buildout_defaults.jl"
```

# ISP 2024: Build-out defaults

Optional build-out rows combine a user-supplied workbook with the generator and storage defaults used by ParseISP.
The workbook supplies the technology, subregion, capacity, build year, and unit count.
ParseISP uses the selected template to complete the static asset row and create the corresponding unit-count schedule.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using ParseISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

const BUILDOUT_PARSER = joinpath(REPO_ROOT, "src", "parsers", "ParseISP-2024buildout.jl")
ParseISPDocUtils.validate_buildout_defaults_contract(BUILDOUT_PARSER)
````

```@raw html
</details>
```

## Parameter sources

The build-out workbook is user-supplied and is separate from AEMO's ISP workbooks.
Stored template values are classified as `ISP workbook`, `Published report`, or `ParseISP default`.
`ParseISP default` denotes a value currently maintained in ParseISP whose upstream workbook or report source has not yet been identified.

Field meanings and units are defined in the [output tables](output-tables.md).

## Supported build-out technology labels

A workbook label selects one ParseISP template. Storage labels also select the duration used to calculate `ESS.emax`.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
reference_tables = ParseISPDocUtils.buildout_reference_tables()
ParseISPDocUtils.markdown_table(reference_tables.technology; allow_markdown_in_cells = true)
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

ParseISP does not copy a complete static row from the workbook. Each output field is supplied by the build-out workbook, generated or looked up, calculated explicitly, or read from the selected stored defaults.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.origins; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **output** | **field_group** | **rule** |
|:--|:--|:--|
| ESS static row | Build-out workbook | `tech`, `subregion`, and `capacity` select, locate, and size the asset. |
| ESS static row | Generated or looked up | ParseISP generates `id_ess`, `name`, and `alias`, and resolves `id_bus` from the subregion. |
| ESS static row | Calculated or explicit | `emax = duration_h × capacity`; `pmax = capacity`; `lmax = capacity`; coordinates are `0.0`. |
| ESS static row | Stored default | The 27 non-placeholder fields listed below come from `ParseISP.params_buildout_bess`. |
| ESS unit-count schedule | Build-out workbook and generated | The workbook supplies `year` and `n`; ParseISP adds scenario IDs, row IDs, and `DateTime(year, 1, 1)`. |
| Generator static row | Build-out workbook | `tech`, `subregion`, and `capacity` select, locate, and size the asset. |
| Generator static row | Generated or looked up | ParseISP generates `id_gen`, `name`, and `alias`, and resolves `id_bus` from the subregion. |
| Generator static row | Calculated or explicit | `pmax = capacity`; coordinates are `0.0`. |
| Generator static row | Stored default | The 40 non-placeholder fields listed below come from `ParseISP.params_buildout_gen`. |
| Generator unit-count schedule | Build-out workbook and generated | The workbook supplies `year` and `n`; ParseISP adds scenario IDs, row IDs, and `DateTime(year, 1, 1)`. |


## Template placeholders and applied rules

`nothing` values in the raw template dictionaries are placeholders. The parser replaces them using workbook values, generated identifiers, bus lookup, capacity calculations, or explicit coordinates.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.placeholders; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **output_table** | **field** | **applied_rule** |
|:--|:--|:--|
| ESS | `alias` | Set equal to the generated name. |
| ESS | `capacity` | Read from the build-out workbook. |
| ESS | `emax` | Computed as duration in hours multiplied by workbook capacity. |
| ESS | `id_bus` | Looked up from the workbook subregion in the current bus table. |
| ESS | `id_ess` | Sequential identifier generated by ParseISP. |
| ESS | `latitude` | Set explicitly to `0.0` by the build-out parser. |
| ESS | `lmax` | Set to workbook capacity. |
| ESS | `longitude` | Set explicitly to `0.0` by the build-out parser. |
| ESS | `name` | Generated as `uppercase(tech * "_" * subregion) * "_NEW"`. |
| ESS | `pmax` | Set to workbook capacity. |
| Generator | `alias` | Set equal to the generated name. |
| Generator | `capacity` | Read from the build-out workbook. |
| Generator | `id_bus` | Looked up from the workbook subregion in the current bus table. |
| Generator | `id_gen` | Sequential identifier generated by ParseISP. |
| Generator | `latitude` | Set explicitly to `0.0` by the build-out parser. |
| Generator | `longitude` | Set explicitly to `0.0` by the build-out parser. |
| Generator | `name` | Generated as `uppercase(tech * "_" * subregion) * "_NEW"`. |
| Generator | `pmax` | Set to workbook capacity. |


## Storage defaults

These fields are written from the selected entry in `ParseISP.params_buildout_bess` to every new `ESS` static row.
The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

### Defaults shared by every storage template

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.ess_common; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **value** | **source** |
|:--|--:|:--|
| `investment` | 0.0 | ParseISP default |
| `active` | 1.0 | ParseISP default |
| `eini` | 0.0 | ParseISP default |
| `emin` | 0.0 | ParseISP default |
| `pmin` | 0.0 | ParseISP default |
| `lmin` | 0.0 | ParseISP default |
| `partialout` | 0.0 | ParseISP default |
| `mttrpart` | 1.0 | ParseISP default |
| `inertia` | 0.0 | ParseISP default |
| `powerfactor` | 1.0 | ParseISP default |
| `ffr` | 1.0 | ParseISP default |
| `pfr` | 0.0 | ParseISP default |
| `res2` | 1.0 | ParseISP default |
| `res3` | 0.0 | ParseISP default |
| `fr_db` | 0.0 | ParseISP default |
| `fr_ad` | 0.3 | ParseISP default |
| `fr_dt` | 0.05 | ParseISP default |
| `fr_frt` | 1000.0 | ParseISP default |
| `fr_fr` | 70.0 | ParseISP default |
| `n` | 0.0 | ParseISP default |
| `contingency` | 0.0 | ParseISP default |


### Defaults that vary by storage technology

Source of each varying field:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.ess_varying_fields; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **source** |
|:--|:--|
| `tech` | ParseISP default |
| `type` | ParseISP default |
| `ch_eff` | ISP workbook — Storage properties |
| `dch_eff` | ISP workbook — Storage properties |
| `fullout` | ISP workbook — Generator Reliability Settings |
| `mttrfull` | ISP workbook — Generator Reliability Settings |


Value of each varying field by storage technology:

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.ess_varying_values; allow_markdown_in_cells = true)
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

These fields are written from the selected entry in `ParseISP.params_buildout_gen` to every new `Generator` static row.
The static `n = 0` value is distinct from the time-varying unit count supplied by the workbook.

### Defaults shared by every generator template

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.gen_common; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **value** | **source** |
|:--|:--|:--|
| `fuel` | Natural Gas | ParseISP default |
| `partialout` | 0.0 | ParseISP default |
| `derate` | 0.0 | ParseISP default |
| `mttrpart` | 0.0 | ParseISP default |
| `rup` | 22.0 | ISP workbook — Max Ramp Rates |
| `rdw` | 22.0 | ISP workbook — Max Ramp Rates |
| `investment` | 0 | ParseISP default |
| `active` | 1 | ParseISP default |
| `pfrmax` | 0.1 | ParseISP default |
| `g` | 0.0 | ParseISP default |
| `inertia` | 4.0 | ParseISP default |
| `ffr` | 0 | ParseISP default |
| `pfr` | 1 | ParseISP default |
| `res2` | 1 | ParseISP default |
| `res3` | 0 | ParseISP default |
| `powerfactor` | 0.85 | ParseISP default |
| `n` | 0 | ParseISP default |
| `contingency` | 1 | ParseISP default |
| `last_state` | 0.0 | ParseISP default |
| `last_state_period` | 0.0 | ParseISP default |
| `last_state_output` | 0.0 | ParseISP default |
| `start_up_cost` | 0.0 | ParseISP default |
| `shut_down_cost` | 0.0 | ParseISP default |
| `start_up_time` | 0.0 | ParseISP default |
| `shut_down_time` | 0.0 | ParseISP default |


### Defaults that vary by generator technology

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
ParseISPDocUtils.markdown_table(reference_tables.gen_varying; allow_markdown_in_cells = true)
````

```@raw html
</details>
```

| **field** | **source** | **ccgt** | **ocgt_l** | **ocgt_s** |
|:--|:--|:--|:--|:--|
| `tech` | ParseISP default | CCGT | OCGT | OCGT |
| `type` | ParseISP default | CCGT | OCGT | OCGT |
| `forate` | ISP workbook — Generator Reliability Settings (derived) | 0.965 | 0.98 | 0.98 |
| `fullout` | ISP workbook — Generator Reliability Settings | 0.035 | 0.02 | 0.02 |
| `mttrfull` | ISP workbook — Generator Reliability Settings | 54.0 | 22.0 | 75.0 |
| `pmin` | ParseISP default | 46.0 | 0.0 | 0.0 |
| `cvar` | ISP workbook — New Entrant Data Summary | 118.123 | 192.876 | 185.356 |
| `cfuel` | ISP workbook — New Entrant Data Summary | 15.7488 | 16.9304 | 16.9304 |
| `cvom` | ISP workbook — New Entrant Data Summary | 3.95641 | 7.80589 | 12.8316 |
| `cfom` | ISP workbook — New Entrant Data Summary | 11655.4 | 10906.9 | 13473.2 |
| `co2` | ISP workbook — New Entrant Data Summary | 173.502 | 266.905 | 248.812 |
| `slope` | ParseISP default | 0.4 | 0.6 | 0.6 |
| `hrate` | ISP workbook — New Entrant Data Summary | 7.24923 | 10.9312 | 10.1902 |
| `down_time` | ParseISP default | 4.0 | 0.0 | 0.0 |
| `up_time` | ParseISP default | 4.0 | 0.0 | 0.0 |


## Override and derivation rules

The workbook cannot override stored defaults directly. Changing one requires changing ParseISP's build-out parameter dictionaries.
Capacity affects `capacity`, `pmax`, and, for storage, `lmax` and `emax`; subregion affects `id_bus`; year and `n` affect only the unit-count schedule.
Uniform mode applies one workbook sheet to every ISP scenario. Scenario-specific mode reads one sheet per scenario, unions static assets by generated name, and keeps each scenario's unit-count schedule separate.

See the [preprocessing workflow](../../../editions/isp2024-preprocessing.md) for the stage at which build-outs are inserted, [assumptions and scope](../../../assumptions.md) for the modelling boundary, and [output tables](output-tables.md) for the complete static and schedule schemas.
