# CSV-to-Excel combiner for ParaView probe line outputs
# - Removes duplicate velocity rows (keeps the first)
# - Drops rows with blank velocity data
# - Interpolates back to 500 points along Y_norm (or Y fallback)
#
# Input: Folder of CSVs from ParaView (25 lines, each file)
# Output: One XLSX workbook with one sheet per probe location,
#         including a normalized Y column (Y_norm)

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

# Only the columns that should exist from the new probe script
FINAL_COLUMNS = [
    "X",
    "Y",
    "Z",
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
]

# Velocity columns used for duplicate/blank detection
VELOCITY_COLUMNS = [
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
]

# Target number of points after interpolation
TARGET_POINTS = 500

# ============================================================
# ============== Y NORMALIZATION PARAMETERS =================
# ============================================================

Y_REFERENCE = 0.018593   # Y-location of zero point (e.g., cavity lip)
Y_DEPTH = 0.018593       # Normalization depth (must be non-zero)

# ============================================================
# ================== CLEAN + INTERPOLATE =====================
# ============================================================

def clean_and_interpolate(df: pd.DataFrame) -> pd.DataFrame:
    """
    1. Remove duplicate velocity rows (keep first).
    2. Remove blank velocity rows (all velocity columns NaN).
    3. Compute Y_norm.
    4. Interpolate back to TARGET_POINTS along Y_norm (preferred) or Y.
    """

    # Ensure velocity columns exist subset
    vel_cols = [c for c in VELOCITY_COLUMNS if c in df.columns]

    # If no velocity columns found, just return df as-is
    if not vel_cols:
        return df

    # --- Remove duplicate velocity rows ---
    df = df.drop_duplicates(subset=vel_cols, keep="first")

    # --- Remove blank velocity rows (all velocity columns NaN) ---
    df = df.dropna(subset=vel_cols, how="all")

    if df.empty:
        return df

    # --- Compute / fallback for Y_norm ---
    if "Y" in df.columns and Y_DEPTH != 0.0:
        df["Y_norm"] = (df["Y"] - Y_REFERENCE) / Y_DEPTH
        y_col = "Y_norm"
    elif "Y" in df.columns:
        # Fallback: use raw Y instead of normalized
        df["Y_norm"] = df["Y"]
        y_col = "Y_norm"
    else:
        # If no Y at all, nothing to interpolate on
        return df

    # Sort by Y_norm to prepare for interpolation
    df = df.sort_values(y_col).reset_index(drop=True)

    # Remove any duplicated Y_norm values
    df = df.drop_duplicates(subset=[y_col], keep="first")

    # If we have fewer than 2 points, interpolation is not meaningful
    if df.shape[0] < 2:
        return df

    # --- Build new Y_norm grid with TARGET_POINTS points ---
    y_min = df[y_col].min()
    y_max = df[y_col].max()
    new_y = np.linspace(y_min, y_max, TARGET_POINTS)

    # Set Y_norm (or Y) as index for reindex + interpolation
    df = df.set_index(y_col)

    # Reindex to the new grid
    df = df.reindex(new_y)

    # Interpolate numeric columns linearly
    df_interpolated = df.interpolate(method="linear", axis=0)

    # Restore y-axis column name
    df_interpolated.index.name = y_col
    df_interpolated = df_interpolated.reset_index()

    # If we are using Y_norm as the physical normalized coordinate,
    # ensure it's named Y_norm, and rebuild Y if appropriate
    if y_col == "Y_norm":
        # Recompute Y from Y_norm if Y exists in FINAL_COLUMNS
        if "Y" in FINAL_COLUMNS and Y_DEPTH != 0.0:
            df_interpolated["Y"] = df_interpolated["Y_norm"] * Y_DEPTH + Y_REFERENCE
    else:
        # y_col was something else (e.g., "Y"), keep Y_norm consistent
        df_interpolated["Y_norm"] = df_interpolated[y_col]

    # Reorder columns: keep FINAL_COLUMNS that exist, then extras (including Y_norm)
    existing_final = [c for c in FINAL_COLUMNS if c in df_interpolated.columns]
    cols = existing_final + [c for c in df_interpolated.columns
                             if c not in existing_final]
    df_interpolated = df_interpolated[cols]

    return df_interpolated

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

                # Clean + interpolate to fixed resolution (500 points)
                df_clean = clean_and_interpolate(df)

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
root.title("Probe CSV → Excel Combiner (Clean + Interpolate)")
root.geometry("460x160")
root.resizable(False, False)

run_button = tk.Button(
    root,
    text="Select Probe CSV Folder and Create Cleaned/Interpolated Excel",
    command=run_conversion,
    height=2,
    width=55
)

run_button.pack(pady=35)

root.mainloop()