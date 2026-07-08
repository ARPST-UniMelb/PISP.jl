"""
eda/02_plot_4006_traces.py
Plot AEMO ISP 4006 composite trace — solar and wind capacity factors by region/state.
Shows diurnal, seasonal, and inter-annual patterns.
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

TRACES = Path("data/pisp-downloads/Traces")
FIGURES = Path("eda/figures")
FIGURES.mkdir(parents=True, exist_ok=True)

# ---- Helper: add datetime, compute daily stats ----
def add_datetime(df):
    df = df.copy()
    df['datetime'] = pd.to_datetime(
        df['Year'].astype(int).astype(str) + '-' + 
        df['Month'].astype(int).astype(str).str.zfill(2) + '-' + 
        df['Day'].astype(int).astype(str).str.zfill(2)
    )
    return df

def daily_cf(df, half_hour_cols):
    """Compute daily mean capacity factor from half-hourly columns."""
    return df[half_hour_cols].mean(axis=1)

def midday_cf(df, cols_24_to_36):
    """Max capacity factor during midday (hours 12-18, cols 24-36)."""
    return df[cols_24_to_36].max(axis=1)

# ---- Load representative traces across states ----
def load_traces(tech, trace_year, locations):
    """Load CSVs for given technology, year, and location names."""
    dfs = {}
    base = TRACES / f"{tech}_{trace_year}"
    for loc in locations:
        file = base / f"{loc}_RefYear{trace_year}.csv"
        if file.exists():
            dfs[loc] = add_datetime(pd.read_csv(file))
    return dfs

# State-representative solar locations
SOLAR_LOCATIONS = {
    'VIC': 'Bannerton_SAT',
    'NSW': 'Darlington_Point_SAT',  
    'QLD': 'Banksia_SAT',
    'SA': 'Bungala_One_SAT',
    'TAS': 'Derby_SAT',
}

# State-representative wind locations  
WIND_LOCATIONS = {
    'VIC': 'DUNDWF1',
    'NSW': 'GULLRWF1',
    'QLD': 'KABANWF1',
    'SA': 'CLEMGPWF', 
    'TAS': 'MUSSELR1',
}

HH_COLS_SOL = [str(i) for i in range(1, 49)]
HH_COLS_WIND = [str(i).zfill(2) for i in range(1, 49)]

# ---- Load 4006 traces ----
sol_4006 = load_traces('solar', 4006, SOLAR_LOCATIONS.values())
wind_4006 = load_traces('wind', 4006, WIND_LOCATIONS.values())

print(f"Loaded {len(sol_4006)} solar locations, {len(wind_4006)} wind locations for trace 4006")

# ====== Figure 1: 4006 Solar CF Overview ======
fig, axes = plt.subplots(len(sol_4006), 1, figsize=(16, 3*len(sol_4006)), sharex=True)
if len(sol_4006) == 1:
    axes = [axes]

state_names = {v: k for k, v in SOLAR_LOCATIONS.items()}
for ax, (loc, df) in zip(axes, sol_4006.items()):
    state = state_names.get(loc, loc)
    # Daily mean CF
    daily = daily_cf(df, HH_COLS_SOL)
    ax.plot(df['datetime'], daily, linewidth=0.3, alpha=0.7, color='darkorange')
    # 7-day rolling
    ax.plot(df['datetime'], daily.rolling(7).mean(), linewidth=1.5, color='darkred', label='7-day avg')
    ax.set_ylabel(f"{state}\nCF")
    ax.set_ylim(0, 1)
    ax.legend(loc='upper right', fontsize=8)
    ax.grid(True, alpha=0.3)

axes[-1].set_xlabel("Date")
fig.suptitle("Solar 4006 — Daily Mean Capacity Factor by State", fontsize=14, y=1.01)
plt.tight_layout()
plt.savefig(FIGURES / "02_solar_4006_daily_cf.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 02_solar_4006_daily_cf.png")

# ====== Figure 2: 4006 Wind CF Overview ======
fig2, axes2 = plt.subplots(len(wind_4006), 1, figsize=(16, 3*len(wind_4006)), sharex=True)
if len(wind_4006) == 1:
    axes2 = [axes2]

state_names_w = {v: k for k, v in WIND_LOCATIONS.items()}
for ax, (loc, df) in zip(axes2, wind_4006.items()):
    state = state_names_w.get(loc, loc)
    daily = daily_cf(df, HH_COLS_WIND)
    ax.plot(df['datetime'], daily, linewidth=0.3, alpha=0.7, color='steelblue')
    ax.plot(df['datetime'], daily.rolling(7).mean(), linewidth=1.5, color='darkblue', label='7-day avg')
    ax.set_ylabel(f"{state}\nCF")
    ax.set_ylim(0, 1)
    ax.legend(loc='upper right', fontsize=8)
    ax.grid(True, alpha=0.3)

axes2[-1].set_xlabel("Date")
fig2.suptitle("Wind 4006 — Daily Mean Capacity Factor by State", fontsize=14, y=1.01)
plt.tight_layout()
plt.savefig(FIGURES / "02_wind_4006_daily_cf.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 02_wind_4006_daily_cf.png")

# ====== Figure 3: Solar summer vs winter daily profiles ======
fig3, axes3 = plt.subplots(2, 1, figsize=(14, 8))

# Pick one location for profile
prof_loc = 'Bannerton_SAT'  # VIC solar
df_prof = sol_4006[prof_loc]

# Summer (Dec-Feb) and Winter (Jun-Aug)
summer_mask = df_prof['Month'].isin([12, 1, 2])
winter_mask = df_prof['Month'].isin([6, 7, 8])

# Half-hourly profiles
half_hours = np.arange(0.5, 24.5, 0.5)

for season, mask, color, ax in [('Summer', summer_mask, 'darkorange', axes3[0]), 
                                  ('Winter', winter_mask, 'steelblue', axes3[1])]:
    df_season = df_prof[mask]
    hh_vals = df_season[HH_COLS_SOL]
    
    # Plot all days
    for i in range(min(200, len(df_season))):
        ax.plot(half_hours, hh_vals.iloc[i,:], linewidth=0.3, alpha=0.15, color=color)
    
    mean_profile = hh_vals.mean(axis=0)
    ax.plot(half_hours, mean_profile, linewidth=2.5, color='black', label='Mean')
    
    p10 = hh_vals.quantile(0.1, axis=0)
    p90 = hh_vals.quantile(0.9, axis=0)
    ax.fill_between(half_hours, p10, p90, alpha=0.3, color=color, label='P10-P90')
    
    ax.set_title(f"{prof_loc} {season} ({mask.sum()} days)")
    ax.set_ylabel("Capacity Factor")
    ax.set_ylim(0, 1.05)
    ax.set_xlabel("Hour of day")
    ax.legend(loc='upper right', fontsize=8)
    ax.grid(True, alpha=0.3)

fig3.suptitle("Solar 4006 — Diurnal Profiles: Summer vs Winter", fontsize=14)
plt.tight_layout()
plt.savefig(FIGURES / "02_solar_4006_diurnal.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 02_solar_4006_diurnal.png")

# ====== Figure 4: Wind seasonal analysis ======
fig4, axes4 = plt.subplots(2, 1, figsize=(14, 8))

wind_loc = 'DUNDWF1'  # VIC
df_wind_prof = wind_4006.get(wind_loc)

if df_wind_prof is not None:
    wind_hh_cols = [str(i).zfill(2) for i in range(1, 49)]
    hh_idx = pd.Index([str(i).zfill(2) for i in range(1, 49)])
    
    # Monthly mean CF
    df_wind_prof['month'] = df_wind_prof['Month']
    monthly_cf = df_wind_prof.groupby('month')[wind_hh_cols].mean()
    
    ax = axes4[0]
    for m in range(1, 13):
        if m in monthly_cf.index:
            ax.plot(half_hours, monthly_cf.loc[m], linewidth=1, 
                   alpha=0.8, label=f'Month {m}')
    ax.set_title(f"Wind 4006 — Mean Diurnal Profile by Month: {wind_loc}")
    ax.set_ylabel("Capacity Factor")
    ax.legend(loc='upper right', fontsize=7, ncol=4)
    ax.grid(True, alpha=0.3)
    ax.set_ylim(0, 1)
    
    # Annual CF over time
    ax2 = axes4[1]
    daily_wind = daily_cf(df_wind_prof, wind_hh_cols)
    ax2.plot(df_wind_prof['datetime'], daily_wind, linewidth=0.3, alpha=0.5, color='steelblue')
    monthly_mean = daily_wind.groupby(df_wind_prof['datetime'].dt.to_period('M')).mean()
    monthly_dates = monthly_mean.index.to_timestamp()
    ax2.plot(monthly_dates, monthly_mean.values, linewidth=1.5, color='darkblue')
    ax2.set_title(f"Wind 4006 — Daily & Monthly Mean CF: {wind_loc}")
    ax2.set_ylabel("Capacity Factor")
    ax2.set_ylim(0, 1)
    ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "02_wind_4006_seasonal.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 02_wind_4006_seasonal.png")

# ====== Figure 5: 4006 composite year-by-year overview ======
# Show how each financial year in the composite looks
fig5, ax5 = plt.subplots(figsize=(16, 6))

# Use Bannerton (solar) and DUNDWF1 (wind) as representative
df_s = sol_4006.get('Bannerton_SAT')
df_w = wind_4006.get('DUNDWF1')

if df_s is not None:
    df_s['fy'] = (df_s['datetime'] + pd.offsets.MonthEnd(6)).dt.year
    monthly_sol = daily_cf(df_s, HH_COLS_SOL).groupby(df_s['fy']).mean()
    ax5.plot(monthly_sol.index, monthly_sol.values, 'o-', color='darkorange', 
            linewidth=2, markersize=6, label='Solar CF (Bannerton VIC)')

if df_w is not None:
    wind_hh_cols = [str(i).zfill(2) for i in range(1, 49)]
    df_w['fy'] = (df_w['datetime'] + pd.offsets.MonthEnd(6)).dt.year
    monthly_wind = daily_cf(df_w, wind_hh_cols).groupby(df_w['fy']).mean()
    ax5.plot(monthly_wind.index, monthly_wind.values, 's-', color='darkblue',
            linewidth=2, markersize=6, label='Wind CF (DUNDWF1 VIC)')

ax5.set_xlabel("Financial Year (ending)")
ax5.set_ylabel("Annual Mean Capacity Factor")
ax5.set_title("Trace 4006 — Annual Mean Capacity Factor by Financial Year")
ax5.legend()
ax5.grid(True, alpha=0.3)
ax5.set_ylim(0, 0.5)

plt.tight_layout()
plt.savefig(FIGURES / "02_4006_annual_cf.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 02_4006_annual_cf.png")

print("\nDone.")
