"""
eda/03_year_comparison.py
Compare solar and wind capacity factors across historical reference years (2011-2023).
Key question: do any years show patterns consistent with extreme heat derating?
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from table_utils import write_table

SCRIPT_STEM = "03_year_comparison"
TRACES = Path("data/pisp-downloads/Traces")
FIGURES = Path("eda/figures")
FIGURES.mkdir(parents=True, exist_ok=True)

YEARS = list(range(2011, 2024))
HH_COLS_SOL = [str(i) for i in range(1, 49)]
HH_COLS_WIND = [str(i).zfill(2) for i in range(1, 49)]

# ---- Load solar traces for a representative location across all years ----
def load_location_all_years(tech, location, years):
    """Load a single location's traces across all historical years."""
    dfs = {}
    for yr in years:
        f = TRACES / f"{tech}_{yr}" / f"{location}_RefYear{yr}.csv"
        if f.exists():
            df = pd.read_csv(f)
            df['datetime'] = pd.to_datetime(
                df['Year'].astype(int).astype(str) + '-' +
                df['Month'].astype(int).astype(str).str.zfill(2) + '-' +
                df['Day'].astype(int).astype(str).str.zfill(2)
            )
            df['year'] = yr
            dfs[yr] = df
    return dfs

# Representative locations
SOLAR_LOC = 'Bannerton_SAT'  # VIC solar
WIND_LOC = 'DUNDWF1'        # VIC wind

sol_years = load_location_all_years('solar', SOLAR_LOC, YEARS)
wind_years = load_location_all_years('wind', WIND_LOC, YEARS)

print(f"Loaded solar {SOLAR_LOC}: {len(sol_years)} years")
print(f"Loaded wind {WIND_LOC}: {len(wind_years)} years")

# ====== Figure 1: Summer CF comparison across years ======
fig, axes = plt.subplots(2, 2, figsize=(14, 10))

seasonal_cf_rows = []

# Solar summer (Dec-Feb) daily mean CF by year
for ax in [axes[0, 0], axes[0, 1]]:
    is_solar = ax == axes[0, 0]
    loc = SOLAR_LOC if is_solar else WIND_LOC
    hh_cols = HH_COLS_SOL if is_solar else HH_COLS_WIND
    data = sol_years if is_solar else wind_years
    color = 'darkorange' if is_solar else 'steelblue'
    tech = 'Solar' if is_solar else 'Wind'

    summer_cfs = {}
    for yr, df in data.items():
        summer = df[df['Month'].isin([12, 1, 2])]
        if len(summer) > 0:
            summer_cfs[yr] = summer[hh_cols].mean(axis=1)
            seasonal_cf_rows.append({
                "tech": tech.lower(),
                "location": loc,
                "season": "Summer",
                "year": yr,
                "n_days": len(summer_cfs[yr]),
                "mean_cf": summer_cfs[yr].mean(),
                "std_cf": summer_cfs[yr].std(),
                "min_cf": summer_cfs[yr].min(),
                "max_cf": summer_cfs[yr].max(),
            })

    # Boxplot
    bp_data = []
    bp_labels = []
    for yr in sorted(summer_cfs.keys()):
        bp_data.append(summer_cfs[yr].values)
        bp_labels.append(str(yr))

    ax.boxplot(bp_data, labels=bp_labels, patch_artist=True,
               boxprops=dict(facecolor=color, alpha=0.3),
               medianprops=dict(color='black', linewidth=1.5))
    ax.set_title(f"{tech} {loc} — Summer Daily Mean CF by Year")
    ax.set_ylabel("Daily Mean Capacity Factor")
    ax.set_ylim(0, 1)
    ax.tick_params(axis='x', rotation=45)
    ax.grid(True, alpha=0.3)

# Solar/winter comparison
for ax in [axes[1, 0], axes[1, 1]]:
    is_solar = ax == axes[1, 0]
    loc = SOLAR_LOC if is_solar else WIND_LOC
    hh_cols = HH_COLS_SOL if is_solar else HH_COLS_WIND
    data = sol_years if is_solar else wind_years
    color = 'darkorange' if is_solar else 'steelblue'
    tech = 'Solar' if is_solar else 'Wind'

    winter_cfs = {}
    for yr, df in data.items():
        winter = df[df['Month'].isin([6, 7, 8])]
        if len(winter) > 0:
            winter_cfs[yr] = winter[hh_cols].mean(axis=1)
            seasonal_cf_rows.append({
                "tech": tech.lower(),
                "location": loc,
                "season": "Winter",
                "year": yr,
                "n_days": len(winter_cfs[yr]),
                "mean_cf": winter_cfs[yr].mean(),
                "std_cf": winter_cfs[yr].std(),
                "min_cf": winter_cfs[yr].min(),
                "max_cf": winter_cfs[yr].max(),
            })

    bp_data = []
    bp_labels = []
    for yr in sorted(winter_cfs.keys()):
        bp_data.append(winter_cfs[yr].values)
        bp_labels.append(str(yr))

    ax.boxplot(bp_data, labels=bp_labels, patch_artist=True,
               boxprops=dict(facecolor=color, alpha=0.3),
               medianprops=dict(color='black', linewidth=1.5))
    ax.set_title(f"{tech} {loc} — Winter Daily Mean CF by Year")
    ax.set_ylabel("Daily Mean Capacity Factor")
    ax.set_ylim(0, 1)
    ax.tick_params(axis='x', rotation=45)
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "03_year_comparison_boxplot.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 03_year_comparison_boxplot.png")

seasonal_cf_path = write_table(pd.DataFrame(seasonal_cf_rows), SCRIPT_STEM, "seasonal_cf_by_year")
print(f"Saved table: {seasonal_cf_path}")

# ====== Figure 2: Annual mean CF trend ======
fig2, ax2 = plt.subplots(figsize=(12, 5))

annual_cf_rows = []
for tech, data, hh_cols, color, marker in [
    ('Solar', sol_years, HH_COLS_SOL, 'darkorange', 'o'),
    ('Wind', wind_years, HH_COLS_WIND, 'steelblue', 's'),
]:
    location = SOLAR_LOC if tech == 'Solar' else WIND_LOC
    annual_means = []
    yrs = []
    for yr, df in sorted(data.items()):
        daily = df[hh_cols].mean(axis=1)
        annual_means.append(daily.mean())
        yrs.append(yr)
    for yr, mean_cf in zip(yrs, annual_means):
        annual_cf_rows.append({
            "tech": tech.lower(),
            "location": location,
            "year": yr,
            "mean_cf": mean_cf,
        })
    ax2.plot(yrs, annual_means, f'{marker}-', color=color, linewidth=2,
            markersize=8, label=f'{tech} {loc}')

ax2.set_xlabel("Reference Year")
ax2.set_ylabel("Annual Mean Capacity Factor")
ax2.set_title(f"Annual Mean CF: Solar ({SOLAR_LOC}) vs Wind ({WIND_LOC})")
ax2.legend()
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "03_annual_cf_trend.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 03_annual_cf_trend.png")

annual_cf_path = write_table(pd.DataFrame(annual_cf_rows), SCRIPT_STEM, "annual_cf_by_year")
print(f"Saved table: {annual_cf_path}")

# ====== Figure 3: Worst summer days by year ======
# For each year, find the day with lowest midday solar output
fig3, ax3 = plt.subplots(figsize=(12, 5))

midday_cols = [str(i) for i in range(24, 36)]  # hours 12-18

worst_summer_day_rows = []
for yr, df in sorted(sol_years.items()):
    summer = df[df['Month'].isin([12, 1, 2])]
    if len(summer) == 0:
        continue
    midday_max = summer[midday_cols].max(axis=1)
    worst_day_idx = midday_max.idxmin()
    worst_day = summer.loc[worst_day_idx]
    worst_cf = midday_max.min()
    worst_summer_day_rows.append({
        "year": yr,
        "date": worst_day['datetime'].strftime("%Y-%m-%d"),
        "midday_max_cf": worst_cf,
    })
    ax3.bar(str(yr), worst_cf, color='darkorange', alpha=0.7)
    ax3.annotate(f"{worst_cf:.2f}", (str(yr), worst_cf),
                textcoords="offset points", xytext=(0, 5),
                ha='center', fontsize=8)

ax3.set_title(f"Solar {SOLAR_LOC} — Worst Summer Day (Midday Max CF) by Year")
ax3.set_ylabel("Midday Max Capacity Factor")
ax3.set_ylim(0, 1)
ax3.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "03_worst_summer_day.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 03_worst_summer_day.png")

worst_summer_day_path = write_table(pd.DataFrame(worst_summer_day_rows), SCRIPT_STEM, "worst_summer_day_by_year")
print(f"Saved table: {worst_summer_day_path}")

# ====== Figure 4: Days with near-zero midday solar (potential extreme heat?) ======
fig4, axes4 = plt.subplots(1, 2, figsize=(14, 5))

low_output_rows = []
for yr, df in sorted(sol_years.items()):
    summer = df[df['Month'].isin([12, 1, 2])]
    if len(summer) == 0:
        continue
    midday_max = summer[midday_cols].max(axis=1)
    n_low = (midday_max < 0.05).sum()
    n_total = len(summer)
    low_output_rows.append({
        "tech": "solar",
        "location": SOLAR_LOC,
        "year": yr,
        "metric": "midday_max_cf",
        "threshold": 0.05,
        "n_low": int(n_low),
        "n_total": int(n_total),
        "low_percent": 100 * n_low / n_total,
    })
    axes4[0].bar(str(yr), 100 * n_low / n_total, color='darkorange', alpha=0.7)
    axes4[0].annotate(f"{n_low}", (str(yr), 100 * n_low / n_total),
                     textcoords="offset points", xytext=(0, 5),
                     ha='center', fontsize=8)

axes4[0].set_title(f"Solar {SOLAR_LOC} — % Summer Days with Midday Max CF < 0.05")
axes4[0].set_ylabel("% of Summer Days")
axes4[0].grid(True, alpha=0.3)

# Same for wind: days with CF < 0.05
for yr, df in sorted(wind_years.items()):
    summer = df[df['Month'].isin([12, 1, 2])]
    if len(summer) == 0:
        continue
    daily = summer[HH_COLS_WIND].mean(axis=1)
    n_low = (daily < 0.05).sum()
    n_total = len(summer)
    low_output_rows.append({
        "tech": "wind",
        "location": WIND_LOC,
        "year": yr,
        "metric": "daily_mean_cf",
        "threshold": 0.05,
        "n_low": int(n_low),
        "n_total": int(n_total),
        "low_percent": 100 * n_low / n_total,
    })
    axes4[1].bar(str(yr), 100 * n_low / n_total, color='steelblue', alpha=0.7)
    axes4[1].annotate(f"{n_low}", (str(yr), 100 * n_low / n_total),
                     textcoords="offset points", xytext=(0, 5),
                     ha='center', fontsize=8)

axes4[1].set_title(f"Wind {WIND_LOC} — % Summer Days with Daily Mean CF < 0.05")
axes4[1].set_ylabel("% of Summer Days")
axes4[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "03_zero_output_days.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 03_zero_output_days.png")

low_output_path = write_table(pd.DataFrame(low_output_rows), SCRIPT_STEM, "low_output_days_by_year")
print(f"Saved table: {low_output_path}")

# ====== Print summary statistics ======
print("\n=== YEAR-TO-YEAR VARIABILITY ===")
variability_rows = []
for tech, data, hh_cols in [('Solar', sol_years, HH_COLS_SOL), ('Wind', wind_years, HH_COLS_WIND)]:
    location = SOLAR_LOC if tech == 'Solar' else WIND_LOC
    annual = {}
    for yr, df in data.items():
        annual[yr] = df[hh_cols].mean(axis=1).mean()
    vals = list(annual.values())
    print(f"{tech}: mean={np.mean(vals):.3f}, std={np.std(vals):.3f}, "
          f"range=[{min(vals):.3f}, {max(vals):.3f}]")
    for yr, cf in sorted(annual.items()):
        print(f"  {yr}: {cf:.4f}")
    variability_rows.append({
        "tech": tech.lower(),
        "location": location,
        "mean_annual_cf": np.mean(vals),
        "std_annual_cf": np.std(vals),
        "min_annual_cf": min(vals),
        "max_annual_cf": max(vals),
    })

variability_path = write_table(pd.DataFrame(variability_rows), SCRIPT_STEM, "annual_cf_variability_summary")
print(f"Saved table: {variability_path}")

print("\nDone.")
