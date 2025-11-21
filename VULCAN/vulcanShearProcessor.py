from paraview.simple import *
from paraview import servermanager
import os


#should be constant across radii
INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
INPUT_DIR = "iteration-009\Plot_files\vulcan_solution.plt" 
OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\output\VulcanProcessingOutput"

# ---------------- USER SETTINGS - Controls the VULCAN case to be processed ----------------
CASE = "CAVmix_SSWT_r0p5_noinject"

# Slice positions
YZ_SLICE_X = [-0.26, -0.2, -0.15, -0.1]   
XY_SLICE_Z = [0.0, 0.03805]                

# Line extraction along Y
X_LOCATIONS_FOR_LINE = [-0.2, -0.15, -0.1]
LINE_RESOLUTION = 500

# Variables
PRESSURE_NAME = "Pressure"
VELOCITY_NAME = "Velocity"
VELMAG_NAME = "VelocityMagnitude"
VELOCITY_X_NAME = "Velocity_X"

CAMERA_ZOOM = 0.25
IMG_RESOLUTION = [1920, 1080]

# ------------------------------------------------------------------------------------------

# I/O Directory Management
OUTPUT_DIR = f"{OUTPUT_ROOT}\{CASE}"
INPUT_FILE = f"{INPUT_ROOT}\{CASE}\{INPUT_DIR}"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ---------------- LOAD CGNS ----------------
reader = CONVERGECFDCGNSReader(FileNames=[INPUT_FILE])
reader.UpdatePipeline()

# ---------------- CALCULATOR: Extract Velocity X-component ----------------
calcUx = Calculator(Input=reader)
calcUx.ResultArrayName = VELOCITY_X_NAME
calcUx.Function = "Velocity[0]"  # Extract X-component (first column)
calcUx.UpdatePipeline()

# Use this as the source for all slices and lines
source_for_processing = calcUx

# ---------------- GLOBAL RANGE SCANNER ----------------
def get_global_range(proxy, array_name, component=None):
    data = servermanager.Fetch(proxy)
    vmin, vmax = float('inf'), float('-inf')

    if data.IsA("vtkPartitionedDataSetCollection"):
        n_top = data.GetNumberOfPartitionedDataSets()
        for i in range(n_top):
            n_parts = data.GetNumberOfPartitions(i)
            for j in range(n_parts):
                block = data.GetPartition(i, j)
                if block is None: continue
                pd = block.GetPointData()
                for k in range(pd.GetNumberOfArrays()):
                    arr = pd.GetArray(k)
                    if not arr: continue
                    if arr.GetName() == array_name:
                        for t in range(arr.GetNumberOfTuples()):
                            val = arr.GetTuple(t)[component] if component is not None else arr.GetTuple1(t)
                            vmin = min(vmin, val)
                            vmax = max(vmax, val)
    return vmin, vmax

global_ranges = {
    PRESSURE_NAME: get_global_range(source_for_processing, PRESSURE_NAME),
    VELOCITY_X_NAME: get_global_range(source_for_processing, VELOCITY_X_NAME),
    VELMAG_NAME: get_global_range(source_for_processing, VELMAG_NAME)
}

print("\nGlobal variable ranges:")
for k, v in global_ranges.items():
    print(f"  {k}: {v}")

# ---------------- APPLY COLORMAP ----------------
def apply_colormap(array_name, display):
    # Fetch the color transfer function for the array
    lut = GetColorTransferFunction(array_name)
    pwf = GetOpacityTransferFunction(array_name)

    # Auto-rescale to current data
    lut.RescaleTransferFunctionToDataRange()
    pwf.RescaleTransferFunctionToDataRange()

    # Apply to the display
    view = GetActiveViewOrCreate('RenderView')
    ColorBy(display, ('POINTS', array_name))

    # Optional: use a journal-quality colormap
    lut.ApplyPreset('Cool to Warm (Extended)', True)  # or 'Viridis (matplotlib)'

    # Scalar bar
    bar = GetScalarBar(lut, view)
    bar.Title = array_name
    bar.Orientation = "Horizontal"
    bar.Position = [0.25, 0.05]
    bar.ScalarBarLength = 0.5
    bar.TitleFontSize = 12
    bar.LabelFontSize = 10
    bar.TitleColor = [0, 0, 0]
    bar.LabelColor = [0, 0, 0]
    display.SetScalarBarVisibility(view, True)

# ---------------- SLICE FUNCTION ----------------
def make_slice(input_proxy, normal, origin, array_name, filename):
    """
    Create a slice, color it, orient camera, style scalar bar, and save image.
    """

    # Ensure we pass float tuples to ParaView properties
    normal = tuple(float(x) for x in normal)
    origin = tuple(float(x) for x in origin)

    # --- Slice creation ---
    sl = Slice(Input=input_proxy)
    sl.SliceType = 'Plane'
    sl.SliceType.Normal = normal
    sl.SliceType.Origin = origin
    sl.UpdatePipeline()

    view = GetActiveViewOrCreate('RenderView')
    #view.BackgroundTexture = None
    #view.BackgroundColorMode = 'Single Color'
    #view.Background = [1.0, 1.0, 1.0]
    view.OrientationAxesVisibility = 1
    SetViewProperties(
        Background=[1, 1, 1],
        UseColorPaletteForBackground = 0,
    )

    disp = Show(sl, view)
    disp.Representation = 'Surface'
    HideInteractiveWidgets(proxy=sl)
    

    apply_colormap(array_name, disp)

    # --- Camera setup ---
    cam = view.GetActiveCamera()
    if normal == (1.0, 0.0, 0.0):  # YZ plane (-X view)
        center_yz = [0.0, 0.06026, 0.0]
        cam.SetPosition(1.0, center_yz[1], center_yz[2])
        cam.SetFocalPoint(center_yz)
        cam.SetViewUp(0.0, 0.0, 1.0)
        cam.Roll(90)  # CCW rotation
        view.CameraParallelProjection = 1
        view.CameraParallelScale = 0.05
    elif normal == (0.0, 0.0, 1.0):  # XY plane (side view)
        center_xy = [-0.147222, 0.046904, 0.0]
        cam.SetPosition(center_xy[0], center_xy[1], 1.0)
        cam.SetFocalPoint(center_xy)
        cam.SetViewUp(0.0, 1.0, 0.0)
        view.CameraParallelProjection = 1
        view.CameraParallelScale = 0.2  # zoom out more

    # --- Scalar bar styling ---
    lut = GetColorTransferFunction(array_name)
    disp.LookupTable = lut
    sb = GetScalarBar(lut, view)
    sb.TitleColor = [0, 0, 0]
    sb.LabelColor = [0, 0, 0]
    sb.TitleFontSize = 12
    sb.LabelFontSize = 10
    sb.ScalarBarThickness = 12
    sb.ScalarBarLength = 0.50
    sb.WindowLocation = 'Lower Center'

    # --- Render and save ---
    RenderAllViews()
    SaveScreenshot(os.path.join(OUTPUT_DIR, filename), view, ImageResolution=IMG_RESOLUTION)

    # --- Cleanup ---
    Hide(sl, view)
    Delete(sl)
    

# ---------------- LINE EXTRACTION ----------------
def extract_line(input_proxy, xloc, filename):
    line = PlotOverLine(Input=input_proxy)
    line.Point1 = [xloc, -0.042964, 0.0]
    line.Point2 = [xloc, 0.1135, 0.0]
    line.Resolution = LINE_RESOLUTION
    line.UpdatePipeline()
    SaveData(os.path.join(OUTPUT_DIR, filename), proxy=line, FieldAssociation='Point Data')
    Delete(line)

# ---------------- GENERATE OUTPUTS ----------------
for x in YZ_SLICE_X:
    make_slice(source_for_processing, [1,0,0], [x,0,0], PRESSURE_NAME, f"YZ_x{x:+0.5f}_P.png")
    make_slice(source_for_processing, [1,0,0], [x,0,0], VELOCITY_X_NAME, f"YZ_x{x:+0.5f}_Ux.png")
    make_slice(source_for_processing, [1,0,0], [x,0,0], VELMAG_NAME, f"YZ_x{x:+0.5f}_VelMag.png")

for z in XY_SLICE_Z:
    make_slice(source_for_processing, [0,0,1], [0,0,z], PRESSURE_NAME, f"XY_z{z:+0.5f}_P.png")
    make_slice(source_for_processing, [0,0,1], [0,0,z], VELOCITY_X_NAME, f"XY_z{z:+0.5f}_Ux.png")
    make_slice(source_for_processing, [0,0,1], [0,0,z], VELMAG_NAME, f"XY_z{z:+0.5f}_VelMag.png")

for x in X_LOCATIONS_FOR_LINE:
    extract_line(source_for_processing, x, f"Ux_vs_y_x{x:+0.5f}.csv")

print("\n✅ Journal-quality slices and line CSVs created successfully.")
