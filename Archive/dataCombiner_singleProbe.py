import pandas as pd
import re
import os
from tkinter import Tk, filedialog

# ---------------------------------------------------------------
# Utility: extract probe number from strings like "probe00000"
# ---------------------------------------------------------------
def extract_probe_number(name):
    match = re.search(r'probe0*(\d+)', str(name))
    return int(match.group(1)) if match else None

# ---------------------------------------------------------------
# GUI: Get root directory
# ---------------------------------------------------------------
Tk().withdraw()
root_dir = r"E:\Boller CFD\AVIATION CFD\TimeSensitivityData\test1tM2SSWT_000"

# ---------------------------------------------------------------
# GUI: Select coordinates file
# ---------------------------------------------------------------
coords_path = filedialog.askopenfilename(
    title="Select the coords file (e.g., XX.coords.dat)",
    initialdir=root_dir,
    filetypes=[("DAT files", "*.dat"), ("All files", "*.*")]
)

if not coords_path:
    raise SystemExit("No coords file selected. Exiting.")

# ---------------------------------------------------------------
# GUI: Select probe data files
# ---------------------------------------------------------------
data_paths = filedialog.askopenfilenames(
    title="Select the probe data files (e.g., XX.YY.dat)",
    initialdir=root_dir,
    filetypes=[("DAT files", "*.dat"), ("All files", "*.*")]
)

if not data_paths:
    raise SystemExit("No data files selected. Exiting.")

# ---------------------------------------------------------------
# Determine dynamic prefix (before the first '.')
# ---------------------------------------------------------------
coords_filename = os.path.basename(coords_path)
prefix = coords_filename.split(".")[0]
output_file = os.path.join(root_dir, f"{prefix}dataCombined.xlsx")

# ---------------------------------------------------------------
# Load coords file
# ---------------------------------------------------------------
coords = pd.read_csv(
    coords_path,
    sep=r"\s+",
    comment="#",            # skip header line starting with #
    header=None,
    usecols=[0, 1, 2, 3],  # keep only number, x, y, z
    names=["probe_num", "x", "y", "z"]
)
coords.set_index("probe_num", inplace=True)

# ---------------------------------------------------------------
# Process each selected data file (wide-form)
# ---------------------------------------------------------------
for fpath in data_paths:
    filename = os.path.basename(fpath)
    parts = filename.split(".")
    variable_name = parts[1] if len(parts) > 2 else filename

    # Load wide-form probe data
    df = pd.read_csv(fpath, sep=r"\s+", comment="#", header=None)
    
    # Extract the header manually (first row of file)
    with open(fpath, "r") as f:
        header_line = f.readline().strip()
    header_cols = header_line.lstrip("#").split()
    
    df.columns = header_cols  # set proper column names

    # Take last timestep row
    last_row = df.iloc[-1, 1:]  # skip 'time' column

    # Map probe columns to probe numbers
    probe_nums = [extract_probe_number(col) for col in last_row.index]

    # Assign values to coords
    coords[variable_name] = pd.Series(last_row.values, index=probe_nums)

# ---------------------------------------------------------------
# Save final combined Excel file
# ---------------------------------------------------------------
coords.to_excel(output_file)

print("\n------------------------------------------")
print(f" Combined file saved as: {output_file}")
print("------------------------------------------")

