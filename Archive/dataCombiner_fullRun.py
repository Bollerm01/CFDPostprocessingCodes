# Code to take data from line probes, pull the last timesteps data, and concatenate to the probe point coordinates
# Iterates through for all of the probes within a given simulation
# Outputs to an .xlsx file for each probe

import pandas as pd
import re
import os
from tkinter import Tk, filedialog
from collections import defaultdict

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
root_dir = filedialog.askdirectory(title="Select the root directory containing all data sets")

if not root_dir:
    raise SystemExit("No root directory selected. Exiting.")

# ---------------------------------------------------------------
# Select all coords files in directory
# ---------------------------------------------------------------
coords_files = filedialog.askopenfilenames(
    title="Select all coords files",
    initialdir=root_dir,
    filetypes=[("DAT files", "*.dat"), ("All files", "*.*")]
)

if not coords_files:
    raise SystemExit("No coords files selected. Exiting.")

# ---------------------------------------------------------------
# Select all probe data files
# ---------------------------------------------------------------
data_files = filedialog.askopenfilenames(
    title="Select all probe data files",
    initialdir=root_dir,
    filetypes=[("DAT files", "*.dat"), ("All files", "*.*")]
)

if not data_files:
    raise SystemExit("No probe data files selected. Exiting.")

# ---------------------------------------------------------------
# Group files by leading prefix before first '.' 
# e.g., US.XXX.dat -> prefix = 'US'
# ---------------------------------------------------------------
def get_prefix(filename):
    return os.path.basename(filename).split(".")[0]

coords_groups = defaultdict(list)
for f in coords_files:
    prefix = get_prefix(f)
    coords_groups[prefix].append(f)

data_groups = defaultdict(list)
for f in data_files:
    prefix = get_prefix(f)
    data_groups[prefix].append(f)

# ---------------------------------------------------------------
# Process each group
# ---------------------------------------------------------------
for prefix in coords_groups.keys():
    print(f"\nProcessing group: {prefix}")
    
    # Normally expect one coords file per group
    coords_path = coords_groups[prefix][0]

    # Load coords file
    coords = pd.read_csv(
        coords_path,
        sep=r"\s+",
        comment="#",
        header=None,
        usecols=[0, 1, 2, 3],
        names=["probe_num", "x", "y", "z"]
    )
    coords.set_index("probe_num", inplace=True)
    
    # Process all probe data files for this group
    for fpath in data_groups.get(prefix, []):
        filename = os.path.basename(fpath)
        parts = filename.split(".")
        variable_name = parts[1] if len(parts) > 2 else filename

        # Load wide-form probe data
        df = pd.read_csv(fpath, sep=r"\s+", comment="#", header=None)
        
        # Extract header manually (first line)
        with open(fpath, "r") as f:
            header_line = f.readline().strip()
        header_cols = header_line.lstrip("#").split()
        df.columns = header_cols

        # Take last timestep row
        last_row = df.iloc[-1, 1:]  # skip 'time' column

        # Map probe columns to probe numbers
        probe_nums = [extract_probe_number(col) for col in last_row.index]

        # Assign values to coords
        coords[variable_name] = pd.Series(last_row.values, index=probe_nums)
    
    # Sort by probe number to ensure proper order
    coords.sort_index(inplace=True)

    # Save Excel file
    output_file = os.path.join(root_dir, f"{prefix}_dataCombined.xlsx")
    coords.to_excel(output_file)
    print(f" -> Saved combined file for {prefix} as: {output_file}")

print("\n------------------------------------------")
print("All groups processed successfully.")
print("------------------------------------------")
