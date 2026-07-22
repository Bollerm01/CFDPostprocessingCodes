# File to combine all of the extracted .DAT files set up in the Volcano simulation
# Input: Root directory with subdirectories full of .DAT files for each run
# Output: Single .XLSX file for each run with columns for each field of data

import pandas as pd
import re
import os
from tkinter import Tk, filedialog
from collections import defaultdict

# ---------------------------------------------------------------
# Utility: extract probe number from strings like "probe00000"
# ---------------------------------------------------------------
def extract_probe_number(name):
    match = re.search(r'probe0*(\d+)', str(name))
    return int(match.group(1)) if match else None

# ---------------------------------------------------------------
# GUI: Get root directory
# ---------------------------------------------------------------
Tk().withdraw()
root_dir = filedialog.askdirectory(
    title="Select the root directory containing all data sets"
)

if not root_dir:
    raise SystemExit("No root directory selected. Exiting.")

# ---------------------------------------------------------------
# Auto-detect files in directory
# ---------------------------------------------------------------
all_dat_files = [
    os.path.join(root_dir, f)
    for f in os.listdir(root_dir)
    if f.lower().endswith(".dat")
]

coords_files = [
    f for f in all_dat_files
    if re.match(r".+\.coords\.dat$", os.path.basename(f))
]

data_files = [f for f in all_dat_files if f not in coords_files]

if not coords_files:
    raise SystemExit("No coords files found. Ensure files match pattern XX.coords.dat.")

if not data_files:
    raise SystemExit("No probe data files found.")

print(f"Found {len(coords_files)} coords files.")
print(f"Found {len(data_files)} data files.")

# ---------------------------------------------------------------
# Group files by prefix
# ---------------------------------------------------------------
def get_prefix(filename):
    return os.path.basename(filename).split(".")[0]

coords_groups = defaultdict(list)
for f in coords_files:
    coords_groups[get_prefix(f)].append(f)

data_groups = defaultdict(list)
for f in data_files:
    data_groups[get_prefix(f)].append(f)

# ---------------------------------------------------------------
# Process each prefix group
# ---------------------------------------------------------------
for prefix in coords_groups.keys():

    print(f"\nProcessing prefix group: {prefix}")

    coords_path = coords_groups[prefix][0]

    coords = pd.read_csv(
        coords_path,
        sep=r"\s+",
        comment="#",
        header=None,
        usecols=[0,1,2,3],
        names=["probe_num","x","y","z"]
    )

    coords.set_index("probe_num", inplace=True)

    # -----------------------------------------------------------
    # Process every variable
    # -----------------------------------------------------------
    for fpath in data_groups.get(prefix, []):

        filename = os.path.basename(fpath)

        parts = filename.split(".")
        variable_name = parts[1] if len(parts) > 2 else filename

        # Read header
        with open(fpath, "r") as f:
            header_line = f.readline().strip()

        header_cols = header_line.lstrip("#").split()

        # Read data
        df = pd.read_csv(
            fpath,
            sep=r"\s+",
            comment="#",
            header=None,
            skiprows=1
        )

        df.columns = header_cols

        # -------------------------------------------------------
        # LAST TIMESTEP VALUES
        # -------------------------------------------------------
        last_row = df.iloc[-1,1:]

        probe_nums = [
            extract_probe_number(col)
            for col in last_row.index
        ]

        coords[variable_name] = pd.Series(
            last_row.values,
            index=probe_nums
        )

        # -------------------------------------------------------
        # Compute velocity statistics
        # -------------------------------------------------------
        if variable_name.lower() == "velocityx":

            # Remove time column
            probe_data = df.iloc[:, 1:]

            # Mean velocity (time-average at each probe)
            velocity_avg = probe_data.mean(axis=0)

            # Fluctuating velocity: v' = v - v_avg (row-wise subtraction
            # broadcasts the per-probe mean across every timestep)
            velocity_fluct = probe_data.sub(velocity_avg, axis=1)

            # RMS of the fluctuating velocity: sqrt(mean(v'^2))
            velocity_rms = (velocity_fluct**2).mean(axis=0)**0.5

            probe_nums = [
                extract_probe_number(col)
                for col in probe_data.columns
            ]

            coords["velocityxavg"] = pd.Series(
                velocity_avg.values,
                index=probe_nums
            )

            coords["velocityxrms"] = pd.Series(
                velocity_rms.values,
                index=probe_nums
            )
    # -----------------------------------------------------------
    # Rename x,y,z -> X,Y,Z
    # -----------------------------------------------------------
    df.rename(columns={'x': 'X', 'y': 'Y', 'z': 'Z'}, inplace=True)

    # -----------------------------------------------------------
    # Sort probes
    # -----------------------------------------------------------
    coords.sort_index(inplace=True)

    # -----------------------------------------------------------
    # Save Excel
    # -----------------------------------------------------------
    output_file = os.path.join(
        root_dir,
        f"{prefix}_dataCombined_{prefix}.xlsx"
    )

    coords.to_excel(output_file)

    print(f" -> Saved: {output_file}")

print("\n------------------------------------------")
print("All prefix groups processed successfully.")
print("------------------------------------------")