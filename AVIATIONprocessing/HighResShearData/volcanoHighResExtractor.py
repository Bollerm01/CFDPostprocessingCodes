from paraview.simple import *
import os

# ============================================================
# ====================== USER SETTINGS =======================
# ============================================================

# --- Input volcano file ---
# VOLCANO_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD00/RD00_004/latest.volcano"
# VOLCANO_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD17/RD17_022/latest.volcano" # RD17 Path
VOLCANO_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD52/RD52_057/latest.volcano" # RD52 Path

# --- Output directory ---
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/RDsteps/highResShearOutput/RD52"  # Change tailing folder
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the volcano file ---
POINT_ARRAYS = [
    "velocitymag",
    "velocitymagavg",
    "velocityx",
    "velocityxavg", 
    "tke"
]

# --- Line resolution ---
LINE_RESOLUTION = 500

# --- Number of probe lines between xL_0p03 and xL1 (inclusive) ---
N_PROBE_LINES = 25

# x/L range
X_OVER_L_START = 0.03
X_OVER_L_END   = 1.0

# --- Z planes and filename tags ---
# z = -0.0381  -> "_z75"
# z =  0.0     -> "_MP"
# z = +0.0381  -> "_z25"
PLANES = [
    ("_z75", -0.0381),
    ("_MP",   0.0),
    ("_z25",  0.0381),
]

# ============================================================
# ========== BASELINE LINES TO INTERPOLATE BETWEEN ===========
# ============================================================

# Base definition at z = 0; we'll adjust z per plane later.
# xL_0p03
start_0 = [2.15058, 0.0,     0.0]
end_0   = [2.15058, 0.03719, 0.0]

# xL1
start_1 = [2.21695, 0.0,     0.0]
end_1   = [2.21695, 0.04648, 0.0]  # Down to floor even though on ramp

# US line definition (x, y only; z comes from the plane)
US_X = 2.0801
US_Y_START = 0.018593
US_Y_END   = 0.055779

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
# =================== PROBE EXTRACTION =======================
# ============================================================

for plane_tag, plane_z in PLANES:
    print(f"Creating slice at z = {plane_z} ({plane_tag})")

    # Create slice for this z-plane
    slice_plane = VolcanoSlice(
        registrationName=f"Slice_{plane_tag}",
        Input=volcano
    )
    slice_plane.SlicePoint = [0.0, 0.0, plane_z]
    slice_plane.SliceNormal = [0.0, 0.0, 1.0]

    # Extract xL probe lines on this slice
    for label, line_def in PROBE_LINES.items():
        full_label = f"{label}{plane_tag}"
        print(f"  Extracting {full_label}...")

        # Copy start/end and set their z to the plane z to be explicit
        start_pt = [line_def["start"][0], line_def["start"][1], plane_z]
        end_pt   = [line_def["end"][0],   line_def["end"][1],   plane_z]

        pol = PlotOverLine(Input=slice_plane)
        pol.Point1 = start_pt
        pol.Point2 = end_pt
        pol.Resolution = LINE_RESOLUTION

        RenameSource(full_label, pol)

        output_file = os.path.join(OUTPUT_DIR, f"{full_label}.csv")

        # Export to CSV
        SaveData(
            output_file,
            proxy=pol,
            Precision=6,
        )

        # Cleanup probe filter
        Delete(pol)

    # --------------------------------------------------------
    # Additional "US" line for each plane:
    # US_MP, US_z25, US_z75
    # --------------------------------------------------------
    us_label = f"US{plane_tag}"  # -> "US_MP", "US_z25", "US_z75"
    print(f"  Extracting {us_label}...")

    us_start = [US_X, US_Y_START, plane_z]
    us_end   = [US_X, US_Y_END,   plane_z]

    us_pol = PlotOverLine(Input=slice_plane)
    us_pol.Point1 = us_start
    us_pol.Point2 = us_end
    us_pol.Resolution = LINE_RESOLUTION

    RenameSource(us_label, us_pol)

    us_output_file = os.path.join(OUTPUT_DIR, f"{us_label}.csv")

    SaveData(
        us_output_file,
        proxy=us_pol,
        Precision=6,
    )

    Delete(us_pol)

    # Cleanup slice for this plane
    Delete(slice_plane)

print("All probe lines (including US_MP, US_z25, US_z75) extracted successfully for all z-planes.")