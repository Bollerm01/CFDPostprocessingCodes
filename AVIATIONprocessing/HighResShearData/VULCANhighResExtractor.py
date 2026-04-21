from paraview.simple import *
import os
import numpy as np
import csv
import pandas as pd

# ---------------- USER SETTINGS ----------------
INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
CASE = "CAVmix_SSWT_r0_noinject"
INPUT_FILE = rf"{INPUT_ROOT}\{CASE}\iteration-009\Plot_files\vulcan_solution.plt"

OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\Paper Results\finalData\VULCAN\HighResShearData"
OUTPUT_DIR = os.path.join(OUTPUT_ROOT, CASE)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Reference velocity for normalization (update as needed)
V_REF = 694.0

# --- Z-plane slice location for probes (all lines will be at this z) ---
SLICE_Z = 0.0127

# --- Number of probe lines between xL_0p03 and xL1 ---
N_PROBE_LINES = 13  # includes endpoints

# x/L values corresponding to the first and last line
X_OVER_L_START = 0.03
X_OVER_L_END   = 1.0

# ============================================================
# ========== BASELINE LINES TO INTERPOLATE BETWEEN ===========
# ============================================================

# Use your corrected xL_0p03 and xL_1 definitions as the endpoints
# xL_0p03
start_0 = [0.465522, -0.0218, SLICE_Z]
end_0   = [0.465522,  0.015387, SLICE_Z]

# xL_1
start_1 = [0.53165, -0.0153, SLICE_Z]
end_1   = [0.53165,  0.021882, SLICE_Z]

# Optional: US line definition (x, y only; z from SLICE_Z)
US_X = 0.455  # <-- put your correct value here if needed
US_Y_START = -0.005  # example placeholders
US_Y_END   =  0.035  # example placeholders

# ============================================================
# ========== VARIABLES TO LOAD FROM VULCAN FILE ==============
# ============================================================

POINT_ARRAYS = [
    'U_velocity_m_s',
    'X',
    'Y',
    'Z',
    'zone2/U_velocity_m_s',
    'zone2/X',
    'zone2/Y',
    'zone2/Z'
]

LINE_RESOLUTION = 500
ACTIVE_ZONES = ["zone1", "zone2"]

# ---------------- LOAD Tecplot ----------------
reader = VisItTecplotBinaryReader(
    registrationName=CASE,
    FileName=[INPUT_FILE]
)
reader.Set(
    MeshStatus=ACTIVE_ZONES,
    PointArrayStatus=POINT_ARRAYS
)
reader.UpdatePipeline()

# ---------------- CALCULATE VELOCITY NORM (ZONE2 U / V_REF) -------------
vel_norm_calc = Calculator(registrationName='U_velocity_norm', Input=reader)
vel_norm_calc.Function = f'"zone2/U_velocity_m_s" / {V_REF}'
vel_norm_calc.ResultArrayName = "U_velocity_norm"
vel_norm_calc.UpdatePipeline()

# ---------------- PASSTHROUGH: EXPORT RELEVANT ARRAYS ----------------
pa = PassArrays(registrationName='ExportData', Input=vel_norm_calc)
pa.PointDataArrays = [
    'U_velocity_m_s',        # zone1 U
    'X',
    'Y',
    'Z',
    'zone2/U_velocity_m_s',  # zone2 U
    'zone2/X',
    'zone2/Y',
    'zone2/Z',
    'U_velocity_norm'        # normalized U from zone2
]
pa.UpdatePipeline()

# ============================================================
# ========== BUILD PROBE_LINES BY INTERPOLATION ==============
# ============================================================

PROBE_LINES = {}

for i in range(N_PROBE_LINES):
    t = float(i) / float(N_PROBE_LINES - 1)  # 0 to 1

    # Interpolate between start_0 and start_1
    start_interp = [
        (1.0 - t) * start_0[j] + t * start_1[j]
        for j in range(3)
    ]
    # Interpolate between end_0 and end_1
    end_interp = [
        (1.0 - t) * end_0[j] + t * end_1[j]
        for j in range(3)
    ]

    # Ensure z is exactly SLICE_Z
    start_interp[2] = SLICE_Z
    end_interp[2]   = SLICE_Z

    # Corresponding x/L value between 0.03 and 1.0
    x_over_L = X_OVER_L_START + t * (X_OVER_L_END - X_OVER_L_START)

    # --- Labeling rules ---
    if i == 0:
        label = "xL_0p03"
    elif i == N_PROBE_LINES - 1:
        label = "xL1"
    else:
        val = int(round(x_over_L * 100))   # e.g., 0.11 -> 11
        label = f"xL_0p{val:02d}"

    PROBE_LINES[label] = {
        "start": start_interp,
        "end":   end_interp,
    }

# Optional US line
# PROBE_LINES["US"] = {
#     "start": [US_X, US_Y_START, SLICE_Z],
#     "end":   [US_X, US_Y_END,   SLICE_Z],
# }

# ---------------- FUNCTION: LINE EXTRACTION ----------------
def extract_line(input_proxy, line_def, label):
    pol = PlotOverLine(Input=input_proxy)
    pol.Point1 = line_def["start"]
    pol.Point2 = line_def["end"]
    pol.Resolution = LINE_RESOLUTION
    RenameSource(label, pol)

    pol.UpdatePipeline()

    output_file = os.path.join(
        OUTPUT_DIR, f"{label}.csv"
    )

    SaveData(
        output_file,
        proxy=pol,
        Precision=6
    )

# ---------------- GENERATE LINE PROFILES ----------------
for label, line_def in PROBE_LINES.items():
    extract_line(pa, line_def, label)

print(f"\nProfiles extracted successfully.")
print(f"   Zones used: {ACTIVE_ZONES}")
print(f"   Variables: {pa.PointDataArrays}")
print(f"   Output directory: {OUTPUT_DIR}")
print(f"   Number of probe lines (including US): {len(PROBE_LINES)}")