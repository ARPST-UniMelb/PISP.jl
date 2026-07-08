"""
eda/07_demand_heat_events.py
Analyze demand patterns during summer heat events.
Key: does demand spike when VRE output is lowest (hot calm days)?
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

TRACES = Path("data/pisp-downloads/Traces")
OUT = Path("data/pisp-datasets/out-ref4006-poe10/csv")
FIGURES = Path("eda/figures")
FIGURES.mkdir(parents=True, exist_ok=True)

HH_COLS_SOL = [str(i) for i in range(1, 49)]

# ---- Load demand traces from 4006 ----
dem_dir = TRACES / "demand_VIC_Step Change"
dem_files = sorted(dem_dir.glob("*_POE10_OPSO_MODELLING.csv"))
print(f"Found {len(dem_files)} demand trace files")

# ---- Load demand schedule from PISP output ----
dem_load = pd.read_csv(OUT / "schedule-2030" / "Demand_load_sched.csv")
dem_df = pd.read_csv(OUT / "Demand.csv")
bus_df = pd.read_csv(OUT / "Bus.csv")

area_map = dict(zip(bus_df['id_bus'], bus_df['id_area']))
area_names = {1: 'QLD', 2: 'NSW', 3: 'VIC', 4: 'TAS', 5: 'SA'}

dem_load['datetime'] = pd.to_datetime(dem_load['date'])
dem_load = dem_load.merge(dem_df[['id_dem', 'id_bus']], on='id_dem')
dem_load['area'] = dem_load['id_bus'].map(area_map)

# ---- Aggregate daily demand by area ----
dem_daily = dem_load.groupby([dem_load['datetime'].dt.date, 'area'])['value'].mean().reset_index()
dem_daily.columns = ['date', 'area', 'demand_mw']

# ---- Load solar 4006 for VIC ----
sol_4006 = {}
locations = ['Bannerton_SAT', 'Darlington_Point_SAT']
for loc in locations:
    f = TRACES / "solar_4006" / f"{loc}_RefYear4006.csv"
    if f.exists():
        df = pd.read_csv(f)
        df['datetime'] = pd.to_datetime(
            df['Year'].astype(int).astype(str) + '-' +
            df['Month'].astype(int).astype(str).str.zfill(2) + '-' +
            df['Day'].astype(int).astype(str).str.zfill(2)
        )
        sol_4006[loc] = df

print(f"Loaded {len(sol_4006)} solar locations for 4006")

# ====== Figure 1: Demand + VRE during summer ======
fig, axes = plt.subplots(2, 1, figsize=(16, 10))

vic_dem = dem_load[dem_load['area'] == 3].copy()  # VIC
vic_daily = vic_dem.groupby(vic_dem['datetime'].dt.date)['value'].mean()

if 'Bannerton_SAT' in sol_4006:
    sol_vic = sol_4006['Bannerton_SAT']
    sol_vic_daily = sol_vic[HH_COLS_SOL].mean(axis=1)
    sol_vic_dates = sol_vic['datetime']

    ax = axes[0]
    ax.plot(sol_vic_dates, sol_vic_daily, color='darkorange', linewidth=0.5,
           alpha=0.7, label='Solar CF (Bannerton)')
    ax.plot(sol_vic_dates, sol_vic_daily.rolling(7).mean(), color='darkred',
           linewidth=2, label='7-day avg')
    ax.set_title("4006 Solar CF — Bannerton VIC (Full Period)")
    ax.set_ylabel("Daily Mean CF")
    ax.set_ylim(0, 0.4)
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45)

vic_dem_dates = pd.to_datetime(vic_daily.index)
ax = axes[1]
ax.plot(vic_dem_dates, vic_daily.values, color='grey', linewidth=0.5,
       alpha=0.7, label='VIC Demand')
ax.plot(vic_dem_dates, vic_daily.rolling(7).mean(), color='black',
       linewidth=2, label='7-day avg')
ax.set_title("2030 VIC Daily Mean Demand (MW)")
ax.set_ylabel("Demand (MW)")
ax.legend()
ax.grid(True, alpha=0.3)
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
plt.setp(ax.xaxis.get_majorticklabels(), rotation=45)

plt.tight_layout()
plt.savefig(FIGURES / "07_vic_demand_solar_4006.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 07_vic_demand_solar_4006.png")

# ====== Figure 2: Scatter: demand vs solar CF ======
fig2, ax2 = plt.subplots(figsize=(10, 6))

# Find days where demand is high AND solar is low (worst combo)
vic_daily_df = pd.DataFrame({'date': vic_daily.index, 'demand': vic_daily.values})
vic_daily_df['datetime'] = pd.to_datetime(vic_daily_df['date'])

if 'Bannerton_SAT' in sol_4006:
    sol_dates = sol_4006['Bannerton_SAT']['datetime'].values
    sol_daily_vals = sol_4006['Bannerton_SAT'][HH_COLS_SOL].mean(axis=1).values

    merged = vic_daily_df.copy()
    merged['solar_cf'] = np.nan
    for i, row in merged.iterrows():
        matches = sol_4006['Bannerton_SAT'][
            (sol_4006['Bannerton_SAT']['datetime'].dt.date == row['date'])
        ]
        if len(matches) > 0:
            merged.at[i, 'solar_cf'] = matches[HH_COLS_SOL].mean(axis=1).values[0]

    merged = merged.dropna(subset=['solar_cf'])
    ax2.scatter(merged['solar_cf'], merged['demand'], s=5, alpha=0.3, c='purple')
    ax2.set_title("VIC Demand vs Solar CF (2030, Bannerton)")
    ax2.set_xlabel("Daily Mean Solar CF")
    ax2.set_ylabel("Daily Mean Demand (MW)")
    ax2.grid(True, alpha=0.3)

    # Highlight high-demand low-solar days
    threshold_demand = merged['demand'].quantile(0.9)
    threshold_solar = merged['solar_cf'].quantile(0.1)
    bad_days = merged[(merged['demand'] > threshold_demand) & (merged['solar_cf'] < threshold_solar)]
    ax2.scatter(bad_days['solar_cf'], bad_days['demand'], s=30, c='red',
               label=f'High demand ({threshold_demand:.0f} MW) + Low solar (<{threshold_solar:.3f} CF)')
    ax2.legend(fontsize=8)
    ax2.grid(True, alpha=0.3)

    print(f"\nHigh-demand + Low-solar days: {len(bad_days)}")
    print(f"  Threshold: demand > {threshold_demand:.0f} MW, solar CF < {threshold_solar:.3f}")

plt.tight_layout()
plt.savefig(FIGURES / "07_demand_vs_solar_scatter.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 07_demand_vs_solar_scatter.png")

# ====== Figure 3: Demand heat events vs normal days ======
fig3, axes3 = plt.subplots(2, 2, figsize=(14, 10))

# Split demand into heat events vs normal
demand_p90 = vic_daily.quantile(0.9)
demand_p95 = vic_daily.quantile(0.95)

vic_dem_full = vic_dem.copy()
vic_dem_full['date_only'] = vic_dem_full['datetime'].dt.date
daily_vic = vic_dem_full.groupby('date_only')['value'].mean()

heat_days = daily_vic[daily_vic >= demand_p95].index
normal_days = daily_vic[daily_vic < demand_p90].index

print(f"\nDemand thresholds: P90={demand_p90:.0f} MW, P95={demand_p95:.0f} MW")
print(f"Heat event days (>P95): {len(heat_days)}")
print(f"Normal days (<P90): {len(normal_days)}")

# Hourly profile for heat days vs normal days
ax = axes3[0, 0]
heat_df = vic_dem_full[vic_dem_full['date_only'].isin(heat_days)]
normal_df = vic_dem_full[vic_dem_full['date_only'].isin(normal_days)]

heat_hourly = heat_df.groupby(heat_df['datetime'].dt.hour)['value'].mean()
normal_hourly = normal_df.groupby(normal_df['datetime'].dt.hour)['value'].mean()

ax.plot(range(24), heat_hourly.values, 'r-', linewidth=2, marker='o', markersize=4,
       label=f'Heat days (>{demand_p95:.0f} MW, n={len(heat_days)})')
ax.plot(range(24), normal_hourly.values, 'b-', linewidth=2, marker='s', markersize=4,
       label=f'Normal days (<{demand_p90:.0f} MW, n={len(normal_days)})')
ax.set_title("VIC Demand: Heat Event Days vs Normal Days")
ax.set_xlabel("Hour")
ax.set_ylabel("Demand (MW)")
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)

# Duration curve
ax = axes3[0, 1]
sorted_demand = np.sort(vic_daily.values)[::-1]
ax.plot(sorted_demand, 'grey', linewidth=1.5)
ax.axhline(demand_p90, color='blue', linestyle='--', label=f'P90={demand_p90:.0f}')
ax.axhline(demand_p95, color='red', linestyle='--', label=f'P95={demand_p95:.0f}')
ax.set_title("VIC Demand Duration Curve (2030)")
ax.set_xlabel("Day Rank")
ax.set_ylabel("Demand (MW)")
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)

# Seasonal demand heatmap
ax = axes3[1, 0]
dem_monthly = dem_load.copy()
dem_monthly['month'] = dem_monthly['datetime'].dt.month
dem_monthly['hour'] = dem_monthly['datetime'].dt.hour
pivot = dem_monthly[dem_monthly['area'] == 3].pivot_table(
    index='month', columns='hour', values='value', aggfunc='mean'
)
if not pivot.empty:
    im = ax.imshow(pivot.values, aspect='auto', cmap='YlOrRd', origin='lower')
    ax.set_title("VIC Demand Heatmap: Month vs Hour")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Month")
    ax.set_yticks(range(12))
    ax.set_yticklabels(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
    plt.colorbar(im, ax=ax, label='Demand (MW)')

# Combined: VRE capacity vs demand
ax = axes3[1, 1]
if 'Bannerton_SAT' in sol_4006:
    # Use aggregated daily
    merged_sorted = merged.sort_values('demand')
    ax.bar(range(len(merged_sorted)), merged_sorted['demand'] / merged_sorted['demand'].max(),
          alpha=0.5, color='grey', label='VIC Demand (norm)', width=1)
    ax.plot(range(len(merged_sorted)), merged_sorted['solar_cf'] / merged_sorted['solar_cf'].max(),
           'darkorange', linewidth=1, label='Solar CF (norm)')
    ax.set_title("Normalized Demand & Solar CF (sorted by demand)")
    ax.set_xlabel("Day Rank")
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "07_demand_heat_events.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 07_demand_heat_events.png")

# ====== Print key statistics ======
print("\n=== DEMAND HEAT EVENT ANALYSIS ===")
print(f"Total days: {len(daily_vic)}")
print(f"Heat event days (>P95): {len(heat_days)} ({100*len(heat_days)/len(daily_vic):.1f}%)")
print(f"Peak demand: {daily_vic.max():.0f} MW on {daily_vic.idxmax()}")
print(f"Mean demand: {daily_vic.mean():.0f} MW")

# Check solar CF on the hottest demand days
if 'Bannerton_SAT' in sol_4006:
    hot_day_cfs = []
    for hd in heat_days[:10]:
        match = sol_4006['Bannerton_SAT'][
            sol_4006['Bannerton_SAT']['datetime'].dt.date == hd
        ]
        if len(match) > 0:
            hot_day_cfs.append(match[HH_COLS_SOL].mean(axis=1).values[0])
    print(f"\nSolar CF on top 10 heat event days: mean={np.mean(hot_day_cfs):.4f}")
    print(f"  Individual CFs: {[f'{c:.4f}' for c in hot_day_cfs]}")

print("\nDone.")