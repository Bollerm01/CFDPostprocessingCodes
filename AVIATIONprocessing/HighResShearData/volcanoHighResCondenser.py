# CSV-to-Excel combiner for ParaView probe line outputs
# Cleaning logic:
#   1) Rename coordinates
#   2) Keep only selected columns
#   3) Drop rows where ALL velocity columns are NaN
#   4) "Fix" duplicate velocity points locally:
#        - For each velocity column, detect flat segments (consecutive duplicates)
#        - Replace those duplicate values by a local linear interpolation
#          between the nearest changing values on each side
#        - The number of rows is unchanged; each column keeps its original length
#   5) Compute Y_norm and sort by it (if possible)
#
# No global resampling; we only adjust duplicated values in-place.
#
# Input: Folder of CSVs from ParaView (probe lines)
# Output: One XLSX workbook with one sheet per probe location,
#         including a normalized Y column (Y_norm) where possible.

import os
import numpy as np
import pandas as pd
import tkinter as tk
from tkinter import filedialog, messagebox

# ============================================================
# ================= COLUMN DEFINITIONS =======================
# ============================================================

COLUMN_RENAME_MAP = {
    "Points:0": "X",
    "Points:1": "Y",
    "Points:2": "Z",
}

# Columns expected from the probe script
FINAL_COLUMNS = [
    "X",
    "Y",
    "Z",
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
]

# Velocity columns used for blank-row and duplicate detection
VELOCITY_COLUMNS = [
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
]

# ============================================================
# ============== Y NORMALIZATION PARAMETERS =================
# ============================================================

Y_REFERENCE = 0.018593   # Y-location of zero point (e.g., cavity lip)
Y_DEPTH = 0.018593       # Normalization depth (must be non-zero)

# ============================================================
# ============ LOCAL DUPLICATE INTERPOLATION HELPERS =========
# ============================================================

def _interp_flat_segments(y_axis: np.ndarray, values: np.ndarray) -> np.ndarray:
    """
    Given:
      - y_axis: 1D array (e.g., Y_norm) assumed sorted
      - values: 1D numeric array of same length
    Detect flat segments (consecutive duplicate values) and
    locally replace them with linearly interpolated values
    between the nearest changing points.

    The length of values is unchanged.
    """

    v = values.copy()
    n = len(v)
    if n < 2:
        return v

    # Indices where value changes
    diff = np.diff(v)
    change_idx = np.where(diff != 0)[0]  # positions where v[i+1] != v[i]

    if len(change_idx) == 0:
        # Entire column is flat; nothing meaningful to interpolate
        return v

    # We'll treat flat segments between changes
    # We'll scan the array and find stretches where diff == 0
    i = 0
    while i < n - 1:
        if v[i+1] == v[i]:
            # Start of a flat segment
            start = i
            while i < n - 1 and v[i+1] == v[i]:
                i += 1
            end = i + 1  # segment is indices [start, end], inclusive, with v[start:end+1] = const

            # Now we have a flat segment from start to end (inclusive)
            # Find neighbors just outside this segment, if they exist
            left_idx = start - 1 if start - 1 >= 0 else None
            right_idx = end + 1 if end + 1 < n else None

            # If we don't have two distinct neighbors, we can't interpolate better
            if left_idx is None and right_idx is None:
                # Nothing to do (entire array flat)
                continue
            elif left_idx is None:
                # Only right neighbor: linearly ramp from current flat value to right neighbor
                y0 = y_axis[start]
                y1 = y_axis[right_idx]
                v0 = v[start]
                v1 = v[right_idx]
                seg_y = y_axis[start:right_idx]
                v[start:right_idx] = np.interp(seg_y, [y0, y1], [v0, v1])
            elif right_idx is None:
                # Only left neighbor: ramp from left neighbor to current flat
                y0 = y_axis[left_idx]
                y1 = y_axis[end]
                v0 = v[left_idx]
                v1 = v[end]
                seg_y = y_axis[left_idx+1:end+1]
                v[left_idx+1:end+1] = np.interp(seg_y, [y0, y1], [v0, v1])
            else:
                # Both neighbors exist: interpolate from left neighbor to right neighbor
                y0 = y_axis[left_idx]
                y1 = y_axis[right_idx]
                v0 = v[left_idx]
                v1 = v[right_idx]
                seg_y = y_axis[left_idx+1:right_idx]
                v[left_idx+1:right_idx] = np.interp(seg_y, [y0, y1], [v0, v1])

        else:
            i += 1

    return v

def _fix_duplicate_velocities(df: pd.DataFrame) -> pd.DataFrame:
    """
    For each velocity column:
      - Use Y_norm (if present) or Y as the axis.
      - Detect flat segments (consecutive identical values).
      - Locally interpolate across those segments.
    """

    # Determine axis to use for "local" interpolation
    if "Y_norm" in df.columns:
        axis_col = "Y_norm"
    elif "Y" in df.columns:
        axis_col = "Y"
    else:
        # No axis; cannot perform local interpolation meaningfully
        return df

    y_axis = df[axis_col].to_numpy()

    for col in VELOCITY_COLUMNS:
        if col not in df.columns:
            continue

        series = df[col]
        if not np.issubdtype(series.dtype, np.number):
            continue

        v = series.to_numpy()

        # Only consider rows with finite y and v
        mask = np.isfinite(y_axis) & np.isfinite(v)
        if mask.sum() < 2:
            continue

        # Work only on valid subset, then put back
        y_valid = y_axis[mask]
        v_valid = v[mask]

        # Ensure y_valid is sorted; also keep mapping to original index order
        sort_idx = np.argsort(y_valid)
        y_sorted = y_valid[sort_idx]
        v_sorted = v_valid[sort_idx]

        v_fixed_sorted = _interp_flat_segments(y_sorted, v_sorted)

        # Put back into original order
        v_fixed = v.copy()
        v_fixed_indices = np.where(mask)[0][sort_idx]
        v_fixed[v_fixed_indices] = v_fixed_sorted

        df[col] = v_fixed

    return df

# ============================================================
# ========================= CLEANING =========================
# ============================================================

def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Cleaning steps:
      1. Drop rows where ALL velocity columns are NaN.
      2. Compute Y_norm if Y and Y_DEPTH are available (fallback to Y if needed).
      3. Sort by Y_norm if present.
      4. For each velocity column, locally interpolate to remove flat
         (duplicate) segments, keeping the same number of points.
    No global resampling.
    """

    # Ensure velocity columns exist subset
    vel_cols = [c for c in VELOCITY_COLUMNS if c in df.columns]

    # --- 1) Drop rows with NO velocity data at all ---
    if vel_cols:
        df = df.dropna(subset=vel_cols, how="all")
        if df.empty:
            return df

    # --- 2) Compute Y_norm if possible ---
    if "Y" in df.columns and Y_DEPTH != 0.0:
        df["Y_norm"] = (df["Y"] - Y_REFERENCE) / Y_DEPTH
    elif "Y" in df.columns:
        # Fallback: use raw Y in place of normalized coordinate
        df["Y_norm"] = df["Y"]

    # --- 3) Sort by Y_norm if present ---
    if "Y_norm" in df.columns:
        df = df.sort_values("Y_norm").reset_index(drop=True)

    # --- 4) Fix duplicate velocity values via local interpolation ---
    df = _fix_duplicate_velocities(df)

    return df

# ============================================================
# ===================== MAIN PROCESS =========================
# ============================================================

def run_conversion():

    # --- Select input folder ---
    csv_folder = filedialog.askdirectory(
        title="Select folder containing CSV files"
    )

    if not csv_folder:
        messagebox.showerror("Error", "No CSV folder selected.")
        return

    if Y_DEPTH == 0.0:
        messagebox.showerror(
            "Configuration Error",
            "Y_DEPTH cannot be zero."
        )
        return

    geometry = csv_folder.split('/')[-1]
    output_name = f"CondensedProbeData_{geometry}.xlsx"
    output_excel = os.path.join(csv_folder, output_name)

    # --- Find CSV files ---
    csv_files = sorted(
        f for f in os.listdir(csv_folder)
        if f.lower().endswith(".csv")
    )

    if not csv_files:
        messagebox.showerror(
            "Error",
            "No CSV files found in the selected folder."
        )
        return

    try:
        with pd.ExcelWriter(output_excel, engine="openpyxl") as writer:

            for csv_file in csv_files:
                csv_path = os.path.join(csv_folder, csv_file)
                print(f"Processing {csv_file}")

                df = pd.read_csv(csv_path)

                # Rename coordinate columns if present
                df = df.rename(columns=COLUMN_RENAME_MAP)

                # Keep only desired columns that actually exist
                existing_cols = [c for c in FINAL_COLUMNS if c in df.columns]
                df = df[existing_cols]

                # Clean according to custom logic (blank removal + local duplicate fix)
                df_clean = clean_data(df)

                # Excel sheet name (31 char limit)
                sheet_name = os.path.splitext(csv_file)[0][:31]

                df_clean.to_excel(
                    writer,
                    sheet_name=sheet_name,
                    index=False
                )

        messagebox.showinfo(
            "Success",
            f"Excel file created:\n{output_excel}"
        )

    except Exception as e:
        messagebox.showerror(
            "Processing Error",
            str(e)
        )

# ============================================================
# ========================= GUI ==============================
# ============================================================

root = tk.Tk()
root.title("Probe CSV → Excel Combiner (Custom Clean)")
root.geometry("500x180")
root.resizable(False, False)

run_button = tk.Button(
    root,
    text="Select Probe CSV Folder and Create Cleaned Excel",
    command=run_conversion,
    height=2,
    width=60
)

run_button.pack(pady=35)

root.mainloop()