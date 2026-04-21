from paraview.simple import *
import os

# ============================================================
# ====================== USER SETTINGS =======================
# ============================================================

# --- Input volcano file ---
VOLCANO_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD00/RD00_004/latest.volcano"
# VOLCANO_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD17/RD17_022/latest.volcano" # RD17 Path
# VOLCANO_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD52/RD52_057/latest.volcano" # RD52 Path

# --- Output directory ---
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/RDsteps/highResShearOutput/RD00"  # Change tailing folder
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the volcano file ---
# Reduced to only the requested arrays
POINT_ARRAYS = [
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg",
]

# --- Z-plane slice location ---
SLICE_Z = 0.0

# --- Line resolution ---
LINE_RESOLUTION = 500

# --- Number of probe lines between xL_0p03 and xL1 (inclusive) ---
N_PROBE_LINES = 25

# x/L range
X_OVER_L_START = 0.03
X_OVER_L_END   = 1.0

# ============================================================
# ========== BASELINE LINES TO INTERPOLATE BETWEEN ===========
# ============================================================

# xL_0p03
start_0 = [2.15058, 0.0,     0.0]
end_0   = [2.15058, 0.03719, 0.0]

# xL1
start_1 = [2.21695, 0.0,     0.0]
end_1   = [2.21695, 0.4648, 0.0]  # Down to floor even though on ramp

# Build PROBE_LINES by linear interpolation between (start_0, end_0) and (start_1, end_1)
# parameter t runs from 0 to 1 over N_PROBE_LINES points.
PROBE_LINES = {}

for i in range(N_PROBE_LINES):
    t = float(i) / float(N_PROBE_LINES - 1)  # 0 to 1

    start_interp = [
        (1.0 - t) * start_0[j] + t * start_1[j]
        for j in range(3)
    ]
    end_interp = [
        (1.0 - t) * end_0[j] + t * end_1[j]
        for j in range(3)
    ]

    # Compute corresponding x/L value between 0.03 and 1.0
    x_over_L = X_OVER_L_START + t * (X_OVER_L_END - X_OVER_L_START)

    # --- Labeling rules ---
    # First line: xL_0p03
    # Last line:  xL1
    # Intermediate: xL_0pXX where XX are two digits of 100*x/L (e.g., 0.11 -> xL_0p11)
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

# ============================================================
# ====================== LOAD DATA ===========================
# ============================================================

volcano = FileSeriesReader(
    registrationName="VolcanoData",
    FileNames=[VOLCANO_FILE],
)

# Only load the requested arrays
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

    pol = PlotOverLine(Input=slice_z0)
    pol.Point1 = line_def["start"]
    pol.Point2 = line_def["end"]
    pol.Resolution = LINE_RESOLUTION

    RenameSource(label, pol)

    output_file = os.path.join(OUTPUT_DIR, f"{label}.csv")

    # Export to CSV
    SaveData(
        output_file,
        proxy=pol,
        Precision=6,
    )

    # Cleanup
    Delete(pol)

print("All probe lines extracted successfully.")