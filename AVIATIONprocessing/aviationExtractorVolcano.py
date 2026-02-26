from paraview.simple import *
import os

# ============================================================
# ====================== USER SETTINGS =======================
# ============================================================

# --- Input volcano file (Edit prior to executing) ---
VOLCANO_FILE = r"/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD00/RD00_004/latest.volcano"

# --- Output directory ---
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/RDsteps/testOutput"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the volcano file ---
POINT_ARRAYS = [
    "velocityxavg",
    "velocityyavg",
    "velocityzavg",
    "qcriterion",
    "reynoldsstressxx",
    "reynoldsstressxy",
    "reynoldsstressxz",
    "reynoldsstressyy",
    "reynoldsstressyz",
    "reynoldsstresszz",
    "tke",
    "vorticityX",
    "vorticityY", 
    "vorticityZ",
    "vorticityXavg", 
    "vorticityYavg", 
    "vorticityZavg", 
    "vorticityMagavg",
    "vorticityMag"

]

# --- Z-plane slice location ---
SLICE_Z0 = 0.0
SLICE_Z25 = 0.0381
SLICE_Z75 = -0.0381

# --- Line resolution ---
LINE_RESOLUTION = 500

# --- Probe line definitions ---
# label : {start:[x,y,z], end:[x,y,z]}
PROBE_LINES = {
    "xL0p03": {
        "start": [2.15058, 0.0, 0.0],
        "end":   [2.15058, 0.037186, 0.0],
    },
    "xL0p17": {
        "start": [2.16016, 0.0, 0.0],
        "end":   [2.16016, 0.037186, 0.0],
    },
    "xL0p3": {
        "start": [2.169052, 0.0, 0.0],
        "end":   [2.169052, 0.037186, 0.0],
    },
    "xL0p45": {
        "start": [2.1793151, 0.0, 0.0],
        "end":   [2.1793151, 0.037186, 0.0],
    },
    "xL0p59": {
        "start": [2.18889362, 0.0, 0.0],
        "end":   [2.18889362, 0.037186, 0.0],
    },
    "xL0p73": {
        "start": [2.198472, 0.001645, 0.0],
        "end":   [2.198472, 0.038831, 0.0],
    },
    "xL0p86": {
        "start": [2.20736648, 0.005329, 0.0],
        "end":   [2.20736648, 0.042515, 0.0],
    },
    "xL1": {
        "start": [2.216945, 0.009296, 0.0],
        "end":   [2.216945, 0.046527, 0.0],
    },
    "xL1p2": {
        "start": [2.2306286, 0.014965, 0],
        "end":   [2.2306286, 0.052151, 0],
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
# ====================== SLICES ===========================
# ============================================================

# ====================== MIDPLANE SLICE ====================
slice_z0 = VolcanoSlice(registrationName="Z0_Slice", Input=volcano)
slice_z0.SlicePoint = [0.0, 0.0, SLICE_Z0]
slice_z0.SliceNormal = [0.0, 0.0, 1.0]

# ====================== Z/w = 0.25 SLICE ====================

slice_z25 = VolcanoSlice(registrationName="Z25_Slice", Input=volcano)
slice_z25.SlicePoint = [0.0, 0.0, SLICE_Z25]
slice_z25.SliceNormal = [0.0, 0.0, 1.0]


# ====================== Z/w = 0.75 SLICE ====================

slice_z75 = VolcanoSlice(registrationName="Z75_Slice", Input=volcano)
slice_z75.SlicePoint = [0.0, 0.0, SLICE_Z75]
slice_z75.SliceNormal = [0.0, 0.0, 1.0]

# collects slices to loop
SLICES = [
    ("MP", slice_z0, SLICE_Z0),
    ("z25", slice_z25, SLICE_Z25),
    ("z75", slice_z75, SLICE_Z75),
]
# ============================================================
# =================== PROBE EXTRACTION =======================
# ============================================================

for slice_tag, slice_obj, z_val in SLICES:
    print(f"Processing slice {slice_tag} at z = {z_val}")

    for label, line_def in PROBE_LINES.items():

        print(f"Extracting {label} on {slice_tag}...")

        # copies endpoints and sets z to current slice z
        p1 = list(line_def["start"])
        p2 = list(line_def["end"])
        p1[2] = z_val
        p2[2] = z_val

        pol = PlotOverLine(
            Input=slice_obj
        )
        pol.Point1 = p1
        pol.Point2 = p2
        pol.Resolution = LINE_RESOLUTION

        line_name = f"{label}_{slice_tag}"
        RenameSource(line_name, pol)

        output_file = os.path.join(
            OUTPUT_DIR, f"{line_name}.csv"
        )

        # Export to Excel
        SaveData(
            output_file,
            proxy=pol,
            Precision=6
        )

        # Cleanup
        Delete(pol)

print("All probe lines extracted successfully for all slices.")
