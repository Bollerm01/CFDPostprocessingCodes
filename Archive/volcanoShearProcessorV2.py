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

#Uncomment when wanting full run
'''YZ_SLICE_X = [
    2.011691, 2.080109, 2.114318, 2.15057954,
    2.16015806, 2.1690524, 2.1793151,
    2.18889362, 2.19847214, 2.20736648,
    2.216945, 2.307804104
]
'''
#XZ_SLICE_Z = [-0.0381, 0.0, 0.0381]

# DEBUGGING SWEEP TO LIMIT OUTPUT
YZ_SLICE_X = [2.011691]
XZ_SLICE_Z = [0.0]

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

os.makedirs(OUTPUT_DIR, exist_ok=True)

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

def hide_all_scalar_bars(view):
    for lut in list(GetColorTransferFunction().values()):
        HideScalarBarIfNotNeeded(lut, view)

def array_location(source, name):
    pd = source.GetPointDataInformation()
    cd = source.GetCellDataInformation()
    if pd.GetArray(name) is not None:
        return "POINTS"
    if cd.GetArray(name) is not None:
        return "CELLS"
    raise RuntimeError(f"Array '{name}' not found on points or cells")

def setup_colorbar(lut, plane):
    bar = GetScalarBar(lut, view)
    if plane == "XZ":
        bar.Orientation = "Horizontal"
        bar.Position = [0.32, 0.05]
        bar.ScalarBarLength = 0.36
    else:
        bar.Orientation = "Vertical"
        bar.Position = [0.70, 0.35]
        bar.ScalarBarLength = 0.35
    bar.TitleFontSize = 18
    bar.LabelFontSize = 16
    return bar

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

def create_slice(origin, normal, plane, fname, scalar, schlieren=False):

    sl = VolcanoSlice(registrationName=fname, Input=src)
    sl.SlicePoint = origin
    sl.SliceNormal = normal
    sl.InterpolatedField = scalar
    sl.MinMaxField = scalar
    sl.Crinkle = 0

    disp = Show(sl, view)
    disp.Representation = "Surface"

    #hide_all_scalar_bars(view)
    disp.SetScalarBarVisibility(view, False)


    if not schlieren:
        loc = array_location(sl, scalar)
        ColorBy(disp, (loc, scalar))

        lut = GetColorTransferFunction(scalar)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        setup_colorbar(lut, plane)
        disp.SetScalarBarVisibility(view, True)

        Render(view)
        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{scalar}.png"),
                       view, ImageResolution=IMG_RES)
        Hide(sl, view)
        return

    for calc in schlieren_pipeline(sl):
        name = calc.ResultArrayName
        loc = array_location(calc, name)
        ColorBy(disp, (loc, name))

        lut = GetColorTransferFunction(name)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        setup_colorbar(lut, plane)
        disp.SetScalarBarVisibility(view, True)

        Render(view)
        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{name}.png"),
                       view, ImageResolution=IMG_RES)

    Hide(sl, view)

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for s in SCALARS:
    for x in YZ_SLICE_X:
        create_slice([x,0,0], [1,0,0], "YZ", f"YZ_x{x:+0.5f}", s)

    for z in XZ_SLICE_Z:
        create_slice([0,0,z], [0,0,1], "XZ", f"XZ_z{z:+0.5f}", s)

if ENABLE_SCHLIEREN:
    for x in YZ_SLICE_X:
        create_slice([x,0,0], [1,0,0], "YZ",
                     f"YZ_x{x:+0.5f}_Schlieren", DENSITY_NAME, True)

    for z in XZ_SLICE_Z:
        create_slice([0,0,z], [0,0,1], "XZ",
                     f"XZ_z{z:+0.5f}_Schlieren", DENSITY_NAME, True)

print("\nAll slices rendered.")

