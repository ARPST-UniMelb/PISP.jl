"""
eda/01_data_loading.py
Load and inspect AEMO ISP solar/wind trace data structure.
"""
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# ---- Paths ----
TRACES = Path("data/pisp-downloads/Traces")
FIGURES = Path("eda/figures")
FIGURES.mkdir(parents=True, exist_ok=True)

# ---- Load a single solar trace as example ----
sol_file = TRACES / "solar_4006" / "Bannerton_SAT_RefYear4006.csv"
df_sol = pd.read_csv(sol_file)
print("=== SOLAR TRACE EXAMPLE ===")
print(f"File: {sol_file}")
print(f"Shape: {df_sol.shape}")
print(f"Columns: {list(df_sol.columns[:10])}...")
print(f"Date range: {df_sol.iloc[0, :3].to_dict()} to {df_sol.iloc[-1, :3].to_dict()}")
print(f"Value range: [{df_sol.iloc[:, 3:].min().min():.4f}, {df_sol.iloc[:, 3:].max().max():.4f}]")

# Check for zero values in middle of day (potential derating signal)
midday_cols = [str(i) for i in range(24, 36)]  # hours 12-18, highest solar
daily_max = df_sol[midday_cols].max(axis=1)
n_low = (daily_max < 0.1).sum()
n_total = len(df_sol)
print(f"Days with midday max < 0.1: {n_low}/{n_total} ({100*n_low/n_total:.1f}%)")

# ---- Load a single wind trace ----
wind_file = TRACES / "wind_4006" / "ARWF1_RefYear4006.csv"
df_wind = pd.read_csv(wind_file)
print("\n=== WIND TRACE EXAMPLE ===")
print(f"File: {wind_file}")
print(f"Shape: {df_wind.shape}")
print(f"Date range: {df_wind.iloc[0, :3].to_dict()} to {df_wind.iloc[-1, :3].to_dict()}")
wind_cols = [c for c in df_wind.columns[3:]]
print(f"Value range: [{df_wind[wind_cols].min().min():.4f}, {df_wind[wind_cols].max().max():.4f}]")

# ---- Sample a few demand traces ----
demand_dir = TRACES / "demand_VIC_Step Change"
dem_files = sorted(demand_dir.glob("*_PV_TOT.csv"))
if dem_files:
    df_dem = pd.read_csv(dem_files[0])
    print("\n=== DEMAND TRACE EXAMPLE ===")
    print(f"File: {dem_files[0].name}")
    print(f"Shape: {df_dem.shape}")
    print(f"Columns: {list(df_dem.columns)}")
    print(f"Head:\n{df_dem.head(3)}")

# ---- Build date column ----
def add_date_column(df):
    """Add datetime column to trace dataframe."""
    df['datetime'] = pd.to_datetime(
        df['Year'].astype(str) + '-' + 
        df['Month'].astype(str).str.zfill(2) + '-' + 
        df['Day'].astype(str).str.zfill(2)
    )
    return df

df_sol = add_date_column(df_sol)
df_wind = add_date_column(df_wind)

# ---- Plot example traces ----
fig, axes = plt.subplots(2, 1, figsize=(14, 8))

# Solar - first 30 days
sol_sub = df_sol.iloc[:30]
sol_hourly = sol_sub.iloc[:, 3:51].mean(axis=1)
axes[0].plot(sol_sub['datetime'], sol_hourly, 'orange', linewidth=0.8)
axes[0].set_title(f"Solar 4006 — Bannerton_SAT (first 30 days)")
axes[0].set_ylabel("Mean half-hourly CF")

# Wind - first 30 days
wind_sub = df_wind.iloc[:30]
wind_hourly = wind_sub.iloc[:, 3:51].mean(axis=1)
axes[1].plot(wind_sub['datetime'], wind_hourly, 'steelblue', linewidth=0.8)
axes[1].set_title(f"Wind 4006 — ARWF1 (first 30 days)")
axes[1].set_ylabel("Mean half-hourly CF")

plt.tight_layout()
plt.savefig(FIGURES / "01_sample_traces.png", dpi=120)
plt.close()
print(f"\nSaved: {FIGURES / '01_sample_traces.png'}")

# ---- Summary stats ----
print("\n=== SUMMARY ===")
# Count locations
n_solar = len(list((TRACES / "solar_4006").glob("*.csv")))
n_wind = len(list((TRACES / "wind_4006").glob("*.csv")))
print(f"Solar locations in 4006: {n_solar}")
print(f"Wind locations in 4006: {n_wind}")

# Check available years for a specific solar location
for yr in [2011, 2015, 2019, 2023]:
    test_file = TRACES / f"solar_{yr}" / "Bannerton_SAT_RefYear{yr}.csv"
    print(f"Solar {yr} exists: {test_file.exists()}", end="")
    if test_file.exists():
        df_check = pd.read_csv(test_file, nrows=1)
        print(f"  (first date: {df_check.iloc[0, :3].to_dict()})")
    else:
        print()

print("\nDone.")
