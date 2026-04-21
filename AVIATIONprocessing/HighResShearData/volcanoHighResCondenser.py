# CSV-to-Excel combiner for ParaView probe line outputs
# - Cleaning steps:
#   * Rename coordinates
#   * Keep only selected columns
#   * Drop rows where ALL velocity columns are NaN
#   * Drop duplicate velocity rows (keep the first)
#   * Compute Y_norm
# - No interpolation or resampling is performed.
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
# ========================= CLEANING =========================
# ============================================================

def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Cleaning steps:
      1. Drop rows where ALL velocity columns are NaN.
      2. Drop duplicate velocity rows (based on velocity columns, keep first).
      3. Compute Y_norm if Y and Y_DEPTH are available (fallback to Y if needed).
      4. Sort by Y_norm if present.
    No interpolation or resampling.
    """

    # Ensure velocity columns exist subset
    vel_cols = [c for c in VELOCITY_COLUMNS if c in df.columns]

    # If no velocity columns found, just compute Y_norm (if possible) and return
    if not vel_cols:
        if "Y" in df.columns and Y_DEPTH != 0.0:
            df["Y_norm"] = (df["Y"] - Y_REFERENCE) / Y_DEPTH
        return df

    # --- 1) Drop rows with NO velocity data at all ---
    df = df.dropna(subset=vel_cols, how="all")
    if df.empty:
        return df

    # --- 2) Drop duplicate velocity rows (keep first) ---
    df = df.drop_duplicates(subset=vel_cols, keep="first")

    # --- 3) Compute Y_norm if possible ---
    if "Y" in df.columns and Y_DEPTH != 0.0:
        df["Y_norm"] = (df["Y"] - Y_REFERENCE) / Y_DEPTH
    elif "Y" in df.columns:
        # Fallback: use raw Y in place of normalized coordinate
        df["Y_norm"] = df["Y"]
    else:
        # No Y available: no Y_norm column
        pass

    # --- 4) Sort by Y_norm if present ---
    if "Y_norm" in df.columns:
        df = df.sort_values("Y_norm").reset_index(drop=True)

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

                # Clean (drop NaN velocity rows + duplicate velocity rows)
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
root.title("Probe CSV → Excel Combiner (Clean Only, Remove Duplicates)")
root.geometry("480x170")
root.resizable(False, False)

run_button = tk.Button(
    root,
    text="Select Probe CSV Folder and Create Cleaned Excel",
    command=run_conversion,
    height=2,
    width=58
)

run_button.pack(pady=35)

root.mainloop()