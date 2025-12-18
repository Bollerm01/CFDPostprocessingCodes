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

YZ_SLICE_X = [2.011691]
XY_SLICE_Z = [0.0]

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ===================== CAMERA PRESETS =======================
# ============================================================

CAMERA_PRESETS = {
    "XY_NEAR": {
        "CameraPosition":   [2.1922574427684838, 0.018226216790868725, 5.011192474629075],
        "CameraFocalPoint": [2.1922574427684838, 0.018226216790868725, 0.0],
        "CameraViewUp":     [0,1,0],
        "ParallelScale":    0.06142870916705136,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.31, 0.15],
            "Length":      0.33,
        }
    },
    "XY_FAR": {
        "CameraPosition":   [1.4547914383436304, 0.05994982668344116, 5.011016610690195],
        "CameraFocalPoint": [1.4547914383436304, 0.05994982668344116, 0.0],
        "CameraViewUp":     [0,1,0],
        "ParallelScale":    0.7320925072135284,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.29, 0.26],
            "Length":      0.33,
        }
    },
    "YZ": {
        "CameraPosition":   [2.745205, 0.0887413, 0.0],
        "CameraFocalPoint": [2.15058,  0.0887413, 0.0],
        "CameraViewUp":     [0,1,0],
        "ParallelScale":    0.11684418,
        "InteractionMode":  "2D",
        "Colorbar": {
            "Orientation": "Vertical",
            "Position":    [0.66, 0.38],
            "Length":      0.33,
        }
    }
}

# ============================================================
# ===================== LOAD DATA ============================
# ============================================================

src = OpenDataFile(INPUT_FILE)
src.CellArrayStatus = SCALARS + [DENSITY_NAME]

view = GetActiveViewOrCreate("RenderView")
view.Background = [1,1,1]
view.CameraParallelProjection = 1

# ============================================================
# ===================== UTILITIES ============================
# ============================================================

def hide_scalar_bar_for_array(array_name):
    try:
        lut = GetColorTransferFunction(array_name)
        HideScalarBarIfNotNeeded(lut, view)
    except:
        pass

def array_location(source, name):
    pd = source.GetPointDataInformation()
    cd = source.GetCellDataInformation()
    if pd.GetArray(name) is not None:
        return "POINTS"
    if cd.GetArray(name) is not None:
        return "CELLS"
    raise RuntimeError(f"Array '{name}' not found on points or cells")

def apply_camera_and_colorbar(lut, preset, array_name):

    p = CAMERA_PRESETS[preset]

    # ---- Camera ----
    view.CameraPosition      = p["CameraPosition"]
    view.CameraFocalPoint    = p["CameraFocalPoint"]
    view.CameraViewUp        = p["CameraViewUp"]
    view.CameraParallelScale = p["ParallelScale"]

    if "InteractionMode" in p:
        view.InteractionMode = p["InteractionMode"]

    # ---- Scalar bar ----
    bar = GetScalarBar(lut, view)
    bar.Visibility = 1

    bar.Orientation = p["Colorbar"]["Orientation"]
    bar.Position    = p["Colorbar"]["Position"]
    bar.ScalarBarLength = p["Colorbar"]["Length"]

    # ---- Title ----
    bar.Title = array_name
    bar.ComponentTitle = ""

    bar.TitleFontSize = 18
    bar.LabelFontSize = 16



# ============================================================
# ===================== SCHLIEREN ============================
# ============================================================

def schlieren_pipeline(slice_src):
    # Ensure slice has produced point data
    slice_src.UpdatePipeline()

    # ---- Gradient of density ----
    grad = Gradient(Input=slice_src)
    grad.ScalarArray = ['POINTS', DENSITY_NAME]
    grad.ResultArrayName = "delRho"
    grad.UpdatePipeline()

    # ---- |∇ρ| ----
    mag = Calculator(Input=grad)
    mag.ResultArrayName = "magDelRho"
    mag.Function = "mag(delRho)"
    mag.UpdatePipeline()

    # ---- ∂ρ/∂x ----
    dx = Calculator(Input=grad)
    dx.ResultArrayName = "Schlieren_dRho_dX"
    dx.Function = "delRho[0]"
    dx.UpdatePipeline()

    # ---- ∂ρ/∂y ----
    dy = Calculator(Input=grad)
    dy.ResultArrayName = "Schlieren_dRho_dY"
    dy.Function = "delRho[1]"
    dy.UpdatePipeline()

    return [mag, dx, dy]


# ============================================================
# ===================== SLICE ================================
# ============================================================

def create_slice(origin, normal, preset, fname, scalar, schlieren=False):

    sl = VolcanoSlice(registrationName=fname, Input=src)
    sl.SlicePoint = origin
    sl.SliceNormal = normal
    if schlieren:
        sl.InterpolatedField = DENSITY_NAME
        sl.MinMaxField = DENSITY_NAME
    else:
        sl.InterpolatedField = scalar
        sl.MinMaxField = scalar
    sl.Crinkle = 0

    if not schlieren:
        for sb in GetScalarBars(view).values():
            sb.Visibility = 0
        disp = Show(sl, view)
        loc = array_location(sl, scalar)
        ColorBy(disp, (loc, scalar))

        lut = GetColorTransferFunction(scalar)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset, scalar)
        Render(view)

        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{scalar}.png"),
                       view, ImageResolution=IMG_RES)
        Hide(sl, view)
        return

    # ---- Schlieren (each component gets its own display) ----
    for calc in schlieren_pipeline(sl):
        for sb in GetScalarBars(view).values():
            sb.Visibility = 0
        disp = Show(calc, view)
        name = calc.ResultArrayName
        loc = array_location(calc, name)

        ColorBy(disp, (loc, name))
        lut = GetColorTransferFunction(name)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset, name)
        Render(view)

        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{name}.png"),
                       view, ImageResolution=IMG_RES)
        Hide(calc, view)

    Hide(sl, view)

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for s in SCALARS:
    for x in YZ_SLICE_X:
        create_slice([x,0,0], [1,0,0], "YZ", f"YZ_x{x:+0.5f}", s)

    for z in XY_SLICE_Z:
        create_slice([0,0,z], [0,0,1], "XY_NEAR", f"XY_near_z{z:+0.5f}", s)
        create_slice([0,0,z], [0,0,1], "XY_FAR",  f"XY_far_z{z:+0.5f}",  s)

if ENABLE_SCHLIEREN:
    for z in XY_SLICE_Z:
        create_slice([0,0,z], [0,0,1], "XY_NEAR",
                     f"XY_near_z{z:+0.5f}", DENSITY_NAME, True)
        create_slice([0,0,z], [0,0,1], "XY_FAR",
                     f"XY_far_z{z:+0.5f}",  DENSITY_NAME, True)

print("\nAll slices rendered correctly.")
