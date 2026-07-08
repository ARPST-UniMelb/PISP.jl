"""
eda/04_seasonal_extremes.py
Analyze summer extremes: zero-output events, extended low-output periods,
and patterns that could indicate extreme heat derating.
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.dates import DateFormatter

TRACES = Path("data/pisp-downloads/Traces")
FIGURES = Path("eda/figures")
FIGURES.mkdir(parents=True, exist_ok=True)

HH_COLS_SOL = [str(i) for i in range(1, 49)]
HH_COLS_WIND = [str(i).zfill(2) for i in range(1, 49)]
MIDDAY = [str(i) for i in range(24, 36)]

def load_trace(tech, year, location):
    f = TRACES / f"{tech}_{year}" / f"{location}_RefYear{year}.csv"
    if not f.exists():
        return None
    df = pd.read_csv(f)
    df['datetime'] = pd.to_datetime(
        df['Year'].astype(int).astype(str) + '-' +
        df['Month'].astype(int).astype(str).str.zfill(2) + '-' +
        df['Day'].astype(int).astype(str).str.zfill(2)
    )
    return df

# ====== 1. Find hottest historical summers and examine solar patterns ======
# Known hot Australian summers:
# 2019: Black Summer (bushfires, extreme heat)
# 2013: "Angry Summer" (record heat)
# 2017: Hot summer in NSW/VIC
# 2015: Strong El Niño

HOT_SUMMERS = [2019, 2013, 2017, 2015, 2023]
COOL_SUMMERS = [2011, 2016, 2020, 2022]  # La Niña years

SOLAR_LOC = 'Bannerton_SAT'
WIND_LOC = 'DUNDWF1'

# ====== Figure 1: Hot vs Cool summer solar profiles ======
fig, axes = plt.subplots(2, 1, figsize=(14, 10))

for ax, season_type, year_list, color in [
    (axes[0], 'Hot Summers', HOT_SUMMERS, 'darkred'),
    (axes[1], 'Cool Summers', COOL_SUMMERS, 'steelblue'),
]:
    for yr in year_list:
        df = load_trace('solar', yr, SOLAR_LOC)
        if df is None:
            continue
        summer = df[df['Month'].isin([12, 1, 2])]
        if len(summer) == 0:
            continue
        daily = summer[HH_COLS_SOL].mean(axis=1)
        ax.plot(summer['datetime'], daily, linewidth=0.5, alpha=0.6,
               color=color, label=str(yr) if yr == year_list[0] else None)
        ax.plot(summer['datetime'], daily.rolling(3).mean(), linewidth=1.5,
               color='black', alpha=0.8)

    ax.set_title(f"Solar {SOLAR_LOC} — {season_type} Daily Mean CF")
    ax.set_ylabel("Daily Mean CF")
    ax.set_ylim(0, 0.5)
    ax.grid(True, alpha=0.3)
    ax.legend(loc='upper right', fontsize=8)

axes[1].set_xlabel("Date")
plt.tight_layout()
plt.savefig(FIGURES / "04_hot_vs_cool_summer_solar.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 04_hot_vs_cool_summer_solar.png")

# ====== Figure 2: Extended low-output events (3+ consecutive days) ======
fig2, axes2 = plt.subplots(2, 2, figsize=(14, 10))

for ax, tech, loc, hh_cols in [
    (axes2[0, 0], 'solar', SOLAR_LOC, HH_COLS_SOL),
    (axes2[0, 1], 'wind', WIND_LOC, HH_COLS_WIND),
]:
    # Find multi-day low-output events across all years
    all_low_events = []
    for yr in range(2011, 2024):
        df = load_trace(tech, yr, loc)
        if df is None:
            continue
        summer = df[df['Month'].isin([12, 1, 2])]
        if len(summer) == 0:
            continue
        daily = summer[hh_cols].mean(axis=1)
        threshold = 0.1 if tech == 'solar' else 0.15

        # Find consecutive days below threshold
        below = (daily < threshold).astype(int)
        diff = below.diff()
        starts = diff[diff == 1].index
        ends = diff[diff == -1].index

        for s, e in zip(starts, ends):
            duration = (e - s) + 1
            if duration >= 3:
                all_low_events.append({
                    'year': yr,
                    'start': summer.loc[s, 'datetime'],
                    'end': summer.loc[e, 'datetime'],
                    'duration': duration,
                    'min_cf': daily.loc[s:e].min(),
                    'mean_cf': daily.loc[s:e].mean(),
                    'tech': tech,
                })

    events_df = pd.DataFrame(all_low_events)
    if len(events_df) > 0:
        # Histogram of event duration
        ax.hist(events_df['duration'], bins=range(1, max(events_df['duration']) + 2),
               color='darkorange' if tech == 'solar' else 'steelblue', alpha=0.7, edgecolor='black')
        ax.set_title(f"{tech.upper()} {loc} — Duration of Low-Output Events (≥3 days)")
        ax.set_xlabel("Consecutive Days Below Threshold")
        ax.set_ylabel("Count")
        ax.grid(True, alpha=0.3)

        # Print worst events
        worst = events_df.nsmallest(5, 'mean_cf')
        print(f"\n{tech.upper()} worst summer low-output events:")
        for _, row in worst.iterrows():
            print(f"  {row['year']}: {row['start'].date()} to {row['end'].date()} "
                  f"({row['duration']}d, mean={row['mean_cf']:.3f}, min={row['min_cf']:.3f})")
    else:
        ax.text(0.5, 0.5, 'No multi-day low-output events found',
               ha='center', va='center', transform=ax.transAxes)
        ax.set_title(f"{tech.upper()} {loc} — No Extended Low Events")

# ====== Figure 3: Worst single-day solar events ======
ax3 = axes2[1, 0]
worst_solar_days = []
for yr in range(2011, 2024):
    df = load_trace('solar', yr, SOLAR_LOC)
    if df is None:
        continue
    summer = df[df['Month'].isin([12, 1, 2])]
    if len(summer) == 0:
        continue
    daily = summer[HH_COLS_SOL].mean(axis=1)
    worst_idx = daily.idxmin()
    worst_solar_days.append({
        'year': yr,
        'date': summer.loc[worst_idx, 'datetime'],
        'cf': daily.loc[worst_idx],
    })

worst_df = pd.DataFrame(worst_solar_days).sort_values('cf')
colors = ['darkred' if y in HOT_SUMMERS else 'steelblue' for y in worst_df['year']]
ax3.bar(range(len(worst_df)), worst_df['cf'], color=colors, alpha=0.7)
ax3.set_xticks(range(len(worst_df)))
ax3.set_xticklabels([f"{r['year']}" for _, r in worst_df.iterrows()], rotation=45, fontsize=8)
ax3.set_title(f"Solar {SOLAR_LOC} — Worst Summer Day by Year (sorted)")
ax3.set_ylabel("Daily Mean CF")
ax3.grid(True, alpha=0.3)

# ====== Figure 4: Half-hourly profile of worst solar day ======
ax4 = axes2[1, 1]
if len(worst_df) > 0:
    worst_row = worst_df.iloc[0]
    yr = int(worst_row['year'])
    worst_date = worst_row['date']
    df = load_trace('solar', yr, SOLAR_LOC)
    if df is not None:
        mask = (df['datetime'] == worst_date)
        if mask.any():
            worst_day = df[mask]
            half_hours = np.arange(0.5, 24.5, 0.5)
            ax4.plot(half_hours, worst_day.iloc[0, 3:51], 'darkred', linewidth=2, marker='o', markersize=3)
            ax4.set_title(f"Worst Solar Day: {worst_date.date()} (CF={worst_row['cf']:.3f})")
            ax4.set_xlabel("Hour")
            ax4.set_ylabel("Capacity Factor")
            ax4.set_ylim(0, 1)
            ax4.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "04_low_output_events.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 04_low_output_events.png")

# ====== Figure 5: Hourly CF distribution by month (solar) ======
fig5, ax5 = plt.subplots(figsize=(12, 6))

df_all = load_trace('solar', 2019, SOLAR_LOC)  # Use 2019 as representative hot year
if df_all is not None:
    df_all['month'] = df_all['Month']
    monthly_stats = df_all.groupby('month')[HH_COLS_SOL].agg(['mean', 'std', 'min', 'max'])

    months = range(1, 13)
    means = [monthly_stats.loc[m, ('mean',)].mean() if m in monthly_stats.index else 0 for m in months]
    stds = [monthly_stats.loc[m, ('mean', std)].mean() if m in monthly_stats.index else 0 for m in months]

    ax5.bar(months, means, yerr=stds, color='darkorange', alpha=0.6, edgecolor='black')
    ax5.set_title(f"Solar {SOLAR_LOC} 2019 — Monthly Mean CF ± Std")
    ax5.set_xlabel("Month")
    ax5.set_ylabel("Mean Capacity Factor")
    ax5.set_xticks(months)
    ax5.set_xticklabels(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])
    ax5.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "04_monthly_cf_2019.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 04_monthly_cf_2019.png")

# ====== Figure 6: Summer 2019 detailed — Black Summer ======
fig6, ax6 = plt.subplots(figsize=(16, 5))
df_2019 = load_trace('solar', 2019, SOLAR_LOC)
if df_2019 is not None:
    summer_2019 = df_2019[df_2019['Month'].isin([12, 1, 2])]
    daily = summer_2019[HH_COLS_SOL].mean(axis=1)
    ax6.plot(summer_2019['datetime'], daily, linewidth=0.5, color='darkorange', alpha=0.7)
    ax6.plot(summer_2019['datetime'], daily.rolling(3).mean(), linewidth=2, color='darkred')
    ax6.set_title(f"Solar {SOLAR_LOC} — Summer 2019 (Black Summer)")
    ax6.set_ylabel("Daily Mean CF")
    ax6.set_ylim(0, 0.5)
    ax6.grid(True, alpha=0.3)
    ax6.xaxis.set_major_formatter(DateFormatter('%Y-%m-%d'))
    plt.xticks(rotation=45)

plt.tight_layout()
plt.savefig(FIGURES / "04_summer_2019_black_summer.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 04_summer_2019_black_summer.png")

print("\nDone.")
