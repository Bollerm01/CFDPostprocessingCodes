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

CAMERA_PRESETS = {

    # ---------- XZ FARFIELD ----------
    "XZ_FAR": {
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

    # ---------- XY ----------
    "XY": {
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
    },

    # ---------- XZ NEARFIELD ----------
    "XZ_NEAR": {
        "CameraPosition":     [2.1922574427684838, 0.018226216790868725, 5.011192474629075],
        "CameraFocalPoint":   [2.1922574427684838, 0.018226216790868725, 0.0],
        "CameraViewUp":       [0.0, 1.0, 0.0],
        "ParallelScale":      0.06142870916705136,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.3108355795148248, 0.14925373134328357],
            "Length":      0.33,
        }
    }
}

# Label style
LABEL_FONT_SIZE = 18
LABEL_COLOR = [0, 0, 0]
LABEL_BG_COLOR = [1.0, 1.0, 1.0, 0.6]

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
# ================== CAMERA FUNCTION ========================
# ============================================================

def apply_camera_and_colorbar(view, display, preset_name, scalar):

    preset = CAMERA_PRESETS[preset_name]

    view.CameraParallelProjection = 1
    view.CameraPosition   = preset["CameraPosition"]
    view.CameraFocalPoint = preset["CameraFocalPoint"]
    view.CameraViewUp     = preset.get("CameraViewUp", [0, 1, 0])
    view.CameraParallelScale = preset["ParallelScale"]

    if "InteractionMode" in preset:
        view.InteractionMode = preset["InteractionMode"]

    # Colorbar
    lut = GetColorTransferFunction(scalar)
    display.SetScalarBarVisibility(view, True)
    cb = GetScalarBar(lut, view)

    cb.Orientation       = preset["Colorbar"]["Orientation"]
    cb.WindowLocation    = "Any Location"
    cb.Position          = preset["Colorbar"]["Position"]
    cb.ScalarBarLength   = preset["Colorbar"]["Length"]

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

    txtDisp.BackgroundColor = LABEL_BG_COLOR

    return txt


# ============================================================
# ================== SLICE FUNCTION ===========================
# ============================================================

def create_slice(input_src, origin, normal, scalar, fname,
                 plane="XZ", field_region="FAR"):

    view = GetActiveViewOrCreate("RenderView")

    sl = VolcanoSlice(Input=input_src)
    sl.MinMaxField = scalar
    sl.InterpolatedField = scalar
    sl.Crinkle = 0
    sl.SlicePoint  = origin
    sl.SliceNormal = normal
    sl.UpdatePipeline()

    disp = Show(sl, view, 'UnstructuredGridRepresentation')
    disp.Representation = "Surface"

    ColorBy(disp, ('POINTS', scalar))
    disp.RescaleTransferFunctionToDataRange(True, False)

    # -------- CAMERA SELECTION --------
    if plane == "XZ":
        preset = "XZ_NEAR" if field_region == "NEAR" else "XZ_FAR"
    elif plane == "XY":
        preset = "XY"
    else:
        raise ValueError("Unsupported plane")

    apply_camera_and_colorbar(view, disp, preset, scalar)

    Render(view)

    SaveScreenshot(
        os.path.join(OUTPUT_DIR, fname),
        view,
        ImageResolution=IMG_RES
    )
    
    # ---- Cleanup ----
    Delete(label)
    Hide(sl, view)
    Delete(sl)
    
    return sl




# ============================================================
# ===================== GENERATE SLICES =======================
# ============================================================

# ---- Standard scalars ----
for scalar in SCALARS:
    for x in YZ_SLICE_X:
        create_slice(source, [x,0,0], [1,0,0], scalar, f"YZ_x{x:+0.5f}_{scalar}.png")
    for z in XZ_SLICE_Z:
        # Nearfield slices
        create_slice(source, [0,0,z], [0,0,1], scalar, f"XZ_near_z{z:+0.5f}_{scalar}.png", plane="XZ", field_region="NEAR")
        # Farfield slices
        create_slice(source, [0,0,z], [0,0,1], scalar, f"XZ_far_z{z:+0.5f}_{scalar}.png", plane="XZ", field_region="FAR")
print("\n Non-calculated slices completed.")

# ---- Schlieren slices ----
if ENABLE_SCHLIEREN:
    for name, calc in calculators.items():
        for x in YZ_SLICE_X:
            create_slice(calc, [x,0,0], [1,0,0], name, f"YZ_x{x:+0.5f}_{name}.png")
        for z in XZ_SLICE_Z:
            # Nearfield slice
            create_slice(calc, [0,0,z], [0,0,1], name, f"XZ_near_z{z:+0.5f}_{name}.png", plane="XZ", field_region="NEAR")
            # Farfield slice
            create_slice(calc, [0,0,z], [0,0,1], name, f"XZ_far_z{z:+0.5f}_{name}.png", plane="XZ", field_region="FAR")

print("\n Schlieren slices completed.")
