# Script to extract Mach number and XYZ along a single probe line from a VULCAN.plt file
# Output: CSV file with columns: X, Y, Z, Mach_Number
# Input: VULCAN.plt file (zone2 volume mesh)

from paraview.simple import *
import os

# ---------------- USER SETTINGS ----------------
INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
CASE = "CAVmix_SSWT_r0_noinject"
INPUT_FILE = rf"{INPUT_ROOT}\{CASE}\iteration-009\Plot_files\vulcan_solution.plt"

OUTPUT_ROOT = r"E:\Boller CFD\GitHub\CFDPostprocessingCodes\TunnelDataProcessing"


# -------- USER-SELECTED PROBE LINE (change this label to choose line) --------
SELECTED_PROBE_LABEL = "BL_Pos"  

# --- Probe line definitions ---
# label : {start:[x,y,z], end:[x,y,z]}
PROBE_LINES = {
    "BL_Pos": {
        "start": [0.346456, 0.0, 0.0127],
        "end":   [0.346456, 0.05, 0.0127],
    }
}

# --- Line resolution ---
LINE_RESOLUTION = 500

# Zones to include (volume mesh solution only)
ACTIVE_ZONES = ["zone2"]

# --- Variables to load from the VULCAN file ---
# Only load what we need: Mach number and coordinates for zone2
POINT_ARRAYS = [
    'zone2/Mach_Number',
    'zone2/X',
    'zone2/Y',
    'zone2/Z'
]

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

# ---------------- PASS ONLY MACH AND XYZ ----------------
pa = PassArrays(registrationName='ExportData', Input=reader)
pa.PointDataArrays = [
    'zone2/Mach_Number',
    'zone2/X',
    'zone2/Y',
    'zone2/Z'
]
pa.UpdatePipeline()

# ---------------- FUNCTION: LINE EXTRACTION ----------------
def extract_line_single(input_proxy, line_def, label):
    """
    Extracts line data along the specified probe line and
    writes zone2 Mach number and XYZ to a CSV.
    """
    pol = PlotOverLine(Input=input_proxy)
    pol.Point1 = line_def["start"]
    pol.Point2 = line_def["end"]
    pol.Resolution = LINE_RESOLUTION
    RenameSource(label, pol)
    pol.UpdatePipeline()

    output_file = os.path.join(OUTPUT_ROOT, f"{label}_BL_Data_VULCAN.csv")

    SaveData(
        output_file,
        proxy=pol,
        Precision=6
    )

# ---------------- RUN FOR USER-SELECTED LINE ----------------
if SELECTED_PROBE_LABEL not in PROBE_LINES:
    raise ValueError(f"Selected probe label '{SELECTED_PROBE_LABEL}' not found in PROBE_LINES.")

line_def = PROBE_LINES[SELECTED_PROBE_LABEL]
extract_line_single(pa, line_def, SELECTED_PROBE_LABEL)

print(f"\nProbe line '{SELECTED_PROBE_LABEL}' extracted successfully.")
print(f"   Zones used: {ACTIVE_ZONES}")
print(f"   Variables exported: {pa.PointDataArrays}")
print(f"   Output file directory: {OUTPUT_ROOT}")