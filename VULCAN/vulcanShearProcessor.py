from paraview.simple import *
from paraview import servermanager
import os


#should be constant across radii
INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
INPUT_DIR = "iteration-009\Plot_files\vulcan_solution.plt" 
OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\output\VulcanProcessingOutput"

# ---------------- USER SETTINGS - Controls the VULCAN case to be processed ----------------
CASE = "CAVmix_SSWT_r0p5_noinject"

# full loop Slice positions
#YZ_SLICE_X = [0.327131, 0.395304, 0.4293905, 0.46552219, 0.47506641, 0.4839289, 0.49415485, 0.50369907, 0.51324329, 0.52210578, 0.53165, 0.622183744]   
#XY_SLICE_Z = [0.0127]   

# Testing loop positions
YZ_SLICE_X = [0.327131]   
XY_SLICE_Z = [0.0127]              

# ------------------------------------------------------------------------------------------

# I/O Directory Management
OUTPUT_DIR = f"{OUTPUT_ROOT}\{CASE}"
INPUT_FILE = f"{INPUT_ROOT}\{CASE}\{INPUT_DIR}"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ===================== LOAD .PLT ============================
# ============================================================
reader = VisItTecplotBinaryReader(registrationName=CASE, FileNames=[INPUT_FILE])
reader.Set(
    MeshStatus=['zone1','zone2'],
    PointArrayStatus=[
        'Pressure_Pa', 
        'U_velocity_m_s',
        'Density_kg_msup3_sup'
        'greekt_greeksubxx_subsupt_sup',
        'greekt_greeksubxy_subsupt_sup', 
        'greekt_greeksubxz_subsupt_sup', 
        'greekt_greeksubyy_subsupt_sup', 
        'greekt_greeksubyz_subsupt_sup', 
        'greekt_greeksubzz_subsupt_sup',
        'zone2/Pressure_Pa', 
        'zone2/U_velocity_m_s',
        'zone2/Density_kg_msup3_sup',
        'zone2/greekt_greeksubxx_subsupt_sup',
        'zone2/greekt_greeksubxy_subsupt_sup', 
        'zone2/greekt_greeksubxz_subsupt_sup', 
        'zone2/greekt_greeksubyy_subsupt_sup', 
        'zone2/greekt_greeksubyz_subsupt_sup', 
        'zone2/greekt_greeksubzz_subsupt_sup',
        ]
)

reader.UpdatePipeline()

ENABLE_SCHLIEREN = True
DENSITY_NAME = "zone2/Density_kg_msup3_sup" # fix logic below

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# ===================== CAMERA PRESETS =======================
# ============================================================

CAMERA_PRESETS = {
    "YZ": {  # renderView1
        "CameraPosition": [0.9120590004774782, 0.06435919553041458, 0.01269999984651804],
        "CameraFocalPoint": [0.4476749897003174,0.06435919553041458,0.01269999984651804],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.4564267410905977,
        "Colorbar": {
            "Orientation": "Vertical",  # default (never overridden)
            "Position": [0.6419153365718251,0.35205992509363293],
            "Length": 0.33,
        },
    },

    "XY_FAR": {  # renderView2
        "CameraPosition": [0.4476749897003174,0.06435919553041458,0.8285855560611272],
        "CameraFocalPoint": [0.4476749897003174,0.06435919553041458,0.01269999984651804],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.5477120893087172,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position": [0.3329077029840388,0.0898876404494382],
            "Length": 0.33,
        },
    },

    "XY_NEAR": {  # renderView3
        "CameraPosition": [0.5052304592990174,-0.007906881310699177,0.16060976619697473],
        "CameraFocalPoint": [0.5052304592990174,-0.007906881310699177, 0.01269999984651804],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.4562500191632675,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position": [0.31070090215128393,0.07490636704119849],
            "Length": 0.33,
        },
    },
}


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
