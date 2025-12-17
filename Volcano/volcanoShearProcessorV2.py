from paraview.simple import *
import os

# ============================================================
# ======================= USER INPUT =========================
# ============================================================

INPUT_FILE = "/home/bollerma/LESdata/SSWT/fullCav/timeSensitivityStudy/test1t/test1tM2SSWT_000/latest.volcano"
OUTPUT_DIR = "/home/bollerma/LESdata/SSWT/fullCav/timeSensitivityStudy/test1t/OUTPUT"

SCALARS = [
    "reynoldsstressxx", "reynoldsstressyy", "reynoldsstresszz",
    "reynoldsstressxy", "reynoldsstressxz", "reynoldsstressyz",
    "velocityx", "velocityxavg", "tke", "pressureavg"
]

ENABLE_SCHLIEREN = True
DENSITY_NAME = "density"

SCHLIEREN_COMPONENTS = {
    "Schlieren_dRho_dY": "delRho[1]",
    "Schlieren_dRho_dZ": "delRho[2]"
}

YZ_SLICE_X = [
    2.011691, 2.080109, 2.114318, 2.15057954, 2.16015806,
    2.1690524, 2.1793151, 2.18889362, 2.19847214,
    2.20736648, 2.216945, 2.307804104
]
XZ_SLICE_Z = [-0.0381, 0.0, 0.0381]

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

CAMERA_PRESETS = {
    "XZ_FAR": {
        "CameraPosition": [1.45479, 0.05995, 5.01102],
        "CameraFocalPoint": [1.45479, 0.05995, 0.0],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.73209,
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.29, 0.26], "Length": 0.33}
    },
    "XZ_NEAR": {
        "CameraPosition": [2.19226, 0.01823, 5.01119],
        "CameraFocalPoint": [2.19226, 0.01823, 0.0],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.06143,
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.31, 0.15], "Length": 0.33}
    },
    "XY": {
        "CameraPosition": [2.7452, 0.08874, 0.0],
        "CameraFocalPoint": [2.15058, 0.08874, 0.0],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.11684,
        "InteractionMode": "2D",
        "Colorbar": {"Orientation": "Vertical", "Position": [0.66, 0.38], "Length": 0.33}
    }
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ===================== LOAD DATA ============================
# ============================================================

vol = OpenDataFile(INPUT_FILE)
vol.CellArrayStatus = SCALARS + ([DENSITY_NAME] if ENABLE_SCHLIEREN else [])
source = vol

view = GetActiveViewOrCreate("RenderView")
view.Background = [1, 1, 1]

# ============================================================
# ===================== CAMERA ===============================
# ============================================================

def apply_camera(view, plane, field_region):
    if plane == "XZ":
        preset = "XZ_NEAR" if field_region == "NEAR" else "XZ_FAR"
    elif plane in ["XY", "YZ"]:
        preset = "XY"
    else:
        raise ValueError(f"Unsupported plane: {plane}")

    cam = CAMERA_PRESETS[preset]
    view.CameraParallelProjection = 1
    view.CameraPosition = cam["CameraPosition"]
    view.CameraFocalPoint = cam["CameraFocalPoint"]
    view.CameraViewUp = cam.get("CameraViewUp", [0,1,0])
    view.CameraParallelScale = cam["ParallelScale"]

    if "InteractionMode" in cam:
        view.InteractionMode = cam["InteractionMode"]

    return cam["Colorbar"]

# ============================================================
# ===================== SCHLIEREN ============================
# ============================================================

def create_schlieren_pipeline(slice_src, tag):
    grad = Gradient(Input=slice_src)
    grad.ResultArrayName = "delRho"

    outputs = {}

    mag = Calculator(Input=grad)
    mag.ResultArrayName = "magDelRho"
    mag.Function = "mag(delRho)"
    outputs["magDelRho"] = mag

    for name, expr in SCHLIEREN_COMPONENTS.items():
        c = Calculator(Input=grad)
        c.ResultArrayName = name
        c.Function = expr
        outputs[name] = c

    return outputs

# ============================================================
# ===================== SLICE ================================
# ============================================================

def create_slice(input_src, origin, normal, plane, field_region, fname_prefix, scalar, schlieren=False):

    sl = VolcanoSlice(Input=input_src)
    sl.SlicePoint = origin
    sl.SliceNormal = normal
    sl.InterpolatedField = scalar
    sl.MinMaxField = scalar
    sl.Crinkle = 0

    disp = Show(sl, view)
    disp.Representation = "Surface"

    cb_cfg = apply_camera(view, plane, field_region)

    if not schlieren:
        ColorBy(disp, ('POINTS', scalar))
        lut = GetColorTransferFunction(scalar)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)
        disp.SetScalarBarVisibility(view, True)

        Render(view)
        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname_prefix}_{scalar}.png"),
                       view, ImageResolution=IMG_RES)
        return

    schl = create_schlieren_pipeline(sl, fname_prefix)

    for arr, src in schl.items():
        ColorBy(disp, ('POINTS', arr))
        lut = GetColorTransferFunction(arr)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        bar = GetScalarBar(lut, view)
        bar.Title = arr
        bar.Orientation = cb_cfg["Orientation"]
        bar.Position = cb_cfg["Position"]
        bar.ScalarBarLength = cb_cfg["Length"]

        disp.SetScalarBarVisibility(view, True)
        Render(view)

        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname_prefix}_{arr}.png"),
                       view, ImageResolution=IMG_RES)

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for s in SCALARS:
    for x in YZ_SLICE_X:
        create_slice(source, [x,0,0], [1,0,0], "YZ", "FAR",
                     f"YZ_x{x:+0.5f}", s)

    for z in XZ_SLICE_Z:
        create_slice(source, [0,0,z], [0,0,1], "XZ", "NEAR",
                     f"XZ_near_z{z:+0.5f}", s)
        create_slice(source, [0,0,z], [0,0,1], "XZ", "FAR",
                     f"XZ_far_z{z:+0.5f}", s)

if ENABLE_SCHLIEREN:
    for x in YZ_SLICE_X:
        create_slice(source, [x,0,0], [1,0,0], "YZ", "FAR",
                     f"YZ_x{x:+0.5f}_Schlieren", DENSITY_NAME, schlieren=True)

    for z in XZ_SLICE_Z:
        create_slice(source, [0,0,z], [0,0,1], "XZ", "NEAR",
                     f"XZ_near_z{z:+0.5f}_Schlieren", DENSITY_NAME, schlieren=True)
        create_slice(source, [0,0,z], [0,0,1], "XZ", "FAR",
                     f"XZ_far_z{z:+0.5f}_Schlieren", DENSITY_NAME, schlieren=True)

print("\n✅ All slices and Schlieren components completed successfully.")
