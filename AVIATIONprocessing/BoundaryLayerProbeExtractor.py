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
    "temperature",
    "temperatureavg",
    "density",
    "densityavg",
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
LINE_RESOLUTION = 1000

# --- Probe line definitions ---
# label : {start:[x,y,z], end:[x,y,z]}
PROBE_LINES = {
    #Midline Probe
    "xL_BL_mid": {
        "start": [2.031503, 0.018671, 0.0], 
        "end":   [2.031503, 0.177397, 0.0], 
    },
    # 1 Injector closer to nearwall in CFD 
    "xL_BL_inj2": { 
        "start": [2.031503, 0.018671, 0.0254], 
        "end":   [2.031503, 0.177397, 0.0254], 
    },
    # 1 Injector closer to farwall in CFD 
    "xL_BL_inj4": {
        "start": [2.031503, 0.018671, -0.0254], 
        "end":   [2.031503, 0.177397, -0.0254], 
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
