"""
eda/archive/06_pisp_outputs.py
Inspect and plot the PISP-produced output: Generator_pmax_sched, Demand_load_sched, etc.
Compare with the raw capacity factor traces.
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from table_utils import write_table

SCRIPT_STEM = "06_pisp_outputs"
OUT = Path("data/2024/pisp-datasets/out-ref4006-poe10/csv")
FIGURES = Path("eda/figures/python") / SCRIPT_STEM
FIGURES.mkdir(parents=True, exist_ok=True)

# ---- Load static tables ----
gen_df = pd.read_csv(OUT / "Generator.csv")
dem_df = pd.read_csv(OUT / "Demand.csv")
bus_df = pd.read_csv(OUT / "Bus.csv")

print("=== Generator Table ===")
print(f"Shape: {gen_df.shape}")
print(f"Columns: {list(gen_df.columns)}")
print(f"\nFuel types:\n{gen_df['fuel'].value_counts()}")
print(f"\nTech types:\n{gen_df['tech'].value_counts()}")

fuel_counts = gen_df['fuel'].value_counts()
write_table(
    fuel_counts.rename_axis('fuel').reset_index(name='count'),
    SCRIPT_STEM,
    "generator_fuel_counts",
)
tech_counts = gen_df['tech'].value_counts()
write_table(
    tech_counts.rename_axis('tech').reset_index(name='count'),
    SCRIPT_STEM,
    "generator_tech_counts",
)

# ---- Load schedule files ----
gen_pmax = pd.read_csv(OUT / "schedule-2030" / "Generator_pmax_sched.csv")
dem_load = pd.read_csv(OUT / "schedule-2030" / "Demand_load_sched.csv")

print("\n=== Generator_pmax_sched ===")
print(f"Shape: {gen_pmax.shape}")
print(f"Columns: {list(gen_pmax.columns)}")
print(gen_pmax.head(5))

print("\n=== Demand_load_sched ===")
print(f"Shape: {dem_load.shape}")
print(dem_load.head(5))

write_table(
    pd.DataFrame([
        {"schedule": "Generator_pmax_sched", "n_rows": gen_pmax.shape[0], "n_cols": gen_pmax.shape[1]},
        {"schedule": "Demand_load_sched", "n_rows": dem_load.shape[0], "n_cols": dem_load.shape[1]},
    ]),
    SCRIPT_STEM,
    "schedule_shapes",
)

# ---- Map generators to buses/areas ----
area_map = dict(zip(bus_df['id_bus'], bus_df['id_area']))
gen_df['area'] = gen_df['id_bus'].map(area_map)
area_names = {1: 'QLD', 2: 'NSW', 3: 'VIC', 4: 'TAS', 5: 'SA'}
gen_df['area_name'] = gen_df['area'].map(area_names)

# ---- Solar/Wind generators ----
solar_gens = gen_df[gen_df['tech'].str.contains('PV|SOLAR', case=False, na=False)]
wind_gens = gen_df[gen_df['tech'].str.contains('WIND', case=False, na=False)]
print(f"\nSolar generators: {len(solar_gens)}")
print(f"Wind generators: {len(wind_gens)}")
print(f"\nSolar tech breakdown:\n{solar_gens['tech'].value_counts()}")
print(f"\nWind tech breakdown:\n{wind_gens['tech'].value_counts()}")

write_table(
    pd.DataFrame([
        {"category": "solar", "n_generators": len(solar_gens)},
        {"category": "wind", "n_generators": len(wind_gens)},
    ]),
    SCRIPT_STEM,
    "solar_wind_generator_counts",
)
solar_wind_tech_counts = pd.concat([
    solar_gens['tech'].value_counts().rename_axis('tech').reset_index(name='count').assign(category='solar'),
    wind_gens['tech'].value_counts().rename_axis('tech').reset_index(name='count').assign(category='wind'),
], ignore_index=True)[['category', 'tech', 'count']]
write_table(solar_wind_tech_counts, SCRIPT_STEM, "solar_wind_tech_counts")

# ---- Annual mean pmax per generator type ----
fig, axes = plt.subplots(2, 2, figsize=(14, 10))

# Solar pmax annual mean
ax = axes[0, 0]
solar_ids = solar_gens['id_gen'].tolist()
wind_ids = wind_gens['id_gen'].tolist()
sol_sched = gen_pmax[gen_pmax['id_gen'].isin(solar_ids)]
wind_sched = gen_pmax[gen_pmax['id_gen'].isin(wind_ids)]

# ---- Annual mean pmax per generator type ----
fig, axes = plt.subplots(2, 2, figsize=(14, 10))

# Solar pmax annual mean
ax = axes[0, 0]
sol_annual = sol_sched.groupby('id_gen')['value'].mean().sort_values()
ax.barh(range(len(sol_annual)), sol_annual.values, color='darkorange', alpha=0.7)
ax.set_yticks(range(len(sol_annual)))
ax.set_yticklabels([f"G{g}" for g in sol_annual.index], fontsize=6)
ax.set_title("Solar Generators — Annual Mean pmax (MW)")
ax.set_xlabel("PMax (MW)")
ax.grid(True, alpha=0.3)

# sol_annual above is computed only once in this script (this occurrence);
# it is the value that feeds the saved figure, so it is the table baseline
# for the solar half of `annual_mean_pmax`.

# Wind pmax annual mean
ax = axes[0, 1]
wind_annual = wind_sched.groupby('id_gen')['value'].mean().sort_values()
ax.barh(range(len(wind_annual)), wind_annual.values, color='steelblue', alpha=0.7)
ax.set_yticks(range(len(wind_annual)))
ax.set_yticklabels([f"G{g}" for g in wind_annual.index], fontsize=6)
ax.set_title("Wind Generators — Annual Mean pmax (MW)")
ax.set_xlabel("PMax (MW)")
ax.grid(True, alpha=0.3)

# Demand by area
ax = axes[1, 0]
dem_load_full = dem_load[dem_load['id_dem'].isin(dem_df['id_dem'])].copy()
dem_load_full['datetime'] = pd.to_datetime(dem_load_full['date'])
dem_load_full = dem_load_full.merge(dem_df[['id_dem', 'id_bus']], on='id_dem')
dem_load_full['area'] = dem_load_full['id_bus'].map(area_map)
dem_load_full['area_name'] = dem_load_full['area'].map(area_names)
dem_daily = dem_load_full.groupby([dem_load_full['datetime'].dt.date, 'area_name'])['value'].sum()
dem_daily.unstack('area_name').plot(ax=ax, linewidth=1)
ax.set_title("Daily Total Demand (MW) by NEM Area")
ax.set_xlabel("Date")
ax.set_ylabel("Demand (MW)")
ax.legend(fontsize=7)
ax.grid(True, alpha=0.3)

# Duration curve: solar vs wind
ax = axes[1, 1]
# Capacity factor for solar and wind divides each generator's scheduled mean
# output by that generator's own scheduled maximum, not by the static `pmax`
# recorded in `Generator.csv`. The static field is not a reliable capacity
# reference for these generators: rooftop PV rows carry a fixed placeholder
# pmax (src/parsers/PISP-2024parser.jl:1070, `gen_pmax_distpv`), and
# utility-scale solar/wind rows record only currently operating capacity,
# which a future-year schedule can exceed once ISP-outlook build-out is
# reflected in the trace (`gen_pmax_wind`, ~1386 vs. ~1477 in the same
# file). SiennaNEM.jl, which builds unit-commitment models from this same
# PISP output, applies the same convention (src/read_data.jl:214-229,
# `update_system_data_bound!`) and calls the static pmax "dummy" for these
# generators (src/create_system.jl:342,368). See PISP.jl's own
# the generated Parameters and mappings page and docs/src/assumptions.md for the full caveat.
sol_cf = sol_sched.groupby('id_gen')['value'].mean() / sol_sched.groupby('id_gen')['value'].max()
wind_cf = wind_sched.groupby('id_gen')['value'].mean() / wind_sched.groupby('id_gen')['value'].max()
ax.plot(np.sort(sol_cf.dropna().values)[::-1], color='darkorange', linewidth=1.5, label=f'Solar (n={len(sol_cf.dropna())})', alpha=0.7)
ax.plot(np.sort(wind_cf.dropna().values)[::-1], color='steelblue', linewidth=1.5, label=f'Wind (n={len(wind_cf.dropna())})', alpha=0.7)
ax.set_title("Capacity Factor Duration Curve (2030)")
ax.set_xlabel("Generator Rank")
ax.set_ylabel("Capacity Factor")
ax.legend()
ax.grid(True, alpha=0.3)

# Wind pmax annual mean
# NOTE: this is the second (live) occurrence of this block — it re-derives
# wind_ids/wind_sched/wind_annual and overwrites the values from the block
# above just before the figure is saved, so this is the value instrumented
# below for the wind half of `annual_mean_pmax`.
ax = axes[0, 1]
wind_ids = wind_gens['id_gen'].values
wind_sched = gen_pmax[gen_pmax['id_gen'].isin(wind_ids)]
wind_annual = wind_sched.groupby('id_gen')['value'].mean().sort_values()
ax.barh(range(len(wind_annual)), wind_annual.values, color='steelblue', alpha=0.7)
ax.set_title("Wind Generators — Annual Mean pmax (MW)")
ax.set_xlabel("PMax (MW)")
ax.grid(True, alpha=0.3)

annual_mean_pmax = pd.concat([
    pd.DataFrame({"tech": "solar", "id_gen": sol_annual.index, "mean_pmax": sol_annual.values}),
    pd.DataFrame({"tech": "wind", "id_gen": wind_annual.index, "mean_pmax": wind_annual.values}),
], ignore_index=True)
write_table(annual_mean_pmax, SCRIPT_STEM, "annual_mean_pmax")

# Demand by area
# NOTE: this is the second (live) occurrence of the demand-by-area block —
# it re-derives dem_load_full/dem_daily and overwrites the values from the
# block above just before the figure is saved, so this is the value
# instrumented below for `demand_by_area_daily`. It is also the last
# assignment of `dem_load_full`, which is reused later for the daily
# solar/wind/demand time series.
ax = axes[1, 0]
dem_ids = dem_df['id_dem'].values
dem_load_full = dem_load[dem_load['id_dem'].isin(dem_ids)]
dem_load_full = dem_load_full.copy()
dem_load_full['datetime'] = pd.to_datetime(dem_load_full['date'])
dem_load_full = dem_load_full.merge(dem_df[['id_dem', 'id_bus']], on='id_dem')
dem_load_full['area'] = dem_load_full['id_bus'].map(area_map)
dem_load_full['area_name'] = dem_load_full['area'].map(area_names)
dem_daily = dem_load_full.groupby([dem_load_full['datetime'].dt.date, 'area_name'])['value'].sum()
dem_daily.unstack('area_name').plot(ax=ax, linewidth=1)
ax.set_title("Daily Total Demand (MW) by NEM Area")
ax.set_xlabel("Date")
ax.set_ylabel("Demand (MW)")
ax.legend(fontsize=7)
ax.grid(True, alpha=0.3)

demand_by_area_daily = dem_daily.rename_axis(['date', 'area_name']).reset_index(name='total_demand_mw')
write_table(demand_by_area_daily, SCRIPT_STEM, "demand_by_area_daily")

# Duration curve: solar vs wind
# NOTE: this is the second (live) occurrence of the duration-curve block —
# `sol_cf`/`wind_cf` are recomputed here (guarded by non-empty checks that
# are always true for this dataset) and plotted last, so these sorted,
# NaN-dropped values are what is instrumented below for
# `capacity_factor_duration`. See the first occurrence above for why the
# denominator is each generator's own scheduled maximum, not Generator.csv's
# static pmax.
ax = axes[1, 1]
cf_duration_frames = []
if len(sol_sched) > 0:
    sol_cf = sol_sched.groupby('id_gen')['value'].mean() / sol_sched.groupby('id_gen')['value'].max()
    sol_cf_sorted = np.sort(sol_cf.dropna().values)[::-1]
    ax.plot(sol_cf_sorted, color='darkorange', linewidth=1.5, label='Solar CF', alpha=0.7)
    cf_duration_frames.append(pd.DataFrame({
        "tech": "solar",
        "rank": np.arange(1, len(sol_cf_sorted) + 1),
        "capacity_factor": sol_cf_sorted,
    }))
if len(wind_sched) > 0:
    wind_cf = wind_sched.groupby('id_gen')['value'].mean() / wind_sched.groupby('id_gen')['value'].max()
    wind_cf_sorted = np.sort(wind_cf.dropna().values)[::-1]
    ax.plot(wind_cf_sorted, color='steelblue', linewidth=1.5, label='Wind CF', alpha=0.7)
    cf_duration_frames.append(pd.DataFrame({
        "tech": "wind",
        "rank": np.arange(1, len(wind_cf_sorted) + 1),
        "capacity_factor": wind_cf_sorted,
    }))
if cf_duration_frames:
    write_table(pd.concat(cf_duration_frames, ignore_index=True), SCRIPT_STEM, "capacity_factor_duration")
ax.set_title("Capacity Factor Duration Curve (2030)")
ax.set_xlabel("Generator Rank")
ax.set_ylabel("Capacity Factor")
ax.legend()
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "06_pisp_outputs_overview.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"\nSaved: 06_pisp_outputs_overview.png")

# ---- Time series: solar+winds pmax vs demand ----
fig2, ax2 = plt.subplots(figsize=(16, 6))

gen_pmax_ts = gen_pmax.copy()
gen_pmax_ts['datetime'] = pd.to_datetime(gen_pmax_ts['date'])
gen_pmax_ts = gen_pmax_ts.merge(gen_df[['id_gen', 'tech']], on='id_gen')

sol_pmax_ts = gen_pmax_ts[gen_pmax_ts['tech'].str.contains('PV|SOLAR', case=False, na=False)]
sol_daily = sol_pmax_ts.groupby(sol_pmax_ts['datetime'].dt.date)['value'].sum()

wind_pmax_ts = gen_pmax_ts[gen_pmax_ts['tech'].str.contains('WIND', case=False, na=False)]
wind_daily = wind_pmax_ts.groupby(wind_pmax_ts['datetime'].dt.date)['value'].sum()

dem_daily_ts = dem_load_full.groupby(dem_load_full['datetime'].dt.date)['value'].sum()

dates = pd.to_datetime(sol_daily.index)

daily_solar_wind_demand_gw = pd.DataFrame({
    "date": dates,
    "solar_gw": sol_daily.values / 1000,
    "wind_gw": wind_daily.values / 1000,
    "demand_gw": dem_daily_ts.values / 1000,
})
write_table(daily_solar_wind_demand_gw, SCRIPT_STEM, "daily_solar_wind_demand_gw")

ax2.plot(dates, sol_daily.values / 1000, color='darkorange', linewidth=1, alpha=0.7, label='Solar PMax (GW)')
ax2.plot(dates, wind_daily.values / 1000, color='steelblue', linewidth=1, alpha=0.7, label='Wind PMax (GW)')
ax2.plot(dates, dem_daily_ts.values / 1000, color='grey', linewidth=1, alpha=0.7, label='Total Demand (GW)')
ax2.set_title("2030 — Daily Aggregate: Solar PMax, Wind PMax, Total Demand")
ax2.set_xlabel("Date")
ax2.set_ylabel("GW")
ax2.legend(fontsize=9)
ax2.grid(True, alpha=0.3)
ax2.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
plt.xticks(rotation=45)

plt.tight_layout()
plt.savefig(FIGURES / "06_solar_wind_vs_demand_ts.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 06_solar_wind_vs_demand_ts.png")

# ---- Check: is there any hourly variation in pmax schedules? ----
# (vs raw CFs which have 48 timesteps per day)
fig3, axes3 = plt.subplots(2, 2, figsize=(14, 10))

gen_pmax_ts['date_only'] = gen_pmax_ts['datetime'].dt.date
gen_pmax_ts_30 = gen_pmax_ts[gen_pmax_ts['date_only'] <= pd.to_datetime('2030-01-30').date()]

# Solar: time series of first 30 days
ax = axes3[0, 0]
top_sol = gen_pmax_ts_30[gen_pmax_ts_30['tech'].str.contains('PV|SOLAR', case=False, na=False)]
top_sol_ts = top_sol.groupby(['id_gen', top_sol['datetime'].dt.hour])['value'].mean()
for gid in list(top_sol_ts.index.get_level_values(0).unique())[:5]:
    ax.plot(range(24), top_sol_ts.loc[gid].values, linewidth=1.5, label=f'Solar Gen {gid}')
ax.set_title("Solar PMax: Hourly Profile (mean of first 30 days)")
ax.set_xlabel("Hour")
ax.set_ylabel("PMax (MW)")
ax.legend(fontsize=7)
ax.grid(True, alpha=0.3)

# Wind: hourly profile
ax = axes3[0, 1]
top_wind = gen_pmax_ts_30[gen_pmax_ts_30['tech'].str.contains('WIND', case=False, na=False)]
top_wind_ts = top_wind.groupby(['id_gen', top_wind['datetime'].dt.hour])['value'].mean()
for gid in list(top_wind_ts.index.get_level_values(0).unique())[:5]:
    ax.plot(range(24), top_wind_ts.loc[gid].values, linewidth=1.5, label=f'Wind Gen {gid}')
ax.set_title("Wind PMax: Hourly Profile (mean of first 30 days)")
ax.set_xlabel("Hour")
ax.set_ylabel("PMax (MW)")
ax.legend(fontsize=7)
ax.grid(True, alpha=0.3)

hourly_pmax_profile = pd.concat([
    top_sol_ts.rename('mean_pmax').reset_index().rename(columns={'datetime': 'hour'}).assign(tech='solar'),
    top_wind_ts.rename('mean_pmax').reset_index().rename(columns={'datetime': 'hour'}).assign(tech='wind'),
], ignore_index=True)[['tech', 'id_gen', 'hour', 'mean_pmax']]
write_table(hourly_pmax_profile, SCRIPT_STEM, "hourly_pmax_profile")

# Daily aggregate solar+wind vs demand scatter
ax = axes3[1, 0]
all_dates = pd.to_datetime(sol_daily.index)
combined = pd.DataFrame({
    'date': all_dates,
    'solar_gw': sol_daily.values / 1000,
    'wind_gw': wind_daily.values / 1000,
    'demand_gw': dem_daily_ts.values / 1000,
}).set_index('date')
combined['vre'] = combined['solar_gw'] + combined['wind_gw']
ax.scatter(combined['demand_gw'], combined['vre'], s=5, alpha=0.3, c='purple')
ax.plot([0, combined['demand_gw'].max()], [0, combined['demand_gw'].max()], 'k--', label='1:1')
ax.set_title("VRE Generation vs Total Demand (2030)")
ax.set_xlabel("Demand (GW)")
ax.set_ylabel("VRE Solar+Wind (GW)")
ax.grid(True, alpha=0.3)

write_table(
    pd.DataFrame([{
        "n_days": len(combined),
        "mean_demand_gw": combined['demand_gw'].mean(),
        "mean_vre_gw": combined['vre'].mean(),
        "min_demand_gw": combined['demand_gw'].min(),
        "max_demand_gw": combined['demand_gw'].max(),
        "min_vre_gw": combined['vre'].min(),
        "max_vre_gw": combined['vre'].max(),
        "corr_demand_vre": combined['demand_gw'].corr(combined['vre']),
    }]),
    SCRIPT_STEM,
    "vre_vs_demand_summary",
)

# Distribution of demand
ax = axes3[1, 1]
ax.hist(dem_daily_ts.values, bins=50, color='grey', alpha=0.6)
ax.set_title("Daily Total Demand Distribution (2030)")
ax.set_xlabel("Demand (MW)")
ax.grid(True, alpha=0.3)

write_table(
    pd.DataFrame([{
        "n": len(dem_daily_ts),
        "mean_mw": dem_daily_ts.mean(),
        "std_mw": dem_daily_ts.std(),
        "min_mw": dem_daily_ts.min(),
        "max_mw": dem_daily_ts.max(),
        "median_mw": dem_daily_ts.median(),
    }]),
    SCRIPT_STEM,
    "demand_distribution_summary",
)

plt.tight_layout()
plt.savefig(FIGURES / "06_pisp_detailed.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 06_pisp_detailed.png")

print("\nDone.")
