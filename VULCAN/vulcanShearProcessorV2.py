from paraview.simple import *
import os

# ============================================================
# ===================== USER SETTINGS =======================
# ============================================================

INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
CASE = "CAVmix_SSWT_r0p5_noinject"
INPUT_FILE = rf"{INPUT_ROOT}\{CASE}\iteration-009\Plot_files\vulcan_solution.plt"

OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\output\VulcanProcessingOutput"
OUTPUT_DIR = os.path.join(OUTPUT_ROOT, CASE)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Test Locations
YZ_SLICE_X = [0.46552219, 0.49415485, 0.53165] #x/L = 0.03, 0.45, 1
XY_SLICE_Z = [0.0001]
XZ_SLICE_Y = [-0.0215, -0.01556]

# Full loop Slice positions
# YZ_SLICE_X = [0.327131, 0.395304, 0.4293905, 0.46552219, 0.47506641, 0.4839289, 0.49415485, 0.50369907, 0.51324329, 0.52210578, 0.53165, 0.5452846, 0.622183744]   
# XY_SLICE_Z = [0.0127]  

# 3D slices group
YZ_SLICE_X_3D = [0.46552219, 0.49415485, 0.53165] #x/L = 0.03, 0.45, 1
XY_SLICE_Z_3D = [0.0001]
XZ_SLICE_Y_3D = [-0.0215, -0.01556]



# SCALAR_MAP = {
#     "Pressure_Pa": {"zone1": "Pressure_Pa", "zone2": "zone2/Pressure_Pa"},
#     "U_velocity_m_s": {"zone1": "U_velocity_m_s", "zone2": "zone2/U_velocity_m_s"},
#     "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": {
#         "zone1": "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup",
#         "zone2": "zone2/Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup",
#     },
#     "greekt_greeksubxx_subsupt_sup": {"zone1": "greekt_greeksubxx_subsupt_sup", "zone2": "zone2/greekt_greeksubxx_subsupt_sup"},
#     "greekt_greeksubxy_subsupt_sup": {"zone1": "greekt_greeksubxy_subsupt_sup", "zone2": "zone2/greekt_greeksubxy_subsupt_sup"},
#     "greekt_greeksubxz_subsupt_sup": {"zone1": "greekt_greeksubxz_subsupt_sup", "zone2": "zone2/greekt_greeksubxz_subsupt_sup"},
#     "greekt_greeksubyy_subsupt_sup": {"zone1": "greekt_greeksubyy_subsupt_sup", "zone2": "zone2/greekt_greeksubyy_subsupt_sup"},
#     "greekt_greeksubyz_subsupt_sup": {"zone1": "greekt_greeksubyz_subsupt_sup", "zone2": "zone2/greekt_greeksubyz_subsupt_sup"},
#     "greekt_greeksubzz_subsupt_sup": {"zone1": "greekt_greeksubzz_subsupt_sup", "zone2": "zone2/greekt_greeksubzz_subsupt_sup"},
# }

# Debugging Scalar Map
SCALAR_MAP = {
    "U_velocity_m_s": {"zone1": "U_velocity_m_s", "zone2": "zone2/U_velocity_m_s"}
}

# # User-editable scalar bar titles
# SCALAR_TITLES = {
#     "Pressure_Pa": "Pressure [Pa]",
#     "U_velocity_m_s": "U Velocity [m/s]",
#     "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": "Turbulence Kinetic Energy [m²/s²]",
#     "greekt_greeksubxx_subsupt_sup": r"$\tau_{xx}$",
#     "greekt_greeksubxy_subsupt_sup": r"$\tau_{xy}$",
#     "greekt_greeksubxz_subsupt_sup": r"$\tau_{xz}$",
#     "greekt_greeksubyy_subsupt_sup": r"$\tau_{yy}$",
#     "greekt_greeksubyz_subsupt_sup": r"$\tau_{yz}$",
#     "greekt_greeksubzz_subsupt_sup": r"$\tau_{zz}$",
# }

# Debugging Titles
SCALAR_TITLES = {
    "U_velocity_m_s": "U Velocity [m/s]"
}

DENSITY_ZONE2 = "zone2/Density_kg_msup3_sup"
ENABLE_SCHLIEREN = False

IMG_RES = [1920, 1080]
COLORMAP_PRESET = "Cool to Warm (Extended)"

# ============================================================
# ===================== LOAD DATA ===========================
# ============================================================

reader = VisItTecplotBinaryReader(
    registrationName=CASE,
    FileName=[INPUT_FILE],
    PointArrayStatus=[
        'Pressure_Pa', 
        'U_velocity_m_s',
        'Density_kg_msup3_sup',
        'Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup',
        'greekt_greeksubxx_subsupt_sup',
        'greekt_greeksubxy_subsupt_sup', 
        'greekt_greeksubxz_subsupt_sup', 
        'greekt_greeksubyy_subsupt_sup', 
        'greekt_greeksubyz_subsupt_sup', 
        'greekt_greeksubzz_subsupt_sup',
        'zone2/Pressure_Pa', 
        'zone2/U_velocity_m_s',
        'zone2/Density_kg_msup3_sup',
        'zone2/Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup',
        'zone2/greekt_greeksubxx_subsupt_sup',
        'zone2/greekt_greeksubxy_subsupt_sup', 
        'zone2/greekt_greeksubxz_subsupt_sup', 
        'zone2/greekt_greeksubyy_subsupt_sup', 
        'zone2/greekt_greeksubyz_subsupt_sup', 
        'zone2/greekt_greeksubzz_subsupt_sup',
        ]
)
reader.MeshStatus = ["zone1", "zone2"]
reader.UpdatePipeline()

zone1 = reader  # edges / surface variables
zone2 = reader  # volume variables

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
        "CameraPosition": [0.912059, 0.064359, 0.0127],
        "CameraFocalPoint": [0.447675, 0.064359, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.1 , # was 0.1
        "Colorbar": {"Orientation": "Vertical", "Position": [0.642, 0.352], "Length": 0.33},
    },
    "XZ": {
        "CameraPosition": [0.4895413324640084, 0.8157857852644791, 0.009204647557753496],
        "CameraFocalPoint": [0.4895413324640084, -0.0215000007301569, 0.009204647557753496],
        "CameraViewUp":[-1.0, 0.0, 0.0],
        "ParallelScale": 0.032211892863822096,
        "Colorbar": {"Orientation": "Vertical", "Position": [0.642, 0.352], "Length": 0.33},
    },
    "XY_FAR": {
        "CameraPosition": [0.447675, 0.064359, 0.828586],
        "CameraFocalPoint": [0.447675, 0.064359, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.28, # was 0.3
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.333, 0.090], "Length": 0.33},
    },
    "XY_NEAR": {
        "CameraPosition": [0.50523, -0.007907, 0.16061],
        "CameraFocalPoint": [0.50523, -0.007907, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.05, # was 0.1
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.311, 0.075], "Length": 0.33},
    },
    "3D_NEAR": {
        "CameraPosition": [0.5824733318592127, 0.04876318085243274, 0.16198669927641116],
        "CameraFocalPoint": [0.5081591609315163, -0.006139535238138901, 0.008629380687868398],
        "CameraViewUp": [-0.09739205196914372, 0.9510508347723189, -0.29328671618761587],
        "ParallelScale": 0.045, # was 0.1
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.174555, 0.0997015], "Length": 0.5},
    },
}

# ============================================================
# ===================== UTILITIES ===========================
# ============================================================

def array_location(src, name):
    pd = src.GetPointDataInformation()
    cd = src.GetCellDataInformation()
    if pd.GetArray(name):
        return "POINTS"
    if cd.GetArray(name):
        return "CELLS"
    raise RuntimeError(f"Array '{name}' not found on source {src.GetXMLName()}")


def apply_camera_and_colorbar(lut, preset, title):
    p = CAMERA_PRESETS[preset]

    view.CameraPosition = p["CameraPosition"]
    view.CameraFocalPoint = p["CameraFocalPoint"]
    view.CameraViewUp = p["CameraViewUp"]
    view.CameraParallelScale = p["ParallelScale"]

    # Get scalar bar for current LUT
    sb = GetScalarBar(lut, view)
    sb.Visibility = 1 # CHANGE TO 0 TO HIDE BAR
    sb.WindowLocation = "Any Location"
    sb.Orientation = p["Colorbar"]["Orientation"]
    sb.Position = p["Colorbar"]["Position"]
    sb.ScalarBarLength = p["Colorbar"]["Length"]

    sb.Title = title
    sb.ComponentTitle = ""
    sb.TitleFontSize = 12
    sb.LabelFontSize = 10
    sb.LabelColor = [0.0, 0.0, 0.0]
    sb.TitleColor = [0.0, 0.0, 0.0]

    # --- Sets background ---
    # find settings proxy
    colorPalette = GetSettingsProxy('ColorPalette')

    # Properties modified on colorPalette (white)
    colorPalette.Background = [1.0, 1.0, 1.0]

    # ---- Sets axis label color -----
    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0] # black


def make_slice(src, origin, normal, scalar_name=None, loc_identifier=None):
    """
    Create a slice plane from a source, assign a unique registration name, and hide the plane.
    :param src: ParaView source
    :param origin: [x,y,z] slice origin
    :param normal: [nx,ny,nz] slice normal
    :param scalar_name: name of the scalar (for unique identifier)
    :param loc_identifier: location string (e.g., X0.3271, Z0.0127)
    :return: the Slice object
    """

    # Assign a unique registration name
    if scalar_name and loc_identifier:
        regName = f"{scalar_name}_{loc_identifier}"
    elif scalar_name:
        regName = f"{scalar_name}"
    else:
        regName = f"Slice_{CASE}"


    sl = Slice(registrationName=regName, Input=src)
    sl.SliceType = "Plane"
    sl.SliceType.Origin = origin
    sl.SliceType.Normal = normal
    
    sl.UpdatePipeline()

    # Hide the slice plane in the view
    disp = Show(sl)
    disp.Visibility = 0
    HideInteractiveWidgets(proxy=sl.SliceType)


    return sl


# ============================================================
# ===================== OVERLAY SLICE ========================
# ============================================================

def render_overlay_slice(origin, normal, preset, fname, logical_scalar, hide_slice=True):
    scalar_zone1 = SCALAR_MAP[logical_scalar]["zone1"]
    scalar_zone2 = SCALAR_MAP[logical_scalar]["zone2"]

    # Create slices with unique registration names
    loc_id = fname.replace(" ", "_")
    zone1_slice = make_slice(zone1, origin, normal, scalar_zone1, loc_id)
    zone2_slice = make_slice(zone2, origin, normal, scalar_zone2, loc_id)

    # Volume slice (zone2)
    vol_disp = Show(zone2_slice, view)
    vol_disp.Representation = "Surface"
    try:
        loc2 = array_location(zone2_slice, scalar_zone2)
        ColorBy(vol_disp, (loc2, scalar_zone2))
        lut = GetColorTransferFunction(scalar_zone2)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)
    except RuntimeError:
        print(f"Warning: {scalar_zone2} not found on zone2 slice")
        lut = None

    # Edge slice (zone1)
    edge_disp = Show(zone1_slice, view)
    edge_disp.Representation = "Surface With Edges"
    edge_disp.DiffuseColor = [0, 0, 0]
    edge_disp.LineWidth = 1.5
    try:
        loc1 = array_location(zone1_slice, scalar_zone1)
        ColorBy(edge_disp, (loc1, scalar_zone1))
    except RuntimeError:
        pass

    if lut:
        title = SCALAR_TITLES.get(logical_scalar, logical_scalar)
        apply_camera_and_colorbar(lut, preset, title)

    # ---- Sets axis label color -----
    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0] # black

    Render(view)
    SaveScreenshot(
        os.path.join(OUTPUT_DIR, f"{fname}_{logical_scalar}.png"),
        view,
        ImageResolution=IMG_RES, TransparentBackground=1
    )

    if hide_slice:
        Hide(zone1_slice, view)
        Hide(zone2_slice, view)

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
        slice_source = FindSource(sl)
        SetActiveSource(slice_source)
        disp = Show(slice_source, view)
        disp.Representation = "Surface"
        loc = array_location(slice_source, scalar)
        ColorBy(disp, (loc, scalar))

        lut = GetColorTransferFunction(scalar)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset, scalar)
        Render(view)

    # # Configure shared LUT
    # lut.RescaleTransferFunctionToDataRange()
    # lut.ApplyPreset(COLORMAP_PRESET, True)

    # # Apply camera + colorbar
    # apply_camera_and_colorbar(lut, preset, scalar)

    # # Render and save a single screenshot containing all visible slices
    # Render(view)

    # ---- Sets axis label color -----
    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0] # black

    scalarSave = scalar.split("/")[1]
    SaveScreenshot(os.path.join(OUTPUT_DIR, f"{fname}_{scalarSave}.png"),
                   view, ImageResolution=IMG_RES, TransparentBackground=1)

    # Optionally hide slices afterwards
    # for sl in slices:
    #     Hide(sl, view

# ============================================================
# ===================== SCHLIEREN ============================
# ============================================================

def schlieren_pipeline_full_domain():
    grad = Gradient(Input=zone2)
    grad.ScalarArray = ["POINTS", DENSITY_ZONE2]
    grad.ResultArrayName = "delRho"
    grad.UpdatePipeline()

    mag = Calculator(Input=grad)
    mag.ResultArrayName = "Schlieren_magDelRho"
    mag.Function = "mag(delRho)"
    mag.UpdatePipeline()

    dx = Calculator(Input=grad)
    dx.ResultArrayName = "Schlieren_dRho_dX"
    dx.Function = "delRho[0]"
    dx.UpdatePipeline()

    dy = Calculator(Input=grad)
    dy.ResultArrayName = "Schlieren_dRho_dY"
    dy.Function = "delRho[1]"
    dy.UpdatePipeline()

    return [mag, dx, dy]


def render_schlieren(origin, normal, preset, fname):
    for calc in schlieren_pipeline_full_domain():
        slice_calc = make_slice(calc, origin, normal)

        disp = Show(slice_calc, view)
        disp.Representation = "Surface"
        try:
            loc = array_location(slice_calc, calc.ResultArrayName)
            ColorBy(disp, (loc, calc.ResultArrayName))
        except RuntimeError:
            print(f"Warning: {calc.ResultArrayName} not found on slice")

        lut = GetColorTransferFunction(calc.ResultArrayName)
        lut.RescaleTransferFunctionToDataRange()
        lut.ApplyPreset(COLORMAP_PRESET, True)

        apply_camera_and_colorbar(lut, preset, calc.ResultArrayName)

        Render(view)
        SaveScreenshot(
            os.path.join(OUTPUT_DIR, f"{fname}_{calc.ResultArrayName}.png"),
            view,
            ImageResolution=IMG_RES, TransparentBackground=1
        )

        Hide(slice_calc, view)

def make_slice_group(xySlices, xzSlices, yzSlices, scalar):
    group = []
    if xySlices:
        for z in xySlices:
            loc_ID = f"XY_near_z{z:+0.5f}"
            sl_name = f"{scalar}_{loc_ID}"
            #sl = make_slice([0, 0, z], [0, 0, 1], sl_name, scalar, schlieren=False)
            group.append(sl_name)
    if xzSlices:
        for y in xzSlices:
            loc_ID = f"XZ_y{y:+0.5f}"
            sl_name = f"{scalar}_{loc_ID}"
            #sl = make_slice([0, y, 0], [0, 1, 0], sl_name, scalar, schlieren=False)
            group.append(sl_name)
    if yzSlices:
        for x in yzSlices:
            loc_ID = f"YZ_x{x:+0.5f}"
            sl_name = f"{scalar}_{loc_ID}"
            #sl = make_slice([x, 0, 0], [1, 0, 0], sl_name, scalar, schlieren=False)
            group.append(sl_name)

    print(f"Grouped Imgs: {group}")
    return group

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for scalar in SCALAR_MAP.keys():
    for x in YZ_SLICE_X:
        render_overlay_slice(
            origin=[x, 0, 0],
            normal=[1, 0, 0],
            preset="YZ",
            fname=f"YZ_x{x:+0.5f}",
            logical_scalar=scalar
        )

    for y in XZ_SLICE_Y:
        render_overlay_slice(
            origin=[0, y, 0],
            normal=[0, 1, 0],
            preset="XZ",
            fname=f"XZ_y{y:+0.5f}",
            logical_scalar=scalar
        )

    for z in XY_SLICE_Z:
        render_overlay_slice(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_NEAR",
            fname=f"XY_near_z{z:+0.5f}",
            logical_scalar=scalar
        )
        render_overlay_slice(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_FAR",
            fname=f"XY_far_z{z:+0.5f}",
            logical_scalar=scalar
        )
        ######### FIX HERE ##############
        # 3D figs - Near 3D
        scalar_zone2 = SCALAR_MAP[scalar]["zone2"]
        sliceGroup = make_slice_group(XY_SLICE_Z_3D, XZ_SLICE_Y_3D, YZ_SLICE_X_3D, scalar)
        outputFileName = "3D_Near_Group"
        make_3D_slice_view(sliceGroup, "3D_NEAR", outputFileName, scalar_zone2)

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
