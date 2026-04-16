from paraview.simple import *
import os

# ============================================================
# ====================== USER SETTINGS =======================
# ============================================================

# --- Input volcano file (Edit prior to executing) ---
VOLCANO_FILE = r"/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD00/RD00_004/latest.volcano"

# --- Output directory (Edit prior to executing) ---
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/RDsteps/BLprobeOutput"

# ============================================================
# ============================================================
# ============================================================

os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the volcano file ---
POINT_ARRAYS = [
    "machnumberavg",
    "machnumber",
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

# --- X-plane slice location ---
SLICE_X = 2.031503

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
    # 1 Injector closer to farwall in CFD (ACTUAL PROBE LOC)
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

slice_x0 = VolcanoSlice(registrationName="X0_Slice", Input=volcano)
slice_x0.SlicePoint = [SLICE_X, 0.0, 0.0]
slice_x0.SliceNormal = [1.0, 0.0, 0.0]

# ============================================================
# =================== PROBE EXTRACTION =======================
# ============================================================

for label, line_def in PROBE_LINES.items():

    print(f"Extracting {label}...")

    pol = PlotOverLine(
        Input=slice_x0
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

print(f"All probe lines extracted successfully and saved in: {OUTPUT_DIR}.")
