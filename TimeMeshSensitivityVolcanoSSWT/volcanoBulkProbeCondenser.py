import os
import re
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
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
    "pressure",
    "pressureavg",
    "qcriterion",
    "tke"
]

# ============================================================
# ===================== HELPERS ==============================
# ============================================================

def load_and_clean_csv(path):
    df = pd.read_csv(path)
    df = df.rename(columns=COLUMN_RENAME_MAP)

    existing_cols = [c for c in FINAL_COLUMNS if c in df.columns]
    return df[existing_cols]

def extract_fl_number(filename):
    """Extract numeric index from FL files (FL1, FL2, etc)."""
    m = re.search(r"FL(\d+)", filename, re.IGNORECASE)
    return int(m.group(1)) if m else None

def xyz_tuple(row):
    return (row["X"], row["Y"], row["Z"])

# ============================================================
# ===================== MAIN PROCESS =========================
# ============================================================

def run_conversion():

    csv_folder = filedialog.askdirectory(
        title="Select folder containing CSV files"
    )

    if not csv_folder:
        messagebox.showerror("Error", "No CSV folder selected.")
        return

    # Get folder name to use as Excel file title
    folder_name = os.path.basename(os.path.normpath(csv_folder))
    output_excel = os.path.join(
        csv_folder, f"{folder_name}_condensedData.xlsx"
    )

    csv_files = [
        f for f in os.listdir(csv_folder)
        if f.lower().endswith(".csv")
    ]

    if not csv_files:
        messagebox.showerror("Error", "No CSV files found.")
        return

    # Group files
    fl_files = []
    cl_files = []
    ctrl_files = []

    for f in csv_files:
        name = f.upper()
        if name.startswith("FL"):
            fl_files.append(f)
        elif name.startswith("CTRL"):
            ctrl_files.append(f)
        elif name.startswith("CL"):
            cl_files.append(f)

    try:
        with pd.ExcelWriter(output_excel, engine="openpyxl") as writer:

            # ====================================================
            # ===================== FL ===========================
            # ====================================================
            if fl_files:
                fl_files.sort(key=extract_fl_number)

                combined_df = None

                for i, fname in enumerate(fl_files):
                    path = os.path.join(csv_folder, fname)
                    df = load_and_clean_csv(path)

                    if combined_df is None:
                        combined_df = df.copy()
                        continue

                    # continuity check
                    prev_last = xyz_tuple(combined_df.iloc[-1])
                    curr_first = xyz_tuple(df.iloc[0])

                    if prev_last != curr_first:
                        raise ValueError(
                            f"FL continuity error between files:\n"
                            f"{fl_files[i-1]} → {fname}\n"
                            f"{prev_last} != {curr_first}"
                        )

                    # drop overlapping first row
                    df = df.iloc[1:].reset_index(drop=True)
                    combined_df = pd.concat(
                        [combined_df, df],
                        ignore_index=True
                    )

                combined_df.to_excel(
                    writer,
                    sheet_name="FL",
                    index=False
                )

            # ====================================================
            # ===================== CL ===========================
            # ====================================================
            if cl_files:
                cl_dfs = [
                    load_and_clean_csv(os.path.join(csv_folder, f))
                    for f in sorted(cl_files)
                ]
                cl_df = pd.concat(cl_dfs, ignore_index=True)

                cl_df.to_excel(
                    writer,
                    sheet_name="CL",
                    index=False
                )

            # ====================================================
            # ==================== CTRL ==========================
            # ====================================================
            if ctrl_files:
                ctrl_dfs = [
                    load_and_clean_csv(os.path.join(csv_folder, f))
                    for f in sorted(ctrl_files)
                ]
                ctrl_df = pd.concat(ctrl_dfs, ignore_index=True)

                ctrl_df.to_excel(
                    writer,
                    sheet_name="CTRL",
                    index=False
                )

        messagebox.showinfo(
            "Success",
            f"Excel file created:\n{output_excel}"
        )

    except Exception as e:
        messagebox.showerror("Processing Error", str(e))


# ============================================================
# ========================= GUI ==============================
# ============================================================

root = tk.Tk()
root.title("CSV Probe Condenser")
root.geometry("400x140")
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
