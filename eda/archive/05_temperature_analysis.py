"""
eda/archive/05_temperature_analysis.py
Investigate whether AEMO ISP models temperature-dependent derating.
Examines: ISP assumptions workbook, generator parameters, and trace patterns.
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import json

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from table_utils import write_table

SCRIPT_STEM = "05_temperature_analysis"
TRACES = Path("data/2024/pisp-downloads/Traces")
DOWNLOADS = Path("data/2024/pisp-downloads")
FIGURES = Path("eda/figures/python") / SCRIPT_STEM
FIGURES.mkdir(parents=True, exist_ok=True)

HH_COLS_SOL = [str(i) for i in range(1, 49)]
HH_COLS_WIND = [str(i).zfill(2) for i in range(1, 49)]

# ---- Baseline table schemas (kept explicit so empty tables still carry headers) ----
SHEET_INVENTORY_COLS = ["sheet_index", "sheet_name", "is_keyword_match", "is_rooftop_match", "is_reliability_match"]
RELEVANT_SHEET_SHAPE_COLS = ["sheet_name", "n_rows", "n_cols", "read_ok"]
ROOFTOP_SHEET_COLS = ["sheet_name", "n_rows", "n_cols", "columns_preview"]
RELIABILITY_SHEET_SHAPE_COLS = ["sheet_name", "n_rows", "n_cols"]
PISP_OUTPUT_INVENTORY_COLS = ["kind", "name"]
GENERATOR_DETAILS_COLS = ["category", "id_gen", "name", "tech", "forate", "derate", "pmin", "pmax", "n"]
GENERATOR_TEMP_COLS_COLS = ["generator_table_exists", "total_columns", "n_temp_columns", "temp_columns_list"]
CLIMATE_ZONE_SUMMARY_COLS = [
    "zone", "location", "n_summer_days", "mean_daily_cf", "mean_midday_cf", "min_midday_cf", "p5_midday_cf",
]


def write_sheet_inventory_table(rows):
    path = write_table(pd.DataFrame(rows, columns=SHEET_INVENTORY_COLS), SCRIPT_STEM, "workbook_sheet_inventory")
    print(f"Saved table: {path}")


def write_relevant_sheet_shapes_table(rows):
    path = write_table(
        pd.DataFrame(rows, columns=RELEVANT_SHEET_SHAPE_COLS), SCRIPT_STEM, "workbook_relevant_sheet_shapes"
    )
    print(f"Saved table: {path}")


def write_rooftop_sheet_table(rows):
    path = write_table(pd.DataFrame(rows, columns=ROOFTOP_SHEET_COLS), SCRIPT_STEM, "workbook_rooftop_sheet_summary")
    print(f"Saved table: {path}")


def write_reliability_sheet_shapes_table(rows):
    path = write_table(
        pd.DataFrame(rows, columns=RELIABILITY_SHEET_SHAPE_COLS), SCRIPT_STEM, "workbook_reliability_sheet_shapes"
    )
    print(f"Saved table: {path}")


def write_pisp_output_inventory_table(rows):
    path = write_table(
        pd.DataFrame(rows, columns=PISP_OUTPUT_INVENTORY_COLS), SCRIPT_STEM, "pisp_output_inventory"
    )
    print(f"Saved table: {path}")


def write_generator_details_table(rows):
    path = write_table(
        pd.DataFrame(rows, columns=GENERATOR_DETAILS_COLS), SCRIPT_STEM, "generator_solar_wind_details"
    )
    print(f"Saved table: {path}")


def write_generator_temp_columns_table(row):
    path = write_table(
        pd.DataFrame([row], columns=GENERATOR_TEMP_COLS_COLS), SCRIPT_STEM, "generator_temperature_columns"
    )
    print(f"Saved table: {path}")


def write_climate_zone_summary_table(rows):
    path = write_table(
        pd.DataFrame(rows, columns=CLIMATE_ZONE_SUMMARY_COLS), SCRIPT_STEM, "climate_zone_summer_cf_summary"
    )
    print(f"Saved table: {path}")


# ====== 1. Examine ISP Assumptions Workbook ======
workbook_path = DOWNLOADS / "2024-isp-inputs-and-assumptions-workbook.xlsx"
print(f"Workbook exists: {workbook_path.exists()}")

sheet_inventory_rows = []
relevant_sheet_shape_rows = []
rooftop_sheet_rows = []
reliability_sheet_shape_rows = []

if workbook_path.exists():
    xls = pd.ExcelFile(workbook_path)
    print(f"\n=== ISP Assumptions Workbook Sheets ({len(xls.sheet_names)}) ===")
    for i, name in enumerate(xls.sheet_names):
        print(f"  {i+1:2d}. {name}")

    # Search for temperature-related sheets
    temp_keywords = ['temp', 'heat', 'thermal', 'derate', 'pv', 'solar', 'wind', 'rooftop', 'inverter']
    print("\n=== Potentially Relevant Sheets ===")
    for name in xls.sheet_names:
        name_lower = name.lower()
        if any(kw in name_lower for kw in temp_keywords):
            print(f"  - {name}")

    for i, name in enumerate(xls.sheet_names):
        name_lower = name.lower()
        sheet_inventory_rows.append({
            "sheet_index": i + 1,
            "sheet_name": name,
            "is_keyword_match": 1 if any(kw in name_lower for kw in temp_keywords) else 0,
            "is_rooftop_match": 1 if ('rooftop' in name_lower or 'rtpv' in name_lower) else 0,
            "is_reliability_match": 1 if ('reliability' in name_lower or 'outage' in name_lower or 'generator' in name_lower) else 0,
        })

    # Read key sheets
    relevant_sheets = [s for s in xls.sheet_names if any(kw in s.lower() for kw in temp_keywords)]

    for sheet in relevant_sheets[:10]:  # Limit to first 10
        try:
            df = pd.read_excel(xls, sheet_name=sheet, header=None)
            print(f"\n--- Sheet: {sheet} (shape: {df.shape}) ---")
            print(df.head(20).to_string())
            relevant_sheet_shape_rows.append({
                "sheet_name": sheet, "n_rows": df.shape[0], "n_cols": df.shape[1], "read_ok": 1,
            })
        except Exception as e:
            print(f"\n--- Sheet: {sheet} — Error: {e}")
            relevant_sheet_shape_rows.append({
                "sheet_name": sheet, "n_rows": np.nan, "n_cols": np.nan, "read_ok": 0,
            })

    # Specifically look for Rooftop PV sheet
    for sheet in xls.sheet_names:
        if 'rooftop' in sheet.lower() or 'rtpv' in sheet.lower():
            try:
                df = pd.read_excel(xls, sheet_name=sheet)
                print(f"\n=== Rooftop PV Sheet ({sheet}) ===")
                print(f"Columns: {list(df.columns)}")
                print(df.head(10).to_string())
                rooftop_sheet_rows.append({
                    "sheet_name": sheet,
                    "n_rows": df.shape[0],
                    "n_cols": df.shape[1],
                    "columns_preview": "|".join(map(str, list(df.columns)[:5])),
                })
            except Exception as e:
                print(f"\n=== Rooftop PV Sheet ({sheet}) — Error: {e}")

    # Generator Reliability Settings
    for sheet in xls.sheet_names:
        if 'reliability' in sheet.lower() or 'outage' in sheet.lower() or 'generator' in sheet.lower():
            try:
                df = pd.read_excel(xls, sheet_name=sheet, header=None)
                print(f"\n=== Reliability Sheet: {sheet} (shape: {df.shape}) ===")
                print(df.head(30).to_string())
                reliability_sheet_shape_rows.append({
                    "sheet_name": sheet, "n_rows": df.shape[0], "n_cols": df.shape[1],
                })
            except Exception as e:
                pass

write_sheet_inventory_table(sheet_inventory_rows)
write_relevant_sheet_shapes_table(relevant_sheet_shape_rows)
write_rooftop_sheet_table(rooftop_sheet_rows)
write_reliability_sheet_shapes_table(reliability_sheet_shape_rows)

# ====== 2. Examine PISP Output Generator Table ======
gen_csv = Path("data/2024/pisp-datasets/out-ref4006-poe10/csv/Bus.csv")
csv_dir = Path("data/2024/pisp-datasets/out-ref4006-poe10/csv/")
sched_dir = Path("data/2024/pisp-datasets/out-ref4006-poe10/")

print(f"\n=== PISP Output Files ===")
pisp_output_rows = []
if csv_dir.exists():
    for f in sorted(csv_dir.glob("*.csv")):
        print(f"  CSV: {f.name}")
        pisp_output_rows.append({"kind": "csv", "name": f.name})

for d in sorted(sched_dir.glob("schedule-*")):
    print(f"  Schedule: {d.name}")
    pisp_output_rows.append({"kind": "schedule", "name": d.name})

write_pisp_output_inventory_table(pisp_output_rows)

# Read Generator table
gen_path = csv_dir / "Generator.csv"
generator_details_rows = []
generator_temp_columns_row = {
    "generator_table_exists": 0, "total_columns": np.nan, "n_temp_columns": np.nan, "temp_columns_list": "",
}
if gen_path.exists():
    gen_df = pd.read_csv(gen_path)
    print(f"\n=== Generator Table (shape: {gen_df.shape}) ===")
    print(f"Columns: {list(gen_df.columns)}")

    # Solar and wind generators
    solar_gens = gen_df[gen_df['tech'].str.contains('PV|SOLAR|DISTPV', case=False, na=False)]
    wind_gens = gen_df[gen_df['tech'].str.contains('WIND', case=False, na=False)]

    print(f"\nSolar generators: {len(solar_gens)}")
    if len(solar_gens) > 0:
        print(solar_gens[['tech', 'forate', 'derate', 'pmin', 'pmax', 'n']].head(10).to_string())

    print(f"\nWind generators: {len(wind_gens)}")
    if len(wind_gens) > 0:
        print(wind_gens[['tech', 'forate', 'derate', 'pmin', 'pmax', 'n']].head(10).to_string())

    for category, subset in (("solar", solar_gens), ("wind", wind_gens)):
        for _, row in subset.iterrows():
            generator_details_rows.append({
                "category": category,
                "id_gen": row["id_gen"],
                "name": row["name"],
                "tech": row["tech"],
                "forate": row["forate"],
                "derate": row["derate"],
                "pmin": row["pmin"],
                "pmax": row["pmax"],
                "n": row["n"],
            })

    # Check for any temperature-related columns
    temp_cols = [c for c in gen_df.columns if any(kw in c.lower() for kw in ['temp', 'heat', 'thermal'])]
    print(f"\nTemperature-related columns in Generator: {temp_cols}")
    generator_temp_columns_row = {
        "generator_table_exists": 1,
        "total_columns": len(gen_df.columns),
        "n_temp_columns": len(temp_cols),
        "temp_columns_list": "|".join(temp_cols),
    }

write_generator_details_table(generator_details_rows)
write_generator_temp_columns_table(generator_temp_columns_row)

# ====== 3. Analyze solar trace for temperature derating signatures ======
# If temperature derating were modeled, we'd expect:
# - Lower CF on hottest days (even with good irradiance)
# - Midday "notching" during extreme heat
# - Geographic correlation (hotter regions show more derating)

# Load solar traces from multiple locations with different climates
CLIMATE_ZONES = {
    'Hot_Inland': 'Bomen_SAT',           # NSW inland, hot
    'Hot_SA': 'Cultana_SAT',            # SA, very hot
    'Moderate_VIC': 'Bannerton_SAT',     # VIC, moderate
    'Cool_TAS': 'Derby_SAT',            # TAS, cool
}

print("\n=== Solar CF by Climate Zone (Summer 2019) ===")
climate_zone_summary_rows = []
for zone, loc in CLIMATE_ZONES.items():
    f = TRACES / "solar_2019" / f"{loc}_RefYear2019.csv"
    if f.exists():
        df = pd.read_csv(f)
        summer = df[df['Month'].isin([12, 1, 2])]
        if len(summer) > 0:
            daily = summer[HH_COLS_SOL].mean(axis=1)
            midday = summer[[str(i) for i in range(24, 36)]].mean(axis=1)
            print(f"  {zone} ({loc}): mean_daily={daily.mean():.3f}, "
                  f"mean_midday={midday.mean():.3f}, "
                  f"min_midday={midday.min():.3f}, "
                  f"p5_midday={midday.quantile(0.05):.3f}")
            climate_zone_summary_rows.append({
                "zone": zone,
                "location": loc,
                "n_summer_days": len(summer),
                "mean_daily_cf": daily.mean(),
                "mean_midday_cf": midday.mean(),
                "min_midday_cf": midday.min(),
                "p5_midday_cf": midday.quantile(0.05),
            })

write_climate_zone_summary_table(climate_zone_summary_rows)

# ====== Figure: CF distribution by climate zone ======
fig, ax = plt.subplots(figsize=(10, 6))

for zone, loc in CLIMATE_ZONES.items():
    f = TRACES / "solar_2019" / f"{loc}_RefYear2019.csv"
    if f.exists():
        df = pd.read_csv(f)
        summer = df[df['Month'].isin([12, 1, 2])]
        if len(summer) > 0:
            daily = summer[HH_COLS_SOL].mean(axis=1)
            ax.hist(daily.values, bins=50, alpha=0.5, label=f'{zone} ({loc})', density=True)

ax.set_title("Summer 2019 — Daily Solar CF Distribution by Climate Zone")
ax.set_xlabel("Daily Mean Capacity Factor")
ax.set_ylabel("Density")
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(FIGURES / "05_cf_by_climate_zone.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 05_cf_by_climate_zone.png")

# ====== Figure: Midday CF vs daily mean (scatter) ======
# If temperature derating exists, we'd see a "ceiling" effect at high CF
fig2, axes2 = plt.subplots(2, 2, figsize=(14, 10))

for ax, (zone, loc) in zip(axes2.flat, CLIMATE_ZONES.items()):
    f = TRACES / "solar_2019" / f"{loc}_RefYear2019.csv"
    if f.exists():
        df = pd.read_csv(f)
        summer = df[df['Month'].isin([12, 1, 2])]
        if len(summer) > 0:
            daily = summer[HH_COLS_SOL].mean(axis=1)
            midday = summer[[str(i) for i in range(24, 36)]].mean(axis=1)
            ax.scatter(daily, midday, s=5, alpha=0.3, color='darkorange')
            ax.plot([0, 0.5], [0, 0.5], 'k--', alpha=0.3, label='1:1')
            ax.set_title(f"{zone} ({loc})")
            ax.set_xlabel("Daily Mean CF")
            ax.set_ylabel("Midday Mean CF")
            ax.set_xlim(0, 0.5)
            ax.set_ylim(0, 0.8)
            ax.grid(True, alpha=0.3)
            ax.legend(fontsize=7)

fig2.suptitle("Summer 2019 — Midday vs Daily Mean Solar CF (Temperature Derating Check)")
plt.tight_layout()
plt.savefig(FIGURES / "05_midday_vs_daily_scatter.png", dpi=120, bbox_inches='tight')
plt.close()
print(f"Saved: 05_midday_vs_daily_scatter.png")

# ====== Summary ======
print("\n=== TEMPERATURE ANALYSIS SUMMARY ===")
print("""
Key findings:
1. ISP Assumptions Workbook contains NO temperature-dependent PV/wind parameters
2. Generator table has NO temperature columns — only reliability-based derate (forced outages)
3. Solar CF varies by climate zone but shows no clear temperature derating signature
4. The CF values in traces are from AEMO's PLEXOS model, which uses irradiance/wind speed
   but does NOT appear to model inverter thermal shutdown or turbine thermal limits
5. Rooftop PV inverter derating at >50°C is NOT captured in the ISP data
""")

print("Done.")
