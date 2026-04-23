from paraview.simple import *
import os

# ============================================================
# ======================= USER INPUT =========================
# ============================================================

INPUT_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD00/RD00_004/latest.volcano"
# INPUT_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD17/RD17_022/latest.volcano" # RD17 Path
# INPUT_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD52/RD52_057/latest.volcano" # RD52 Path

OUTPUT_DIR = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/contourOutput/RD00/vorticityShots" # CHANGE PER RUN
folder_path = os.path.dirname(INPUT_FILE) # /home/user/project
file_name = os.path.basename(folder_path) # project
# SCALARS = [
#     "reynoldsstressxx", "reynoldsstressyy", "reynoldsstresszz",
#     "reynoldsstressxy", "reynoldsstressxz", "reynoldsstressyz",
#     "velocityx", "velocityxavg", "tke", "pressure", "pressureavg", 
#     "vorticitymag", "vorticitymagavg"
# ]

# Debugging scalars
SCALARS = ["vorticitymag", "vorticitymagavg"]
ENABLE_SCHLIEREN = True # Change to true if desired
DENSITY_NAME = "density"

# <<< NEW: Optional, user-defined scalar ranges (min, max) per array name >>>
# If a scalar is not in this dictionary, the script will fall back to the
# actual data range for that array.
SCALAR_RANGES = {
    # ---- Example ranges: update to match your dataset ----
    # Reynolds stresses
    "reynoldsstressxx": (0.0, 2.4e4),
    "reynoldsstressyy": (0.0, 6500.0),
    "reynoldsstresszz": (-100.0, 100.0),
    "reynoldsstressxy": (-5e3, 1.5e3),
    "reynoldsstressxz": (-400.0, 250.0),
    "reynoldsstressyz": (-400.0, 250.0),

    # Velocities
    "velocityx":    (-160.0, 730.0),
    "velocityxavg": (-160.0, 730.0),

    # Turbulence / pressure
    "tke":         (0.0, 20000.0),
    "pressureavg": (13000.0, 32000.0),
    "pressureavg": (13000.0, 32000.0),

    # Vorticity
    "vorticitymag":    (0.0, 1.1e5),
    "vorticitymagavg": (0.0, 1.1e5),

    # Schlieren outputs (only used if ENABLE_SCHLIEREN is True)
    "magDelRho":         (0.0, 120.0),
    "Schlieren_dRho_dX": (0.0, 90.0),
    "Schlieren_dRho_dY": (0.0, 90.0),
}
# <<< END NEW >>>

# Debugging loop
# YZ_SLICE_X = [2.15057954, 2.1793151, 2.216945]
# XY_SLICE_Z = [0.0381]
# XZ_SLICE_Y = [0.0093,0.001]

# full loop
YZ_SLICE_X = [2.011691, 2.080109, 2.114318, 2.15057954, 2.16015806, 2.1690524, 2.1793151, 2.18889362, 2.19847214, 2.20736648, 2.216945, 2.223063, 2.307804104]
XY_SLICE_Z = [-0.0381, 0.00, 0.0381]
XZ_SLICE_Y = [0.0182, 0.0093, 0.003, 0.001]

# 3D slices group
YZ_SLICE_X_3D = [2.15057954, 2.1793151, 2.216945] #x/L = 0.03, 0.45, 1
XY_SLICE_Z_3D = [0.0381]
XZ_SLICE_Y_3D = [0.0093,0.001]

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
            "Position":    [0.29, 0.15],
            "Length":      0.5, # was 0.33
        }
    },
    "XY_FAR": {
        "CameraPosition":   [1.25, 0.05994982668344116, 5.011016610690195],
        "CameraFocalPoint": [1.25, 0.05994982668344116, 0.0],
        "CameraViewUp":     [0,1,0],
        "ParallelScale":    0.75,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.29, 0.26],
            "Length":      0.5,
        }
    },
    "YZ": {
        "CameraPosition":   [2.745205, 0.0887413, 0.0],
        "CameraFocalPoint": [2.15058,  0.0887413, 0.0],
        "CameraViewUp":     [0,1,0],
        "ParallelScale":    0.10,
        "InteractionMode":  "2D",
        "Colorbar": {
            "Orientation": "Vertical",
            "Position":    [0.80, 0.24],
            "Length":      0.5,
        }
    },
    "XZ": {
        "CameraPosition":   [2.19626, 5.25954, -0.0137621],
        "CameraFocalPoint": [2.19626, 0.240491, -0.0137621],
        "CameraViewUp":     [-1, 0, 0],
        "ParallelScale":    0.065, 
        "InteractionMode":  "3D",
        "Colorbar": {
            "Orientation": "Vertical",
            "Position":    [0.80, 0.38],
            "Length":      0.5,
        }
    },
    "3D_Near": {
        "CameraPosition":   [3.47514, 1.07704, 4.42635],
        "CameraFocalPoint": [2.10515, -0.0598313, -0.266117],
        "CameraViewUp":     [-0.0835596, 0.973793, -0.21153],
        "ParallelScale":    0.065,
        "InteractionMode":  "3D",
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.174555, 0.0997015],
            "Length":      0.5,
        }
    },
    "3D_Top": {
        "CameraPosition":   [4.50317, 2.18599, 3.42866],
        "CameraFocalPoint": [2.01636, -0.171346, -0.238507],
        "CameraViewUp":     [-10.247616, 0.882667, -0.399482],
        "ParallelScale":    0.065,
        "InteractionMode":  "3D",
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position":    [0.174555, 0.0997015],
            "Length":      0.5,
        }
    }
}

# ============================================================
# ===================== LOAD DATA ============================
# ============================================================

src = OpenDataFile(INPUT_FILE)
RenameSource(file_name, src)
src.CellArrayStatus = SCALARS + [DENSITY_NAME]

view = GetActiveViewOrCreate("RenderView")
view.Background = [0, 0, 0]
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

# Helper to apply user-defined or automatic LUT range
def apply_lut_range(lut, array_name):
    """
    If array_name has a manual range in SCALAR_RANGES, use that range.
    Otherwise, fall back to the data-derived range.
    """
    if array_name in SCALAR_RANGES:
        vmin, vmax = SCALAR_RANGES[array_name]
        lut.RescaleTransferFunction(vmin, vmax)
    else:
        # Use data range if not specified
        lut.RescaleTransferFunctionToDataRange()

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
    # bar.Visibility = 0 # hides bar

    # --- Reset cached geometry ----
    bar.AutomaticLabelFormat = 0
    bar.UseCustomLabels = 0
    bar.WindowLocation = "Any Location"
    bar.ScalarBarThickness = bar.ScalarBarThickness  # forces refresh

    bar.Orientation = p["Colorbar"]["Orientation"]
    bar.Position    = p["Colorbar"]["Position"]
    bar.ScalarBarLength = p["Colorbar"]["Length"]
    bar.TitleColor = [0.0, 0.0, 0.0] # black
    bar.LabelColor = [0.0, 0.0, 0.0] # black

    # ---- Title ----
    bar.Title = array_name
    bar.ComponentTitle = ""

    bar.TitleFontSize = 12 # was 18
    bar.LabelFontSize = 10 # was 16

    # --- Sets background ---
    # find settings proxy
    colorPalette = GetSettingsProxy('ColorPalette')

    # Properties modified on colorPalette (white)
    colorPalette.Background = [1.0, 1.0, 1.0]

    # ---- Sets axis label color -----
    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0] # black



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

# Helper: Make Slice
def make_slice(origin, normal, fname, scalar, schlieren=False):
    """
    Create and configure a VolcanoSlice but do not show or save.
    Returns the slice proxy.
    """
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
    return sl


# ============================================================
# ===================== SLICE ================================
# ============================================================

def create_slice(origin, normal, preset, fname, scalar, schlieren=False):

    sl = make_slice(origin, normal, fname, scalar, schlieren=schlieren)

    if not schlieren:
        disp = Show(sl, view)
        loc = array_location(sl, scalar)
        ColorBy(disp, (loc, scalar))

        lut = GetColorTransferFunction(scalar)
        # <<< CHANGED: use helper for manual/automatic range >>>
        apply_lut_range(lut, scalar)
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset, scalar)
        Render(view)

        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{scalar}_Volcano.png"),
                       view, ImageResolution=IMG_RES, TransparentBackground=1)
        Hide(sl, view)
        return

    # ---- Schlieren (each component gets its own display) ----
    for calc in schlieren_pipeline(sl):
        disp = Show(calc, view)
        name = calc.ResultArrayName
        loc = array_location(calc, name)

        ColorBy(disp, (loc, name))
        lut = GetColorTransferFunction(name)
        # <<< CHANGED: use helper here too >>>
        apply_lut_range(lut, name)
        lut.ApplyPreset(COLORMAP_PRESET, True)
        # NEW BAR HIDING #
        bar = GetScalarBar(lut, view)
        bar.Visibility = 1
        ##################
        apply_camera_and_colorbar(lut, preset, name)
        Render(view)

        SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{name}_Volcano.png"),
                       view, ImageResolution=IMG_RES, TransparentBackground=1)
        Hide(calc, view)

    Hide(sl, view)

def make_3D_slice_view(slices, preset, fname, scalar):
    """
    slices : list of slice proxies (VolcanoSlice outputs)
    scalar : name of the scalar field that is present on these slices
    """
    lut = GetColorTransferFunction(scalar)

    for sl in slices:
        SetActiveSource(sl)
        disp = Show(sl, view)
        loc = array_location(sl, scalar)
        ColorBy(disp, (loc, scalar))

    # Configure shared LUT once
    # <<< CHANGED: use helper for manual/automatic range >>>
    apply_lut_range(lut, scalar)
    lut.ApplyPreset(COLORMAP_PRESET, True)

    apply_camera_and_colorbar(lut, preset, scalar)
    Render(view)

    SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{scalar}_Volcano.png"),
                   view, ImageResolution=IMG_RES, TransparentBackground=1)

    # Optionally hide
    for sl in slices:
        Hide(sl, view)

def make_slice_group(xySlices, xzSlices, yzSlices, scalar):
    group = []

    # XY planes
    if xySlices:
        for z in xySlices:
            fname = f"XY_near_z{z:+0.5f}_3D_{scalar}"
            sl = make_slice([0, 0, z], [0, 0, 1], fname, scalar, schlieren=False)
            group.append(sl)

    # XZ planes
    if xzSlices:
        for y in xzSlices:
            fname = f"XZ_y{y:+0.5f}_3D_{scalar}"
            sl = make_slice([0, y, 0], [0, 1, 0], fname, scalar, schlieren=False)
            group.append(sl)

    # YZ planes
    if yzSlices:
        for x in yzSlices:
            fname = f"YZ_x{x:+0.5f}_3D_{scalar}"
            sl = make_slice([x, 0, 0], [1, 0, 0], fname, scalar, schlieren=False)
            group.append(sl)

    print(f"Grouped 3D slice proxies for {scalar}: {group}")
    return group


# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for s in SCALARS:
    for x in YZ_SLICE_X:
        create_slice([x,0,0], [1,0,0], "YZ", f"YZ_x{x:+0.5f}", s)
    
    for y in XZ_SLICE_Y:
        create_slice([0,y,0], [0,1,0], "XZ", f"XZ_y{y:+0.5f}", s)

    for z in XY_SLICE_Z:
        create_slice([0,0,z], [0,0,1], "XY_NEAR", f"XY_near_z{z:+0.5f}", s)
        # create_slice([0,0,z], [0,0,1], "XY_FAR",  f"XY_far_z{z:+0.5f}",  s)

    # 3D figs - Near 3D (for this scalar s)
    sliceGroup = make_slice_group(XY_SLICE_Z_3D, XZ_SLICE_Y_3D, YZ_SLICE_X_3D, s)
    outputFileName = "3D_Near_Group"
    make_3D_slice_view(sliceGroup, "3D_Near", outputFileName, s)
    

if ENABLE_SCHLIEREN:
    for z in XY_SLICE_Z:

        create_slice([0,0,z], [0,0,1], "XY_NEAR",
                     f"XY_near_z{z:+0.5f}", DENSITY_NAME, True)
        create_slice([0,0,z], [0,0,1], "XY_FAR",
                     f"XY_far_z{z:+0.5f}",  DENSITY_NAME, True)

print("\nAll slices rendered correctly.")