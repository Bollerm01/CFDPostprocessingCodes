## CONDENSER FOR VULCAN PROBE DATA ##

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
    "Velocity_Vect:0": "Velocity_X",
    "Velocity_Vect:1": "Velocity_Y",
    "Velocity_Vect:2": "Velocity_Z",
    "Velocity_Mag_m_s": "Velocity_Mag",
    "U_velocity_norm" : "Velocity_X_Norm",
    "U_velocity_rms" : "Velocity_X_RMS", 
    'zone2/Pressure_Pa': "Pressure",
    'zone2/Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup': "TKE",
    'zone2/greekt_greeksubxx_subsupt_sup': "Rxx",
    'zone2/greekt_greeksubxy_subsupt_sup': "Rxy",
    'zone2/greekt_greeksubxz_subsupt_sup': "Rxz",
    'zone2/greekt_greeksubyy_subsupt_sup': "Ryy",
    'zone2/greekt_greeksubyz_subsupt_sup': "Ryz",
    'zone2/greekt_greeksubzz_subsupt_sup': "Rzz"
}

FINAL_COLUMNS = [
    "X",
    "Y",
    "Z",
    "Velocity_X",
    "Velocity_Y",
    "Velocity_Z",
    "Velocity_Mag",
    "Velocity_X_Norm",
    "Velocity_X_RMS", 
    "Pressure",
    "TKE",
    "Rxx",
    "Rxy",
    "Rxz",
    "Ryy",
    "Ryz",
    "Rzz"    
]

# ============================================================
# ============== Y NORMALIZATION PARAMETERS =================
# ============================================================

Y_REFERENCE = -0.003324  # Y-location of zero point
Y_DEPTH = 0.018369       # Normalization depth (must be non-zero)


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

                # Rename coordinate columns
                df = df.rename(columns=COLUMN_RENAME_MAP)

                # Keep only desired columns that exist
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
