# CSV-to-Excel combiner for ParaView probe line outputs
# Input: Folder of CSVs from ParaView (25 lines, each file)
# Output: One XLSX workbook with one sheet per probe location,
#         including a normalized Y column (Y_norm)

import os
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

# ============================================================
# ============== Y NORMALIZATION PARAMETERS =================
# ============================================================

# Adjust these as needed for your geometry
Y_REFERENCE = 0.018593   # Y-location of zero point (e.g., cavity lip)
Y_DEPTH = 0.018593       # Normalization depth (must be non-zero)

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

    output_name = "CondensedProbeData.xlsx"
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

                # --- Normalize Y-coordinate ---
                if "Y" in df.columns:
                    df["Y_norm"] = (df["Y"] - Y_REFERENCE) / Y_DEPTH
                else:
                    df["Y_norm"] = pd.NA

                # Excel sheet name (31 char limit)
                sheet_name = os.path.splitext(csv_file)[0][:31]

                df.to_excel(
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
root.title("Probe CSV → Excel Combiner")
root.geometry("420x140")
root.resizable(False, False)

run_button = tk.Button(
    root,
    text="Select Probe CSV Folder and Create Excel",
    command=run_conversion,
    height=2,
    width=48
)

run_button.pack(pady=35)

root.mainloop()