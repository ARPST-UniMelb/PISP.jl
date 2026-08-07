# # ISP 2024: Hydro parameters and constants
#
# ParseISP uses package constants to connect hydro generators with trace files, annual energy limits, historical hydrological years, and Snowy scheme allocations. These values directly affect the generated `gen_inflow` and `ess_inflow` schedules.
#
# AEMO describes the physical representation of hydro schemes, including Snowy, in the [2023 Inputs, Assumptions and Scenarios Report, p. 97](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=97). The report also describes annual and seasonal hydro inflows on [p. 98](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=98). The tables below show ParseISP's current values; the report provides modelling context rather than defining ParseISP's internal IDs or allocation shares.

using ParseISP
using DataFrames

const REPO_ROOT = normpath(get(ENV, "ParseISP_DOCS_REPO_ROOT", joinpath(@__DIR__, "..", "..", "..", "..")))

include(joinpath(REPO_ROOT, "docs", "utils", "ParseISPDocUtils.jl"))
import .ParseISPDocUtils

# ## Hydro trace assignments
#
# `ParseISP.HYDRO2FILE` assigns each ParseISP hydro generator ID to a trace family. `gen_inflow_sched` treats `MonthlyNaturalInflow` entries as inflow series, `MaxEnergyYear` entries as annual energy limits, and `SNOWY_SCHEME` entries as part of the Snowy allocation.

hydro_trace_assignments = DataFrame([
    (pisp_generator_id=id_gen, trace_family=trace_family)
    for (id_gen, trace_family) in sort(collect(ParseISP.HYDRO2FILE); by=first)
])
ParseISPDocUtils.markdown_table(hydro_trace_assignments)

# ## Annual energy limits
#
# Generators assigned to the `MaxEnergyYear` trace family use `ParseISP.HYDRO2CNS` to select an annual energy-limit series. Several generators can share one named limit; ParseISP distributes the available energy according to generated hydro capacity and unit count.

annual_energy_limits = DataFrame([
    (pisp_generator_id=id_gen, limit_name=limit_name)
    for (id_gen, limit_name) in sort(collect(ParseISP.HYDRO2CNS); by=first)
])
ParseISPDocUtils.markdown_table(annual_energy_limits)

# ## Hydrological reference years
#
# `ParseISP.WEATHER_YEARS` selects the hydrological series used for each planning interval. `Dry` is the label ParseISP uses for its dry-year profile. This sequence differs from the Reference Year and VRE Reference Year sequence used by the solar, wind, and demand trace builder; see [ISP 2024 parameters and mappings](parameters-and-mappings.md).
#
# AEMO's [Figure 41, “Hydro inflow variability across reference weather years – Snowy Hydro”](../../../../../data/2024/pisp-reports/2023-inputs-assumptions-and-scenarios-report.pdf#page=99), illustrates variation in Snowy Hydro inflows across reference weather years. Each row below selects one complete July–June monthly profile for its planning interval. ParseISP distributes each selected monthly value uniformly across the hours in that month, then uses the resulting hourly series as the common starting point for Snowy generator and storage inflow schedules.
#
# Selecting a different hydrological year can therefore change both the seasonal timing and magnitude of `gen_inflow` and `ess_inflow`. The Snowy allocation constants described below determine how that common profile is divided among generators and Tumut 3. Figure 41 provides context for the variation; it does not define ParseISP's year sequence or allocation shares, and these inflow schedules do not by themselves determine storage levels or dispatch.

hydrological_years = sort!(DataFrame([
    (
        planning_interval_start=start_date,
        planning_interval_end=end_date,
        hydrological_year=label,
    )
    for ((start_date, end_date), label) in ParseISP.WEATHER_YEARS
]), :planning_interval_start)
ParseISPDocUtils.markdown_table(hydrological_years)

# ## Snowy scheme allocations
#
# ParseISP separates the Snowy values between the Murray and Tumut generator groups. `ParseISP.DAM_SHARES` supplies the Blowering and Eucumbene proportions, while `ParseISP.HYDRO_DAMS_GENS` associates Snowy generators with a dam.

snowy_generator_allocations = DataFrame([
    (
        group=group,
        pisp_generator_id=id_gen,
        dam=ParseISP.HYDRO_DAMS_GENS[id_gen],
        dam_share=ParseISP.DAM_SHARES[ParseISP.HYDRO_DAMS_GENS[id_gen]],
    )
    for (group, ids) in sort(collect(ParseISP.SNOWY_HYDRO_GROUPS); by=first)
    for id_gen in ids
])
ParseISPDocUtils.markdown_table(snowy_generator_allocations)

# Tumut 3 uses the same Snowy inflow series through the storage mappings. `ParseISP.HYDRO_DAMS_STORAGE` identifies its contributing dams, and `ParseISP.HYDRO_STORAGE_GEN` links the storage unit to the Upper Tumut generator used in the allocation calculation.

snowy_storage_allocations = DataFrame([
    (
        pisp_storage_id=id_ess,
        storage="Tumut 3",
        contributing_dams=join(dams, ", "),
        linked_pisp_generator_id=ParseISP.HYDRO_STORAGE_GEN[id_ess],
    )
    for (id_ess, dams) in sort(collect(ParseISP.HYDRO_DAMS_STORAGE); by=first)
])
ParseISPDocUtils.markdown_table(snowy_storage_allocations)

# ## Where the values are used
#
# `gen_inflow_sched` reads `HYDRO2FILE`, `HYDRO2CNS`, `SNOWY_HYDRO_GROUPS`, `HYDRO_DAMS_GENS`, and `DAM_SHARES` when constructing generator inflow schedules. `build_hourly_snowy` uses `WEATHER_YEARS` to align monthly Snowy values with planning intervals. `ess_inflow_sched` uses `HYDRO_DAMS_STORAGE`, `HYDRO_STORAGE_GEN`, and `DAM_SHARES` when constructing the Tumut 3 storage inflow schedule.
#
# These constants are active modelling inputs. Changing a trace assignment, limit name, hydrological year, dam share, or generator-storage link can change generated schedules even when the downloaded source data is unchanged.
