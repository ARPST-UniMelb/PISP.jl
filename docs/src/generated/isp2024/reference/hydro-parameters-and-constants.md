```@meta
EditURL = "../../../../literate/isp2024/reference/hydro_parameters_and_constants.jl"
```

# ISP 2024: Hydro parameters and constants

PISP uses package constants to connect hydro generators with trace files, annual energy limits, historical hydrological years, and Snowy scheme allocations. These values directly affect the generated `gen_inflow` and `ess_inflow` schedules.

AEMO describes the physical representation of hydro schemes, including Snowy, in the [2023 Inputs, Assumptions and Scenarios Report, p. 97](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=97). The report also describes annual and seasonal hydro inflows on [p. 98](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=98). The tables below show PISP's current values; the report provides modelling context rather than defining PISP's internal IDs or allocation shares.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
using PISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "PISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "PISPDocUtils.jl"))
import .PISPDocUtils
````

```@raw html
</details>
```

## Hydro trace assignments

`PISP.HYDRO2FILE` assigns each PISP hydro generator ID to a trace family. `gen_inflow_sched` treats `MonthlyNaturalInflow` entries as inflow series, `MaxEnergyYear` entries as annual energy limits, and `SNOWY_SCHEME` entries as part of the Snowy allocation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hydro_trace_assignments = DataFrame([
    (pisp_generator_id=id_gen, trace_family=trace_family)
    for (id_gen, trace_family) in sort(collect(PISP.HYDRO2FILE); by=first)
])
PISPDocUtils.markdown_table(hydro_trace_assignments)
````

```@raw html
</details>
```

| **pisp\_generator\_id** | **trace\_family** |
|--:|:--|
| 23 | MaxEnergyYear\_LT\_RefYear4006 |
| 24 | MonthlyNaturalInflow\_Anthony\_Pieman\_RefYear4006 |
| 25 | MaxEnergyYear\_LT\_RefYear4006 |
| 26 | MaxEnergyYear\_LT\_RefYear4006 |
| 27 | MonthlyNaturalInflow\_Lower\_Derwent\_RefYear4006 |
| 28 | MonthlyNaturalInflow\_MF\_Low\_RefYear4006 |
| 29 | MaxEnergyYear\_LT\_RefYear4006 |
| 30 | MonthlyNaturalInflow\_MF\_Low\_RefYear4006 |
| 31 | MaxEnergyYear\_LT\_RefYear4006 |
| 32 | MonthlyNaturalInflow\_MF\_Top\_RefYear4006 |
| 33 | MaxEnergyYear\_LT\_RefYear4006 |
| 34 | MaxEnergyYear\_LT\_RefYear4006 |
| 35 | MaxEnergyYear\_LT\_RefYear4006 |
| 36 | MaxEnergyYear\_LT\_RefYear4006 |
| 37 | MaxEnergyYear\_LT\_RefYear4006 |
| 38 | MaxEnergyYear\_LT\_RefYear4006 |
| 39 | MaxEnergyYear\_LT\_RefYear4006 |
| 40 | MonthlyNaturalInflow\_MF\_Top\_RefYear4006 |
| 41 | MonthlyNaturalInflow\_Anthony\_Pieman\_RefYear4006 |
| 42 | MonthlyNaturalInflow\_Lower\_Derwent\_RefYear4006 |
| 43 | SNOWY\_SCHEME |
| 44 | SNOWY\_SCHEME |
| 45 | MaxEnergyYear\_LT\_RefYear4006 |
| 46 | MonthlyNaturalInflow\_Anthony\_Pieman\_RefYear4006 |
| 47 | MonthlyNaturalInflow\_Tarraleah\_RefYear4006 |
| 48 | MaxEnergyYear\_LT\_RefYear4006 |
| 49 | MonthlyNaturalInflow\_Anthony\_Pieman\_RefYear4006 |
| 50 | MonthlyNaturalInflow\_Tungatinah\_RefYear4006 |
| 51 | SNOWY\_SCHEME |
| 52 | MaxEnergyYear\_LT\_RefYear4006 |


## Annual energy limits

Generators assigned to the `MaxEnergyYear` trace family use `PISP.HYDRO2CNS` to select an annual energy-limit series. Several generators can share one named limit; PISP distributes the available energy according to generated hydro capacity and unit count.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
annual_energy_limits = DataFrame([
    (pisp_generator_id=id_gen, limit_name=limit_name)
    for (id_gen, limit_name) in sort(collect(PISP.HYDRO2CNS); by=first)
])
PISPDocUtils.markdown_table(annual_energy_limits)
````

```@raw html
</details>
```

| **pisp\_generator\_id** | **limit\_name** |
|--:|:--|
| 23 | Barron Gorge Constraint |
| 25 | Blowering Constraint |
| 26 | Bogong - Mackay Constraint |
| 29 | Dartmouth Constraint |
| 31 | Eildon Constraint |
| 33 | HT Annual Storage Constraint |
| 34 | Guthega Constraint |
| 35 | Hume Dam NSW Constraint |
| 36 | Hume Dam VIC Constraint |
| 37 | HT Annual Storage Constraint |
| 38 | Kareeya Constraint |
| 39 | HT Annual Storage Constraint |
| 45 | HT Annual Storage Constraint |
| 48 | HT Annual Storage Constraint |
| 52 | West Kiewa Constraint |


## Hydrological reference years

`PISP.WEATHER_YEARS` selects the hydrological series used for each planning interval. `Dry` is the label PISP uses for its dry-year profile. This sequence differs from the Reference Year and VRE Reference Year sequence used by the solar, wind, and demand trace builder; see [ISP 2024 parameters and mappings](parameters-and-mappings.md).

AEMO's [Figure 41, “Hydro inflow variability across reference weather years – Snowy Hydro”](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=99), illustrates variation in Snowy Hydro inflows across reference weather years. Each row below selects one complete July–June monthly profile for its planning interval. PISP distributes each selected monthly value uniformly across the hours in that month, then uses the resulting hourly series as the common starting point for Snowy generator and storage inflow schedules.

Selecting a different hydrological year can therefore change both the seasonal timing and magnitude of `gen_inflow` and `ess_inflow`. The Snowy allocation constants described below determine how that common profile is divided among generators and Tumut 3. Figure 41 provides context for the variation; it does not define PISP's year sequence or allocation shares, and these inflow schedules do not by themselves determine storage levels or dispatch.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
hydrological_years = sort!(DataFrame([
    (
        planning_interval_start=start_date,
        planning_interval_end=end_date,
        hydrological_year=label,
    )
    for ((start_date, end_date), label) in PISP.WEATHER_YEARS
]), :planning_interval_start)
PISPDocUtils.markdown_table(hydrological_years)
````

```@raw html
</details>
```

| **planning\_interval\_start** | **planning\_interval\_end** | **hydrological\_year** |
|:--|:--|:--|
| 2024-07-01 | 2025-06-30 | 2019 |
| 2025-07-01 | 2026-06-30 | 2020 |
| 2026-07-01 | 2027-06-30 | 2021 |
| 2027-07-01 | 2028-06-30 | 2022 |
| 2028-07-01 | 2029-06-30 | 2013 |
| 2029-07-01 | 2030-06-30 | Dry |
| 2030-07-01 | 2031-06-30 | 2011 |
| 2031-07-01 | 2032-06-30 | 2012 |
| 2032-07-01 | 2033-06-30 | 2013 |
| 2033-07-01 | 2034-06-30 | 2014 |
| 2034-07-01 | 2035-06-30 | Dry |
| 2035-07-01 | 2036-06-30 | 2016 |
| 2036-07-01 | 2037-06-30 | 2017 |
| 2037-07-01 | 2038-06-30 | 2018 |
| 2038-07-01 | 2039-06-30 | 2019 |
| 2039-07-01 | 2040-06-30 | 2020 |
| 2040-07-01 | 2041-06-30 | 2021 |
| 2041-07-01 | 2042-06-30 | 2022 |
| 2042-07-01 | 2043-06-30 | 2013 |
| 2043-07-01 | 2044-06-30 | Dry |
| 2044-07-01 | 2045-06-30 | 2011 |
| 2045-07-01 | 2046-06-30 | 2012 |
| 2046-07-01 | 2047-06-30 | 2013 |
| 2047-07-01 | 2048-06-30 | 2014 |
| 2048-07-01 | 2049-06-30 | Dry |
| 2049-07-01 | 2050-06-30 | 2016 |
| 2050-07-01 | 2051-06-30 | 2017 |
| 2051-07-01 | 2052-06-30 | 2018 |


## Snowy scheme allocations

PISP separates the Snowy values between the Murray and Tumut generator groups. `PISP.DAM_SHARES` supplies the Blowering and Eucumbene proportions, while `PISP.HYDRO_DAMS_GENS` associates Snowy generators with a dam.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
snowy_generator_allocations = DataFrame([
    (
        group=group,
        pisp_generator_id=id_gen,
        dam=PISP.HYDRO_DAMS_GENS[id_gen],
        dam_share=PISP.DAM_SHARES[PISP.HYDRO_DAMS_GENS[id_gen]],
    )
    for (group, ids) in sort(collect(PISP.SNOWY_HYDRO_GROUPS); by=first)
    for id_gen in ids
])
PISPDocUtils.markdown_table(snowy_generator_allocations)
````

```@raw html
</details>
```

| **group** | **pisp\_generator\_id** | **dam** | **dam\_share** |
|:--|--:|:--|--:|
| MURRAY | 43 | Eucumbene | 0.746733 |
| MURRAY | 44 | Eucumbene | 0.746733 |
| TUMUT | 51 | Eucumbene | 0.746733 |


Tumut 3 uses the same Snowy inflow series through the storage mappings. `PISP.HYDRO_DAMS_STORAGE` identifies its contributing dams, and `PISP.HYDRO_STORAGE_GEN` links the storage unit to the Upper Tumut generator used in the allocation calculation.

```@raw html
<details class="source-code"><summary>Show source code</summary>
```

````julia
snowy_storage_allocations = DataFrame([
    (
        pisp_storage_id=id_ess,
        storage="Tumut 3",
        contributing_dams=join(dams, ", "),
        linked_pisp_generator_id=PISP.HYDRO_STORAGE_GEN[id_ess],
    )
    for (id_ess, dams) in sort(collect(PISP.HYDRO_DAMS_STORAGE); by=first)
])
PISPDocUtils.markdown_table(snowy_storage_allocations)
````

```@raw html
</details>
```

| **pisp\_storage\_id** | **storage** | **contributing\_dams** | **linked\_pisp\_generator\_id** |
|--:|:--|:--|--:|
| 59 | Tumut 3 | Eucumbene, Blowering | 51 |


## Where the values are used

`gen_inflow_sched` reads `HYDRO2FILE`, `HYDRO2CNS`, `SNOWY_HYDRO_GROUPS`, `HYDRO_DAMS_GENS`, and `DAM_SHARES` when constructing generator inflow schedules. `build_hourly_snowy` uses `WEATHER_YEARS` to align monthly Snowy values with planning intervals. `ess_inflow_sched` uses `HYDRO_DAMS_STORAGE`, `HYDRO_STORAGE_GEN`, and `DAM_SHARES` when constructing the Tumut 3 storage inflow schedule.

These constants are active modelling inputs. Changing a trace assignment, limit name, hydrological year, dam share, or generator-storage link can change generated schedules even when the downloaded source data is unchanged.
