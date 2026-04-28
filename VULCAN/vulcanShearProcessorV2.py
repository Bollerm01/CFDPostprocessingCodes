from paraview.simple import *
import os

# ============================================================
# ===================== USER SETTINGS =======================
# ============================================================

#### Windows System Roots ####
# INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
# CASE = "CAVmix_SSWT_r0_noinject" #Change this prior to every run
# INPUT_FILE = rf"{INPUT_ROOT}\{CASE}\iteration-009\Plot_files\vulcan_solution.plt"

# OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\Paper Results\finalData\VULCAN\CompleteData\Contours"
# OUTPUT_DIR = os.path.join(OUTPUT_ROOT, "RD00")#Change this prior to every run

# Linux System Roots
CASE = "RD00"  # Change this prior to every run
INPUT_FILE = rf"/home/bollerma/RANSdata/VULCAN/SolutionFilesRDSweep/{CASE}/vulcan_solution.plt"
# INPUT_FILE = rf"/home/bollerma/RANSdata/VULCAN/SolutionFilesRDSweep/RD00/No_inject_r0_vorticity_add.plt" # specific for new vorticity plotting
OUTPUT_DIR = rf"/home/bollerma/RANSdata/VULCAN/SolutionFilesRDSweep/{CASE}/output/AVIATIONfigs/noBars"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Full loop Slice positions
# YZ_SLICE_X = [0.327131, 0.395304, 0.4293905, 0.46552219, 0.47506641, 0.4839289,
#               0.49415485, 0.50369907, 0.51324329, 0.52210578, 0.53165, 0.5452846,
#               0.622183744]
# XZ_SLICE_Y = [-0.0215, -0.01556]
# XY_SLICE_Z = [0.0001, 0.0127]

YZ_SLICE_X = [0.46552219, 0.49415485, 0.52210578, 0.53165]
XZ_SLICE_Y = [-0.0215, -0.01556]
XY_SLICE_Z = [0.0001, 0.0127]

# 3D slices group
YZ_SLICE_X_3D = [0.46552219, 0.49415485, 0.53165]  # x/L = 0.03, 0.45, 1
XY_SLICE_Z_3D = [0.0001]
XZ_SLICE_Y_3D = [-0.0215, -0.01556]

SCALAR_MAP = {
    "Pressure_Pa": {
        "zone1": "Pressure_Pa",
        "zone2": "zone2/Pressure_Pa",
    },
    "U_velocity_m_s": {
        "zone1": "U_velocity_m_s",
        "zone2": "zone2/U_velocity_m_s",
    },
    "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": {
        "zone1": "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup",
        "zone2": "zone2/Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup",
    },
    # zone2 entries point to normalized arrays
    "greekt_greeksubxx_subsupt_sup": {
        "zone1": "greekt_greeksubxx_subsupt_sup",
        "zone2": "Rxx_norm",
    },
    "greekt_greeksubxy_subsupt_sup": {
        "zone1": "greekt_greeksubxy_subsupt_sup",
        "zone2": "Rxy_norm",
    },
    "greekt_greeksubxz_subsupt_sup": {
        "zone1": "greekt_greeksubxz_subsupt_sup",
        "zone2": "Rxz_norm",
    },
    "greekt_greeksubyy_subsupt_sup": {
        "zone1": "greekt_greeksubyy_subsupt_sup",
        "zone2": "Ryy_norm",
    },
    "greekt_greeksubyz_subsupt_sup": {
        "zone1": "greekt_greeksubyz_subsupt_sup",
        "zone2": "Ryz_norm",
    },
    "greekt_greeksubzz_subsupt_sup": {
        "zone1": "greekt_greeksubzz_subsupt_sup",
        "zone2": "Rzz_norm",
    },
    # Vorticity magnitude (computed via PythonCalculator curl pipeline)
    "Vorticity_mag": {
        "zone1": "Vorticity_mag",  # may not exist on zone1; edges will still draw
        "zone2": "Vorticity_mag",
    },
}

SCALAR_TITLES = {
    "Pressure_Pa": "Pressure [Pa]",
    "U_velocity_m_s": "U Velocity [m/s]",
    "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": "Turbulence Kinetic Energy [m²/s²]",
    # Titles correspond to normalized τ_ij / (-ρ)
    "greekt_greeksubxx_subsupt_sup": r"$\tau_{xx}$",
    "greekt_greeksubxy_subsupt_sup": r"$\tau_{xy}$",
    "greekt_greeksubxz_subsupt_sup": r"$\tau_{xz}$",
    "greekt_greeksubyy_subsupt_sup": r"$\tau_{yy}$",
    "greekt_greeksubyz_subsupt_sup": r"$\tau_{yz}$",
    "greekt_greeksubzz_subsupt_sup": r"$\tau_{zz}$",
    "Vorticity_mag": r"$|\omega|$",
}

# <<< NEW: Optional per-logical-scalar ranges (min, max) >>>
SCALAR_RANGES = {
    # Pressure
    "Pressure_Pa": (13000.0, 32000.0),
    # Velocity
    "U_velocity_m_s": (-160.0, 730.0),
    # TKE
    "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": (0.0, 20000.0),
    # Reynolds stresses (now normalized by -ρ)
    "greekt_greeksubxx_subsupt_sup": (0.0, 2.4e4),
    "greekt_greeksubxy_subsupt_sup": (-5e3, 1.5e3),
    "greekt_greeksubxz_subsupt_sup": (-400.0, 250.0),
    "greekt_greeksubyy_subsupt_sup": (0.0, 6500.0),
    "greekt_greeksubyz_subsupt_sup": (-400.0, 250.0),
    "greekt_greeksubzz_subsupt_sup": (-100.0, 100.0),
    # Schlieren optional
    "Schlieren_magDelRho": (0.0, 120.0),
    "Schlieren_dRho_dX": (0.0, 90.0),
    "Schlieren_dRho_dY": (0.0, 90.0),
    # Vorticity magnitude – adjust as appropriate
    "Vorticity_mag": (0.0, 5.0e5),
}
# <<< END NEW >>>

# ============================================================
# =========== OPTIONAL: COLORMAP PRESETS PER SCALAR ==========
# ============================================================

DEFAULT_COLORMAP_PRESET = "Cool to Warm (Extended)"

SCALAR_COLORMAPS = {
    "Pressure_Pa": "Linear Blue (8_31f)",
    "U_velocity_m_s": "Cool to Warm (Extended)",
    "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": "Viridis (matplotlib)",
    "greekt_greeksubxx_subsupt_sup": "Turbo",
    "greekt_greeksubxy_subsupt_sup": "Turbo",
    "greekt_greeksubxz_subsupt_sup": "Turbo",
    "greekt_greeksubyy_subsupt_sup": "Turbo",
    "greekt_greeksubyz_subsupt_sup": "Turbo",
    "greekt_greeksubzz_subsupt_sup": "Turbo",
    "Schlieren_magDelRho": "Grayscale",
    "Schlieren_dRho_dX": "Grayscale",
    "Schlieren_dRho_dY": "Grayscale",
    "Vorticity_mag": "Inferno (matplotlib)",
}

DENSITY_ZONE2 = "zone2/Density_kg_msup3_sup"
ENABLE_SCHLIEREN = False

IMG_RES = [1920, 1080]

# ============================================================
# ===================== LOAD DATA ===========================
# ============================================================

reader = VisItTecplotBinaryReader(
    registrationName=CASE,
    FileName=[INPUT_FILE],
    PointArrayStatus=[
        "Pressure_Pa",
        "U_velocity_m_s",
        "V_velocity_m_s",
        "W_velocity_m_s",
        "Density_kg_msup3_sup",
        "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup",
        "greekt_greeksubxx_subsupt_sup",
        "greekt_greeksubxy_subsupt_sup",
        "greekt_greeksubxz_subsupt_sup",
        "greekt_greeksubyy_subsupt_sup",
        "greekt_greeksubyz_subsupt_sup",
        "greekt_greeksubzz_subsupt_sup",
        "zone2/Pressure_Pa",
        "zone2/U_velocity_m_s",
        "zone2/V_velocity_m_s",
        "zone2/W_velocity_m_s",
        "zone2/Density_kg_msup3_sup",
        "zone2/Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup",
        "zone2/greekt_greeksubxx_subsupt_sup",
        "zone2/greekt_greeksubxy_subsupt_sup",
        "zone2/greekt_greeksubxz_subsupt_sup",
        "zone2/greekt_greeksubyy_subsupt_sup",
        "zone2/greekt_greeksubyz_subsupt_sup",
        "zone2/greekt_greeksubzz_subsupt_sup",
    ],
)
reader.MeshStatus = ["zone1", "zone2"]
reader.UpdatePipeline()

zone1 = reader  # edges / surface variables

# Build normalized Reynolds-stress fields on zone2 via Calculator chain
zone2 = reader

calc_Rxx = Calculator(Input=zone2)
calc_Rxx.ResultArrayName = "Rxx_norm"
calc_Rxx.Function = '"zone2/greekt_greeksubxx_subsupt_sup" / (-"zone2/Density_kg_msup3_sup")'
calc_Rxx.UpdatePipeline()

calc_Rxy = Calculator(Input=calc_Rxx)
calc_Rxy.ResultArrayName = "Rxy_norm"
calc_Rxy.Function = '"zone2/greekt_greeksubxy_subsupt_sup" / (-"zone2/Density_kg_msup3_sup")'
calc_Rxy.UpdatePipeline()

calc_Rxz = Calculator(Input=calc_Rxy)
calc_Rxz.ResultArrayName = "Rxz_norm"
calc_Rxz.Function = '"zone2/greekt_greeksubxz_subsupt_sup" / (-"zone2/Density_kg_msup3_sup")'
calc_Rxz.UpdatePipeline()

calc_Ryy = Calculator(Input=calc_Rxz)
calc_Ryy.ResultArrayName = "Ryy_norm"
calc_Ryy.Function = '"zone2/greekt_greeksubyy_subsupt_sup" / (-"zone2/Density_kg_msup3_sup")'
calc_Ryy.UpdatePipeline()

calc_Ryz = Calculator(Input=calc_Ryy)
calc_Ryz.ResultArrayName = "Ryz_norm"
calc_Ryz.Function = '"zone2/greekt_greeksubyz_subsupt_sup" / (-"zone2/Density_kg_msup3_sup")'
calc_Ryz.UpdatePipeline()

calc_Rzz = Calculator(Input=calc_Ryz)
calc_Rzz.ResultArrayName = "Rzz_norm"
calc_Rzz.Function = '"zone2/greekt_greeksubzz_subsupt_sup" / (-"zone2/Density_kg_msup3_sup")'
calc_Rzz.UpdatePipeline()

# === VORTICITY MOD (trace-based) ===
# Start from the end of the Rij_norm chain
zone2 = calc_Rzz

# 1) Build velocity vector Velocity_Vect = (U, V, W) using Calculator
vel_calc = Calculator(registrationName="Velocity_Vect", Input=zone2)
vel_calc.ResultArrayName = "Velocity_Vect"
vel_calc.Function = (
    'iHat*"zone2/U_velocity_m_s"'
    '+jHat*"zone2/V_velocity_m_s"'
    '+kHat*"zone2/W_velocity_m_s"'
)
vel_calc.UpdatePipeline()

# 2) PythonCalculator: vorticity vector = curl(Velocity_Vect)
vorticity_calc = PythonCalculator(registrationName="vorticity", Input=vel_calc)
vorticity_calc.Expression = "curl(Velocity_Vect)"
vorticity_calc.ArrayName = "vorticity"
vorticity_calc.UpdatePipeline()

# 3) Calculator: vorticity magnitude
vort_mag_calc = Calculator(registrationName="vorticitymagavg", Input=vorticity_calc)
vort_mag_calc.ResultArrayName = "Vorticity_mag"
vort_mag_calc.Function = "mag(vorticity)"
vort_mag_calc.UpdatePipeline()

# final zone2 source for everything downstream (Rij_norm + Vorticity_mag)
zone2 = vort_mag_calc
# === END VORTICITY MOD (trace-based) ===

# Map logical scalars to the pipeline *source* to slice
SCALAR_SOURCES = {
    "Pressure_Pa": zone2,
    "U_velocity_m_s": zone2,
    "Turbulence_Kinetic_Energy_msup2_sup_ssup2_sup": zone2,
    "greekt_greeksubxx_subsupt_sup": zone2,
    "greekt_greeksubxy_subsupt_sup": zone2,
    "greekt_greeksubxz_subsupt_sup": zone2,
    "greekt_greeksubyy_subsupt_sup": zone2,
    "greekt_greeksubyz_subsupt_sup": zone2,
    "greekt_greeksubzz_subsupt_sup": zone2,
    "Vorticity_mag": zone2,
}

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
        "ParallelScale": 0.1,
        "Colorbar": {"Orientation": "Vertical", "Position": [0.642, 0.352], "Length": 0.33},
    },
    "XZ": {
        "CameraPosition": [0.4895413324640084, 0.8157857852644791, 0.009204647557753496],
        "CameraFocalPoint": [0.4895413324640084, -0.0215000007301569, 0.009204647557753496],
        "CameraViewUp": [-1.0, 0.0, 0.0],
        "ParallelScale": 0.032211892863822096,
        "Colorbar": {"Orientation": "Vertical", "Position": [0.642, 0.352], "Length": 0.33},
    },
    "XY_FAR": {
        "CameraPosition": [0.447675, 0.064359, 0.828586],
        "CameraFocalPoint": [0.447675, 0.064359, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.28,
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.333, 0.090], "Length": 0.33},
    },
    "XY_NEAR": {
        "CameraPosition": [0.50523, -0.007907, 0.16061],
        "CameraFocalPoint": [0.50523, -0.007907, 0.0127],
        "CameraViewUp": [0, 1, 0],
        "ParallelScale": 0.05,
        "Colorbar": {"Orientation": "Horizontal", "Position": [0.311, 0.075], "Length": 0.33},
    },
    "3D_NEAR": {
        "CameraPosition": [0.5824733318592127, 0.04876318085243274, 0.16198669927641116],
        "CameraFocalPoint": [0.5081591609315163, -0.006139535238138901, 0.008629380687868398],
        "CameraViewUp": [-0.09739205196914372, 0.9510508347723189, -0.29328671618761587],
        "ParallelScale": 0.045,
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


def normalize_scalar_name(array_name):
    if "/" in array_name:
        return array_name.split("/", 1)[1]
    return array_name


def apply_lut_range(lut, array_name):
    logical_name = normalize_scalar_name(array_name)
    if logical_name in SCALAR_RANGES:
        vmin, vmax = SCALAR_RANGES[logical_name]
        lut.RescaleTransferFunction(vmin, vmax)
    else:
        lut.RescaleTransferFunctionToDataRange()


def apply_lut_preset_for_logical(lut, logical_scalar_name):
    preset = SCALAR_COLORMAPS.get(logical_scalar_name, DEFAULT_COLORMAP_PRESET)
    lut.ApplyPreset(preset, True)


def apply_camera_and_colorbar(lut, preset, title):
    p = CAMERA_PRESETS[preset]

    view.CameraPosition = p["CameraPosition"]
    view.CameraFocalPoint = p["CameraFocalPoint"]
    view.CameraViewUp = p["CameraViewUp"]
    view.CameraParallelScale = p["ParallelScale"]

    sb = GetScalarBar(lut, view)
    sb.Visibility = 0 # 1 for colorbar
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

    colorPalette = GetSettingsProxy("ColorPalette")
    colorPalette.Background = [1.0, 1.0, 1.0]
    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0]


def make_slice(src, origin, normal, scalar_name=None, loc_identifier=None):
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

    loc_id = fname.replace(" ", "_")

    # zone1: from reader (edges)
    zone1_slice = make_slice(zone1, origin, normal, scalar_name=scalar_zone1, loc_identifier=loc_id)

    # zone2: from appropriate calculator pipeline source
    src_for_logical = SCALAR_SOURCES.get(logical_scalar, zone2)
    zone2_slice = make_slice(src_for_logical, origin, normal, scalar_name=scalar_zone2, loc_identifier=loc_id)

    # Volume slice (zone2)
    vol_disp = Show(zone2_slice, view)
    vol_disp.Representation = "Surface"
    lut = None
    try:
        loc2 = array_location(zone2_slice, scalar_zone2)
        ColorBy(vol_disp, (loc2, scalar_zone2))
        lut = GetColorTransferFunction(scalar_zone2)
        apply_lut_range(lut, scalar_zone2)
        apply_lut_preset_for_logical(lut, logical_scalar)
    except RuntimeError:
        print(f"Warning: {scalar_zone2} not found on zone2 slice for {logical_scalar}")

    # Edge slice (zone1) – black edges
    edge_disp = Show(zone1_slice, view)
    edge_disp.Representation = "Surface With Edges"
    edge_disp.DiffuseColor = [0, 0, 0]
    edge_disp.LineWidth = 1.5
    try:
        loc1 = array_location(zone1_slice, scalar_zone1)
        ColorBy(edge_disp, (loc1, scalar_zone1))
    except RuntimeError:
        # Expected for fields not present on zone1
        pass

    if lut:
        title = SCALAR_TITLES.get(logical_scalar, logical_scalar)
        apply_camera_and_colorbar(lut, preset, title)

    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0]

    Render(view)
    SaveScreenshot(
        os.path.join(OUTPUT_DIR, f"{fname}_{logical_scalar}_VULCAN.png"),
        view,
        ImageResolution=IMG_RES,
        TransparentBackground=1,
    )

    if hide_slice:
        Hide(zone1_slice, view)
        Hide(zone2_slice, view)


def make_3D_slice_view(slices, preset, fname, scalar_zone2, logical_scalar):
    lut = GetColorTransferFunction(scalar_zone2)

    for sl in slices:
        SetActiveSource(sl)
        disp = Show(sl, view)
        disp.Representation = "Surface"
        loc = array_location(sl, scalar_zone2)
        ColorBy(disp, (loc, scalar_zone2))

    apply_lut_range(lut, scalar_zone2)
    apply_lut_preset_for_logical(lut, logical_scalar)

    title = SCALAR_TITLES.get(logical_scalar, logical_scalar)
    apply_camera_and_colorbar(lut, preset, title)

    view.OrientationAxesLabelColor = [0.0, 0.0, 0.0]

    Render(view)
    SaveScreenshot(
        os.path.join(OUTPUT_DIR, f"{fname}_{logical_scalar}_VULCAN.png"),
        view,
        ImageResolution=IMG_RES,
        TransparentBackground=1,
    )

    for sl in slices:
        Hide(sl, view)

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
        apply_lut_range(lut, calc.ResultArrayName)
        logical_name = calc.ResultArrayName
        apply_lut_preset_for_logical(lut, logical_name)

        apply_camera_and_colorbar(lut, preset, calc.ResultArrayName)

        Render(view)
        SaveScreenshot(
            os.path.join(OUTPUT_DIR, f"{fname}_{calc.ResultArrayName}_VULCAN.png"),
            view,
            ImageResolution=IMG_RES,
            TransparentBackground=1,
        )

        Hide(slice_calc, view)


def make_slice_group(xySlices, xzSlices, yzSlices, scalar_zone2, logical_scalar):
    group = []
    src_for_logical = SCALAR_SOURCES.get(logical_scalar, zone2)

    if xySlices:
        for z in xySlices:
            loc_ID = f"XY_near_z{z:+0.5f}"
            sl = make_slice(
                src=src_for_logical,
                origin=[0, 0, z],
                normal=[0, 0, 1],
                scalar_name=scalar_zone2,
                loc_identifier=loc_ID,
            )
            group.append(sl)

    if xzSlices:
        for y in xzSlices:
            loc_ID = f"XZ_y{y:+0.5f}"
            sl = make_slice(
                src=src_for_logical,
                origin=[0, y, 0],
                normal=[0, 1, 0],
                scalar_name=scalar_zone2,
                loc_identifier=loc_ID,
            )
            group.append(sl)

    if yzSlices:
        for x in yzSlices:
            loc_ID = f"YZ_x{x:+0.5f}"
            sl = make_slice(
                src=src_for_logical,
                origin=[x, 0, 0],
                normal=[1, 0, 0],
                scalar_name=scalar_zone2,
                loc_identifier=loc_ID,
            )
            group.append(sl)

    print(f"Grouped 3D slice proxies for {scalar_zone2} ({logical_scalar}): {group}")
    return group

# ============================================================
# ===================== EXECUTION ============================
# ============================================================

for logical_scalar in SCALAR_MAP.keys():
    scalar_zone2 = SCALAR_MAP[logical_scalar]["zone2"]

    # 2D OVERLAY SLICES
    for x in YZ_SLICE_X:
        render_overlay_slice(
            origin=[x, 0, 0],
            normal=[1, 0, 0],
            preset="YZ",
            fname=f"YZ_x{x:+0.5f}",
            logical_scalar=logical_scalar,
        )

    for y in XZ_SLICE_Y:
        render_overlay_slice(
            origin=[0, y, 0],
            normal=[0, 1, 0],
            preset="XZ",
            fname=f"XZ_y{y:+0.5f}",
            logical_scalar=logical_scalar,
        )

    for z in XY_SLICE_Z:
        render_overlay_slice(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_NEAR",
            fname=f"XY_near_z{z:+0.5f}",
            logical_scalar=logical_scalar,
        )
        render_overlay_slice(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_FAR",
            fname=f"XY_far_z{z:+0.5f}",
            logical_scalar=logical_scalar,
        )

    # 3D FIGS - Near 3D (zone2 slices) – enable if desired
    # sliceGroup = make_slice_group(
    #     xySlices=XY_SLICE_Z_3D,
    #     xzSlices=XZ_SLICE_Y_3D,
    #     yzSlices=YZ_SLICE_X_3D,
    #     scalar_zone2=scalar_zone2,
    #     logical_scalar=logical_scalar,
    # )
    # outputFileName = "3D_Near_Group"
    # make_3D_slice_view(
    #     slices=sliceGroup,
    #     preset="3D_NEAR",
    #     fname=outputFileName,
    #     scalar_zone2=scalar_zone2,
    #     logical_scalar=logical_scalar,
    # )

if ENABLE_SCHLIEREN:
    for z in XY_SLICE_Z:
        render_schlieren(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_NEAR",
            fname=f"XY_near_z{z:+0.5f}",
        )
        render_schlieren(
            origin=[0, 0, z],
            normal=[0, 0, 1],
            preset="XY_FAR",
            fname=f"XY_far_z{z:+0.5f}",
        )

print("\nAll slices rendered successfully.")