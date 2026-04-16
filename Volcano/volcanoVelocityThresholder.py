import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import re
import os
import tkinter as tk
from tkinter import filedialog, messagebox
import pickle

# ============================================================
# GUI INPUTS
# ============================================================
root = tk.Tk()
root.withdraw()

excel_file = filedialog.askopenfilename(
    title="Select Input Excel Workbook",
    filetypes=[("Excel files", "*.xlsx")]
)
if not excel_file:
    messagebox.showerror("Error", "No Excel file selected.")
    raise SystemExit

# Gets file edge geometry type
fileString = excel_file.split('/')[-1]
geometryType = fileString.split('_')[0]

# Uses the same directory as the workbook
output_dir = os.path.join(os.path.dirname(excel_file), f"ShearResults_{geometryType}")
os.makedirs(output_dir, exist_ok=True)

# Create subfolders
dat_dir = os.path.join(output_dir, "DAT_Files")
plots_dir = os.path.join(output_dir, "Plots")
os.makedirs(dat_dir, exist_ok=True)
os.makedirs(plots_dir, exist_ok=True)


# ============================================================
# COLUMN NAMES (EDIT IF NEEDED)
# ============================================================
Y_COL = "Y_norm"
VELX_COL = "velocityx"
VELXAVG_COL = "velocityxavg"
VELMAG_COL = "velocitymag"
VELMAGAVG_COL = "velocitymagavg"

VELOCITY_COLS = [
    VELX_COL,
    VELXAVG_COL,
    VELMAG_COL,
    VELMAGAVG_COL
]

THRESHOLDS = [(0.95, 0.05), (0.90, 0.10)]

# Locations for freestream sheets and per-location results
LOCATIONS = ["MP", "z25", "z75"]  # corresponding to sheets US_MP, US_z25, US_z75


# ============================================================
# HELPER FUNCTIONS
# ============================================================
def parse_xL(sheet_name):
    """
    Parses x/L value from sheet names like:
      'xL1', 'xL_1'
      'xL0p17', 'xL_0p17'
      'xL1_MP', 'xL0p17_z25', etc.
      'xL_neg2' or 'xLneg2' -> -2.0 (if present)
    """

    # 1) Remove trailing location suffix if present, e.g. '_MP', '_z25', '_z75'
    base = re.sub(r"_(MP|z25|z75)$", "", sheet_name)

    # 2) Handle explicit negative (if you still use xL_neg2/xLneg2)
    if base in ["xL_neg2", "xLneg2"]:
        return -2.0

    # 3) Patterns:
    #    xL_0p17, xL0p17, xL-1p5 -> 0.17, 0.17, -1.5
    m = re.search(r"xL_?(-?[0-9]+)p([0-9]+)$", base)
    if m:
        return float(f"{m.group(1)}.{m.group(2)}")

    #    xL_1, xL1, xL-2 -> 1.0, 1.0, -2.0
    m = re.search(r"xL_?(-?[0-9]+)$", base)
    if m:
        return float(m.group(1))

    raise ValueError(f"Could not parse xL from sheet name: {sheet_name}")


def get_loc_from_sheet(sheet_name, valid_locs):
    """
    Extracts plane/location from sheet name.
    Expected pattern: 'xL1_MP', 'xL0p17_z25', 'xL1_z75', etc.
    Returns the loc string if it matches one of valid_locs, else None.
    """
    parts = sheet_name.split("_")
    if not parts:
        return None
    suffix = parts[-1]
    if suffix in valid_locs:
        return suffix
    return None


def clean_velocity_dataframe(df, y_col, velocity_cols, duplicate_ref_col):
    """
    Single-pass cleaning of entire velocity DataFrame.
    """
    required_cols = [y_col] + velocity_cols
    df_clean = df[required_cols].dropna()
    df_clean = df_clean.sort_values(y_col)

    # Remove duplicated rows using one velocity column
    dup_mask = df_clean[duplicate_ref_col].duplicated(keep="first")
    df_clean = df_clean.loc[~dup_mask]

    return df_clean.reset_index(drop=True)


def prune_profile_keep_first_y(df, y_col, velocity_cols):
    """
    Prune the profile before thresholding:
      - Sort by y.
      - For duplicated velocity data (based on VELMAGAVG_COL and VELXAVG_COL),
        keep the first y.

    Returns:
      df_pruned: DataFrame with columns [y_col] + velocity_cols
    """
    # Sort by y
    df_sorted = df.sort_values(y_col).copy()

    # Prune: for duplicated velocitymagavg, keep the first y
    df_pruned = df_sorted.drop_duplicates(subset=[VELMAGAVG_COL], keep="first")

    # Prune again based on velocityxavg
    df_pruned = df_pruned.drop_duplicates(subset=[VELXAVG_COL], keep="first")

    # Ensure still sorted by y
    df_pruned = df_pruned.sort_values(y_col)

    # Keep only the desired columns (y + velocities)
    required_cols = [y_col] + velocity_cols
    df_pruned = df_pruned[required_cols]

    return df_pruned.reset_index(drop=True)


def find_thickness_robust(y, vel_norm, upper, lower, min_sep=1e-9):
    """
    Robust thickness finder.
    If no values below `lower` are found, takes the last occurrence of the lowest velocity
    (skipping the first 5 points) as the lower crossing.
    Returns: thickness, lower_vel_for_dat (NaN if normal lower crossing was found)
    """
    y = np.asarray(y)
    vel = np.asarray(vel_norm)

    below = vel < lower
    above = vel > upper

    lower_vel_for_dat = np.nan  # Default extra column

    # Upper crossing must exist
    if not np.any(above):
        return np.nan, np.nan

    # Lower crossing
    if np.any(below):
        i_low = np.where(below)[0][-1]  # Last index below threshold
        if i_low >= len(vel) - 1:
            return np.nan, np.nan

        y1, y2 = y[i_low], y[i_low + 1]
        v1, v2 = vel[i_low], vel[i_low + 1]
        if v2 == v1:
            return np.nan, np.nan
        y_lower = y1 + (lower - v1) * (y2 - y1) / (v2 - v1)
        lower_vel_for_dat = np.nan  # Normal crossing found
    else:
        # No point below threshold: find last occurrence of min velocity (skip first 5 points)
        if len(vel) <= 5:
            return np.nan, np.nan  # Not enough points

        vel_tail = vel[5:]
        i_min = np.where(vel_tail == vel_tail.min())[0][-1] + 5
        i_low = i_min

        y_lower = y[i_low]
        lower_vel_for_dat = vel[i_low]

    # Upper crossing
    i_up = np.where(above)[0][0]
    if i_up == 0:
        return np.nan, lower_vel_for_dat

    y1, y2 = y[i_up - 1], y[i_up]
    v1, v2 = vel[i_up - 1], vel[i_up]
    if v2 == v1:
        return np.nan, lower_vel_for_dat
    y_upper = y1 + (upper - v1) * (y2 - y1) / (v2 - v1)

    thickness = y_upper - y_lower
    if thickness <= min_sep:
        return np.nan, lower_vel_for_dat

    return thickness, lower_vel_for_dat


# ============================================================
# LOAD WORKBOOK
# ============================================================
xls = pd.ExcelFile(excel_file)
sheet_names = xls.sheet_names

# ============================================================
# FREESTREAM CALCULATION FROM US_{loc} SHEETS
# ============================================================
freestream_mag = {}  # freestream velocitymagavg per loc
freestream_x = {}    # freestream velocityx per loc (no avg available)

for loc in LOCATIONS:
    fs_sheet = f"US_{loc}"
    if fs_sheet not in sheet_names:
        messagebox.showerror("Error", f"Freestream sheet '{fs_sheet}' not found.")
        raise SystemExit

    df_fs = pd.read_excel(excel_file, sheet_name=fs_sheet)
    df_fs = df_fs.sort_values(Y_COL)

    # Use the tail (second half in y) as freestream region
    df_fs_tail = df_fs.iloc[len(df_fs) // 2 :]

    freestream_mag[loc] = df_fs_tail[VELMAGAVG_COL].mean()
    freestream_x[loc] = df_fs_tail[VELX_COL].mean()  # uses x for FS due to lack of avg

    print("========================================")
    print(f"Freestream values for {loc}")
    print(f"velocitymagavg_fs_{loc} = {freestream_mag[loc]:.6f}")
    print(f"velocityx_fs_{loc}      = {freestream_x[loc]:.6f}")
    print("========================================")


# ============================================================
# NORMALIZED XLSX OUTPUT (ONE WORKBOOK PER LOCATION)
# ============================================================
writers = {}
for loc in LOCATIONS:
    norm_xlsx = os.path.join(output_dir, f"normalized_velocity_profiles_{loc}.xlsx")
    writer = pd.ExcelWriter(norm_xlsx, engine="xlsxwriter")

    # Store freestream values in a sheet
    pd.DataFrame({
        "quantity": ["velocitymagavg", "velocityxavg"],
        "value": [freestream_mag[loc], freestream_x[loc]]
    }).to_excel(writer, sheet_name="freestream", index=False)

    writers[loc] = writer


# ============================================================
# PROCESS AXIAL SHEETS
# ============================================================
# Map of normalized velocity columns to readable names for titles/files
normalized_cols = {
    "velocityx_norm": "Velocity X",
    "velocityxavg_norm": "Velocity X Avg",
    "velocitymag_norm": "Velocity Mag",
    "velocitymagavg_norm": "Velocity Mag Avg"
}

# results[loc][(norm_col, (upper, lower))] = list of (xL, thickness, lower_vel_for_dat)
results = {
    loc: {
        (norm_col, threshold): []
        for norm_col in normalized_cols.keys()
        for threshold in THRESHOLDS
    }
    for loc in LOCATIONS
}

# Axial sheets: everything that starts with 'xL'
all_axial_sheets = [s for s in sheet_names if s.startswith("xL")]

# Group axial sheets by plane/location based on suffix (_MP, _z25, _z75)
axial_sheets_by_loc = {loc: [] for loc in LOCATIONS}
for s in all_axial_sheets:
    loc = get_loc_from_sheet(s, LOCATIONS)
    if loc is not None:
        axial_sheets_by_loc[loc].append(s)
    # else:
    #     print(f"Warning: axial sheet '{s}' has no recognized plane suffix; skipping.")

# Process sheets per location (each sheet only contributes to its own plane)
for loc in LOCATIONS:
    for sheet in axial_sheets_by_loc[loc]:
        xL = parse_xL(sheet)
        df = pd.read_excel(excel_file, sheet_name=sheet)

        # Basic cleaning (NaNs, sort, remove duplicates in reference col)
        df_clean = clean_velocity_dataframe(
            df,
            y_col=Y_COL,
            velocity_cols=VELOCITY_COLS,
            duplicate_ref_col=VELMAGAVG_COL
        )

        # Pruning ONLY (no interpolation)
        df_pruned = prune_profile_keep_first_y(
            df_clean,
            y_col=Y_COL,
            velocity_cols=VELOCITY_COLS
        )

        # Use pruned y for thickness calculations
        y = df_pruned[Y_COL].to_numpy()

        # Normalize this pruned profile using freestream for THIS loc only
        df_loc = df_pruned.copy()
        df_loc["velocityx_norm"] = df_loc[VELX_COL] / freestream_x[loc]
        df_loc["velocityxavg_norm"] = df_loc[VELXAVG_COL] / freestream_x[loc]
        df_loc["velocitymag_norm"] = df_loc[VELMAG_COL] / freestream_mag[loc]
        df_loc["velocitymagavg_norm"] = df_loc[VELMAGAVG_COL] / freestream_mag[loc]

        # Write normalized data into the location-specific workbook
        df_loc.to_excel(writers[loc], sheet_name=sheet, index=False)

        # Thickness calculations for all normalized columns
        for norm_col, nice_name in normalized_cols.items():
            vel_used = df_loc[norm_col].to_numpy()
            for upper, lower in THRESHOLDS:
                thickness, lower_vel_for_dat = find_thickness_robust(
                    y, vel_used, upper, lower
                )
                results[loc][(norm_col, (upper, lower))].append(
                    (xL, thickness, lower_vel_for_dat)
                )

# Close Excel writers
for loc in LOCATIONS:
    writers[loc].close()


# ============================================================
# OUTPUT DAT FILES + OVERLAID PLOTS (PNG + FIG) FOR EACH LOCATION
# ============================================================
for loc in LOCATIONS:
    # --- 1) Write DAT files for all normalized quantities and thresholds ---
    for (norm_col, (upper, lower)), data in results[loc].items():
        if not data:
            continue

        data = np.array(sorted(data, key=lambda x: x[0]))  # sort by xL

        dat_path = os.path.join(
            dat_dir,
            f"thickness_{norm_col}_{int(upper*100)}_{int(lower*100)}_{loc}.dat"
        )
        np.savetxt(
            dat_path,
            data,
            header="xL thickness lower_vel_for_dat",
            comments=""
        )

    # --- 2) Overlaid plots ONLY for average quantities ---
    avg_norm_cols = {
        "velocityxavg_norm": "Velocity X Avg",
        "velocitymagavg_norm": "Velocity Mag Avg"
    }

    for norm_col, nice_name in avg_norm_cols.items():
        plt.figure()
        has_data = False

        for (upper, lower) in THRESHOLDS:
            key = (norm_col, (upper, lower))
            data = results[loc].get(key, [])
            if not data:
                continue

            data = np.array(sorted(data, key=lambda x: x[0]))

            label = f"{int(upper*100)}/{int(lower*100)}"
            plt.plot(
                data[:, 0],
                data[:, 1],
                marker="o",
                label=label
            )
            has_data = True

        if not has_data:
            plt.close()
            continue

        plt.xlabel("x/L")
        plt.ylabel("Shear Layer Thickness")
        plt.title(f"{nice_name} Thickness ({loc})")
        plt.grid(True)
        plt.legend()
        plt.tight_layout()

        # PNG (overlaid thresholds, averages only)
        plot_path_png = os.path.join(
            plots_dir,
            f"thickness_{norm_col}_overlaid_{loc}.png"
        )
        plt.savefig(plot_path_png, dpi=300)

        # FIG (pickled matplotlib figure)
        plot_path_fig = os.path.join(
            plots_dir,
            f"thickness_{norm_col}_overlaid_{loc}.fig"
        )
        with open(plot_path_fig, "wb") as f:
            pickle.dump(plt.gcf(), f)

        plt.close()

print(f"Processing complete. Files stored at : {output_dir}")