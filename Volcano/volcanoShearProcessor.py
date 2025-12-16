from paraview.simple import *
import os

# ============================================================
# ======================= USER INPUT ========================
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

# Schlieren controls
ENABLE_SCHLIEREN = True
DENSITY_NAME = "density"
SCHLIEREN_COMPONENTS = {
    "Schlieren_dRho_dY": "delRho[1]",  # vertical knife-edge
    "Schlieren_dRho_dZ": "delRho[2]",  # horizontal knife-edge
}

# Slice locations
YZ_SLICE_X = [2.011691, 2.080109, 2.114318, 2.15057954, 2.16015806, 2.1690524, 2.1793151, 2.18889362, 2.19847214, 2.20736648, 2.216945, 2.307804104]
XZ_SLICE_Z = [-0.0381, 0.00, 0.0381]

# View settings
BACKGROUND_COLOR = [1, 1, 1]
CAMERA_PARALLEL_SCALE = 0.25
IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

CAMERA_PRESETS = {
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

LABEL_FONT_SIZE = 18
LABEL_COLOR = [0,0,0]
LABEL_BG_COLOR = [1.0, 1.0, 1.0, 0.6]
LABEL_POSITION = "Upper Left Corner"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ==================== LOAD VOLCANO FILE =====================
# ============================================================

vol = OpenDataFile(INPUT_FILE)
vol.CellArrayStatus = SCALARS + ([DENSITY_NAME] if ENABLE_SCHLIEREN else [])
source = vol

# ============================================================
# ==================== Slice + Schlieren Helper ==============
# ============================================================

def create_schlieren_gradient_components(slice_source, slice_name="Slice"):
    """
    Compute gradient of density and create calculators for magnitude + components.
    Returns: dict of {component_name: source}
    """
    results = {}

    # Gradient
    grad = Gradient(Input=slice_source)
    grad.ResultArrayName = "delRho"
    RenameSource(f"{slice_name}_Gradient", grad)

    # Magnitude
    mag_calc = Calculator(Input=grad)
    mag_calc.ResultArrayName = "magDelRho"
    mag_calc.Function = "mag(delRho)"
    RenameSource(f"{slice_name}_MagGradient", mag_calc)
    results["magDelRho"] = mag_calc

    # Individual components
    for name, expr in SCHLIEREN_COMPONENTS.items():
        calc = Calculator(Input=grad)
        calc.ResultArrayName = name
        calc.Function = expr
        RenameSource(f"{slice_name}_{name}", calc)
        results[name] = calc

    return results

# ============================================================
# ==================== Slice Creation ========================
# ============================================================

def create_slice(input_src, origin, normal, scalar,
                 fname, plane="XZ", field_region="FAR",
                 enable_schlieren=False, view=None, output_dir=OUTPUT_DIR):

    if view is None:
        view = GetActiveViewOrCreate("RenderView")

    # -------- Volcano Slice --------
    sl = VolcanoSlice(Input=input_src)
    sl.SlicePoint = origin
    sl.SliceNormal = normal
    sl.MinMaxField = scalar
    sl.InterpolatedField = scalar
    sl.Crinkle = 0

    disp = Show(sl, view, 'UnstructuredGridRepresentation')
    disp.Representation = "Surface"

    final_sources = {"slice": sl}

    # -------- Schlieren Gradient + Components --------
    if enable_schlieren:
        comps = create_schlieren_gradient_components(sl, slice_name=f"{scalar}_Slice")
        final_sources.update(comps)
        # Default display uses magnitude
        ColorBy(disp, ('POINTS', 'magDelRho'))
    else:
        ColorBy(disp, ('POINTS', scalar))

    # -------- Colormap --------
    lut = GetColorTransferFunction(list(final_sources.keys())[-1])
    lut.RescaleTransferFunctionToDataRange()
    if COLORMAP_PRESET:
        lut.ApplyPreset(COLORMAP_PRESET, True)
    disp.SetScalarBarVisibility(view, True)
    bar = GetScalarBar(lut, view)
    bar.Title = list(final_sources.keys())[-1]
    bar.TitleColor = LABEL_COLOR
    bar.LabelColor = LABEL_COLOR

    # -------- Camera --------
    if plane == "XZ":
        preset = "XZ_NEAR" if field_region == "NEAR" else "XZ_FAR"
    elif plane == "XY":
        preset = "XY"
    else:
        raise ValueError("Unsupported plane")

    cam_preset = CAMERA_PRESETS[preset]
    view.CameraParallelProjection = 1
    view.CameraPosition   = cam_preset["CameraPosition"]
    view.CameraFocalPoint = cam_preset["CameraFocalPoint"]
    view.CameraViewUp     = cam_preset.get("CameraViewUp", [0,1,0])
    view.CameraParallelScale = cam_preset["ParallelScale"]
    if "InteractionMode" in cam_preset:
        view.InteractionMode = cam_preset["InteractionMode"]

    bar.Orientation       = cam_preset["Colorbar"]["Orientation"]
    bar.WindowLocation    = "Any Location"
    bar.Position          = cam_preset["Colorbar"]["Position"]
    bar.ScalarBarLength   = cam_preset["Colorbar"]["Length"]

    # -------- Render & save --------
    Render(view)
    SaveScreenshot(os.path.join(output_dir, fname), view, ImageResolution=IMG_RES)

    return final_sources

# ============================================================
# ================== GENERATE ALL SLICES =====================
# ============================================================

view = GetActiveViewOrCreate("RenderView")

# Standard scalars
for scalar in SCALARS:
    for x in YZ_SLICE_X:
        create_slice(source, [x,0,0], [1,0,0], scalar,
                     f"YZ_x{x:+0.5f}_{scalar}.png",
                     plane="YZ", view=view)
    for z in XZ_SLICE_Z:
        create_slice(source, [0,0,z], [0,0,1], scalar,
                     f"XZ_near_z{z:+0.5f}_{scalar}.png",
                     plane="XZ", field_region="NEAR", view=view)
        create_slice(source, [0,0,z], [0,0,1], scalar,
                     f"XZ_far_z{z:+0.5f}_{scalar}.png",
                     plane="XZ", field_region="FAR", view=view)

# Schlieren slices (magnitude + components)
if ENABLE_SCHLIEREN:
    for x in YZ_SLICE_X:
        create_slice(source, [x,0,0], [1,0,0], DENSITY_NAME,
                     f"YZ_x{x:+0.5f}_Schlieren.png",
                     plane="YZ", enable_schlieren=True, view=view)
    for z in XZ_SLICE_Z:
        create_slice(source, [0,0,z], [0,0,1], DENSITY_NAME,
                     f"XZ_near_z{z:+0.5f}_Schlieren.png",
                     plane="XZ", field_region="NEAR", enable_schlieren=True, view=view)
        create_slice(source, [0,0,z], [0,0,1], DENSITY_NAME,
                     f"XZ_far_z{z:+0.5f}_Schlieren.png",
                     plane="XZ", field_region="FAR", enable_schlieren=True, view=view)

print("\nAll slices including Schlieren components completed successfully.")
