from paraview.simple import *
import glob
import os

# ----------------------
# USER SETTINGS
# ----------------------
base_dir = "/home/bollerma/LESdata/SSWT/fullCav/injectionTest/test15/test1M2SSWTInjection_002/surfaceData/cavityPlane"
file_pattern = "cavityPlane.*.plt"

frames_dir = "/home/bollerma/LESdata/SSWT/fullCav/injectionTest/test15/frames"
image_width = 800
image_height = 600
var_name = "massfraction1"

# ----------------------
# COLLECT FILES
# ----------------------
files = sorted(glob.glob(os.path.join(base_dir, file_pattern)))
if not files:
    raise RuntimeError(f"No files found matching {file_pattern} in {base_dir}")

print(f"Found {len(files)} files.")
os.makedirs(frames_dir, exist_ok=True)

# ----------------------
# SET UP VIEW (ONCE)
# ----------------------
paraview.simple._DisableFirstRenderCameraReset()

renderView1 = GetActiveViewOrCreate('RenderView')
renderView1.ViewSize = [image_width, image_height]

# Camera from your trace
renderView1.Set(
    InteractionMode='2D',
    CameraPosition=[2.1945000886917114, 0.5291300058364868, 0.0],
    CameraFocalPoint=[2.1945000886917114, 0.01858999952673912, 0.0],
    CameraViewUp=[1.0, 0.0, 0.0],
    CameraParallelScale=0.09074449712164291,
)

renderView1.UseColorPaletteForBackground = 0  # plain background

# ----------------------
# LOOP OVER FILES
# ----------------------
for i, f in enumerate(files):
    print(f"Processing {i+1}/{len(files)}: {f}")

    # Clear previous sources
    DeleteAll()
    renderView1.Update()

    # Reader for this specific PLT file
    reader = VisItTecplotBinaryReader(
        registrationName=os.path.basename(f),
        FileName=[f],
    )
    reader.PointArrayStatus = [var_name]

    display = Show(reader, renderView1, 'UnstructuredGridRepresentation')
    display.Representation = 'Surface'

    # Coloring
    ColorBy(display, ('POINTS', var_name))
    display.RescaleTransferFunctionToDataRange(True, False)
    display.SetScalarBarVisibility(renderView1, True)

    lut = GetColorTransferFunction(var_name)
    pwf = GetOpacityTransferFunction(var_name)
    scalar_bar = GetScalarBar(lut, renderView1)

    # Move scalar bar further to the RIGHT
    scalar_bar.WindowLocation = 'Any Location'
    scalar_bar.Position = [0.90, 0.20]   # x ~ 0.90 (near right edge), y ~ 0.20
    scalar_bar.ScalarBarLength = 0.33

    # Ensure camera stays as desired
    renderView1.Set(
        InteractionMode='2D',
        CameraPosition=[2.1945000886917114, 0.5291300058364868, 0.0],
        CameraFocalPoint=[2.1945000886917114, 0.01858999952673912, 0.0],
        CameraViewUp=[1.0, 0.0, 0.0],
        CameraParallelScale=0.09074449712164291,
    )

    renderView1.Update()

    # Save frame
    frame_path = os.path.join(frames_dir, f"frame_{i:04d}.png")
    SaveScreenshot(frame_path, renderView1,
                   ImageResolution=[image_width, image_height])

print(f"All frames written to: {frames_dir}")