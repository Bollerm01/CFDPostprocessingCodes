#!/usr/bin/env python3

import re
from pathlib import Path
import pandas as pd
import numpy as np


# ---------------------------------------------------------------------
# INPUT
# ---------------------------------------------------------------------
dat_folder = Path(input("Enter DAT folder path: ").strip()).resolve()

if not dat_folder.is_dir():
    raise RuntimeError(f"Folder does not exist: {dat_folder}")


output_root = dat_folder / "combined_csvs"
output_root.mkdir(exist_ok=True)

# ---------------------------------------------------------------------
# SETTINGS
# ---------------------------------------------------------------------
VALID_PLANES = ["mid", "zWp25", "zWp75"]
IGNORE_VARIABLES = {"coords"}

pattern = re.compile(
    r"^(?P<location>.+?)_(?P<plane>mid|zWp25|zWp75)\.(?P<variable>[^.]+)\.dat$",
    re.IGNORECASE,
)

# ---------------------------------------------------------------------
# INDEX FILES BY LOCATION
# ---------------------------------------------------------------------
files_by_location = {}

for file in sorted(dat_folder.glob("*.dat")):

    m = pattern.match(file.name)
    if not m:
        continue

    location = m.group("location")
    plane = m.group("plane")
    variable = m.group("variable")

    if variable.lower() in IGNORE_VARIABLES:
        continue

    files_by_location.setdefault(location, []).append((file, plane, variable))


# ---------------------------------------------------------------------
# PROCESS ONE LOCATION AT A TIME (STREAMING)
# ---------------------------------------------------------------------
for location, items in files_by_location.items():

    print(f"\nProcessing LOCATION: {location}")

    plane_store = {}

    # -------------------------------------------------------------
    # Load all planes for this location only
    # -------------------------------------------------------------
    for file, plane, variable in items:

        print(f"  Reading {file.name}")

        df = pd.read_csv(file, sep=r"\s+", engine="python")
        df.columns = [c.lstrip("#").strip() for c in df.columns]

        time_col = next((c for c in df.columns if c.lower() == "time"), None)
        if time_col is None:
            continue

        df[time_col] = pd.to_numeric(df[time_col], errors="coerce")
        df = df.dropna(subset=[time_col])

        # enforce unique time 
        df = df.groupby(time_col, as_index=False).mean()

        rename_map = {}
        for col in df.columns:
            m2 = re.match(r"probe(\d+)", col, re.IGNORECASE)
            if m2:
                rename_map[col] = f"{int(m2.group(1)):03d}_{variable}"

        df = df.rename(columns=rename_map)

        keep_cols = [time_col] + list(rename_map.values())
        df = df[keep_cols]

        plane_store.setdefault(plane, []).append(df)

    # -------------------------------------------------------------
    # Process each plane independently
    # -------------------------------------------------------------
    for plane, dfs in plane_store.items():

        print(f"  Combining plane: {plane}")

        # master time from first dataset
        master_time = np.sort(dfs[0].iloc[:, 0].values)

        aligned = []

        for df in dfs:

            time_col = df.columns[0]

            df = df.sort_values(time_col)

            t = df[time_col].values

            df_interp = pd.DataFrame()
            df_interp["time"] = master_time

            for col in df.columns[1:]:
                df_interp[col] = np.interp(master_time, t, df[col].values)

            aligned.append(df_interp.set_index("time"))

        combined = pd.concat(aligned, axis=1).reset_index()

        # reorder columns
        cols = combined.columns.tolist()
        combined = combined[[cols[0]] + sorted(cols[1:])]

        # ---------------------------------------------------------
        # WRITE OUTPUT
        # ---------------------------------------------------------
        out_dir = output_root / plane
        out_dir.mkdir(exist_ok=True)

        out_file = out_dir / f"{location}.csv"
        combined.to_csv(out_file, index=False)

        print(f"  Saved: {out_file}")

        # free memory explicitly
        del aligned
        del combined

    # clear per-location memory
    del plane_store

print("\nDone.")