# Current workflow for condensing CSVs of probe lines from Volcano sims
# Future improvements needed when running final sims with direct probe .DAT files (see Time SensitivityVolcano data combiner workflow)
# Input: Folder of CSVs from Paraview
# Output: Condensed XLSX workbook with sheets per xL location

import os
import pandas as pd
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog

# ============================================================
# ================= COLUMN DEFINITIONS =======================
# ============================================================

COLUMN_RENAME_MAP = {
    "Points:0": "X",
    "Points:1": "Y",
    "Points:2": "Z",
}

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

    output_name = "CondensedProbeData"

    if not output_name:
        messagebox.showerror("Error", "No output file name provided.")
        return

    if not output_name.lower().endswith(".xlsx"):
        output_name += ".xlsx"

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

                # Rename coordinate columns
                df = df.rename(columns=COLUMN_RENAME_MAP)

                # Keep only desired columns that exist
                existing_cols = [c for c in FINAL_COLUMNS if c in df.columns]
                df = df[existing_cols]

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
root.title("CSV Probe Condenser")
root.geometry("380x130")
root.resizable(False, False)

run_button = tk.Button(
    root,
    text="Select CSV Folder and Create Excel",
    command=run_conversion,
    height=2,
    width=45
)

run_button.pack(pady=35)

root.mainloop()
