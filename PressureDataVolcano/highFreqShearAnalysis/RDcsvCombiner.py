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

# Key = (location, plane)
combined_data = {}

# ---------------------------------------------------------------------
# READ FILES
# ---------------------------------------------------------------------
for file in sorted(dat_folder.glob("*.dat")):

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
            comment="#",
            engine="python"
        )
    except Exception as e:
        print(f"Skipping {file.name}: {e}")
        continue

    time_col = next(
        (c for c in df.columns if c.lower() == "time"),
        None
    )

    if time_col is None:
        print(f"No time column found in {file.name}")
        continue

    rename_map = {}

    for col in df.columns:

        probe_match = re.match(
            r"probe(\d+)",
            col,
            re.IGNORECASE
        )

        if probe_match:
            probe_num = int(probe_match.group(1))

            rename_map[col] = (
                f"{probe_num:03d}_{variable}"
            )

    df = df.rename(columns=rename_map)

    keep_cols = [time_col] + list(rename_map.values())
    df = df[keep_cols]

    key = (location, plane)

    if key not in combined_data:
        combined_data[key] = df
    else:
        combined_data[key] = pd.merge(
            combined_data[key],
            df,
            on=time_col,
            how="outer"
        )

# ---------------------------------------------------------------------
# WRITE OUTPUTS
# ---------------------------------------------------------------------
for (location, plane), df in combined_data.items():

    plane_folder = output_root / plane
    plane_folder.mkdir(exist_ok=True)

    time_col = next(
        (c for c in df.columns if c.lower() == "time"),
        df.columns[0]
    )

    probe_cols = sorted(
        [c for c in df.columns if c != time_col]
    )

    df = df[[time_col] + probe_cols]

    output_file = plane_folder / f"{location}.csv"

    df.to_csv(output_file, index=False)

    print(f"Saved {output_file}")

print("\nFinished.")