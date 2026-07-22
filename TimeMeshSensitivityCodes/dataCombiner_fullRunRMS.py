# Script to process a folder of probe CSV files (columns: "#", "time", "XXX_variable")
# For each CSV, computes average and RMS of velocityX for each probe (0-499),
# and matches the probe's Y-coordinate from the hardcoded YAML probe definitions
# (based on filename matching the probe "name" field).
#
# Input:  Folder of .csv files, one per probe-set, named to include the probe
#         group name (e.g. "US_MP", "xL0p03_MP", "DS_MP", etc.)
# Output: One .xlsx file per input CSV, with columns: probe_num, Y, velocityxavg, velocityxrms

import pandas as pd
import numpy as np
import re
import os
from tkinter import Tk, filedialog

# ---------------------------------------------------------------
# Probe definitions (from YAML config)
# Edit/extend this dict if probe layout changes.
# ---------------------------------------------------------------
PROBE_DEFINITIONS = {
    "US_MP":     {"start": [2.0801,     0.018593, 0.0], "end": [2.0801,     0.055779, 0.0], "n": 500},
    "xL0p03_MP": {"start": [2.15058,    0.0,      0.0], "end": [2.15058,    0.037186, 0.0], "n": 500},
    "xL0p17_MP": {"start": [2.16016,    0.0,      0.0], "end": [2.16016,    0.037186, 0.0], "n": 500},
    "xL0p3_MP":  {"start": [2.169052,   0.0,      0.0], "end": [2.169052,   0.037186, 0.0], "n": 500},
    "xL0p45_MP": {"start": [2.1793151,  0.0,      0.0], "end": [2.1793151,  0.037186, 0.0], "n": 500},
    "xL0p59_MP": {"start": [2.18889362, 0.0,      0.0], "end": [2.18889362, 0.037186, 0.0], "n": 500},
    "xL0p73_MP": {"start": [2.198472,   0.001645, 0.0], "end": [2.198472,   0.038831, 0.0], "n": 500},
    "xL0p86_MP": {"start": [2.20736648, 0.005329, 0.0], "end": [2.20736648, 0.042515, 0.0], "n": 500},
    "xL1_MP":    {"start": [2.216945,   0.009296, 0.0], "end": [2.216945,   0.046527, 0.0], "n": 500},
    "xL1p2_MP":  {"start": [2.2306286,  0.014965, 0.0], "end": [2.2306286,  0.052151, 0.0], "n": 500},
    "DS_MP":     {"start": [2.3078,     0.018593, 0.0], "end": [2.3078,     0.055779, 0.0], "n": 500},
}

# ---------------------------------------------------------------
# Utility: find which probe definition a filename corresponds to
# ---------------------------------------------------------------
def match_probe_definition(filename):
    base = os.path.splitext(os.path.basename(filename))[0]
    matches = [name for name in PROBE_DEFINITIONS if name in base]
    if not matches:
        return None
    # If multiple names could match (e.g. "xL1_MP" is a substring of "xL1p2_MP"),
    # prefer the longest (most specific) match.
    return max(matches, key=len)

# ---------------------------------------------------------------
# Utility: extract probe number from column names like "12_velocityX"
# ---------------------------------------------------------------
def extract_probe_number(col_name):
    match = re.match(r"(\d+)_", str(col_name))
    return int(match.group(1)) if match else None

# ---------------------------------------------------------------
# GUI: Get root directory
# ---------------------------------------------------------------
Tk().withdraw()
root_dir = filedialog.askdirectory(
    title="Select the folder containing probe CSV files"
)

if not root_dir:
    raise SystemExit("No directory selected. Exiting.")

csv_files = [
    os.path.join(root_dir, f)
    for f in os.listdir(root_dir)
    if f.lower().endswith(".csv")
]

if not csv_files:
    raise SystemExit("No CSV files found in the selected directory.")

print(f"Found {len(csv_files)} CSV files.")

# ---------------------------------------------------------------
# Process each CSV file
# ---------------------------------------------------------------
for fpath in csv_files:
    filename = os.path.basename(fpath)
    print(f"\nProcessing: {filename}")

    df = pd.read_csv(fpath)
    df.columns = [c.strip() for c in df.columns]

    # Find all "XXX_velocityX" columns (case-insensitive, exact variable match
    # so e.g. "12_velocityMag" doesn't get picked up)
    velx_cols = [
        c for c in df.columns
        if re.match(r"^\d+_velocityx$", c, flags=re.IGNORECASE)
    ]

    if not velx_cols:
        print(f"  No velocityX columns found in {filename}, skipping.")
        continue

    # -------------------------------------------------------
    # Compute avg + RMS of velocityX per probe
    # -------------------------------------------------------
    records = []
    for col in velx_cols:
        probe_num = extract_probe_number(col)
        series = df[col].dropna()
        avg_val = series.mean()
        rms_val = (series ** 2).mean() ** 0.5
        records.append({
            "probe_num": probe_num,
            "velocityxavg": avg_val,
            "velocityxrms": rms_val,
        })

    result = pd.DataFrame(records).set_index("probe_num").sort_index()

    # -------------------------------------------------------
    # Match Y-values from YAML probe definitions (by filename)
    # -------------------------------------------------------
    probe_name = match_probe_definition(filename)
    if probe_name is not None:
        defn = PROBE_DEFINITIONS[probe_name]
        y_start = defn["start"][1]
        y_end = defn["end"][1]
        n_points = defn["n"]
        y_values = np.linspace(y_start, y_end, n_points)

        y_series = pd.Series(y_values, index=range(n_points), name="Y")
        result = result.join(y_series, how="left")
        result = result[["Y", "velocityxavg", "velocityxrms"]]
        print(f"  Matched probe definition: {probe_name}")
    else:
        print(f"  WARNING: No matching probe definition found for '{filename}'. "
              f"Y column omitted -- check that the filename contains a probe group "
              f"name (e.g. 'US_MP', 'xL0p03_MP', etc.)")

    # -------------------------------------------------------
    # Save output
    # -------------------------------------------------------
    base_name = os.path.splitext(filename)[0]
    output_file = os.path.join(root_dir, f"{base_name}_velocityxStats.xlsx")
    result.to_excel(output_file, index_label="probe_num")

    print(f"  -> Saved: {output_file}")

print("\n------------------------------------------")
print("All CSV files processed successfully.")
print("------------------------------------------")