from paraview.simple import *
import glob
import os

# ----------------------
# USER SETTINGS
# ----------------------
# Directory containing the.plt files
input_dir = "/path/to/your/plt_files"

# Pattern for PLT files (sorted by name)
pattern = "plane_*.plt"

# Output movie file name (MP4)
movie_filename = os.path.join(input_dir, "movie.mp4")

# Smaller resolution
image_width = 800
image_height = 600

# Frames per second
fps = 24

# Variable to color by (adapt to your PLT variable names)
color_var = "Pressure"  # e.g., "Pressure", "Temperature", etc.

# ----------------------
# PREPARE FILE LIST
# ----------------------
file_list = sorted(glob.glob(os.path.join(input_dir, pattern)))
if not file_list:
    raise RuntimeError(f"No files found matching pattern {pattern} in {input_dir}")

print(f"Found {len(file_list)} PLT files.")

# ----------------------
# CREATE A TIME-SERIES SOURCE
# ----------------------
# Many PLT series can be read as a single source with multiple time steps
reader = TecplotReader(FileNames=file_list)

# ----------------------
# SET UP RENDER VIEW
# ----------------------
renderView = CreateView('RenderView')
renderView.ViewSize = [image_width, image_height]
renderView.Background = [1.0, 1.0, 1.0]  # white background

display = Show(reader, renderView)

# Color by chosen variable
ColorBy(display, ('CELLS', color_var))
display.RescaleTransferFunctionToDataRange(True, False)

# Color/opacity transfer functions
lut = GetColorTransferFunction(color_var)
lut.ApplyPreset('Cool to Warm', True)
pwf = GetOpacityTransferFunction(color_var)

# Reset camera (and optionally tweak it once so all frames share the same view)
renderView.ResetCamera()
camera = GetActiveCamera()
# Example tweaks (optional):
# camera.Elevation(20)
# camera.Azimuth(30)

# ----------------------
# ANIMATION / MOVIE SETTINGS
# ----------------------
animationScene = GetAnimationScene()
animationScene.UpdateAnimationUsingDataTimeSteps()  # use time steps from reader

# ----------------------
# SAVE MOVIE AS MP4
# ----------------------
SaveAnimation(
    movie_filename,
    renderView,
    ImageResolution=[image_width, image_height],
    FrameRate=fps,
    FrameWindow=[0, len(file_list) - 1]
)

print(f"MP4 movie saved as: {movie_filename}")