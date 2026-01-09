import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import re
import os
import tkinter as tk
from tkinter import filedialog, messagebox

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

output_dir = filedialog.askdirectory(
    title="Select Output Directory"
)

if not output_dir:
    messagebox.showerror("Error", "No output directory selected.")
    raise SystemExit

os.makedirs(output_dir, exist_ok=True)

# ============================================================
# COLUMN NAMES (EDIT IF NEEDED)
# ============================================================
Y_COL = "Y"
VELX_COL = "velocityx"
VELXAVG_COL = "velocityxavg"
VELMAG_COL = "velocitymag"
VELMAGAVG_COL = "velocitymagavg"

THRESHOLDS = [(0.95, 0.05), (0.90, 0.10)]

# ============================================================
# HELPER FUNCTIONS
# ============================================================
def parse_xL(sheet_name):
    if sheet_name == "xL_1":
        return 1.0

    match = re.search(r"xL_([0-9]+)p([0-9]+)", sheet_name)
    if match:
        return float(f"{match.group(1)}.{match.group(2)}")

    match = re.search(r"xL_([0-9]+)", sheet_name)
    if match:
        return float(match.group(1))

    raise ValueError(f"Could not parse xL from sheet name: {sheet_name}")

def find_thickness(y, vel_norm, upper, lower):
    """
    Compute shear layer thickness for monotonic increasing velocity profiles.

    Thickness definition:
        y(first U/Uinf > upper) - y(last U/Uinf < lower)

    Assumes:
        - y is sorted ascending
        - vel_norm increases with y
    """

    # Indices where velocity is below the lower threshold
    idx_lower = np.where(vel_norm < lower)[0]

    # Indices where velocity exceeds the upper threshold
    idx_upper = np.where(vel_norm > upper)[0]

    # If thresholds are never crossed, thickness is undefined
    if len(idx_lower) == 0 or len(idx_upper) == 0:
        return np.nan

    # Last low-velocity point (bottom of shear layer)
    y_lower = y[idx_lower[-1]]

    # First freestream-like point (top of shear layer)
    y_upper = y[idx_upper[0]]

    return y_upper - y_lower


# ============================================================
# LOAD WORKBOOK
# ============================================================
xls = pd.ExcelFile(excel_file)
sheet_names = xls.sheet_names

# ============================================================
# FREESTREAM CALCULATION
# ============================================================
if "xL_neg2" not in sheet_names:
    raise RuntimeError("Sheet 'xL_neg2' not found in workbook.")

df_fs = pd.read_excel(excel_file, sheet_name="xL_neg2")
df_fs = df_fs.sort_values(Y_COL)

half_index = len(df_fs) // 2
df_fs_tail = df_fs.iloc[half_index:]

velocitymagavg_fs = df_fs_tail[VELMAGAVG_COL].mean()
velocityxavg_fs = df_fs_tail[VELXAVG_COL].mean()

print("========================================")
print("Freestream Values (from xL_neg2)")
print(f"velocitymagavg_fs = {velocitymagavg_fs:.6f}")
print(f"velocityxavg_fs   = {velocityxavg_fs:.6f}")
print("========================================")

# ============================================================
# OUTPUT WORKBOOK FOR NORMALIZED VELOCITIES
# ============================================================
norm_xlsx_path = os.path.join(output_dir, "normalized_velocity_profiles.xlsx")
norm_writer = pd.ExcelWriter(norm_xlsx_path, engine="xlsxwriter")

# Write freestream summary sheet
pd.DataFrame({
    "quantity": ["velocitymagavg", "velocityxavg"],
    "value": [velocitymagavg_fs, velocityxavg_fs]
}).to_excel(norm_writer, sheet_name="freestream", index=False)

# ============================================================
# PROCESS REMAINING SHEETS
# ============================================================
results = {
    (0.95, 0.05): [],
    (0.90, 0.10): []
}

for sheet in sheet_names:
    if sheet == "xL_neg2":
        continue

    df = pd.read_excel(excel_file, sheet_name=sheet)
    df = df.sort_values(Y_COL)

    xL = parse_xL(sheet)
    y = df[Y_COL].to_numpy()

    # Normalized velocities
    df_norm = pd.DataFrame({
        "Y": df[Y_COL],
        "velocityx_norm": df[VELX_COL] / velocityxavg_fs,
        "velocityxavg_norm": df[VELXAVG_COL] / velocityxavg_fs,
        "velocitymag_norm": df[VELMAG_COL] / velocitymagavg_fs,
        "velocitymagavg_norm": df[VELMAGAVG_COL] / velocitymagavg_fs
    })

    # Write normalized profile to workbook
    df_norm.to_excel(norm_writer, sheet_name=sheet, index=False)

    vel_used = df_norm["velocitymagavg_norm"].to_numpy()

    for upper, lower in THRESHOLDS:
        thickness = find_thickness(y, vel_used, upper, lower)
        results[(upper, lower)].append((xL, thickness))

# Close normalized workbook
norm_writer.close()

# ============================================================
# OUTPUT DAT FILES + PLOTS
# ============================================================
for (upper, lower), data in results.items():
    data = np.array(sorted(data, key=lambda x: x[0]))

    dat_path = os.path.join(
        output_dir,
        f"thickness_{int(upper*100)}_{int(lower*100)}.dat"
    )
    np.savetxt(dat_path, data, header="xL  thickness", comments="")

    plt.figure()
    plt.plot(data[:, 0], data[:, 1], marker="o")
    plt.xlabel("x/L")
    plt.ylabel("Shear Layer Thickness")
    plt.title(f"{int(upper*100)}% / {int(lower*100)}% Thickness")
    plt.grid(True)

    plot_path = os.path.join(
        output_dir,
        f"thickness_{int(upper*100)}_{int(lower*100)}.png"
    )
    plt.savefig(plot_path, dpi=300)
    plt.close()

messagebox.showinfo(
    "Complete",
    "Processing complete.\n"
    "• Normalized velocity workbook written\n"
    "• DAT files generated\n"
    "• Plots saved"
)
