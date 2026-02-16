from paraview.simple import *
import os

# ============================================================
# File to take midline velocity probe measurements and
# floor/ceiling pressure line measurements
#
# Input : .volcano file
# Output: CSV files (one per probe line)
# ============================================================

# ============================================================
# ====================== USER SETTINGS =======================
# ============================================================

# --- Input volcano file ---
VOLCANO_FILE = r"/home/bollerma/LESdata/SSWT/fullCav/meshStudy/test15/test15M2SSWT_000/checkpoint.1262687.volcano"
#VOLCANO_FILE = r"E:\Boller CFD\AVIATION CFD\MeshSensitivityData\test14M2SSWT_000\checkpoint.1193017.volcano"

# --- Output directory ---
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/meshStudy/bulkProbeOutput/test15"
#OUTPUT_DIR = r"E:\Boller CFD\AVIATION CFD\MeshSensitivityData\bulkFloorCeilingMidlineData\test14"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the volcano file ---
POINT_ARRAYS = [
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
    "pressure",
    "pressureavg",
    "tke"
]

# --- Z-plane slice location ---
SLICE_Z = 0.0

# --- Line resolution ---
LINE_RESOLUTION = 500

# ============================================================
# ================= PROBE LINE DEFINITIONS ===================
# ============================================================
# Floor / Ceiling probe lines for SSWT M2 domain
# Midplane (Z = 0)

PROBE_LINES = {
    "FL1": {
        "start": [2.024618, 0.018743, 0.0],
        "end":   [2.148677, 0.018743, 0.0],
    },
    "FL2": {
        "start": [2.148677, 0.018743, 0.0],
        "end":   [2.148677, 0.00015, 0.0],
    },
    "FL3": {
        "start": [2.148677, 0.00015, 0.0],
        "end":   [2.194501, 0.00015, 0.0],
    },
    "FL4": {
        "start": [2.194501, 0.00015, 0.0],
        "end":   [2.239388, 0.018743, 0.0],
    },
    "FL5": {
        "start": [2.239388, 0.018743, 0.0],
        "end":   [2.548577, 0.018743, 0.0],
    },
    "CL1": {
        "start": [2.024618, 0.177227, 0.0],
        "end":   [2.548577, 0.177227, 0.0],
    },
    "CTRL1": {
        "start": [2.024618, 0.097985, 0.0],
        "end":   [2.548577, 0.097985, 0.0],
    }
}

# ============================================================
# ====================== LOAD DATA ===========================
# ============================================================

volcano = FileSeriesReader(
    registrationName="VolcanoData",
    FileNames=[VOLCANO_FILE]
)
volcano.CellArrayStatus = POINT_ARRAYS

# ============================================================
# ====================== Z = 0 SLICE =========================
# ============================================================

slice_z0 = VolcanoSlice(
    registrationName="Z0_Slice",
    Input=volcano
)
slice_z0.SlicePoint = [0.0, 0.0, SLICE_Z]
slice_z0.SliceNormal = [0.0, 0.0, 1.0]

# ============================================================
# =================== PROBE EXTRACTION =======================
# ============================================================

for label, line_def in PROBE_LINES.items():

    print(f"Extracting probe line: {label}")

    pol = PlotOverLine(
        Input=slice_z0
    )
    pol.Point1 = line_def["start"]
    pol.Point2 = line_def["end"]
    pol.Resolution = LINE_RESOLUTION

    RenameSource(label, pol)

    output_file = os.path.join(
        OUTPUT_DIR, f"{label}.csv"
    )

    SaveData(
        output_file,
        proxy=pol,
        Precision=6
    )

    Delete(pol)

print("All probe lines extracted successfully.")
