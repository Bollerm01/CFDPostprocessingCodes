# Template file for the purpose of extracting lines from the VULCAN .plt files
# Output: Format of "XXXDdataCombined.xlsx" from dataCombiner_fullRunV2.py
# Input: VULCAN .plt file

# TEMPLATE CODE - NEED TO CHANGE
from paraview.simple import *
import os
import numpy as np
import csv

# ---------------- USER SETTINGS ----------------
INPUT_FILE = r"D:\BollerCFD\AVIATION CFD\CAV_MIX_act_RC19_3d_no_inject\iteration-006\Plot_files\RC19_full_width_domain.plt"
OUTPUT_DIR = r"D:\BollerCFD\AVIATION CFD\output"

# X-locations for line extraction
X_LOCATIONS_FOR_LINE = [0.255919, 0.274087, 0.303022, 0.32119]

# Y and Z bounds for line extraction
Y_MIN = -0.025
Y_MAX = 0.005
Z_PLANE = 0.0762

# Line sampling resolution
LINE_RESOLUTION = 1000

# ---------------- VARIABLES ----------------
# Reynolds stress and TKE variable names per zone
REY_XY_ZONE1 = "Reynolds_stress_xy"
REY_YZ_ZONE1 = "Reynolds_stress_yz"
REY_XZ_ZONE1 = "Reynolds_stress_xz"
TKE_ZONE1    = "Turbulent_kinetic_energy"

REY_XY_ZONE2 = "zone2/Reynolds_stress_xy"
REY_YZ_ZONE2 = "zone2/Reynolds_stress_yz"
REY_XZ_ZONE2 = "zone2/Reynolds_stress_xz"
TKE_ZONE2    = "zone2/Turbulent_kinetic_energy"

STRESS_NAMES = [
    REY_XY_ZONE1, REY_YZ_ZONE1, REY_XZ_ZONE1, TKE_ZONE1,
    REY_XY_ZONE2, REY_YZ_ZONE2, REY_XZ_ZONE2, TKE_ZONE2
]

# Zones to include
ACTIVE_ZONES = ["zone1", "zone2"]

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ---------------- LOAD Tecplot ----------------
reader = VisItTecplotBinaryReader(
    registrationName='RC19_full_width_domain.plt',
    FileName=[INPUT_FILE]
)
reader.Set(
    MeshStatus=ACTIVE_ZONES,
    PointArrayStatus=STRESS_NAMES
)
reader.UpdatePipeline()

# ---------------- FUNCTION: LINE EXTRACTION ----------------
def extract_line_filtered(input_proxy, xloc, y_min, y_max, z_plane, filename):
    """
    Extracts line data along Y at fixed X,Z and removes rows
    where both zones have NaN for all Reynolds stresses and TKE.
    """
    line = PlotOverLine(Input=input_proxy)
    line.Point1 = [xloc, y_min, z_plane]
    line.Point2 = [xloc, y_max, z_plane]
    line.Resolution = LINE_RESOLUTION
    line.UpdatePipeline()

    data = servermanager.Fetch(line)
    pd = data.GetPointData()

    y_coords = np.array([data.GetPoint(i)[1] for i in range(data.GetNumberOfPoints())])

    # Helper to safely get array values
    def get_array_values(array_name):
        arr = pd.GetArray(array_name)
        if not arr:
            return np.full(len(y_coords), np.nan)
        return np.array([arr.GetValue(i) if not np.isnan(arr.GetValue(i)) else np.nan for i in range(len(y_coords))])

    # Retrieve each variable
    vars_dict = {name: get_array_values(name) for name in STRESS_NAMES}

    # Mask: keep rows where at least one zone has valid data
    mask = np.zeros(len(y_coords), dtype=bool)
    for v in vars_dict.values():
        mask |= ~np.isnan(v)
    y_filtered = y_coords[mask]

    # Apply mask to each variable
    vars_filtered = {k: v[mask] for k, v in vars_dict.items()}

    # Write CSV
    output_path = os.path.join(OUTPUT_DIR, filename)
    with open(output_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Y"] + STRESS_NAMES)
        for i in range(len(y_filtered)):
            row = [y_filtered[i]] + [vars_filtered[name][i] for name in STRESS_NAMES]
            writer.writerow(row)

    Delete(line)

# ---------------- GENERATE CLEAN LINE PROFILES ----------------
for x in X_LOCATIONS_FOR_LINE:
    output_name = f"ReStress_TKE_vs_y_x{x:+0.5f}_z{Z_PLANE:+0.5f}_filtered.csv"
    extract_line_filtered(reader, x, Y_MIN, Y_MAX, Z_PLANE, output_name)

print(f"\n✅ Clean Reynolds stresses and TKE profiles extracted successfully.")
print(f"   Zones used: {ACTIVE_ZONES}")
print(f"   Variables: {STRESS_NAMES}")
print(f"   Output directory: {OUTPUT_DIR}")
