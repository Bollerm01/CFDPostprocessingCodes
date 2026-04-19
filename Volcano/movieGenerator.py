from paraview.simple import *
import glob
import os

# ---------------------------------------------------------
# USER SETTINGS
# ---------------------------------------------------------

# Directory containing your cavityPlane.*.plt files
base_dir = "/home/bollerma/LESdata/SSWT/fullCav/injectionTest/test15/test1M2SSWTInjection_002/surfaceData/cavityPlane"

# Pattern for all time slices
file_pattern = "cavityPlane.*.plt"

# Output movie (MP4)
output_movie = "/home/bollerma/processingCodes/CFDPostprocessingCodes/VULCAN/cavityPlane_massfraction1.mp4"

# Reduced resolution
image_width = 800
image_height = 600

# Frames per second
fps = 24

# Variable to color by
var_name = "massfraction1"

# ---------------------------------------------------------
# COLLECT FILES
# ---------------------------------------------------------
files = sorted(glob.glob(os.path.join(base_dir, file_pattern)))
if not files:
    raise RuntimeError(f"No files found matching {file_pattern} in {base_dir}")

print(f"Found {len(files)} files.")

# ---------------------------------------------------------
# CREATE READER (VisIt Tecplot Binary Reader)
# ---------------------------------------------------------
reader = VisItTecplotBinaryReader(
    registrationName=os.path.basename(files[0]),
    FileName=files,
)

# Enable the variable of interest
reader.PointArrayStatus = [var_name]

# ---------------------------------------------------------
# SET UP RENDER VIEW
# ---------------------------------------------------------
paraview.simple._DisableFirstRenderCameraReset()

renderView1 = GetActiveViewOrCreate('RenderView')
renderView1.ViewSize = [image_width, image_height]

# Use same 2D camera + parameters as your trace
renderView1.Set(
    InteractionMode='2D',
    CameraPosition=[2.1945000886917114, 0.5291300058364868, 0.0],
    CameraFocalPoint=[2.1945000886917114, 0.01858999952673912, 0.0],
    CameraViewUp=[1.0, 0.0, 0.0],
    CameraParallelScale=0.09074449712164291,
)

# Show data
display = Show(reader, renderView1, 'UnstructuredGridRepresentation')
display.Representation = 'Surface'

# Update view
renderView1.Update()

# ---------------------------------------------------------
# COLORING (massfraction1) AND COLOR BAR
# ---------------------------------------------------------
ColorBy(display, ('POINTS', var_name))
display.RescaleTransferFunctionToDataRange(True, False)

display.SetScalarBarVisibility(renderView1, True)

lut = GetColorTransferFunction(var_name)
pwf = GetOpacityTransferFunction(var_name)

# Optional: choose a colormap here (commented; ParaView default used)
# lut.ApplyPreset('Cool to Warm', True)

# Move color bar to roughly where your trace had it
scalar_bar = GetScalarBar(lut, renderView1)
scalar_bar.WindowLocation = 'Any Location'
scalar_bar.Position = [0.68, 0.33]
scalar_bar.ScalarBarLength = 0.33

renderView1.UseColorPaletteForBackground = 0  # plain background

# ---------------------------------------------------------
# ANIMATION SETUP
# ---------------------------------------------------------
animationScene1 = GetAnimationScene()
animationScene1.UpdateAnimationUsingDataTimeSteps()

# ---------------------------------------------------------
# SAVE MP4 ANIMATION
# ---------------------------------------------------------
SaveAnimation(
    output_movie,
    renderView1,
    ImageResolution=[image_width, image_height],
    FrameRate=fps,
    FrameWindow=[0, len(files) - 1],
)

print(f"Saved MP4 movie to: {output_movie}")