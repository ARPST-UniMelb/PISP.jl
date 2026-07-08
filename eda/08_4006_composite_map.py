"""
eda/08_4006_composite_map.py
Document which historical year maps to which financial year in the 4006 composite trace.
Also show the VRE characteristics (solar/wind CF) for each mapped year.
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.patches as mpatches

TRACES = Path("data/pisp-downloads/Traces")
FIGURES = Path("eda/figures")
FIGURES.mkdir(parents=True, exist_ok=True)

HH_COLS_SOL = [str(i) for i in range(1, 49)]
HH_COLS_WIND = [str(i).zfill(2) for i in range(1, 49)]

# ---- The hardcoded DATE_RANGES_REFYEARS mapping from PISP.jl ----
DATE_RANGES_REFYEARS = [
    ('2024-07-01', '2025-06-30', 2019),
    ('2025-07-01', '2026-06-30', 2020),
    ('2026-07-01', '2027-06-30', 2021),
    ('2027-07-01', '2028-06-30', 2022),
    ('2028-07-01', '2029-06-30', 2023),
    ('2029-07-01', '2030-06-30', 2015),
    ('2030-07-01', '2031-06-30', 2011),
    ('2031-07-01', '2032-06-30', 2012),
    ('2032-07-01', '2033-06-30', 2013),
    ('2033-07-01', '2034-06-30', 2014),
    ('2034-07-01', '2035-06-30', 2015),
    ('2035-07-01', '2036-06-30', 2016),
    ('2036-07-01', '2037-06-30', 2017),
    ('2037-07-01', '2038-06-30', 2018),
    ('2038-07-01', '2039-06-30', 2019),
    ('2039-07-01', '2040-06-30', 2020),
    ('2040-07-01', '2041-06-30', 2021),
    ('2041-07-01', '2042-06-30', 2022),
    ('2042-07-01', '2043-06-30', 2023),
    ('2043-07-01', '2044-06-30', 2015),
    ('2044-07-01', '2045-06-30', 2011),
    ('2045-07-01', '2046-06-30', 2012),
    ('2046-07-01', '2047-06-30', 2013),
    ('2047-07-01', '2048-06-30', 2014),
    ('2048-07-01', '2049-06-30', 2015),
    ('2049-07-01', '2050-06-30', 2016),
    ('2050-07-01', '2051-06-30', 2017),
    ('2051-07-01', '2052-06-30', 2018),
]

mapping_df = pd.DataFrame(DATE_RANGES_REFYEARS, columns=['fy_start', 'fy_end', 'ref_year'])
mapping_df['fy_label'] = mapping_df['fy_end'].apply(lambda x: f"FY{x[:4]}")
mapping_df['ref_label'] = mapping_df['ref_year'].apply(lambda x: f"{x}")

print("=== 4006 Composite Mapping ===")
for _, row in mapping_df.iterrows():
    print(f"  {row['fy_start'][:4]} → ref {row['ref_year']}")

# ====== Figure 1: Timeline of historical years in 4006 ======
fig, ax = plt.subplots(figsize=(18, 5))

unique_years = mapping_df['ref_year'].unique()
color_map = {yr: plt.cm.tab20(i % 20) for i, yr in enumerate(sorted(unique_years))}

for _, row in mapping_df.iterrows():
    fy_start = pd.to_datetime(row['fy_start'])
    fy_end = pd.to_datetime(row['fy_end'])
    duration = (fy_end - fy_start).days / 365
    ax.barh(0, duration, left=fy_start, height=0.5,
           color=color_map[row['ref_year']], edgecolor='black', linewidth=0.5)
    ax.text(fy_start + pd.Timedelta(days=90), 0, f"→ {row['ref_year']}",
           va='center', fontsize=8, color='black')

ax.set_yticks([0])
ax.set_yticklabels(['4006 Trace'])
ax.set_xlim(pd.to_datetime('2024-07-01'), pd.to_datetime('2052-07-01'))
ax.xaxis.set_major_locator(mdates.YearLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y'))
ax.set_title("4006 Reference Trace — Historical Year Mapping\n(Each bar = one financial year, color = source historical year)")
ax.set_xlabel("Date")
ax.grid(True, alpha=0.3, axis='x')

# Legend
legend_patches = [mpatches.Patch(color=color_map[yr], label=str(yr)) for yr in sorted(unique_years)]
ax.legend(handles=legend_patches, title='Historical Year', loc='upper right',
         ncol=len(unique_years), fontsize=7, framealpha=0.8)

plt.tight_layout()
plt.savefig(FIGURES / "08_4006_timeline_map.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 08_4006_timeline_map.png")

# ====== Figure 2: VRE CF by historical year ======
# Load Bannerton (solar) and DUNDWF1 (wind) for each unique ref year
SOLAR_LOC = 'Bannerton_SAT'
WIND_LOC = 'DUNDWF1'

year_stats = []
for yr in sorted(mapping_df['ref_year'].unique()):
    for tech, loc, hh_cols in [('solar', SOLAR_LOC, HH_COLS_SOL), ('wind', WIND_LOC, HH_COLS_WIND)]:
        f = TRACES / f"{tech}_{yr}" / f"{loc}_RefYear{yr}.csv"
        if f.exists():
            df = pd.read_csv(f)
            summer = df[df['Month'].isin([12, 1, 2])]
            if len(summer) > 0:
                daily_cf = summer[hh_cols].mean(axis=1)
                year_stats.append({
                    'ref_year': yr,
                    'tech': tech,
                    'annual_mean_cf': df[hh_cols].mean(axis=1).mean(),
                    'summer_mean_cf': daily_cf.mean(),
                    'summer_min_cf': daily_cf.min(),
                    'summer_p5_cf': daily_cf.quantile(0.05),
                })

stats_df = pd.DataFrame(year_stats)

# Bar chart: summer CF by year for solar and wind
fig2, axes2 = plt.subplots(1, 2, figsize=(14, 5))

for ax, tech in [(axes2[0], 'solar'), (axes2[1], 'wind')]:
    tech_df = stats_df[stats_df['tech'] == tech].sort_values('ref_year')
    colors = [color_map[y] for y in tech_df['ref_year']]
    bars = ax.bar(range(len(tech_df)), tech_df['summer_mean_cf'],
                 color=colors, alpha=0.8, edgecolor='black', linewidth=0.5)
    ax.errorbar(range(len(tech_df)), tech_df['summer_mean_cf'],
               yerr=tech_df['summer_mean_cf'] - tech_df['summer_p5_cf'],
               fmt='none', color='black', capsize=3, label='Mean ± P5')
    ax.set_xticks(range(len(tech_df)))
    ax.set_xticklabels([str(y) for y in tech_df['ref_year']], fontsize=9)
    ax.set_title(f"{tech.upper()} {loc} — Summer CF by Historical Year")
    ax.set_xlabel("Historical Year")
    ax.set_ylabel("Summer Daily Mean CF")
    ax.set_ylim(0, 0.5)
    ax.grid(True, alpha=0.3, axis='y')

    # Annotate hot years
    for i, (_, row) in enumerate(tech_df.iterrows()):
        if row['ref_year'] in [2019, 2013, 2017, 2015]:
            ax.annotate('HOT', (i, row['summer_mean_cf']),
                       textcoords="offset points", xytext=(0, 5),
                       ha='center', fontsize=7, color='darkred')

plt.tight_layout()
plt.savefig(FIGURES / "08_vre_by_historical_year.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 08_vre_by_historical_year.png")

# ====== Figure 3: Full-year CF for key decades ======
fig3, axes3 = plt.subplots(2, 1, figsize=(16, 8))

# Compare near-term (2025-2030) vs far-term (2045-2050)
near_years = [2025, 2026, 2027, 2028, 2029]
far_years = [2045, 2046, 2047, 2048, 2049]

def load_year_cf(years, tech, loc, hh_cols):
    """Load average daily CF for a list of years."""
    all_cfs = []
    for yr in years:
        ref_yr = mapping_df[mapping_df['fy_end'].str.startswith(str(yr))]['ref_year'].values
        if len(ref_yr) == 0:
            continue
        ref = ref_yr[0]
        f = TRACES / f"{tech}_{ref}" / f"{loc}_RefYear{ref}.csv"
        if f.exists():
            df = pd.read_csv(f)
            all_cfs.append(df[hh_cols].mean(axis=1).values)
    return np.mean(all_cfs, axis=0) if all_cfs else None

# Annual daily CF comparison
for ax, tech, loc, hh_cols, color in [
    (axes3[0], 'solar', SOLAR_LOC, HH_COLS_SOL, 'darkorange'),
    (axes3[1], 'wind', WIND_LOC, HH_COLS_WIND, 'steelblue'),
]:
    near_cf = load_year_cf(near_years, tech, loc, hh_cols)
    far_cf = load_year_cf(far_years, tech, loc, hh_cols)

    if near_cf is not None:
        ax.plot(near_cf, color=color, linewidth=0.5, alpha=0.5, label=f'Near-term {near_years[0]}-{near_years[-1]}')
        ax.plot(pd.Series(near_cf).rolling(30).mean(), color=color, linewidth=2,
               linestyle='-', label='Near-term 30d avg')

    if far_cf is not None:
        ax.plot(far_cf, color='grey', linewidth=0.5, alpha=0.5, label=f'Far-term {far_years[0]}-{far_years[-1]}')
        ax.plot(pd.Series(far_cf).rolling(30).mean(), color='black', linewidth=2,
               linestyle='--', label='Far-term 30d avg')

    ax.set_title(f"{tech.upper()} {loc} — Near-term vs Far-term Daily CF")
    ax.set_ylabel("Daily Mean CF")
    ax.set_xlabel("Day of Year")
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3)
    ax.set_ylim(0, 0.6)

plt.tight_layout()
plt.savefig(FIGURES / "08_near_vs_far_term.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 08_near_vs_far_term.png")

# ====== Figure 4: Year-by-year CF heatmap ======
fig4, ax4 = plt.subplots(figsize=(16, 4))

years_unique = sorted(mapping_df['ref_year'].unique())
techs = ['solar', 'wind']
heatmap_data = {}

for tech in techs:
    loc = SOLAR_LOC if tech == 'solar' else WIND_LOC
    hh_cols = HH_COLS_SOL if tech == 'solar' else HH_COLS_WIND
    row_data = []
    for yr in years_unique:
        f = TRACES / f"{tech}_{yr}" / f"{loc}_RefYear{yr}.csv"
        if f.exists():
            df = pd.read_csv(f)
            row_data.append(df[hh_cols].mean(axis=1).mean())
        else:
            row_data.append(np.nan)
    heatmap_data[tech] = row_data

# Plot heatmap
import matplotlib.colors as mcolors

combined = np.array([heatmap_data['solar'], heatmap_data['wind']])
im = ax4.imshow(combined, aspect='auto', cmap='YlOrRd', origin='lower')
ax4.set_yticks([0, 1])
ax4.set_yticklabels(['Solar', 'Wind'])
ax4.set_xticks(range(len(years_unique)))
ax4.set_xticklabels([str(y) for y in years_unique], fontsize=9)
ax4.set_title("Annual Mean CF by Historical Year and Technology")
plt.colorbar(im, ax=ax4, label='Annual Mean CF', shrink=0.5)

# Annotate each cell
for i, tech in enumerate(techs):
    for j, yr in enumerate(years_unique):
        val = heatmap_data[tech][j]
        if not np.isnan(val):
            ax4.text(j, i, f"{val:.3f}", ha='center', va='center', fontsize=7,
                   color='black' if val > 0.25 else 'white')

plt.tight_layout()
plt.savefig(FIGURES / "08_vre_heatmap.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 08_vre_heatmap.png")

print("\n=== 4006 COMPOSITE STATS ===")
print(f"Total years: {len(DATE_RANGES_REFYEARS)}")
print(f"Unique historical years used: {sorted(mapping_df['ref_year'].unique())}")
print(f"Most repeated: {mapping_df['ref_year'].value_counts().to_dict()}")

print("\nDone.")