# File to combine all of the extracted .DAT files set up in the Volcano simulation for the full cavity profiles (validation data)
# Input: Root directory with subdirectories full of .DAT files for each run 
# Output: Single .XSLX file for each run with columns for each field of data. This will also combine a full runs worth of profiles in 1 workbook with multiple sheets

import pandas as pd
import re
import os
from tkinter import Tk, filedialog
from collections import defaultdict

# ---------------------------------------------------------------
# Normalization constants
# ---------------------------------------------------------------
Y_REFERENCE = 0.018593   # Y-location of zero point
Y_DEPTH = 0.018593       # Normalization depth (must be non-zero)
V_REF = 694.0            # Reference velocity for normalization (set as needed)

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
root_dir = filedialog.askdirectory(title="Select the root directory containing all data sets")

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

# Coords files match pattern: XX.coords.dat
coords_files = [f for f in all_dat_files if re.match(r".+\.coords\.dat$", os.path.basename(f))]

# Only keep data files that have _MP, _z25, or _z75 in the filename
allowed_markers = ["_MP", "_z25", "_z75"]
data_files = [
    f for f in all_dat_files
    if f not in coords_files
    and any(marker in os.path.basename(f) for marker in allowed_markers)
]

if not coords_files:
    raise SystemExit("No coords files found. Ensure files match pattern XX.coords.dat.")

if not data_files:
    raise SystemExit("No probe data files found matching _MP, _z25, or _z75.")

print(f"Found {len(coords_files)} coords files.")
print(f"Found {len(data_files)} data files (filtered by _MP, _z25, _z75).")

# ---------------------------------------------------------------
# Group files by leading prefix before first '.' 
# (Example: US.coords.dat → 'US')
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
# Output Excel filename (single workbook for all prefixes)
# ---------------------------------------------------------------
# Get just the parent folder name from root_dir
parent_folder = os.path.basename(os.path.normpath(root_dir))

# Save in root_dir, but filename is based on the parent folder name
output_file = os.path.join(root_dir, f"{parent_folder}_combinedFullProfiles.xlsx")

# ---------------------------------------------------------------
# Process each prefix group and write each to its own sheet
# ---------------------------------------------------------------
with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
    for prefix in coords_groups.keys():
        print(f"\nProcessing prefix group: {prefix}")

        # Expect exactly one coords file per group
        coords_path = coords_groups[prefix][0]

        # Load coords file
        coords = pd.read_csv(
            coords_path,
            sep=r"\s+",
            comment="#",
            header=None,
            usecols=[0, 1, 2, 3],
            names=["probe_num", "x", "y", "z"]
        )
        coords.set_index("probe_num", inplace=True)

        # --- Normalize Y-coordinate (based on coords 'y' column) ---
        if "y" in coords.columns and Y_DEPTH != 0:
            coords["Y_norm"] = (coords["y"] - Y_REFERENCE) / Y_DEPTH
        else:
            coords["Y_norm"] = pd.NA

        # Process all filtered data files for this prefix
        for fpath in data_groups.get(prefix, []):
            filename = os.path.basename(fpath)

            # Extract variable name from filename like: US.machavg.dat -> machavg
            parts = filename.split(".")
            variable_name = parts[1] if len(parts) > 2 else filename

            # Load entire file (no header)
            df = pd.read_csv(fpath, sep=r"\s+", comment="#", header=None)

            # The FIRST LINE of the file is actually the header
            with open(fpath, "r") as f:
                header_line = f.readline().strip()

            header_cols = header_line.lstrip("#").split()
            df.columns = header_cols

            # Use last timestep row (skip column 0 = time)
            last_row = df.iloc[-1, 1:]

            # Convert column header "probe00001" → probe number
            probe_nums = [extract_probe_number(col) for col in last_row.index]

            # Write the values into coords
            coords[variable_name] = pd.Series(last_row.values, index=probe_nums)

        # --- Normalize x-velocity (velocityxavg) ---
        if "velocityxavg" in coords.columns and V_REF != 0:
            coords["velocityxavg_norm"] = coords["velocityxavg"] / V_REF
        else:
            coords["velocityxavg_norm"] = pd.NA

        # --- RMS velocity from reynoldsstressxx and density ---
        # velocityRMS = sqrt(reynoldsstressxx / density)
        if "reynoldsstressxx" in coords.columns and "density" in coords.columns:
            # Avoid division by zero: where density is 0, set result to NaN
            with pd.option_context("mode.use_inf_as_na", True):
                coords["velocityxRMS"] = (coords["reynoldsstressxx"] / coords["density"]) ** 0.5
        else:
            coords["velocityxRMS"] = pd.NA

        # Sort by probe number to ensure order
        coords.sort_index(inplace=True)

        # Write to a sheet named after the prefix in the shared workbook
        sheet_name = prefix[:31]  # Excel sheet name limit is 31 chars
        coords.to_excel(writer, sheet_name=sheet_name)
        print(f" -> Written to workbook '{os.path.basename(output_file)}', sheet '{sheet_name}'")

print("\n------------------------------------------")
print(f"All prefix groups processed successfully into {output_file}.")
print("------------------------------------------")