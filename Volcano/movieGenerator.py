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

# Fixed global scalar range
scalar_min = 0.0
scalar_max = 0.25

# Sampling frequency and time step (50 kHz)
sampling_freq = 50000.0        # Hz
dt = 1.0 / sampling_freq       # seconds per frame

# ----------------------
# HELPER: delete all non-text sources
# ----------------------
def delete_all_sources_except_text():
    srcs = GetSources()
    for key, proxy in list(srcs.items()):
        # Keep Text sources so the timestamp survives across frames
        try:
            if proxy.GetXMLName() == "TextSource":
                continue
        except AttributeError:
            pass
        Delete(proxy)

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
# TIMESTAMP TEXT (created once, updated each frame)
# ----------------------
time_text = Text()
time_text.Text = ""
time_display = Show(time_text, renderView1)
time_display.WindowLocation = 'Any Location'
time_display.Position = [0.05, 0.90]  # near top-left
time_display.FontSize = 14

# ----------------------
# LOOP OVER FILES
# ----------------------
lut = None
pwf = None

for i, f in enumerate(files):
    print(f"Processing {i+1}/{len(files)}: {f}")

    # Remove previous data sources but keep timestamp Text
    delete_all_sources_except_text()
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

    # Get LUT/PWF once; enforce global range [0, 0.25] for every frame
    if lut is None:
        lut = GetColorTransferFunction(var_name)
        pwf = GetOpacityTransferFunction(var_name)
    lut.RescaleTransferFunction(scalar_min, scalar_max)
    pwf.RescaleTransferFunction(scalar_min, scalar_max)

    # Do NOT auto-rescale to data; keep fixed global range
    # display.RescaleTransferFunctionToDataRange(True, False)

    display.SetScalarBarVisibility(renderView1, True)
    scalar_bar = GetScalarBar(lut, renderView1)

    # Move scalar bar up and slightly left
    scalar_bar.WindowLocation = 'Any Location'
    scalar_bar.Position = [0.84, 0.35]   # adjust as needed
    scalar_bar.ScalarBarLength = 0.30

    # Re-assert camera (in case ParaView tweaks it)
    renderView1.Set(
        InteractionMode='2D',
        CameraPosition=[2.1945000886917114, 0.5291300058364868, 0.0],
        CameraFocalPoint=[2.1945000886917114, 0.01858999952673912, 0.0],
        CameraViewUp=[1.0, 0.0, 0.0],
        CameraParallelScale=0.09074449712164291,
    )

    # Update timestamp for this frame (here in microseconds)
    t = i * dt  # seconds
    time_text.Text = f"t = {t*1e6:0.0f} μs"
    # If you prefer seconds:
    # time_text.Text = f"t = {t:0.6f} s"

    renderView1.Update()

    # Save frame
    frame_path = os.path.join(frames_dir, f"frame_{i:04d}.png")
    SaveScreenshot(frame_path, renderView1,
                   ImageResolution=[image_width, image_height])

print(f"All frames written to: {frames_dir}")