from paraview.simple import *
paraview.simple._DisableFirstRenderCameraReset()

# ----------------------------
# USER PARAMETERS
# ----------------------------
x_slices = [0.24, 0.31, 0.38, 0.45, 0.53]     # X positions for YZ slices
y_line = -0.0266                              # Y location for horizontal line
z_line =  0.056                               # Z location for vertical line

volcano_file = "/home/bollerma/LESdata/SSWT/M2Nozz/8p34in/fine/SSWTNozzSim3p66fine_000/latest.volcano"


# Load the data
latestvolcano = FileSeriesReader(registrationName='latest.volcano',
    FileNames=[volcano_file]
)
latestvolcano.CellArrayStatus = ['machnumber', 'machnumberavg', 'vorticitymagavg']

renderView = GetActiveViewOrCreate("RenderView")
renderView.InteractionMode = "2D"

# Create slices
slices = []

# Mach Slices
for x in x_slices:
    numStr = str(x)
    sliceName = f"x0p{numStr[-2:]}Mach"
    sl = VolcanoSlice(registrationName=sliceName, Input=latestvolcano)

    sl.MinMaxField = 'machnumberavg'
    sl.InterpolatedField = 'machnumberavg'
    sl.Crinkle = 0

    # KEY LINES: YZ slice at X = x
    sl.XSlice = 0
    sl.YSlice = 0
    sl.ZSlice = 0

    sl.SliceNormal = [1.0, 0.0, 0.0]   # YZ plane
    sl.SlicePoint  = [x, 0.0, 0.0]     # at X = x

    slices.append(sl)

# Display each slice
for sl in slices:
    d = Show(sl, renderView)
    ColorBy(d, ('POINTS', 'machnumberavg'))
    d.RescaleTransferFunctionToDataRange(True, False)
    d.SetScalarBarVisibility(renderView, True)

renderView.ResetCamera()

# Vorticity Slices
for x in x_slices:
    numStr = str(x)
    sliceName = f"x0p{numStr[-2:]}Vorticity"
    sl = VolcanoSlice(registrationName=sliceName, Input=latestvolcano)

    sl.MinMaxField = 'vorticitymagavg'
    sl.InterpolatedField = 'vorticitymagavg'
    sl.Crinkle = 0

    # KEY LINES: YZ slice at X = x
    sl.XSlice = 0
    sl.YSlice = 0
    sl.ZSlice = 0

    sl.SliceNormal = [1.0, 0.0, 0.0]   # YZ plane
    sl.SlicePoint  = [x, 0.0, 0.0]     # at X = x

    slices.append(sl)

# Display each slice
for sl in slices:
    d = Show(sl, renderView)
    ColorBy(d, ('POINTS', 'vorticitymagavg'))
    d.RescaleTransferFunctionToDataRange(True, False)
    d.SetScalarBarVisibility(renderView, True)

renderView.ResetCamera()

# Adds a z = 0.056 slice
# create a new 'Volcano Slice'
volcanoSlicez = VolcanoSlice(registrationName='z0p056Mach', Input=latestvolcano)

# Properties modified on volcanoSlice1
volcanoSlicez.MinMaxField = 'vorticitymagavg'
volcanoSlicez.Crinkle = 0
volcanoSlicez.InterpolatedField = 'vorticitymagavg'

# KEY LINES: YZ slice at X = x
volcanoSlicez.XSlice = 0
volcanoSlicez.YSlice = 0
volcanoSlicez.ZSlice = 0

volcanoSlicez.SliceNormal = [0.0, 0.0, 1.0]   # XY plane
volcanoSlicez.SlicePoint  = [0.0, 0.0, z_line]     # at z=z_line


# show data 
volcanoSlice1Display = Show(volcanoSlicez, renderView)
ColorBy(volcanoSlice1Display, ('POINTS', 'vorticitymagavg'))
volcanoSlice1Display.RescaleTransferFunctionToDataRange(True, False)
volcanoSlice1Display.SetScalarBarVisibility(renderView, True)

# Adds a y-slice @ y_line
# create a new 'Volcano Slice'
volcanoSlicey = VolcanoSlice(registrationName='horizontalMach', Input=latestvolcano)

# Properties modified on volcanoSlice1
volcanoSlicey.MinMaxField = 'machnumberavg'
volcanoSlicey.Crinkle = 0
volcanoSlicey.InterpolatedField = 'machnumberavg'

# KEY LINES: YZ slice at X = x
volcanoSlicey.XSlice = 0
volcanoSlicey.YSlice = 0
volcanoSlicey.ZSlice = 0

volcanoSlicey.SliceNormal = [0.0, 1.0, 0.0]   # xz plane
volcanoSlicey.SlicePoint  = [0.0, y_line, 0.0]     # at y=y_line

# ExtractCellsAlongLine will work now because Slice input is latestvolcano
last_x = x_slices[-1]
strLastX = str(last_x)

horizontalMach = FindSource('horizontalMach')
verticalMach = FindSource(f"x0p{strLastX[-2:]}Mach")

# Horizontal line along Z
SetActiveSource(horizontalMach)
v = ExtractCellsAlongLine(Input=horizontalMach)
v.Point1 = [last_x, y_line, -0.1]
v.Point2 = [last_x, y_line,  0.15]
vPlot = PlotData(Input=v)

# Vertical line along Y
SetActiveSource(verticalMach)
h = ExtractCellsAlongLine(Input=verticalMach)
h.Point1 = [last_x, -0.15, z_line]
h.Point2 = [last_x,  0.15, z_line]
hPlot = PlotData(Input=h)

# Chart view
chart = CreateView("XYChartView")
layout = GetLayout()
AssignViewToLayout(view=chart, layout=layout, hint=0)

vDisp = Show(vPlot, chart, "XYChartRepresentation")
vDisp.UseIndexForXAxis = 0
vDisp.XArrayName = "Points_Z"
vDisp.SeriesVisibility = ['machnumberavg']

hDisp = Show(hPlot, chart, "XYChartRepresentation")
hDisp.UseIndexForXAxis = 0
hDisp.XArrayName = "Points_Y"
hDisp.SeriesVisibility = ['machnumberavg']

chart.SortByXAxis = 1
Render()
