# File to combine all of the extracted .DAT files set up in the Volcano simulation for the full cavity profiles (validation data)
# Input: Root directory with subdirectories full of .DAT files for each run 
# Output: Single .XSLX file for each run with columns for each field of data. This will also combine a full runs worth of profiles in 1 workbook with multiple sheets

import pandas as pd
import re
import os
from tkinter import Tk, filedialog

# ---------------------------------------------------------------
# Normalization constants
# ---------------------------------------------------------------
Y_REFERENCE = 0.018593   # Y-location of zero point
Y_DEPTH     = 0.018593   # Normalization depth (must be non-zero)
V_REF       = 694.0      # Reference velocity for normalization

# ---------------------------------------------------------------
# Utility: extract probe name from column strings like "probe00000"
# ---------------------------------------------------------------
def extract_probe_name(col):
    match = re.search(r'(probe0*\d+)', str(col))
    return match.group(1) if match else None

def extract_probe_number_from_name(probe_name):
    """
    Convert 'probe00003' -> 3 (int), used to match against coords probe_num.
    """
    match = re.search(r'probe0*(\d+)', str(probe_name))
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

# ---------------------------------------------------------------
# Load coords file and compute Y_norm (probe-based normalization)
# ---------------------------------------------------------------
coords_files = [
    f for f in all_dat_files
    if re.match(r".+\.coords\.dat$", os.path.basename(f))
]

coords = None
if coords_files:
    if len(coords_files) > 1:
        print("Warning: multiple coords files found; using the first one.")
    coords_path = coords_files[0]
    print(f"Using coords file for normalization: {os.path.basename(coords_path)}")

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

else:
    print("No coords file found; Y_norm and velocityxavg_norm will be omitted.")
    coords = None

# ---------------------------------------------------------------
# Search for only high-freq markers
# ---------------------------------------------------------------
allowed_markers = ["_mid", "_zWp25", "_zWp75"]

data_files = [
    f for f in all_dat_files
    if any(marker in os.path.basename(f) for marker in allowed_markers)
]

if not data_files:
    raise SystemExit("No probe data files found matching _mid, _zWp25, or _zWp75.")

print(f"Found {len(data_files)} data files (filtered by _mid, _zWp25, _zWp75).")

# ---------------------------------------------------------------
# Helper: read one DAT file into a DataFrame
#   - First line is header (with #)
#   - Remaining lines are data
# ---------------------------------------------------------------
def read_dat_file(path):
    # Read header line manually
    with open(path, "r") as f:
        header_line = f.readline().strip()

    header_cols = header_line.lstrip("#").split()

    df = pd.read_csv(
        path,
        sep=r"\s+",
        comment="#",
        header=None,
        skiprows=1  # we manually consumed header_line
    )
    df.columns = header_cols
    return df

# ---------------------------------------------------------------
# If coords exists, recover velocityxavg from the velocityxavg*.dat
# files (using the last time step), then compute velocityxavg_norm.
# ---------------------------------------------------------------
if coords is not None:
    coords["velocityxavg"] = pd.NA

    for fpath in data_files:
        filename = os.path.basename(fpath)
        parts = filename.split(".")
        # Expected pattern: prefix.variable_name.something.dat
        variable_name = parts[1] if len(parts) > 2 else None

        if variable_name == "velocityxavg":
            print(f"Using {filename} to compute velocityxavg and velocityxavg_norm (last timestep).")
            df_var = read_dat_file(fpath)

            # Last time step row; skip column 0 (time)
            last_row = df_var.iloc[-1, 1:]

            # Columns should be probe00000, probe00001, etc.
            probe_nums = [extract_probe_number_from_name(col) for col in last_row.index]

            # Store into coords["velocityxavg"]
            for pn, val in zip(probe_nums, last_row.values):
                if pn in coords.index:
                    coords.at[pn, "velocityxavg"] = val

    # --- Normalize x-velocity (velocityxavg) ---
    if "velocityxavg" in coords.columns and V_REF != 0:
        coords["velocityxavg_norm"] = coords["velocityxavg"].astype(float) / V_REF
    else:
        coords["velocityxavg_norm"] = pd.NA
else:
    print("No coords; skipping velocityxavg_norm.")

# ---------------------------------------------------------------
# Build one Excel workbook with 5 sheets:
#    probe00000, probe00001,..., probe00004
# For each sheet:
#   - "time" column
#   - one column per DAT file (matching on time)
#   - Y_norm and velocityxavg_norm from coords as extra columns
# ---------------------------------------------------------------
output_file = os.path.join(root_dir, "_combinedHighFreq.xlsx")

# Define the probes we care about
probe_names = [f"probe{str(i).zfill(5)}" for i in range(5)]

with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
    for probe in probe_names:
        print(f"\nBuilding sheet for {probe}")

        probe_df = None  # will hold the merged result for this probe

        for fpath in sorted(data_files):
            filename = os.path.basename(fpath)

            # Use something descriptive from the filename for the column name
            # e.g., "US.velocityxavg_mid.dat" -> "velocityxavg_mid"
            base_name = os.path.splitext(filename)[0]
            parts = base_name.split(".")
            if len(parts) > 2:
                var_name = parts[1]
                suffix = parts[2]
                col_label = f"{var_name}_{suffix}"
            else:
                # Fallback: use base_name if pattern doesn't match
                col_label = base_name

            df = read_dat_file(fpath)

            # Ensure required columns exist
            if "time" not in df.columns or probe not in df.columns:
                print(f"  Skipping {filename}: missing 'time' or '{probe}' column.")
                continue

            # Subset to time + this probe
            df_probe = df[["time", probe]].copy()
            df_probe.rename(columns={probe: col_label}, inplace=True)

            if probe_df is None:
                # First file: establish time base
                probe_df = df_probe
            else:
                # Subsequent files: merge on time
                probe_df = pd.merge(
                    probe_df,
                    df_probe,
                    on="time",
                    how="outer",  # keep all times; use "inner" if only common times
                    sort=True
                )

        if probe_df is None:
            # No usable data for this probe
            print(f"  No data found for {probe}, skipping sheet.")
            continue

        # -------------------------------------------------------
        # Attach normalized columns from coords (Y_norm and velocityxavg_norm)
        # -------------------------------------------------------
        if coords is not None:
            probe_num = extract_probe_number_from_name(probe)
            if probe_num in coords.index:
                y_norm_value = coords.loc[probe_num].get("Y_norm", pd.NA)
                vx_norm_value = coords.loc[probe_num].get("velocityxavg_norm", pd.NA)

                # Add as constant columns (same value for all time rows)
                probe_df["Y_norm"] = y_norm_value
                probe_df["velocityxavg_norm"] = vx_norm_value
            else:
                print(f"  Probe number {probe_num} not found in coords; norms set to NaN.")
                probe_df["Y_norm"] = pd.NA
                probe_df["velocityxavg_norm"] = pd.NA
        else:
            # No coords -> no normalization
            probe_df["Y_norm"] = pd.NA
            probe_df["velocityxavg_norm"] = pd.NA

        # Sort by time just to be tidy
        probe_df.sort_values("time", inplace=True)

        # Write this probe's DataFrame to its own sheet
        sheet_name = probe[:31]  # Excel limit
        probe_df.to_excel(writer, sheet_name=sheet_name, index=False)
        print(f"  -> Written to workbook '{os.path.basename(output_file)}', sheet '{sheet_name}'")

print("\n------------------------------------------")
print(f"All probes processed successfully into {output_file}.")
print("------------------------------------------")