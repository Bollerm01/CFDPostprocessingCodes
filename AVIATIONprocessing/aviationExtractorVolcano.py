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
    ("z0", slice_z0, SLICE_Z0),
    ("z25", slice_z25, SLICE_Z25),
    ("z75", slice_z75, SLICE_Z75),
]
# ============================================================
# =================== PROBE EXTRACTION =======================
# ============================================================

for slice_tag, slice_obj, z_val in SLICES:
    print(f"Processing slice {slice_tag} at z = {z_val}")

    for label, line_def in PROBE_LINES.items():

        print(f"Extracting {label} pn {slice_tag}...")

        # copies endpoints and sets z to current slice z
        p1 = list(line_def["start"])
        p2 = list(line_def["end"])
        p1[2] = z_val
        p2[2] = z_val

        pol = PlotOverLine(
            Input=slice_z0
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
