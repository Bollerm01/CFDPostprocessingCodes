from paraview.simple import *
import os

# ============================================================
# ======================= USER INPUT ==========================
# ============================================================

INPUT_FILE = r"/home/bollerma/LESdata/SSWT/fullCav/timeSensitivityStudy/test1t/test1tM2SSWT_000/latest.volcano"
OUTPUT_DIR = r"/home/bollerma/LESdata/SSWT/fullCav/timeSensitivityStudy/test1t/OUTPUT"

# Standard scalars
SCALARS = [
    "reynoldsstressxx",
    "reynoldsstressyy",
    "reynoldsstresszz",
    "reynoldsstressxy",
    "reynoldsstressxz",
    "reynoldsstressyz",
    "velocityx",
    "velocityxavg",
    "tke",
    "pressureavg"
    
]

# ---- Schlieren controls ----
ENABLE_SCHLIEREN = True
DENSITY_NAME = "density"

# Knife-edge equivalents
SCHLIEREN_SCALARS = {
    "Schlieren_dRho_dY": "delRho[1]",   # vertical knife edge
    "Schlieren_dRho_dZ": "delRho[2]"    # horizontal knife edge
}

# Slice locations
YZ_SLICE_X = [2.011691, 2.080109, 2.114318,	2.15057954,	2.16015806,	2.1690524,	2.1793151,	2.18889362,	2.19847214, 2.20736648,	2.216945, 2.307804104]
XZ_SLICE_Z = [-0.0381, 0.00, 0.0381]

# View settings
BACKGROUND_COLOR = [1, 1, 1]
CAMERA_PARALLEL_SCALE = 0.25
IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

# Label style
LABEL_FONT_SIZE = 18
LABEL_COLOR = [0, 0, 0]
LABEL_BG_COLOR = [1, 1, 1]
LABEL_BG_OPACITY = 0.6
LABEL_POSITION = "Upper Left Corner"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ========= AUTO-DETECT REGISTRATION NAME (2nd INNER FOLDER) ==
# ============================================================

path_parts = os.path.normpath(INPUT_FILE).split(os.sep)
registration_name = path_parts[-3] if len(path_parts) >= 3 else "volcano"

# ============================================================
# ==================== LOAD VOLCANO FILE =====================
# ============================================================

vol = FileSeriesReader(registrationName=registration_name, FileNames=[INPUT_FILE])
vol.CellArrayStatus = SCALARS + ([DENSITY_NAME] if ENABLE_SCHLIEREN else [])
vol.UpdatePipeline()

source = vol

# ============================================================
# =============== SCHLIEREN GRADIENT PIPELINE =================
# ============================================================

if ENABLE_SCHLIEREN:
    print("Creating density gradient pipeline...")

    grad = Gradient(Input=source)
    grad.ScalarArray = ['POINTS', DENSITY_NAME]
    grad.ResultArrayName = "delRho"

    source = grad

    calculators = {}
    for name, expr in SCHLIEREN_SCALARS.items():
        calc = Calculator(Input=source)
        calc.ResultArrayName = name
        calc.Function = expr
        calculators[name] = calc

# ============================================================
# ================== COLORMAP FUNCTION ========================
# ============================================================

def apply_colormap(array_name, display, view):
    lut = GetColorTransferFunction(array_name)
    lut.RescaleTransferFunctionToDataRange()
    if COLORMAP_PRESET:
        lut.ApplyPreset(COLORMAP_PRESET, True)

    ColorBy(display, ('POINTS', array_name))
    bar = GetScalarBar(lut, view)
    bar.Title = array_name
    bar.TitleColor = LABEL_COLOR
    bar.LabelColor = LABEL_COLOR
    display.SetScalarBarVisibility(view, True)

# ============================================================
# ================== LABEL FUNCTION ===========================
# ============================================================

def add_slice_label(view, output_name):

    label_text = os.path.splitext(output_name)[0]

    txt = Text()
    txt.Text = label_text

    txtDisp = Show(txt, view)
    txtDisp.FontSize = LABEL_FONT_SIZE
    txtDisp.Color = LABEL_COLOR

    # UPDATED enum (spaces required)
    txtDisp.WindowLocation = LABEL_POSITION

    txtDisp.UseBackgroundColor = 1
    txtDisp.BackgroundColor = LABEL_BG_COLOR
    txtDisp.BackgroundOpacity = LABEL_BG_OPACITY

    return txt


# ============================================================
# ================== SLICE FUNCTION ===========================
# ============================================================

def create_slice(input_src, origin, normal, scalar, fname):

    view = GetActiveViewOrCreate("RenderView")
    view.Background = BACKGROUND_COLOR
    view.UseColorPaletteForBackground = 0

    # ---- VolcanoSlice (NO SliceType!) ----
    sl = VolcanoSlice(Input=input_src)
    sl.MinMaxField = scalar
    sl.InterpolatedField = scalar
    sl.Crinkle = 0

    # VolcanoSlice-specific plane controls
    sl.SliceNormal = normal
    sl.SlicePoint = origin

    sl.UpdatePipeline()

    disp = Show(sl, view, 'UnstructuredGridRepresentation')
    disp.Representation = "Surface"

    apply_colormap(scalar, disp, view)

    # ---- Camera ----
    cam = view.GetActiveCamera()
    view.CameraParallelProjection = 1
    view.CameraParallelScale = CAMERA_PARALLEL_SCALE

    if normal == [1, 0, 0]:  # YZ
        cam.SetPosition(origin[0] + 1.0, 0.0, 0.0)
        cam.SetFocalPoint(origin)
        cam.SetViewUp(0, 0, 1)
    elif normal == [0, 0, 1]:  # XZ
        cam.SetPosition(0.0, 0.0, origin[2] + 1.0)
        cam.SetFocalPoint(origin)
        cam.SetViewUp(0, 1, 0)

    # ---- Label ----
    label = add_slice_label(view, fname)

    RenderAllViews()
    SaveScreenshot(os.path.join(OUTPUT_DIR, fname), view, ImageResolution=IMG_RES)

    # ---- Cleanup ----
    Delete(label)
    Hide(sl, view)
    Delete(sl)


# ============================================================
# ===================== GENERATE SLICES =======================
# ============================================================

# ---- Standard scalars ----
for scalar in SCALARS:
    for x in YZ_SLICE_X:
        create_slice(source, [x,0,0], [1,0,0], scalar, f"YZ_x{x:+0.5f}_{scalar}.png")
    for z in XZ_SLICE_Z:
        create_slice(source, [0,0,z], [0,0,1], scalar, f"XZ_z{z:+0.5f}_{scalar}.png")

# ---- Schlieren slices ----
if ENABLE_SCHLIEREN:
    for name, calc in calculators.items():
        for x in YZ_SLICE_X:
            create_slice(calc, [x,0,0], [1,0,0], name, f"YZ_x{x:+0.5f}_{name}.png")
        for z in XZ_SLICE_Z:
            create_slice(calc, [0,0,z], [0,0,1], name, f"XZ_z{z:+0.5f}_{name}.png")

print("\n Schlieren-style density gradient slices completed.")
