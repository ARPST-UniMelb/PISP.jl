"""
eda/06_pisp_outputs.py
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

OUT = Path("data/pisp-datasets/out-ref4006-poe10/csv")
FIGURES = Path("eda/figures")
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
sol_pmax_map = solar_gens.set_index('id_gen')['pmax']
wind_pmax_map = wind_gens.set_index('id_gen')['pmax']
sol_cf = sol_sched.groupby('id_gen')['value'].mean() / sol_sched['id_gen'].map(sol_pmax_map)
wind_cf = wind_sched.groupby('id_gen')['value'].mean() / wind_sched['id_gen'].map(wind_pmax_map)
ax.plot(np.sort(sol_cf.dropna().values)[::-1], color='darkorange', linewidth=1.5, label=f'Solar (n={len(sol_cf.dropna())})', alpha=0.7)
ax.plot(np.sort(wind_cf.dropna().values)[::-1], color='steelblue', linewidth=1.5, label=f'Wind (n={len(wind_cf.dropna())})', alpha=0.7)
ax.set_title("Capacity Factor Duration Curve (2030)")
ax.set_xlabel("Generator Rank")
ax.set_ylabel("Capacity Factor")
ax.legend()
ax.grid(True, alpha=0.3)

# Wind pmax annual mean
ax = axes[0, 1]
wind_ids = wind_gens['id_gen'].values
wind_sched = gen_pmax[gen_pmax['id_gen'].isin(wind_ids)]
wind_annual = wind_sched.groupby('id_gen')['value'].mean().sort_values()
ax.barh(range(len(wind_annual)), wind_annual.values, color='steelblue', alpha=0.7)
ax.set_title("Wind Generators — Annual Mean pmax (MW)")
ax.set_xlabel("PMax (MW)")
ax.grid(True, alpha=0.3)

# Demand by area
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

# Duration curve: solar vs wind
ax = axes[1, 1]
if len(sol_sched) > 0:
    sol_cf = sol_sched.groupby('id_gen')['value'].mean() / sol_sched['id_gen'].map(sol_pmax_map)
    ax.plot(np.sort(sol_cf.dropna().values)[::-1], color='darkorange', linewidth=1.5, label='Solar CF', alpha=0.7)
if len(wind_sched) > 0:
    wind_cf = wind_sched.groupby('id_gen')['value'].mean() / wind_sched['id_gen'].map(wind_pmax_map)
    ax.plot(np.sort(wind_cf.dropna().values)[::-1], color='steelblue', linewidth=1.5, label='Wind CF', alpha=0.7)
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

# Distribution of demand
ax = axes3[1, 1]
ax.hist(dem_daily_ts.values, bins=50, color='grey', alpha=0.6)
ax.set_title("Daily Total Demand Distribution (2030)")
ax.set_xlabel("Demand (MW)")
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "06_pisp_detailed.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 06_pisp_detailed.png")

print("\nDone.")
