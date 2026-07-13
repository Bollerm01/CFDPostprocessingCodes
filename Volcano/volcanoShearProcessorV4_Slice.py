from paraview.simple import *
import os

# Code to generate thesis 3D contours for R/D SLICE sweep (0.0, 0.17, 0.52)
# Input: latest.volcano file for the full-width R/D cavity 
# Output: Folder with 3D and 2D layouts of the domain slices

# ============================================================
# ======================= USER INPUT =========================
# ============================================================

# Full Inputs
INPUT_FILES= [
    "/home/bollerma/LESdata/SSWT/sliceCav/J35/RD00si/SSWTM2TestInjectSlice_airOnly_001/latest.volcano", # J35/RD00si Path 3
    "/home/bollerma/LESdata/SSWT/sliceCav/J35/RD52si/SSWTM2RD52InjectSlice_airOnly_000/latest.volcano", # J35/RD52si Path 4
    "/home/bollerma/LESdata/SSWT/sliceCav/J140/RD00si/SSWTM2RD00si_airOnly_001/latest.volcano", # J140/RD00si Path 5 
    "/home/bollerma/LESdata/SSWT/sliceCav/J140/RD52si/SSWTM2RD52si_airOnly_002/latest.volcano" # J140/RD52si Path 6
]
# INPUT_FILES= [
#     "/home/bollerma/LESdata/SSWT/sliceCav/RD00s/SSWTM2Test2s_SurfKulite_003/latest.volcano",  # RD00s Path 0
#     "/home/bollerma/LESdata/SSWT/sliceCav/RD17s/SSWTM2TestRD17s_SurfKulite_001/latest.volcano", # RD17s Path 1
#     "/home/bollerma/LESdata/SSWT/sliceCav/RD52s/SSWTM2TestRD52s_SurfKulite_004/latest.volcano", # RD52s Path 2
#     "/home/bollerma/LESdata/SSWT/sliceCav/J35/RD00si/SSWTM2TestInjectSlice_airOnly_001/latest.volcano", # J35/RD00si Path 3
#     "/home/bollerma/LESdata/SSWT/sliceCav/J35/RD52si/SSWTM2RD52InjectSlice_airOnly_000/latest.volcano", # J35/RD52si Path 4
#     "/home/bollerma/LESdata/SSWT/sliceCav/J140/RD00si/SSWTM2RD00si_airOnly_001/latest.volcano", # J140/RD00si Path 5 
#     "/home/bollerma/LESdata/SSWT/sliceCav/J140/RD52si/SSWTM2RD52si_airOnly_002/latest.volcano" # J140/RD52si Path 6
# ]


# OUTPUT_DIRS = [
#     "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/RD00", # RD00 Output
#     "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/RD17", # RD17 Output
#     "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/RD52" # RD52 Output
# ]
OUTPUT_DIRS = [
    "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/J35/RD00si", # J35/RD00si Path 
    "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/J35/RD52si", # J35/RD52si Path 
    "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/J140/RD00si", # J140/RD00si Path 
    "/home/bollerma/LESdata/SSWT/sliceCav/3DfigOutput/J140/RD52si" # J140/RD52si Path 
]

for i in range(len(INPUT_FILES)):
    folder_path = os.path.dirname(INPUT_FILES[i])
    file_name   = os.path.basename(folder_path)

    # Scalars to render
    # SCALARS = ["pressure"]
    SCALARS = [
        "velocityx", "velocityxavg", "tke", "pressure", "pressureavg",
        "vorticitymag", "vorticitymagavg"
    ]

    # User-defined scalar ranges (min, max) per array name.
    # If a scalar is not listed the script falls back to the data range.
    SCALAR_RANGES = {
        # Velocities
        "velocityx":    (-160.0, 730.0),
        "velocityxavg": (-160.0, 730.0),

        # Turbulence / pressure
        "tke":         (0.0, 20000.0),
        "pressure":    (13000.0, 32000.0),
        "pressureavg": (13000.0, 32000.0),

        # Vorticity
        "vorticitymag":    (0.0, 5.0e5),
        "vorticitymagavg": (0.0, 5.0e5),
    }

    # ============================================================
    # =========== COLORMAP PRESETS PER SCALAR ====================
    # ============================================================
    DEFAULT_CB_NAME = ''

    CB_NAMES = {
        "velocityx":    "Axial Velocity (m/s)",
        "velocityxavg": "Avg. Axial Velocity (m/s)",

        "tke":         "TKE (J/kg)",
        "pressure":    "Pressure (Pa)",
        "pressureavg": "Avg. Pressure (Pa)",

        "vorticitymag":    "Vorticity Magnitude (1/s)",
        "vorticitymagavg": "Avg. Vorticity Magnitude (1/s)",
    }

    DEFAULT_COLORMAP_PRESET = "Cool to Warm (Extended)"

    SCALAR_COLORMAPS = {
        "velocityx":    "Cool to Warm (Extended)",
        "velocityxavg": "Cool to Warm (Extended)",

        "tke":         "Viridis (matplotlib)",
        "pressure":    "Linear Blue (8_31f)",
        "pressureavg": "Linear Blue (8_31f)",

        "vorticitymag":    "Inferno (matplotlib)",
        "vorticitymagavg": "Inferno (matplotlib)",
    }

    # ============================================================
    # ======================= SLICE POSITIONS ====================
    # ============================================================

    # Full Loop
    YZ_SLICE_X = [2.1508, 2.1691, 2.1793151, 2.19847, 2.216945]  # x/L = 0.03, 0.3, 0.45, 0.73, 1
    XY_SLICE_Z  = [0.0]
    XZ_SLICE_Y  = [0.0093, 0.001]

    # Debug Loop
    # YZ_SLICE_X = [2.1793151]  # x/L = 0.03, 0.3, 0.73, 1
    # XY_SLICE_Z  = [0.0]
    # XZ_SLICE_Y  = [0.0093]


    # YZ slices shown in the 3D composite view (subset of YZ_SLICE_X).
    # Corresponds to the slices named qPlane / 3qPlane / xL0p3 / 0p86 / xL1p2 / farwall
    # in the trace.  Adjust to match whatever YZ planes you want visible in the 3D render.
    YZ_SLICE_X_3D = [2.15, 2.17, 2.19, 2.21, 2.23]  # x/L ≈ 0.03, 0.45, 1
    XY_SLICE_Z_3D = [-0.012] 

    IMG_RES = [1920, 1080]

    os.makedirs(OUTPUT_DIRS[i], exist_ok=True)

    # ============================================================
    # ===================== CAMERA PRESETS =======================
    # ============================================================

    CAMERA_PRESETS = {
        "XY_NEAR": {
            "CameraPosition":   [2.1922574427684838, 0.018226216790868725, 5.011192474629075],
            "CameraFocalPoint": [2.1922574427684838, 0.018226216790868725, 0.0],
            "CameraViewUp":     [0, 1, 0],
            "ParallelScale":    0.06142870916705136,
            "Colorbar": {
                "Orientation": "Horizontal",
                "Position":    [0.29, 0.15],
                "Length":      0.5,
            }
        },
        "XY_FAR": {
            "CameraPosition":   [1.25, 0.05994982668344116, 5.011016610690195],
            "CameraFocalPoint": [1.25, 0.05994982668344116, 0.0],
            "CameraViewUp":     [0, 1, 0],
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
            "CameraViewUp":     [0, 1, 0],
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
        # ---- 3D view — camera taken from the final settled position in the trace ----
        "3D": {
            "CameraPosition":   [2.06451, 0.0175185, 0.0908117],
            "CameraFocalPoint": [2.18426, 0.0125338, 0.0139986],
            "CameraViewUp":     [0.0228175, 0.99974, 0.0],
            "ParallelScale":    0.04, #was 1.2967534046463778
            "InteractionMode":  "3D",
            # Colorbar layout matches the trace: horizontal, centred near the bottom
            "Colorbar": {
                "Orientation": "Horizontal",
                "Position":    [0.35328840970350406, 0.04477611940298508],
                "Length":      0.33,
            }
        }
    }

    # ============================================================
    # ===================== LOAD DATA ============================
    # ============================================================

    src = OpenDataFile(INPUT_FILES[i])
    RenameSource(file_name, src)
    src.CellArrayStatus = SCALARS

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
        except Exception:
            pass


    def array_location(source, name):
        pd = source.GetPointDataInformation()
        cd = source.GetCellDataInformation()
        if pd.GetArray(name) is not None:
            return "POINTS"
        if cd.GetArray(name) is not None:
            return "CELLS"
        raise RuntimeError(f"Array '{name}' not found on points or cells")


    def apply_lut_range(lut, array_name):
        if array_name in SCALAR_RANGES:
            vmin, vmax = SCALAR_RANGES[array_name]
            lut.RescaleTransferFunction(vmin, vmax)
        else:
            lut.RescaleTransferFunctionToDataRange()


    def apply_lut_preset(lut, array_name):
        preset = SCALAR_COLORMAPS.get(array_name, DEFAULT_COLORMAP_PRESET)
        lut.ApplyPreset(preset, True)


    def apply_camera_and_colorbar(lut, preset_name, array_name):
        p = CAMERA_PRESETS[preset_name]

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

        bar.AutomaticLabelFormat = 0
        bar.UseCustomLabels       = 0
        bar.WindowLocation        = "Any Location"
        bar.ScalarBarThickness    = bar.ScalarBarThickness  # force refresh

        bar.Orientation     = p["Colorbar"]["Orientation"]
        bar.Position        = p["Colorbar"]["Position"]
        bar.ScalarBarLength = p["Colorbar"]["Length"]

        # bar.Title          = array_name
        cbPreset = CB_NAMES.get(array_name, DEFAULT_CB_NAME)
        bar.Title = cbPreset
        bar.ComponentTitle = ""
        bar.TitleFontSize  = 12
        bar.LabelFontSize  = 10
        bar.TitleColor     = [0.0, 0.0, 0.0]
        bar.LabelColor     = [0.0, 0.0, 0.0]

        # ---- Background (white) ----
        colorPalette = GetSettingsProxy('ColorPalette')
        colorPalette.Background = [1.0, 1.0, 1.0]

        # ---- Axis label colours ----
        view.OrientationAxesLabelColor   = [0.0, 0.0, 0.0]
        view.OrientationAxesOutlineColor = [0.0, 0.0, 0.0]


    # ============================================================
    # ===================== 2D SLICE (unchanged) =================
    # ============================================================

    def make_slice(origin, normal, fname, scalar):
        """Create a VolcanoSlice; do not show or save."""
        sl = VolcanoSlice(registrationName=fname, Input=src)
        sl.SlicePoint        = origin
        sl.SliceNormal       = normal
        sl.InterpolatedField = scalar
        sl.MinMaxField       = scalar
        sl.Crinkle           = 0
        return sl


    def create_slice(origin, normal, preset_name, fname, scalar):
        """Create, render, save, and hide a single 2-D slice."""
        sl   = make_slice(origin, normal, fname, scalar)
        disp = Show(sl, view)
        loc  = array_location(sl, scalar)
        ColorBy(disp, (loc, scalar))

        lut = GetColorTransferFunction(scalar)
        apply_lut_range(lut, scalar)
        apply_lut_preset(lut, scalar)

        apply_camera_and_colorbar(lut, preset_name, scalar)
        Render(view)

        SaveScreenshot(
            os.path.join(OUTPUT_DIRS[i], f"{fname}_{scalar}_Volcano.png"),
            view, ImageResolution=IMG_RES, TransparentBackground=1
        )
        Hide(sl, view)


    # ============================================================
    # ===================== 3D COMPOSITE VIEW ====================
    # ============================================================

    def make_3D_composite_view(yz_x_positions, xy_z_positions, scalar, output_fname="3D_composite"):
        """
        Build a 3-D scene that matches the trace:
        - Multiple YZ slices shown simultaneously with DisableLighting=1
        - A semi-transparent VolcanoSurface (opacity 0.15) as domain boundary
        - Shared LUT with manual / data range applied once
        - Camera and colourbar from the "3D" preset
        Saves one PNG then hides everything.
        """

        # ---- 1. Create and store YZ slice proxies ----
        slices = []
        for x in yz_x_positions:
            fname = f"YZ_x{x:+0.5f}_3D_{scalar}"
            sl    = make_slice([x, 0, 0], [1, 0, 0], fname, scalar)
            slices.append(sl)

        # ---- 1. Create and store XY slice proxies ----
        for z in xy_z_positions:
            fname = f"XY_z{z:+0.5f}_3D_{scalar}"
            sl    = make_slice([0, 0, z], [0, 0, 1], fname, scalar)
            # disp = Show(sl, view)
            # disp.Opacity = 0.7
            slices.append(sl)

        # ---- 2. Create domain surface ----
        surface = VolcanoSurface(registrationName="DomainSurface_3D", Input=src)
        surface.Clip       = 0          # no clip — show full domain boundary
        surface.UpdatePipeline()

        # ---- 3. Show surface (semi-transparent, uncoloured) ----
        surfDisp = Show(surface, view)
        surfDisp.ColorArrayName = ['POINTS', '']
        ColorBy(surfDisp, value=None)         # solid color / no scalar mapping
        surfDisp.Opacity = 0.15
        lut = GetColorTransferFunction(scalar)

        for sl in slices:
            SetActiveSource(sl)
            active_proxy = GetActiveSource()
            disp = Show(sl, view)
            active_name = [name for (name, proxy) in GetSources().items() if proxy == active_proxy]
            print(f"Active Name: {active_name[0][0]}")
            if "XY" in active_name[0][0]:
                disp.Opacity = 0.7 # sets opacity of the axial plane for display
                print("Opacity set successfully")
            SetActiveSource(sl)
            loc  = array_location(sl, scalar)
            ColorBy(disp, (loc, scalar))
            disp.DisableLighting = 1
            disp.SetScalarBarVisibility(view, True)

        # ---- 4. Show all slices, disable lighting, apply shared LUT ----
        apply_lut_range(lut, scalar)
        apply_lut_preset(lut, scalar)

        # ---- 5. Camera, colourbar, render, save ----
        apply_camera_and_colorbar(lut, "3D", scalar)
        print("Camera applied")
        Render(view)

        SaveScreenshot(
            os.path.join(OUTPUT_DIRS[i], f"{output_fname}_{scalar}_Volcano.png"),
            view, ImageResolution=IMG_RES, TransparentBackground=1
        )

        # ---- 6. Clean up ----
        for sl in slices:
            Hide(sl, view)
        Hide(surface, view)

        print(f"3D composite saved: {output_fname}_{scalar}_Volcano.png")

    def delete_downstream_pipeline(source_proxy):
        # Retrieve all pipeline objects and their inputs
        sources = GetSources()
        
        # Track items to delete so we don't modify the dict while iterating
        to_delete = []
        
        for name, obj in sources.items():
            proxy_instance = obj[0]
            # Check if the current proxy depends on our target source
            if hasattr(proxy_instance, 'Input') and proxy_instance.Input == source_proxy:
                to_delete.append(proxy_instance)
                
        # Recursively delete children and disconnect them
        for child in to_delete:
            delete_downstream_pipeline(child)
            Delete(child)


    # ============================================================
    # ===================== EXECUTION ============================
    # ============================================================

    for s in SCALARS:

        # ---- 2-D slices (YZ, XZ, XY) ----
        for x in YZ_SLICE_X:
            create_slice([x, 0, 0], [1, 0, 0], "YZ", f"YZ_x{x:+0.5f}", s)

        for y in XZ_SLICE_Y:
            create_slice([0, y, 0], [0, 1, 0], "XZ", f"XZ_y{y:+0.5f}", s)

        for z in XY_SLICE_Z:
            create_slice([0, 0, z], [0, 0, 1], "XY_NEAR", f"XY_near_z{z:+0.5f}", s)
            # create_slice([0, 0, z], [0, 0, 1], "XY_FAR", f"XY_far_z{z:+0.5f}", s)

        # ---- 3-D composite view ----
        make_3D_composite_view(YZ_SLICE_X_3D, XY_SLICE_Z_3D, s, output_fname="3D_composite")


    print(f"\nAll slices rendered correctly for {INPUT_FILES[i]}.")

    # Cleans up the pipeline 
    delete_downstream_pipeline(src)
    Delete(src)