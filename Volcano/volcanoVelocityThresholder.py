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

# Uses the same directory as the workbook
output_dir = os.path.join(os.path.dirname(excel_file), "ShearResults")

os.makedirs(output_dir, exist_ok=True)


# Create subfolders
dat_dir = os.path.join(output_dir, "DAT_Files")
plots_dir = os.path.join(output_dir, "Plots")

os.makedirs(dat_dir, exist_ok=True)
os.makedirs(plots_dir, exist_ok=True)



# ============================================================
# COLUMN NAMES (EDIT IF NEEDED)
# ============================================================
Y_COL = "Y"
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

    # Enforce monotonic increasing envelope (roll back)
    #for col in velocity_cols:
    #    df_clean[col] = np.maximum.accumulate(df_clean[col].to_numpy())

    return df_clean.reset_index(drop=True)

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

        vel_tail = vel[5:]  # Skip first 5 points
        i_min = np.where(vel_tail == vel_tail.min())[0][-1] + 5  # Adjust index back
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
# FREESTREAM CALCULATION (xL_neg2)
# ============================================================
if "xL_neg2" not in sheet_names:
    raise RuntimeError("Sheet 'xL_neg2' not found.")

df_fs = pd.read_excel(excel_file, sheet_name="xL_neg2")
df_fs = df_fs.sort_values(Y_COL)

df_fs_tail = df_fs.iloc[len(df_fs) // 2 :]
velocitymagavg_fs = df_fs_tail[VELMAGAVG_COL].mean()
velocityxavg_fs = df_fs_tail[VELXAVG_COL].mean()

print("========================================")
print("Freestream values")
print(f"velocitymagavg_fs = {velocitymagavg_fs:.6f}")
print(f"velocityxavg_fs   = {velocityxavg_fs:.6f}")
print("========================================")

# ============================================================
# NORMALIZED XLSX OUTPUT
# ============================================================
norm_xlsx = os.path.join(output_dir, "normalized_velocity_profiles.xlsx")
writer = pd.ExcelWriter(norm_xlsx, engine="xlsxwriter")

pd.DataFrame({
    "quantity": ["velocitymagavg", "velocityxavg"],
    "value": [velocitymagavg_fs, velocityxavg_fs]
}).to_excel(writer, sheet_name="freestream", index=False)

# ============================================================
# PROCESS SHEETS
# ============================================================
# Map of normalized velocity columns to readable names for titles/files
normalized_cols = {
    "velocityx_norm": "Velocity X",
    "velocityxavg_norm": "Velocity X Avg",
    "velocitymag_norm": "Velocity Mag",
    "velocitymagavg_norm": "Velocity Mag Avg"
}

# results dictionary: keys are (norm_col, (upper, lower))
results = {}

for norm_col in normalized_cols.keys():
    for threshold in THRESHOLDS:
        results[(norm_col, threshold)] = []

for sheet in sheet_names:
    if sheet == "xL_neg2":
        continue

    df = pd.read_excel(excel_file, sheet_name=sheet)
    xL = parse_xL(sheet)

    df_clean = clean_velocity_dataframe(
        df,
        y_col=Y_COL,
        velocity_cols=VELOCITY_COLS,
        duplicate_ref_col=VELMAGAVG_COL
    )

    y = df_clean[Y_COL].to_numpy()

    # Normalize
    df_clean["velocityx_norm"] = df_clean[VELX_COL] / velocityxavg_fs
    df_clean["velocityxavg_norm"] = df_clean[VELXAVG_COL] / velocityxavg_fs
    df_clean["velocitymag_norm"] = df_clean[VELMAG_COL] / velocitymagavg_fs
    df_clean["velocitymagavg_norm"] = df_clean[VELMAGAVG_COL] / velocitymagavg_fs

    # Write Excel sheet
    df_clean.to_excel(writer, sheet_name=sheet, index=False)

    # Thickness calculations for all normalized columns
    for norm_col, nice_name in normalized_cols.items():
        vel_used = df_clean[norm_col].to_numpy()
        for upper, lower in THRESHOLDS:
            thickness, lower_vel_for_dat = find_thickness_robust(y, vel_used, upper, lower)
            results[(norm_col, (upper, lower))].append((xL, thickness, lower_vel_for_dat))

writer.close()


# ============================================================
# OUTPUT DAT FILES + PLOTS
# ============================================================
for (norm_col, (upper, lower)), data in results.items():
    data = np.array(sorted(data, key=lambda x: x[0]))  # sort by xL
    nice_name = normalized_cols[norm_col]

    # DAT file path in subfolder
    dat_path = os.path.join(
        dat_dir, f"thickness_{norm_col}_{int(upper*100)}_{int(lower*100)}.dat"
    )
    np.savetxt(
        dat_path,
        data,
        header="xL thickness lower_vel_for_dat",
        comments=""
    )

    # Plot path in subfolder
    plt.figure()
    plt.plot(data[:, 0], data[:, 1], marker="o")
    plt.xlabel("x/L")
    plt.ylabel("Shear Layer Thickness")
    plt.title(f"{nice_name} - {int(upper*100)}% / {int(lower*100)}% Thickness")
    plt.grid(True)
    plt.tight_layout()

    plot_path = os.path.join(
        plots_dir, f"thickness_{norm_col}_{int(upper*100)}_{int(lower*100)}.png"
    )
    plt.savefig(plot_path, dpi=300)
    plt.close()


messagebox.showinfo(
    "Complete",
    "Processing complete.\n"
    "• Single-pass cleaned normalized workbook written\n"
    "• Robust shear-layer thickness extracted\n"
    "• DAT files and plots saved"
)
