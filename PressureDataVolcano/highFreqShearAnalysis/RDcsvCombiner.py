#!/usr/bin/env python3

import re
from pathlib import Path
import pandas as pd


# ---------------------------------------------------------------------
# USER INPUT
# ---------------------------------------------------------------------
dat_folder = Path(input("Enter DAT folder path: ").strip()).resolve()

if not dat_folder.is_dir():
    raise RuntimeError(f"Folder does not exist: {dat_folder}")

# Output structure:
# combined_csvs/<plane>/<location>.csv
output_root = dat_folder / "combined_csvs"
output_root.mkdir(exist_ok=True)

# ---------------------------------------------------------------------
# SETTINGS
# ---------------------------------------------------------------------
VALID_PLANES = {"mid", "zWp25", "zWp75"}
IGNORE_VARIABLES = {"coords"}

pattern = re.compile(
    r"^(?P<location>.+?)_(?P<plane>mid|zWp25|zWp75)\.(?P<variable>[^.]+)\.dat$",
    re.IGNORECASE,
)

# Store lists of DataFrames (FAST APPROACH)
data_store = {}  # key = (location, plane)

# ---------------------------------------------------------------------
# READ FILES
# ---------------------------------------------------------------------
files = sorted(dat_folder.glob("*.dat"))

for file in files:

    match = pattern.match(file.name)
    if not match:
        continue

    location = match.group("location")
    plane = match.group("plane")
    variable = match.group("variable")

    if variable.lower() in IGNORE_VARIABLES:
        continue

    print(f"Reading {file.name}")

    try:
        df = pd.read_csv(
            file,
            sep=r"\s+",
            engine="python"
        )

        # Fix header like "# time"
        df.columns = [c.lstrip("#").strip() for c in df.columns]

    except Exception as e:
        print(f"Skipping {file.name}: {e}")
        continue

    # Identify time column
    time_col = next((c for c in df.columns if c.lower() == "time"), None)

    if time_col is None:
        print(f"No time column in {file.name}, skipping.")
        continue

    # Rename probe columns
    rename_map = {}

    for col in df.columns:
        m = re.match(r"probe(\d+)", col, re.IGNORECASE)
        if m:
            probe_num = int(m.group(1))
            rename_map[col] = f"{probe_num:03d}_{variable}"

    df = df.rename(columns=rename_map)

    # Keep only time + probes
    keep_cols = [time_col] + list(rename_map.values())
    df = df[keep_cols]

    # IMPORTANT: set index for fast alignment
    df = df.set_index(time_col)

    key = (location, plane)

    data_store.setdefault(key, []).append(df)

# ---------------------------------------------------------------------
# COMBINE + WRITE OUTPUT
# ---------------------------------------------------------------------
for (location, plane), df_list in data_store.items():

    print(f"Combining {location} | {plane}")

    # FAST CONCAT (no repeated merges)
    combined = pd.concat(df_list, axis=1, join="outer")

    # Restore time column
    combined = combined.reset_index()

    # Clean column ordering (time first)
    time_col = combined.columns[0]
    other_cols = sorted([c for c in combined.columns if c != time_col])

    combined = combined[[time_col] + other_cols]

    # Output folder per plane
    plane_folder = output_root / plane
    plane_folder.mkdir(exist_ok=True)

    output_file = plane_folder / f"{location}.csv"

    combined.to_csv(output_file, index=False)

    print(f"Saved {output_file}")

print("\nDone.")