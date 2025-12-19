from paraview.simple import *
import os

# ============================================================
# ===================== USER SETTINGS ========================
# ============================================================

INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
CASE = "CAVmix_SSWT_r0p5_noinject"
INPUT_FILE = rf"{INPUT_ROOT}\{CASE}\iteration-009\Plot_files\vulcan_solution.plt"

OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\output\VulcanProcessingOutput"
OUTPUT_DIR = os.path.join(OUTPUT_ROOT, CASE)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Slice locations
YZ_SLICE_X = [0.327131]
XY_SLICE_Z = [0.0127]

# Scalars to render (volume-based)
SCALARS = [
    "Pressure_Pa",
    "U_velocity_m_s",
]

ENABLE_SCHLIEREN = True
DENSITY_NAME = "Density_kg_msup3_sup"

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

# ============================================================
# ===================== LOAD DATA ============================
# ============================================================

reader = VisItTecplotBinaryReader(
    registrationName=CASE,
    FileNames=[INPUT_FILE]
)

reader.MeshStatus = ["zone1", "zone2"]
reader.UpdatePipeline()

# ============================================================
# ===================== EXTRACT ZONES ========================
# ============================================================

def extract_zone(src, zone):
    ex = ExtractBlock(Input=src)
    ex.Selectors = [f"/Root/{zone}"]
    ex.UpdatePipeline()
    return ex

zone1 = extract_zone(reader, "zone1")  # edges / surfaces
zone2 = extract_zone(reader, "zone2")  # volume

# ============================================================
# ===================== VIEW SETUP ===========================
# ============================================================

view = GetActiveViewOrCreate("RenderView")
view.Background = [1, 1, 1]
view.CameraParallelProjection = 1

# ============================================================
# ===================== CAMERA PRESETS =======================
# ============================================================

CAMERA_PRESETS = {
    "YZ": {
        "CameraPosition": [0.9120590004774782, 0.06435919553041458, 0.0127],
        "CameraFocalPoint": [0.4476749897003174, 0.06435919553041458, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.4564267410905977,
        "Colorbar": {
            "Orientation": "Vertical",
            "Position": [0.6419153365718251, 0.35205992509363293],
            "Length": 0.33,
        },
    },
    "XY_FAR": {
        "CameraPosition": [0.4476749897003174, 0.06435919553041458, 0.8285855560611272],
        "CameraFocalPoint": [0.4476749897003174, 0.06435919553041458, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.5477120893087172,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position": [0.3329077029840388, 0.0898876404494382],
            "Length": 0.33,
        },
    },
    "XY_NEAR": {
        "CameraPosition": [0.5052304592990174, -0.007906881310699177, 0.16060976619697473],
        "CameraFocalPoint": [0.5052304592990174, -0.007906881310699177, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.4562500191632675,
        "Colorbar": {
            "Orientation": "Horizontal",
            "Position": [0.31070090215128393, 0.07490636704119849],
            "Length": 0.33,
        },
    },
}

# ============================================================
# ===================== UTILITIES ============================
# ============================================================

def array_location(src, name):
    pd = src.GetPointDataInformation()
    cd = src.GetCellDataInformation()
    if pd.GetArray(name):
        return "POINTS"
    if cd.GetArray(name):
        return "CELLS"
    raise RuntimeError(f"Array '{name}' not found")

def apply_camera_and_colorbar(lut, preset, title):
    p = CAMERA_PRESETS[preset]

    view.CameraPosition = p["CameraPosition"]
    view.CameraFocalPoint = p["CameraFocalPoint"]
    view.CameraViewUp = p["CameraViewUp"]
    view.CameraParallelScale = p["ParallelScale"]

    bar = GetScalarBar(lut, view)
    bar.Visibility = 1
    bar.WindowLocation = "Any Location"
    bar.Orientation = p["Colorbar"]["Orientation"]
    bar.Position = p["Colorbar"]["Position"]
    bar.ScalarBarLength = p["Colorbar"]["Length"]
    bar.Title = title
    bar.ComponentTitle = ""

# ============================================================
# ===================== SLICE HELPERS ========================
# ============================================================

def make_slice(src, origin, normal):
    sl = Slice(Input=src)
    sl.SliceType = "Plane"
    sl.SliceType.Origin = origin
    sl.SliceType.Normal = normal
    sl.UpdatePipeline()
    return sl

# ============================================================
# ===================== OVERLAY SLICE ========================
# ============================================================

def render_overlay_slice(origin, normal, preset, fname, scalar):

    # ---- Volume slice ----
    vol_slice = make_slice(zone2, origin, normal)
    vol_disp = Show(vol_slice, view)
    loc = array_location(vol_slice, scalar)
    ColorBy(vol_disp, (loc, scalar))

    lut = GetColorTransferFunction(scalar)
    lut.RescaleTransferFunctionToDataRange()
    lut.ApplyPreset(COLORMAP_PRESET, True)

    # ---- Edge slice ----
    edge_slice = make_slice(zone1, origin, normal)
    edge_disp = Show(edge_slice, view)
    edge_disp.Representation = "Surface With Edges"
    edge_disp.DiffuseColor = [0, 0, 0]
    edge_disp.LineWidth = 1.5

    apply_camera_and_colorbar(lut, preset, scalar)
    Render(view)

    SaveScreenshot(
        os.path.join(OUTPUT_DIR, f"{fname}_{scalar}.png"),
        view,
        ImageResolution=IMG_RES
    )

    Hide(vol_slice, view)
    Hide(edge_slice, view)

# ============================================================
# ===================== SCHLIEREN ============================
# ============================================================

def schlieren_pipeline(slice_src):

    grad = Gradient(Input=slice_src)
    grad.ScalarArray = ["POINTS", DENSITY_NAME]
    grad.ResultArrayName = "delRho"

    mag = Calculator(Input=grad)
    mag.ResultArrayName = "Schlieren_magDelRho"
    mag.Function = "mag(delRho)"

    dx = Calculator(Input=grad)
    dx.ResultArrayName = "Schlieren_dRho_dX"
    dx.Function = "delRho[0]"

    dy = Calculator(Input=grad)
    dy.ResultArrayName = "Schlieren_dRho_dY"
    dy.Function = "delRho[1]"

    return [mag, dx, dy]

def render_schlieren(origin, normal, preset, fname):

    base_slice = make_slice(zone2, origin, normal)

    for calc in schlieren_pipeline(base_slice):
        disp = Show(calc, view)
        name = calc.ResultArrayName
        loc = array_location(calc, name)

        ColorBy(disp, (loc, name))
        lut = GetColorTransferFunction(name)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset, name)
        Render(view)

        SaveScreenshot(
            os.path.join(OUTPUT_DIR, f"{fname}_{name}.png"),
            view,
            ImageResolution=IMG_RES
        )

        Hide(calc, view)

    Hide(base_slice, view)

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for scalar in SCALARS:
    for x in YZ_SLICE_X:
        render_overlay_slice(
            origin=[x, 0, 0],
            normal=[1, 0, 0],
            preset="YZ",
            fname=f"YZ_x{x:+0.5f}",
            scalar=scalar
        )

    for z in XY_SLICE_Z:
        render_overlay_slice(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_NEAR",
            fname=f"XY_near_z{z:+0.5f}",
            scalar=scalar
        )

        render_overlay_slice(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_FAR",
            fname=f"XY_far_z{z:+0.5f}",
            scalar=scalar
        )

if ENABLE_SCHLIEREN:
    for z in XY_SLICE_Z:
        render_schlieren(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_NEAR",
            fname=f"XY_near_z{z:+0.5f}"
        )

        render_schlieren(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_FAR",
            fname=f"XY_far_z{z:+0.5f}"
        )

print("\nAll slices rendered successfully.")
