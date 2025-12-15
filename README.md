# PISP.jl: Julia parser of the Integrated System Plan

**PISP** (short for *Julia Parser of the Integrated System Plan*) is an open-source toolkit for parsing and generating structured datasets of the East Coast Australian Power System for power system studies. 

The data parsing functionalities are built on publicly available information from the Integrated System Plan (ISP) released by the Australian Energy Market Operator (AEMO) for the Australian National Electricity Market (NEM).

> [!CAUTION]
> The current release is fully functional and has been extensively tested; however, bugs or other issues may still arise. We would greatly appreciate any feedback or bug reports submitted via https://github.com/ARPST-UniMelb/PISP.jl/issues 

## Core function
Dataset construction in PISP is performed through a single high-level function, `build_ISP24_datasets`. A usage example is shown below:
```julia
using PISP

# Set some of the input parameters (see all parameters below)
reference_trace = 4006         # Reference weather trace. 4006 is the one of the Optimal Development Path (ODP) of the ISP
poe             = 10           # Probability of exceedance (POE) for demand
target_years    = [2030, 2031] # Planning years for which to generate datasets

PISP.build_ISP24_datasets(
    downloadpath = joinpath(@__DIR__, "..", "data", "pisp-downloads"),
    poe          = poe,
    reftrace     = reference_trace,
    years        = target_years,
    output_root  = joinpath(@__DIR__, "..", "data", "pisp-datasets"),
    write_csv    = true,
    write_arrow  = false,
    scenarios    = [1,2,3]
    )

```

## Optional parameters for PISP.build_ISP24_datasets()
There are multiple parameters that can be adjusted when generating the dataset from the public 2024 Integrated System Plan (ISP) datafiles:
| Parameter           | Default       | Description                                                                                                                        |
| ------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
|`downloadpath`|"../../data-download"| Path where all files from AEMO's website will be downloaded and extracted
|`download_from_AEMO`|true| Whether to download files from AEMO's website
|`poe`|10| Probability of exceedance (POE) for demand: 10% or 50%
|`reftrace`|4006| Reference weather year trace: select among 2011 - 2023 or 4006 (trace for the Optimal Development Path, ODP from the 2024 ISP)
|`years`|[2025]| Calendar years for which to build the time-varying schedules: select among 2025 - 2050
|`output_name`|"out"| Output folder name
|`output_root`|nothing| Output folder path
|`write_csv`|true| Whether to write CSV (.csv) files
|`write_arrow`|true|Whether to write Arrow (.arrow) files 
|`scenarios`|[1,2,3]|Scenarios to include in the output: 1 for "Progressive Change", 2 for "Step Change", 3 for "Green Energy Exports", from the 2024 ISP


## Description of dataset formatting

## Files description
> [!NOTE] 
> **NEM12**: Time-static information
> - Bus
> - Demand
> - DER
> - ESS
> - Generator
> - Line

## Time-varying parameters

> [!IMPORTANT] 
> **Schedule**: Time-varying parameters
> - Demand_load_sched: `value` load (MW) at a given `date`. Match with column `load_` from Demand
> - DER_pred_max_sched: `value` pred (MW) starting at a given `date`. Match with column `pred` from DER
>   - `pred`: Maximum load reduction capacity (MW)
> - ESS_emax_sched: `value` emax (MWh) starting at a given `date`. Match with column `emax` from ESS
>   - `emax`: Maximum storage energy (MWh).
> - ESS_inflow_sched: approximate energy inflow (MWh), for hydro storages at a given `date`. 
> - ESS_lmax_sched: `value` lmax (MW) starting at a given `date`. Match with column `lmax` from ESS
>   - `lmax`: Maximum storage charge input (MW) *[as a load]*.
> - ESS_n_sched: `value` n (p.u.) starting at a given `date`. Match with column `n` from Generator
>   - `n`: Maximum number of online units
> - ESS_pmax_sched: `value` pmax (MW) starting at a given `date`. Match with column `pmax` from ESS
>   - `pmax`: Maximum storage discharge output (MW).
> - Generator_inflow_sched: approximate energy inflow (MWh), for hydro generators at a given `date`. 
> - Generator_pmax_sched: `value` pmax (MW) at a given `date`. Match with column `pmax` from Generator
>   - `pmax`: Maximum generator output (MW).
> - Generator_n_sched: `value` n (p.u.) starting at a given `date`. Match with column `n` from Generator
>   - `n`: Maximum number of online units
> - Line_tmax_sched: `value` tmax (MW) starting at a given `date`. Match with column `tmax` from Line
>   - `tmax`: Maximum line forward rating (MW)
> - Line_tmin_sched: `value` tmin (MW) starting at a given `date`. Match with column `tmin` from Line
>   - `tmin`: Maximum line reverse rating (MW)


## Relevant calculations

> [!IMPORTANT] 
> *Calculations using parameters from the corresponding tables*
> - **Generator**: 
>   - Maximum generation output = `pmax` * `n`
>   - Minimum generation output = `pmin` * `n`
> - **ESS**: 
>   - Maximum discharging output = `pmax` * `n`
>   - Maximum charging input = `lmax` * `n`
>   - Minimum discharging output = `pmin` * `n`
>   - Minimum charging input = `lmin` * `n`
>   - Minimum state of charge = `emin` (%) * `emax` (MW)
>   - Initial state of charge in $t=1$ = `eini` (%) * `emax` (MW)
> - **Line**: 
>   - Maximum forward capacity output = `tmax` * `n`
>   - Maximum reverse capacity output = `tmin` * `n`

## Time-static parameters in each database

### Bus
| Parameter       | Description |  
|-----------------|-------------|
| `id_bus`            | id of the bus | 
| `active`        | Active flag (1: active; 0: inactive) | 
| `id_area`       | Area of the 5-bus NEM  market model (1: QLD; 2:NSW; 3:VIC; 4:TAS; 5:SA) | 

### Demand
| Parameter       | Description |  
|-----------------|-------------|
| `id_dem`            | id of the bus | 
| `load_`        | Load (MW) | 
| `id_bus`       | Bus the demand is connected to (match with `id_bus` from **Bus** table) | 
| `active`        | Active flag (1:active; 0:inactive) | 
| `controllable`      | Controllable flag (1:controllable; 0:non-controllable) | 
| `voll`       | Value of Lost Load ($/MWh) | 

### DER
| Parameter       | Description |  
|-----------------|-------------|
| `id_der`            | id of the DER | 
| `name`        | Name of the DER | 
| `tech`       | Technology (DSP: demand-side participation) | 
| `id_dem`       | Demand the DER is attached to (match with `id_dem` from **Demand** table) | 
| `active`        | Active flag (1:active; 0:inactive) | 
| `capacity`      | Capacity of the DER service (MW) | 
| `reduct`       | Reduction flag (1:yes, 0:no) | 
| `pred_max`       | Maximum capacity reduction (MW) | 
| `cost_red`       | Cost associated with the reduction ($/MWh) | 

### ESS
| Parameter       | Description |  
|-----------------|-------------|
| `id_ess`            | id of the ESS | 
| `tech`            | Technology (BESS: battery; PS: pumped hydro) | 
| `type`       | Type of storage (SHALLOW, MEDIUM, DEEP) | 
| `investment`      | Investment flag (1:investment; 0:non-investment) | 
| `active`        | Active flag (1:active; 0:inactive) | 
| `id_bus`       | Bus the ESS is connected to (match with `id_bus` from **Bus** table) | 
| `ch_eff`       | Charging efficiency (%) | 
| `dch_eff`       | Discharging efficiency (%) | 
| `eini`       | Initial energy capacity (% of `emax`) | 
| `emin`       | Minimum energy capacity (% of `emax`)| 
| `emax`       | Maximum energy capacity (MWh) | 
| `pmin`       | Minimum discharging power (MW) | 
| `pmax`       | Maximum discharging power (MW) | 
| `lmin`       | Minimum charging power (MW) | 
| `lmax`       | Maximum charging power (MW) | 
| `fullout`       | Forced outage rate - full outage (% of time in decimal form)| 
| `partialout`       |  Forced outage rate - partial outage (% of time in decimal form)| 
| `mttrfull`       | Mean time to repair - full outage (hr) | 
| `mttrpart`       | Mean time to repair - partial outage (hr) |
| `n`       | Maximum number of units online (p.u) | 

### Generator
| Parameter       | Description |  
|-----------------|-------------|
| `id`            | id of the generator | 
| `fuel`        | Fuel type | 
| `tech`            | Generator technology | 
| `type`       | Generator type | 
| `forate`       | Outage rate (%) `forate =` $\ \  1-(\mathcal{F}+\mathcal{P}(1-\alpha))$ ; $\mathcal{F}$, $\mathcal{P}$ full/partial outage rates, $\alpha$ derating factor| 
| `fullout`       | Forced outage rate - full outage (% of time in decimal form)| 
| `partialout`       |  Forced outage rate - partial outage (% of time in decimal form)| 
| `derate`      | Partial outage derating factor (% in decimal form)
| `mttrfull`       | Mean time to repair - full outage (hr) | 
| `mttrpart`       | Mean time to repair - partial outage (hr) |
| `bus_id`      | Bus the generator is connected to (match with `id_bus` from **Bus** table) | 
| `pmin`      | Minimum power output (MW)| 
| `pmax`      | Maximum power output (MW)| 
| `rup`      | Ramp-up capacity (MW/min)| 
| `rdw`      | Ramp-down capacity (MW/min)| 
| `investment`      | Investment flag (1:investment; 0:non-investment) | 
| `active`      | Active flag (1:active; 0:inactive) | 
| `cvar`      | Variable cost ($/MWh)| 
| `cfuel`      | Fuel cost ($/GJ)| 
| `cvom`      | Variable operation and maintenance cost ($/MWh)| 
| `cfom`      | Fixed operation and maintenance cost ($/MWh/yr)| 
| `co2`      | CO2 emmissions (kgC02/MWh)| 
| `hrate`      | Heat rate (MWh/GJ) | 
| `pfrmax`      | Maximum headroom (MW) | 
| `ffr` | Fast frequency response provision flag |
| `pfr` | Primary frequency response provision flag |
| `res2` | Secondary reserve provision flag |
| `res3` | Tertiary (Regulation) reserve provision flag | 
| `n`      | Maximum number of units online (p.u.)| 
| `down_time`       | Minimum down time after being shut-down (h) | 
| `up_time`       |  Minimum up time after being started (h)| 
| `start_up_cost`      | Start-up cost ($) | 
| `shut_down_cost`      | Shut-down cost ($)| 
| `start_up_time`      | Time to start-up units (h)| 
| `shut_down_time`      | Time to shut-down units (h)| 

- Forced Outage Rate (%) - The percentage of time per year that a generator is expected to be out of service due to forced outage.
- Mean time to repair (hrs) - The average time take to return a generating unit to service
- Partial Outage Derating Factor - The loss of capacity during a partial outage, relative to generator unit rating. If the outage factor is 20%, the generator will operate at 80% capacity during a partial outage.
### Line
| Parameter       | Description |  
|-----------------|-------------|
| `id`            | id of the line | 
| `tech`        | Technology | 
| `capacity`            | Maximum capacity | 
| `id_bus_from`       | Bus the line starts (match with `id_bus` from **Bus** table) | 
| `id_bus_to`       | Bus the line ends (match with `id_bus` from **Bus** table) | 
| `investment`      | Investment flag (1:investment; 0:non-investment) | 
| `active`      | Active flag (1:active; 0:inactive) | 
| `tmin`      | Maximum reverse capacity bus_a $\rightarrow$ bus_b (MW)| 
| `tmax`      | Maximum forward capacity bus_b $\rightarrow$ bus_a (MW)| 
| `fullout`       | Unplanned outage rate - single credible contingency (% of time in decimal form)| 
| `mttrfull`       | Mean time to repair - single credible contingency (hr) | 
| `n`      | Maximum number of units online (p.u.)| 


## Data sources of PISP
> [!IMPORTANT] 
> All the datasets that PISP generates are based on publicly available data from AEMO. 
>
> All files are obtained from: https://www.aemo.com.au/energy-systems/major-publications/integrated-system-plan-isp/2024-integrated-system-plan-isp
> - 2024 Integrated System Plan **Inputs and Assumptions workbook**
> - 2024 Integrated System Plan **generation and storage outlook**
> - 2024 Integrated System Plan **Model**
> - 2024 Integrated System Plan **Demand & Variable Renewable Energy trace data**