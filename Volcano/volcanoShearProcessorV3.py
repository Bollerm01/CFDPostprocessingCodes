from paraview.simple import *
import os

# ============================================================
# ======================= USER INPUT =========================
# ============================================================

INPUT_FILE = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD00/RD00_004/latest.volcano"
OUTPUT_DIR = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/testOutput/paraviewImgs"
folder_path = os.path.dirname(INPUT_FILE) # /home/user/project
file_name = os.path.basename(folder_path) # project
# SCALARS = [
#     "reynoldsstressxx", "reynoldsstressyy", "reynoldsstresszz",
#     "reynoldsstressxy", "reynoldsstressxz", "reynoldsstressyz",
#     "velocityx", "velocityxavg", "tke", "pressureavg"
# ]

# Debugging scalars
SCALARS = ["velocityx"]
ENABLE_SCHLIEREN = False # Change to true if desired
DENSITY_NAME = "density"

# Debugging loop
YZ_SLICE_X = [2.15057954, 2.1793151, 2.216945]
XY_SLICE_Z = [0.0381]
XZ_SLICE_Y = [0.0093]

# full loop
# YZ_SLICE_X = [2.011691, 2.080109, 2.114318, 2.15057954, 2.16015806, 2.1690524, 2.1793151, 2.18889362, 2.19847214, 2.20736648, 2.216945, 2.223063, 2.307804104]
# XY_SLICE_Z = [-0.0381, 0.00, 0.0381]
# XZ_SLICE_Y = [0.0182, 0.0093, 0.003, 0.001]

# 3D slices group
YZ_SLICE_X_3D = [2.15057954, 2.1793151, 2.216945]
XY_SLICE_Z_3D = [0.0381]
XZ_SLICE_Y_3D = [0.0093]

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
            "Length":      0.5, # was 0.33
        }
    },
    "XY_FAR": {
        "CameraPosition":   [1.25, 0.05994982668344116, 5.011016610690195], # was [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
        "CameraFocalPoint": [1.25, 0.05994982668344116, 0.0], # was [1.4547914383436304, 0.05994982668344116, 0.0]
        "CameraViewUp":     [0,1,0],
        "ParallelScale":    0.75, # was 0.7320925072135284, 0.8 for centered
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
        "ParallelScale":    0.10, # was 0.11684418
        "InteractionMode":  "2D",
        "Colorbar": {
            "Orientation": "Vertical",
            "Position":    [0.80, 0.38],
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
        "CameraPosition":   [3.88543, 0.657277, 4.35785],
        "CameraFocalPoint": [2.07626, -0.03555, -0.272],
        "CameraViewUp":     [-0.0564687, 0.9904, -0.126141],
        "ParallelScale":    0.065,  # May need to fix 
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
        "ParallelScale":    0.065, # may need to change 
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

def make_slice_group(xySlices, xzSlices, yzSlices):
    group = []
    if not xySlices:
        for z in xySlices:
            name = f"XY_near_z{z:+0.5f}"
            group.append(name)
    if not xzSlices:
        for y in xzSlices:
            name = f"XZ_y{y:+0.5f}"
            group.append(name)
    if not yzSlices:
        for x in yzSlices:
            name = f"YZ_x{x:+0.5f}"
            group.append(name)
    return group

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

    # --- Reset cached geometry ----
    bar.AutomaticLabelFormat = 0
    bar.UseCustomLabels = 0
    bar.WindowLocation = "Any Location"
    bar.ScalarBarThickness = bar.ScalarBarThickness  # forces refresh

    bar.Orientation = p["Colorbar"]["Orientation"]
    bar.Position    = p["Colorbar"]["Position"]
    bar.ScalarBarLength = p["Colorbar"]["Length"]

    # ---- Title ----
    bar.Title = array_name
    bar.ComponentTitle = ""

    bar.TitleFontSize = 12 # was 18
    bar.LabelFontSize = 10 # was 16



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

def make_3D_slice_view(slices, preset, fname, scalar):
    """
    Parameters
    ----------
    slices : list
        List of preexisting slice proxies (e.g., VolcanoSlice outputs).
        Typically length 4 for a 4-slice composite.
    preset : str
        Name of the camera preset to apply (key in CAMERA_PRESETS).
    fname : str
        Output file name (no directory), e.g. 'four_YZ_slices_velocityx.png'.
    scalar : str
        Name of the scalar field to color by.
    """
    displays = []

    # Show and color all slices by the same scalar
    lut = GetColorTransferFunction(scalar)
    for sl in slices:
        currentSlice = FindSource(sl)
        if currentSlice is None:
            raise RuntimeError(f"Source '{sl}' not found in pipeline")
        SetActiveSource(currentSlice)
        disp = Show(sl, view)
        loc = array_location(sl, scalar)
        ColorBy(disp, (loc, scalar))
        displays.append(disp)

    # Configure shared LUT
    lut.RescaleTransferFunctionToDataRange()
    lut.ApplyPreset(COLORMAP_PRESET, True)

    # Apply camera + colorbar
    apply_camera_and_colorbar(lut, preset, scalar)

    # Render and save a single screenshot containing all visible slices
    Render(view)
    SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{scalar}.png"),
                       view, ImageResolution=IMG_RES)

    # Optionally hide slices afterwards
    for sl in slices:
        currentSlice = FindSource(sl)
        Hide(sl, view)


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
        # create_slice([0,0,z], [0,0,1], "XY_FAR",  f"XY_far_z{z:+0.5f}",  s) # ADD BACK IF WANTING FAR SHOTS 

    # 3D figs - Near 3D
    sliceGroup = make_slice_group(XY_SLICE_Z_3D, XZ_SLICE_Y_3D, YZ_SLICE_X_3D)
    outputFileName = "3D_Near_Group"
    make_3D_slice_view(sliceGroup, '3D_Near', outputFileName, s)
    

if ENABLE_SCHLIEREN:
    for z in XY_SLICE_Z:
        create_slice([0,0,z], [0,0,1], "XY_NEAR",
                     f"XY_near_z{z:+0.5f}", DENSITY_NAME, True)
        create_slice([0,0,z], [0,0,1], "XY_FAR",
                     f"XY_far_z{z:+0.5f}",  DENSITY_NAME, True)

print("\nAll slices rendered correctly.")
