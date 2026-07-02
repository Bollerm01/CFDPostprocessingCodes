# Current workflow for condensing CSVs of probe lines from Volcano sims
# Input: Folder of CSVs from Paraview
# Output: Individual cleaned Excel workbook for each CSV

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

FINAL_COLUMNS = [
    "X",
    "Y",
    "Z",
    "machnumberavg",
    "pressureavg",
    "reynoldsstressxx",
    "reynoldsstressyy",
    "reynoldsstresszz",
    "tke",
    "velocityxavg",
    "velocityyavg",
    "velocityzavg"
]

# ============================================================
# ============== Y NORMALIZATION PARAMETERS ==================
# ============================================================

Y_REFERENCE = 0.018593
Y_DEPTH = 0.018593

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
    
    # Name of the selected folder (used as filename prefix)
    root_folder_name = os.path.basename(os.path.normpath(csv_folder))

    if Y_DEPTH == 0.0:
        messagebox.showerror(
            "Configuration Error",
            "Y_DEPTH cannot be zero."
        )
        return

    # Create cleaned output folder
    output_folder = os.path.join(csv_folder, "cleaned")
    os.makedirs(output_folder, exist_ok=True)

    # Find CSV files
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

    processed = 0

    try:

        for csv_file in csv_files:

            csv_path = os.path.join(csv_folder, csv_file)
            print(f"Processing {csv_file}")

            df = pd.read_csv(csv_path)

            # Rename coordinate columns
            df = df.rename(columns=COLUMN_RENAME_MAP)

            # Keep only desired columns that exist
            existing_cols = [c for c in FINAL_COLUMNS if c in df.columns]
            df = df[existing_cols]

            # Insert probe number as the first column (0, 1, 2, ...)
            df.insert(0, "probe_num", range(len(df)))
            
            # Optional Y normalization
            # if "Y" in df.columns:
            #     df["Y_norm"] = (df["Y"] - Y_REFERENCE) / Y_DEPTH

            # Location name from the CSV filename
            location = os.path.splitext(csv_file)[0]

            # Output filename: [rootFolderName]_[location].xlsx
            output_excel = os.path.join(
                output_folder,
                f"{root_folder_name}_{location}.xlsx"
            )

            # Save one workbook per CSV
            with pd.ExcelWriter(output_excel, engine="openpyxl") as writer:
                df.to_excel(
                    writer,
                    sheet_name="Data",
                    index=False
                )

            processed += 1

        messagebox.showinfo(
            "Success",
            f"Created {processed} Excel files in:\n{output_folder}"
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
    text="Select CSV Folder and Create Excel Files",
    command=run_conversion,
    height=2,
    width=45
)

run_button.pack(pady=35)

root.mainloop()