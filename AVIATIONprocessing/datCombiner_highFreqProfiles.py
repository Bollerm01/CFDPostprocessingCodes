# File to combine all of the extracted.DAT files set up in the Volcano simulation
# for the shear layer high freq data, organized by plane, line, and Kulite probes.
#
# Input:
#   Root directory with.DAT files:
#     - Plane data: multiple lines in 3 planes (_mid, _zWp25, _zWp75),
#       each with probes probe00000–probe00004.
#     - Kulite data: files whose names start with k1–k6.
#
# Output:
#   - For each plane (mid, zWp25, zWp75):
#       - One folder per plane under the root directory
#       - Within that folder, one XLSX workbook per line
#         - Each workbook has 5 sheets (probe00000–probe00004)
#         - Each sheet: time history (merged) of all variables (all relevant.DAT files)
#           for that line in that plane.
#   - One Kulite workbook "Kulite_HighFreq.xlsx" in the root directory:
#       - Sheets: k1, k2,..., k6
#       - Each sheet: time history merged from all Kulite files for that probe.

import pandas as pd
import re
import os
from tkinter import Tk, filedialog
from collections import defaultdict

# ---------------------------------------------------------------
# Normalization constants (used only if coords file is present)
# ---------------------------------------------------------------
Y_REFERENCE = 0.018593
Y_DEPTH     = 0.018593
V_REF       = 694.0

# ---------------------------------------------------------------
# Utilities for probes
# ---------------------------------------------------------------
def extract_probe_name(col):
    match = re.search(r'(probe0*\d+)', str(col))
    return match.group(1) if match else None

def extract_probe_number_from_name(probe_name):
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
# Plane / Kulite naming helpers
# ---------------------------------------------------------------
PLANE_MARKERS = {
    "_mid":   "mid",
    "_zWp25": "zWp25",
    "_zWp75": "zWp75",
}

# markers / substrings that must be excluded
BLOCK_MARKERS = [
    "_MP", "_zp25", "_zp75", "_z25", "_z75",
]
BLOCK_SUBSTRINGS = [
    "rampLine", "floorLine",
]

def is_blocked_name(fname: str) -> bool:
    """Return True if this file should be excluded based on blocked markers."""
    name = os.path.basename(fname)
    if any(b in name for b in BLOCK_MARKERS):
        return True
    if any(s in name for s in BLOCK_SUBSTRINGS):
        return True
    return False

def detect_plane_from_name(fname: str):
    """
    Return the allowed plane marker (e.g. '_mid', '_zWp25') if present and not blocked,
    else None.
    """
    name = os.path.basename(fname)
    # Exclude blocked names first
    if is_blocked_name(name):
        return None
    for marker in PLANE_MARKERS.keys():
        if marker in name:
            return marker
    return None

def is_kulite_file(fname: str) -> bool:
    """Kulite: basename starts with k1–k6."""
    base = os.path.basename(fname)
    # Do not treat blocked names as Kulite either (defensive)
    if is_blocked_name(base):
        return False
    return re.match(r'^k[1-6]\.', base) is not None

def get_line_name(fname: str) -> str:
    """
    Line name = substring before first underscore.
    Example: 'xL0p59_zWp25.density.dat' -> 'xL0p59'
    """
    base = os.path.splitext(os.path.basename(fname))[0]
    return base.split("_")[0]

def get_plane_variable_name(fname: str, plane_marker: str) -> str:
    """
    From 'xL0p59_zWp25.density.dat' with plane_marker '_zWp25'
    -> 'density'
    """
    base = os.path.splitext(os.path.basename(fname))[0]  # xL0p59_zWp25.density
    parts = base.split(plane_marker, maxsplit=1)
    if len(parts) < 2:
        return base
    remainder = parts[1]  # '.density'
    remainder = remainder.lstrip(".")
    var = remainder.split(".")[0] if "." in remainder else remainder
    return var

def get_kulite_probe_and_var(fname: str):
    """
    From 'k1.velocityx.dat' -> ('k1', 'velocityx')
    """
    base = os.path.basename(fname)
    stem = os.path.splitext(base)[0]         # k1.velocityx
    parts = stem.split(".")
    if len(parts) >= 2:
        return parts[0], parts[1]
    elif len(parts) == 1:
        return parts[0], "value"
    else:
        return "unknown", "value"

# ---------------------------------------------------------------
# Auto-detect all.dat files in root_dir
# ---------------------------------------------------------------
all_dat_files = [
    os.path.join(root_dir, f)
    for f in os.listdir(root_dir)
    if f.lower().endswith(".dat")
]

# ---------------------------------------------------------------
# Locate coords file (optional normalization)
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

    if "y" in coords.columns and Y_DEPTH != 0:
        coords["Y_norm"] = (coords["y"] - Y_REFERENCE) / Y_DEPTH
    else:
        coords["Y_norm"] = pd.NA
else:
    print("No coords file found; Y_norm column will be set to NaN in outputs.")
    coords = None

# Remove coords files from further processing
data_candidate_files = [f for f in all_dat_files if f not in coords_files]

# ---------------------------------------------------------------
# Separate plane data files and Kulite data files,
# applying exclusion rules
# ---------------------------------------------------------------
plane_files = []
kulite_files = []

for f in data_candidate_files:
    base = os.path.basename(f)
    # Skip any blocked names outright
    if is_blocked_name(base):
        continue

    if is_kulite_file(base):
        kulite_files.append(f)
    else:
        plane_marker = detect_plane_from_name(base)
        if plane_marker is not None:
            plane_files.append(f)
        else:
            # Not Kulite, not allowed plane -> ignore
            pass

print(f"Found {len(plane_files)} plane-related data files (after filtering).")
print(f"Found {len(kulite_files)} Kulite data files (after filtering).")

if not plane_files and not kulite_files:
    raise SystemExit("No valid plane or Kulite data files found after filtering. Exiting.")

# ---------------------------------------------------------------
# Helper: read one DAT file into a DataFrame
# ---------------------------------------------------------------
def read_dat_file(path):
    with open(path, "r") as f:
        header_line = f.readline().strip()
    header_cols = header_line.lstrip("#").split()

    df = pd.read_csv(
        path,
        sep=r"\s+",
        comment="#",
        header=None,
        skiprows=1
    )
    df.columns = header_cols
    return df

# ---------------------------------------------------------------
# Organize plane files:
#   plane_line_files[plane_marker][line_name] = list of file paths
# ---------------------------------------------------------------
plane_line_files = defaultdict(lambda: defaultdict(list))

for f in plane_files:
    plane_marker = detect_plane_from_name(f)
    if plane_marker is None:
        continue
    line_name = get_line_name(f)
    plane_line_files[plane_marker][line_name].append(f)

# ---------------------------------------------------------------
# Probes for plane data
# ---------------------------------------------------------------
probe_names = [f"probe{str(i).zfill(5)}" for i in range(5)]

# ---------------------------------------------------------------
# Process plane data:
#   For each plane -> folder
#   For each line in that plane -> XLSX workbook
#   For each probe -> sheet with merged time history of all variables
# ---------------------------------------------------------------
for plane_marker, lines_dict in plane_line_files.items():
    plane_label = PLANE_MARKERS[plane_marker]  # 'mid', 'zWp25', 'zWp75'

    # Create output folder for this plane
    plane_output_dir = os.path.join(root_dir, f"{plane_label}_plane")
    os.makedirs(plane_output_dir, exist_ok=True)
    print(f"\nProcessing plane '{plane_label}' -> folder '{plane_output_dir}'")

    for line_name, files_for_line in sorted(lines_dict.items()):
        output_file = os.path.join(plane_output_dir, f"{line_name}_{plane_label}.xlsx")
        print(f"  Line '{line_name}': writing to workbook '{output_file}'")

        with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
            for probe in probe_names:
                print(f"    Building sheet for {probe}")
                probe_df = None  # merged result for this probe

                for fpath in sorted(files_for_line):
                    filename = os.path.basename(fpath)
                    df = read_dat_file(fpath)

                    if "time" not in df.columns or probe not in df.columns:
                        print(f"      Skipping {filename}: missing 'time' or '{probe}' column.")
                        continue

                    # Column label: the variable name from the filename
                    var_name = get_plane_variable_name(filename, plane_marker)

                    df_probe = df[["time", probe]].copy()
                    df_probe.rename(columns={probe: var_name}, inplace=True)

                    if probe_df is None:
                        probe_df = df_probe
                    else:
                        probe_df = pd.merge(
                            probe_df,
                            df_probe,
                            on="time",
                            how="inner",
                            sort=True
                        )

                if probe_df is None:
                    print(f"      No data found for {probe} in line '{line_name}', skipping sheet.")
                    continue

                # Attach Y_norm if coords are available
                if coords is not None:
                    probe_num = extract_probe_number_from_name(probe)
                    if probe_num in coords.index:
                        y_norm_value = coords.loc[probe_num].get("Y_norm", pd.NA)
                        probe_df["Y_norm"] = y_norm_value
                    else:
                        print(f"      Probe number {probe_num} not in coords; Y_norm set to NaN.")
                        probe_df["Y_norm"] = pd.NA
                else:
                    probe_df["Y_norm"] = pd.NA

                probe_df.sort_values("time", inplace=True)
                sheet_name = probe[:31]  # Excel sheet name limit
                probe_df.to_excel(writer, sheet_name=sheet_name, index=False)
                print(f"      -> Written sheet '{sheet_name}'")

        print(f"  Finished workbook '{output_file}'")

# ---------------------------------------------------------------
# Process Kulite data:
#   One XLSX workbook with a sheet per Kulite probe (k1–k6)
# ---------------------------------------------------------------
if kulite_files:
    kulite_groups = defaultdict(list)  # kulite_groups['k1'] = [files]

    for f in kulite_files:
        k_probe, _ = get_kulite_probe_and_var(f)
        kulite_groups[k_probe].append(f)

    kulite_output_file = os.path.join(root_dir, "Kulite_HighFreq.xlsx")
    print(f"\nProcessing Kulite data -> workbook '{kulite_output_file}'")

    with pd.ExcelWriter(kulite_output_file, engine="openpyxl") as writer:
        for k_probe, files_for_k in sorted(kulite_groups.items()):
            print(f"  Building sheet for Kulite probe '{k_probe}'")
            merged_df = None

            for fpath in sorted(files_for_k):
                filename = os.path.basename(fpath)
                df = read_dat_file(fpath)

                if "time" not in df.columns:
                    print(f"    Skipping {filename}: missing 'time' column.")
                    continue

                _, var_name = get_kulite_probe_and_var(filename)

                data_cols = [c for c in df.columns if c != "time"]
                if not data_cols:
                    print(f"    Skipping {filename}: no data columns.")
                    continue

                df_sub = df[["time"] + data_cols].copy()
                rename_map = {c: f"{var_name}" if len(data_cols) == 1 else f"{var_name}_{c}"
                              for c in data_cols}
                df_sub.rename(columns=rename_map, inplace=True)

                if merged_df is None:
                    merged_df = df_sub
                else:
                    merged_df = pd.merge(
                        merged_df,
                        df_sub,
                        on="time",
                        how="inner",
                        sort=True
                    )

            if merged_df is None:
                print(f"  No data found for Kulite probe '{k_probe}', skipping sheet.")
                continue

            merged_df.sort_values("time", inplace=True)
            sheet_name = k_probe[:31]
            merged_df.to_excel(writer, sheet_name=sheet_name, index=False)
            print(f"  -> Written Kulite sheet '{sheet_name}'")

    print(f"Finished Kulite workbook '{kulite_output_file}'")
else:
    print("\nNo Kulite files found; skipping Kulite workbook.")

print("\n------------------------------------------")
print("All plane lines and Kulite probes processed successfully (with filtering).")
print("------------------------------------------")