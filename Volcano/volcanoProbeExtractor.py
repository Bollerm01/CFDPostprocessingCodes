from paraview.simple import *
import os

# ============================================================
# ====================== USER SETTINGS =======================
# ============================================================

# --- Input volcano file ---
#EDIT WHEN ITERATING THROUGH
VOLCANO_FILE = r"/home/bollerma/LESdata/SSWT/fullCav/meshStudy/test5/test5M2SSWT_001/latest.volcano"

# --- Output directory ---
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/meshStudy/probeOutput"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the volcano file ---
POINT_ARRAYS = [
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
    "velocityy",
    "velocityyavg",
    "velocityz",
    "velocityzavg",
    "pressure",
    "pressureavg",
    "qcriterion",
    "reynoldsstressxx",
    "reynoldsstressxy",
    "reynoldsstressxz",
    "reynoldsstressyy",
    "reynoldsstressyz",
    "reynoldsstresszz",
    "tke"
]

# --- Z-plane slice location ---
SLICE_Z = 0.0

# --- Line resolution ---
LINE_RESOLUTION = 500

# --- Probe line definitions ---
# label : {start:[x,y,z], end:[x,y,z]}
PROBE_LINES = {
    "xL_neg2": {
        "start": [2.01169, 0.01884, 0.0],
        "end":   [2.01169, 0.05603, 0.0],
    },
    "xL_0p03": {
        "start": [2.15058, 0.0, 0.0],
        "end":   [2.15058, 0.03719, 0.0],
    },
    "xL_0p17": {
        "start": [2.16016, 0.0, 0.0],
        "end":   [2.16016, 0.03719, 0.0],
    },
    "xL_0p3": {
        "start": [2.16905, 0.0, 0.0],
        "end":   [2.16905, 0.03719, 0.0],
    },
    "xL_0p45": {
        "start": [2.17932, 0.0, 0.0],
        "end":   [2.17932, 0.03719, 0.0],
    },
    "xL_0p59": {
        "start": [2.18889, 0.0, 0.0],
        "end":   [2.18889, 0.03719, 0.0],
    },
    "xL_0p73": {
        "start": [2.19847, 0.00165, 0.0],
        "end":   [2.19847, 0.03883, 0.0],
    },
    "xL_0p86": {
        "start": [2.20737, 0.00533, 0.0],
        "end":   [2.20737, 0.04252, 0.0],
    },
    "xL_1": {
        "start": [2.21695, 0.0093, 0.0],
        "end":   [2.21695, 0.04648, 0.0],
    },
    "xL_1p2": {
        "start": [2.230629, 0.024791, -0.0381],
        "end":   [2.230629, 0.014965, -0.0381],
    }
}


# ============================================================
# ====================== LOAD DATA ===========================
# ============================================================

volcano = FileSeriesReader(
    registrationName='VolcanoData',
    FileNames=[VOLCANO_FILE]
)
volcano.CellArrayStatus = POINT_ARRAYS


# ============================================================
# ====================== Z=0 SLICE ===========================
# ============================================================

slice_z0 = VolcanoSlice(registrationName="Z0_Slice", Input=volcano)
slice_z0.SlicePoint = [0.0, 0.0, SLICE_Z]
slice_z0.SliceNormal = [0.0, 0.0, 1.0]

# ============================================================
# =================== PROBE EXTRACTION =======================
# ============================================================

for label, line_def in PROBE_LINES.items():

    print(f"Extracting {label}...")

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

    # Export to Excel
    SaveData(
        output_file,
        proxy=pol,
        Precision=6
    )

    # Cleanup
    Delete(pol)

print("All probe lines extracted successfully.")
