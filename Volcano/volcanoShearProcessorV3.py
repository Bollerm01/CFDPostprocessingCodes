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

# Debug sweep (expand for full runs)
YZ_SLICE_X = [2.011691]   # normal X
XY_SLICE_Z = [0.0]        # normal Z

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ===================== CAMERA PRESETS =======================
# ============================================================
# Names now reflect *physical planes*

CAMERA_PRESETS = {
    # XY plane (normal Z) — FAR
    "XY_FAR": {
        "CameraPosition":     [1.4547914383436304, 0.05994982668344116, 5.011016610690195],
        "CameraFocalPoint":   [1.4547914383436304, 0.05994982668344116, 0.0],
        "CameraViewUp":       [0.0, 1.0, 0.0],
        "ParallelScale":      0.7320925072135284,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.2899460916442047, 0.2630597014925373],
            "Length":      0.33,
        }
    },

    # XY plane (normal Z) — NEAR
    "XY_NEAR": {
        "CameraPosition":     [2.1922574427684838, 0.018226216790868725, 5.011192474629075],
        "CameraFocalPoint":   [2.1922574427684838, 0.018226216790868725, 0.0],
        "CameraViewUp":       [0.0, 1.0, 0.0],
        "ParallelScale":      0.06142870916705136,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.3108355795148248, 0.14925373134328357],
            "Length":      0.33,
        }
    },

    # YZ plane (normal X)
    "YZ": {
        "CameraPosition":     [2.7452049999995722, 0.08874126502707114, 0.0],
        "CameraFocalPoint":   [2.1505799999995725, 0.08874126502707114, 0.0],
        "CameraViewUp":       [0.0, 1.0, 0.0],
        "ParallelScale":      0.11684418042846643,
        "InteractionMode":    "2D",
        "Colorbar": {
            "Orientation": "Vertical",
            "Position":    [0.6610512129380054, 0.3789552238805967],
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
view.Background = [1, 1, 1]
view.CameraParallelProjection = 1

# ============================================================
# ===================== UTILITIES ============================
# ============================================================

def array_location(source, name):
    if source.GetPointDataInformation().GetArray(name):
        return "POINTS"
    if source.GetCellDataInformation().GetArray(name):
        return "CELLS"
    raise RuntimeError(f"Array '{name}' not found")

def apply_camera_and_colorbar(lut, preset):
    p = CAMERA_PRESETS[preset]

    view.CameraParallelProjection = 1
    view.CameraPosition = p["CameraPosition"]
    view.CameraFocalPoint = p["CameraFocalPoint"]
    view.CameraViewUp = p.get("CameraViewUp", [0,1,0])
    view.CameraParallelScale = p["ParallelScale"]

    if "InteractionMode" in p:
        view.InteractionMode = p["InteractionMode"]

    bar = GetScalarBar(lut, view)
    bar.Orientation = p["Colorbar"]["Orientation"]
    bar.Position = p["Colorbar"]["Position"]
    bar.ScalarBarLength = p["Colorbar"]["Length"]
    bar.TitleFontSize = 18
    bar.LabelFontSize = 16

# ============================================================
# ===================== SCHLIEREN ============================
# ============================================================

def schlieren_pipeline(slice_src):
    grad = Gradient(Input=slice_src)
    grad.ResultArrayName = "delRho"

    mag = Calculator(Input=grad)
    mag.ResultArrayName = "magDelRho"
    mag.Function = "mag(delRho)"

    dx = Calculator(Input=grad)
    dx.ResultArrayName = "Schlieren_dRho_dX"
    dx.Function = "delRho[0]"

    dy = Calculator(Input=grad)
    dy.ResultArrayName = "Schlieren_dRho_dY"
    dy.Function = "delRho[1]"

    return [mag, dx, dy]

# ============================================================
# ===================== SLICE ================================
# ============================================================

def create_slice(origin, normal, preset, fname, scalar, schlieren=False):

    sl = VolcanoSlice(registrationName=fname, Input=src)
    sl.SlicePoint = origin
    sl.SliceNormal = normal
    sl.InterpolatedField = scalar
    sl.MinMaxField = scalar
    sl.Crinkle = 0

    disp = Show(sl, view)
    disp.Representation = "Surface"
    disp.SetScalarBarVisibility(view, False)

    def render_and_save(array_name, src_obj):
        loc = array_location(src_obj, array_name)
        ColorBy(disp, (loc, array_name))

        lut = GetColorTransferFunction(array_name)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset)
        disp.SetScalarBarVisibility(view, True)

        Render(view)
        SaveScreenshot(
            os.path.join(OUTPUT_DIR, f"{fname}_{array_name}.png"),
            view,
            ImageResolution=IMG_RES
        )

    if not schlieren:
        render_and_save(scalar, sl)
        Hide(sl, view)
        return

    for calc in schlieren_pipeline(sl):
        render_and_save(calc.ResultArrayName, calc)

    Hide(sl, view)

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

# --- YZ slices (normal X) ---
for s in SCALARS:
    for x in YZ_SLICE_X:
        create_slice(
            origin=[x,0,0],
            normal=[1,0,0],
            preset="YZ",
            fname=f"YZ_x{x:+0.5f}",
            scalar=s
        )

# --- XY slices (normal Z), near / far ---
for s in SCALARS:
    for z in XY_SLICE_Z:
        create_slice(
            [0,0,z], [0,0,1],
            "XY_NEAR",
            f"XY_near_z{z:+0.5f}",
            s
        )
        create_slice(
            [0,0,z], [0,0,1],
            "XY_FAR",
            f"XY_far_z{z:+0.5f}",
            s
        )

if ENABLE_SCHLIEREN:
    for z in XY_SLICE_Z:
        create_slice(
            [0,0,z], [0,0,1],
            "XY_NEAR",
            f"XY_near_z{z:+0.5f}_Schlieren",
            DENSITY_NAME, True
        )
        create_slice(
            [0,0,z], [0,0,1],
            "XY_FAR",
            f"XY_far_z{z:+0.5f}_Schlieren",
            DENSITY_NAME, True
        )

print("\n✅ All slices rendered with physically correct camera preset names.")
