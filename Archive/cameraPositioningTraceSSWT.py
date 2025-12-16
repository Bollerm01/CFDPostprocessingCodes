# trace generated using paraview version 5.13.1
#import paraview
#paraview.compatibility.major = 5
#paraview.compatibility.minor = 13

#### import the simple module from the paraview
from paraview.simple import *
#### disable automatic camera reset on 'Show'
paraview.simple._DisableFirstRenderCameraReset()

# create a new 'File Series Reader'
latestvolcano = FileSeriesReader(registrationName='latest.volcano', FileNames=['/home/bollerma/LESdata/SSWT/fullCav/timeSensitivityStudy/test1t/test1tM2SSWT_000/latest.volcano'])
latestvolcano.CellArrayStatus = []
latestvolcano.ComputableCellArrayStatus = []
latestvolcano.PointArrayStatus = []

# Properties modified on latestvolcano
latestvolcano.CellArrayStatus = ['density', 'machnumber', 'machnumberavg', 'pressureavg', 'reynoldsstressxx', 'reynoldsstressxy', 'reynoldsstressxz', 'reynoldsstressyy', 'reynoldsstressyz', 'reynoldsstresszz', 'tke', 'velocityx']

# Properties modified on latestvolcano
latestvolcano.CellArrayStatus = ['density', 'machnumber', 'machnumberavg', 'pressureavg', 'reynoldsstressxx', 'reynoldsstressxy', 'reynoldsstressxz', 'reynoldsstressyy', 'reynoldsstressyz', 'reynoldsstresszz', 'tke', 'velocityx', 'velocityxavg']

### SLICE EXAMPLE FOR XZ FARFIELD SLICE ###
# create a new 'Volcano Slice'
volcanoSlice1 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)
volcanoSlice1.MinMaxField = ''

# set active source
SetActiveSource(latestvolcano)

# set active source
SetActiveSource(volcanoSlice1)

# Properties modified on volcanoSlice1
volcanoSlice1.MinMaxField = 'velocityxavg'
volcanoSlice1.Crinkle = 0
volcanoSlice1.InterpolatedField = 'velocityxavg'

# get active view
renderView1 = GetActiveViewOrCreate('RenderView')

# show data in view
volcanoSlice1Display = Show(volcanoSlice1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1Display.Representation = 'Surface'
volcanoSlice1Display.ColorArrayName = [None, '']
volcanoSlice1Display.SelectNormalArray = 'None'
volcanoSlice1Display.SelectTangentArray = 'None'
volcanoSlice1Display.SelectTCoordArray = 'None'
volcanoSlice1Display.TextureTransform = 'Transform2'
volcanoSlice1Display.OSPRayScaleArray = 'velocityxavg'
volcanoSlice1Display.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice1Display.Assembly = ''
volcanoSlice1Display.SelectedBlockSelectors = ['']
volcanoSlice1Display.SelectOrientationVectors = 'None'
volcanoSlice1Display.ScaleFactor = 0.25490000000000007
volcanoSlice1Display.SelectScaleArray = 'None'
volcanoSlice1Display.GlyphType = 'Arrow'
volcanoSlice1Display.GlyphTableIndexArray = 'None'
volcanoSlice1Display.GaussianRadius = 0.012745000000000003
volcanoSlice1Display.SetScaleArray = ['POINTS', 'velocityxavg']
volcanoSlice1Display.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice1Display.OpacityArray = ['POINTS', 'velocityxavg']
volcanoSlice1Display.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice1Display.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice1Display.PolarAxes = 'Polar Axes Representation'
volcanoSlice1Display.ScalarOpacityUnitDistance = 0.03853285955377259
volcanoSlice1Display.OpacityArrayName = ['POINTS', 'velocityxavg']
volcanoSlice1Display.SelectInputVectors = [None, '']
volcanoSlice1Display.WriteLog = ''

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
volcanoSlice1Display.ScaleTransferFunction.Points = [-103.57499694824219, 0.0, 0.5, 0.0, 697.7416381835938, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
volcanoSlice1Display.OpacityTransferFunction.Points = [-103.57499694824219, 0.0, 0.5, 0.0, 697.7416381835938, 1.0, 0.5, 0.0]

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# show data in view
volcanoSlice1Display_1 = Show(OutputPort(volcanoSlice1, 1), renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1Display_1.Representation = 'Surface'
volcanoSlice1Display_1.ColorArrayName = [None, '']
volcanoSlice1Display_1.SelectNormalArray = 'None'
volcanoSlice1Display_1.SelectTangentArray = 'None'
volcanoSlice1Display_1.SelectTCoordArray = 'None'
volcanoSlice1Display_1.TextureTransform = 'Transform2'
volcanoSlice1Display_1.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice1Display_1.Assembly = ''
volcanoSlice1Display_1.SelectedBlockSelectors = ['']
volcanoSlice1Display_1.SelectOrientationVectors = 'None'
volcanoSlice1Display_1.ScaleFactor = 0.2548577308654785
volcanoSlice1Display_1.SelectScaleArray = 'None'
volcanoSlice1Display_1.GlyphType = 'Arrow'
volcanoSlice1Display_1.GlyphTableIndexArray = 'None'
volcanoSlice1Display_1.GaussianRadius = 0.012742886543273926
volcanoSlice1Display_1.SetScaleArray = [None, '']
volcanoSlice1Display_1.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice1Display_1.OpacityArray = [None, '']
volcanoSlice1Display_1.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice1Display_1.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice1Display_1.PolarAxes = 'Polar Axes Representation'
volcanoSlice1Display_1.ScalarOpacityUnitDistance = 1.1328447860163144
volcanoSlice1Display_1.OpacityArrayName = [None, '']
volcanoSlice1Display_1.SelectInputVectors = [None, '']
volcanoSlice1Display_1.WriteLog = ''

# update the view to ensure updated data information
renderView1.Update()
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1

# set scalar coloring
ColorBy(volcanoSlice1Display, ('POINTS', 'velocityxavg'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice1Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice1Display.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'velocityxavg'
velocityxavgLUT = GetColorTransferFunction('velocityxavg')

# get opacity transfer function/opacity map for 'velocityxavg'
velocityxavgPWF = GetOpacityTransferFunction('velocityxavg')

# get 2D transfer function for 'velocityxavg'
velocityxavgTF2D = GetTransferFunction2D('velocityxavg')
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1

# get color legend/bar for velocityxavgLUT in view renderView1
velocityxavgLUTColorBar = GetScalarBar(velocityxavgLUT, renderView1)
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1

# change scalar bar placement
velocityxavgLUTColorBar.WindowLocation = 'Any Location'
velocityxavgLUTColorBar.Position = [0.7324797843665768, 0.3208955223880597]
velocityxavgLUTColorBar.ScalarBarLength = 0.3300000000000001
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 1.0718566398113272
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.8858319337283694
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24024126502707127, 5.011016610690195]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.6350828766872607, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.6350828766872607, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.6350828766872607, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.6350828766872607, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.6350828766872607, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.6350828766872607, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1

# change scalar bar placement
velocityxavgLUTColorBar.Orientation = 'Horizontal'
velocityxavgLUTColorBar.Position = [0.2899460916442047, 0.2630597014925373]
velocityxavgLUTColorBar.ScalarBarLength = 0.3300000000000005
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.6350828766872607, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.6350828766872607, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

### FINAL RENDER VIEW FOR XZ FARFIELD ###
# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1

# set active source
SetActiveSource(latestvolcano)


### SLICE EXAMPLE FOR XY PLANE SLICE ###
# create a new 'Volcano Slice'
volcanoSlice2 = VolcanoSlice(registrationName='VolcanoSlice2', Input=latestvolcano)
volcanoSlice2.MinMaxField = ''
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1

# hide data in view
Hide(volcanoSlice1, renderView1)
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1

# hide data in view
Hide(OutputPort(volcanoSlice1, 1), renderView1)
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.4547914383436304, 0.05994982668344116, 5.011016610690195]
renderView1.CameraFocalPoint = [1.4547914383436304, 0.05994982668344116, 2.168404344971009e-17]
renderView1.CameraParallelScale = 0.7320925072135284
renderView1.CameraParallelProjection = 1

# Properties modified on volcanoSlice2
volcanoSlice2.MinMaxField = 'velocityxavg'
volcanoSlice2.Crinkle = 0
volcanoSlice2.InterpolatedField = 'velocityxavg'

# show data in view
volcanoSlice2Display = Show(volcanoSlice2, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice2Display.Representation = 'Surface'
volcanoSlice2Display.ColorArrayName = [None, '']
volcanoSlice2Display.SelectNormalArray = 'None'
volcanoSlice2Display.SelectTangentArray = 'None'
volcanoSlice2Display.SelectTCoordArray = 'None'
volcanoSlice2Display.TextureTransform = 'Transform2'
volcanoSlice2Display.OSPRayScaleArray = 'velocityxavg'
volcanoSlice2Display.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice2Display.Assembly = ''
volcanoSlice2Display.SelectedBlockSelectors = ['']
volcanoSlice2Display.SelectOrientationVectors = 'None'
volcanoSlice2Display.ScaleFactor = 0.01775
volcanoSlice2Display.SelectScaleArray = 'None'
volcanoSlice2Display.GlyphType = 'Arrow'
volcanoSlice2Display.GlyphTableIndexArray = 'None'
volcanoSlice2Display.GaussianRadius = 0.0008874999999999999
volcanoSlice2Display.SetScaleArray = ['POINTS', 'velocityxavg']
volcanoSlice2Display.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice2Display.OpacityArray = ['POINTS', 'velocityxavg']
volcanoSlice2Display.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice2Display.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice2Display.PolarAxes = 'Polar Axes Representation'
volcanoSlice2Display.ScalarOpacityUnitDistance = 0.006319105258036092
volcanoSlice2Display.OpacityArrayName = ['POINTS', 'velocityxavg']
volcanoSlice2Display.SelectInputVectors = [None, '']
volcanoSlice2Display.WriteLog = ''

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
volcanoSlice2Display.ScaleTransferFunction.Points = [-14.061290740966797, 0.0, 0.5, 0.0, 699.608154296875, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
volcanoSlice2Display.OpacityTransferFunction.Points = [-14.061290740966797, 0.0, 0.5, 0.0, 699.608154296875, 1.0, 0.5, 0.0]

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

#changing interaction mode based on data extents
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]

# show data in view
volcanoSlice2Display_1 = Show(OutputPort(volcanoSlice2, 1), renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice2Display_1.Representation = 'Surface'
volcanoSlice2Display_1.ColorArrayName = [None, '']
volcanoSlice2Display_1.SelectNormalArray = 'None'
volcanoSlice2Display_1.SelectTangentArray = 'None'
volcanoSlice2Display_1.SelectTCoordArray = 'None'
volcanoSlice2Display_1.TextureTransform = 'Transform2'
volcanoSlice2Display_1.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice2Display_1.Assembly = ''
volcanoSlice2Display_1.SelectedBlockSelectors = ['']
volcanoSlice2Display_1.SelectOrientationVectors = 'None'
volcanoSlice2Display_1.ScaleFactor = 0.017737738788127882
volcanoSlice2Display_1.SelectScaleArray = 'None'
volcanoSlice2Display_1.GlyphType = 'Arrow'
volcanoSlice2Display_1.GlyphTableIndexArray = 'None'
volcanoSlice2Display_1.GaussianRadius = 0.000886886939406394
volcanoSlice2Display_1.SetScaleArray = [None, '']
volcanoSlice2Display_1.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice2Display_1.OpacityArray = [None, '']
volcanoSlice2Display_1.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice2Display_1.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice2Display_1.PolarAxes = 'Polar Axes Representation'
volcanoSlice2Display_1.ScalarOpacityUnitDistance = 0.14731987284561707
volcanoSlice2Display_1.OpacityArrayName = [None, '']
volcanoSlice2Display_1.SelectInputVectors = [None, '']
volcanoSlice2Display_1.WriteLog = ''

# update the view to ensure updated data information
renderView1.Update()
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1

# set scalar coloring
ColorBy(volcanoSlice2Display, ('POINTS', 'velocityxavg'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice2Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice2Display.SetScalarBarVisibility(renderView1, True)
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 0.0, 1.0]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1

renderView1.AdjustRoll(90.0)
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1

# change scalar bar placement
velocityxavgLUTColorBar.Orientation = 'Vertical'
velocityxavgLUTColorBar.Position = [0.6610512129380054, 0.3789552238805967]
velocityxavgLUTColorBar.ScalarBarLength = 0.3300000000000007
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1
# Adjust camera

### FINAL CAMERA RENDER FOR XY SLICE ###
# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1

# set active source
SetActiveSource(latestvolcano)

# create a new 'Volcano Slice'
volcanoSlice3 = VolcanoSlice(registrationName='VolcanoSlice3', Input=latestvolcano)
volcanoSlice3.MinMaxField = ''

# set active source
SetActiveSource(volcanoSlice3)

# hide data in view
Hide(OutputPort(volcanoSlice2, 1), renderView1)
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1

# hide data in view
Hide(volcanoSlice2, renderView1)
# Adjust camera

# current camera placement for renderView1
renderView1.InteractionMode = '2D'
renderView1.CameraPosition = [2.7452049999995722, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraFocalPoint = [2.1505799999995725, 0.08874126502707114, 5.551115123125783e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 0.11684418042846643
renderView1.CameraParallelProjection = 1

### NEARFIELD (CAVITY VIEW) XZ SLICE EXAMPLE ###
# Properties modified on volcanoSlice3
volcanoSlice3.MinMaxField = 'pressureavg'
volcanoSlice3.Crinkle = 0
volcanoSlice3.InterpolatedField = 'pressureavg'

# show data in view
volcanoSlice3Display = Show(volcanoSlice3, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice3Display.Representation = 'Surface'
volcanoSlice3Display.ColorArrayName = [None, '']
volcanoSlice3Display.SelectNormalArray = 'None'
volcanoSlice3Display.SelectTangentArray = 'None'
volcanoSlice3Display.SelectTCoordArray = 'None'
volcanoSlice3Display.TextureTransform = 'Transform2'
volcanoSlice3Display.OSPRayScaleArray = 'pressureavg'
volcanoSlice3Display.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice3Display.Assembly = ''
volcanoSlice3Display.SelectedBlockSelectors = ['']
volcanoSlice3Display.SelectOrientationVectors = 'None'
volcanoSlice3Display.ScaleFactor = 0.25490000000000007
volcanoSlice3Display.SelectScaleArray = 'None'
volcanoSlice3Display.GlyphType = 'Arrow'
volcanoSlice3Display.GlyphTableIndexArray = 'None'
volcanoSlice3Display.GaussianRadius = 0.012745000000000003
volcanoSlice3Display.SetScaleArray = ['POINTS', 'pressureavg']
volcanoSlice3Display.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice3Display.OpacityArray = ['POINTS', 'pressureavg']
volcanoSlice3Display.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice3Display.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice3Display.PolarAxes = 'Polar Axes Representation'
volcanoSlice3Display.ScalarOpacityUnitDistance = 0.03853285955377259
volcanoSlice3Display.OpacityArrayName = ['POINTS', 'pressureavg']
volcanoSlice3Display.SelectInputVectors = [None, '']
volcanoSlice3Display.WriteLog = ''

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
volcanoSlice3Display.ScaleTransferFunction.Points = [19382.814453125, 0.0, 0.5, 0.0, 158509.25, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
volcanoSlice3Display.OpacityTransferFunction.Points = [19382.814453125, 0.0, 0.5, 0.0, 158509.25, 1.0, 0.5, 0.0]

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

#changing interaction mode based on data extents
renderView1.InteractionMode = '3D'

# show data in view
volcanoSlice3Display_1 = Show(OutputPort(volcanoSlice3, 1), renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice3Display_1.Representation = 'Surface'
volcanoSlice3Display_1.ColorArrayName = [None, '']
volcanoSlice3Display_1.SelectNormalArray = 'None'
volcanoSlice3Display_1.SelectTangentArray = 'None'
volcanoSlice3Display_1.SelectTCoordArray = 'None'
volcanoSlice3Display_1.TextureTransform = 'Transform2'
volcanoSlice3Display_1.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice3Display_1.Assembly = ''
volcanoSlice3Display_1.SelectedBlockSelectors = ['']
volcanoSlice3Display_1.SelectOrientationVectors = 'None'
volcanoSlice3Display_1.ScaleFactor = 0.2548577308654785
volcanoSlice3Display_1.SelectScaleArray = 'None'
volcanoSlice3Display_1.GlyphType = 'Arrow'
volcanoSlice3Display_1.GlyphTableIndexArray = 'None'
volcanoSlice3Display_1.GaussianRadius = 0.012742886543273926
volcanoSlice3Display_1.SetScaleArray = [None, '']
volcanoSlice3Display_1.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice3Display_1.OpacityArray = [None, '']
volcanoSlice3Display_1.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice3Display_1.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice3Display_1.PolarAxes = 'Polar Axes Representation'
volcanoSlice3Display_1.ScalarOpacityUnitDistance = 1.1328447860163144
volcanoSlice3Display_1.OpacityArrayName = [None, '']
volcanoSlice3Display_1.SelectInputVectors = [None, '']
volcanoSlice3Display_1.WriteLog = ''

# update the view to ensure updated data information
renderView1.Update()
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [6.285516610690195, 0.24024126502707127, 8.239936510889834e-17]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 8.239936510889834e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [6.285516610690195, 0.24024126502707127, 8.239936510889834e-17]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24024126502707127, 8.239936510889834e-17]
renderView1.CameraViewUp = [0.0, 1.0, 2.220446049250313e-16]
renderView1.CameraParallelScale = 1.2969465341717061
renderView1.CameraParallelProjection = 1

renderView1.ResetActiveCameraToNegativeZ()

# reset view to fit data
renderView1.ResetCamera(False, 0.9)
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 1.296992051108317
renderView1.CameraParallelProjection = 1

# set scalar coloring
ColorBy(volcanoSlice3Display, ('POINTS', 'pressureavg'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice3Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice3Display.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'pressureavg'
pressureavgLUT = GetColorTransferFunction('pressureavg')

# get opacity transfer function/opacity map for 'pressureavg'
pressureavgPWF = GetOpacityTransferFunction('pressureavg')

# get 2D transfer function for 'pressureavg'
pressureavgTF2D = GetTransferFunction2D('pressureavg')
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 1.296992051108317
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 1.0718942571143115
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.8858630224085218
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.7321182003376212
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.6050563639153893
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.5000465817482556
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.4132616378084756
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.3415385436433682
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.28226325920939516
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745000000000002, 0.24048685882903392, 5.011192474629075]
renderView1.CameraFocalPoint = [1.2745000000000002, 0.24048685882903392, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.23327542083421085
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [1.9299342980901522, 0.10382924289257459, 5.011192474629075]
renderView1.CameraFocalPoint = [1.9299342980901522, 0.10382924289257459, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.23327542083421085
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.2389371876280064, 0.02462005148991343, 5.011192474629075]
renderView1.CameraFocalPoint = [2.2389371876280064, 0.02462005148991343, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.23327542083421085
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.2389371876280064, 0.02462005148991343, 5.011192474629075]
renderView1.CameraFocalPoint = [2.2389371876280064, 0.02462005148991343, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.19278960399521555
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.2389371876280064, 0.02462005148991343, 5.011192474629075]
renderView1.CameraFocalPoint = [2.2389371876280064, 0.02462005148991343, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.15933025123571531
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.2389371876280064, 0.02462005148991343, 5.011192474629075]
renderView1.CameraFocalPoint = [2.2389371876280064, 0.02462005148991343, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.13167789358323578
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.2389371876280064, 0.02462005148991343, 5.011192474629075]
renderView1.CameraFocalPoint = [2.2389371876280064, 0.02462005148991343, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.10882470544069071
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.2389371876280064, 0.02462005148991343, 5.011192474629075]
renderView1.CameraFocalPoint = [2.2389371876280064, 0.02462005148991343, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.08993777309147992
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1936327123767017, 0.02831152725113089, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1936327123767017, 0.02831152725113089, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.08993777309147992
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1936327123767017, 0.02831152725113089, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1936327123767017, 0.02831152725113089, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.07432873809213215
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1936327123767017, 0.02831152725113089, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1936327123767017, 0.02831152725113089, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1

# get color legend/bar for pressureavgLUT in view renderView1
pressureavgLUTColorBar = GetScalarBar(pressureavgLUT, renderView1)
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1

# change scalar bar placement
pressureavgLUTColorBar.Orientation = 'Horizontal'
pressureavgLUTColorBar.WindowLocation = 'Any Location'
pressureavgLUTColorBar.Position = [0.3108355795148248, 0.14925373134328357]
pressureavgLUTColorBar.ScalarBarLength = 0.33
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1
# Adjust camera

### FINAL NEARFIELD XZ SLICE RENDERING ###
# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1

#================================================================
# addendum: following script captures some of the application
# state to faithfully reproduce the visualization during playback
#================================================================

# get layout
layout1 = GetLayout()

#--------------------------------
# saving layout sizes for layouts

# layout/tab size in pixels
layout1.SetSize(1484, 536)

#-----------------------------------
# saving camera placements for views

# current camera placement for renderView1
renderView1.CameraPosition = [2.1922574427684838, 0.018226216790868725, 5.011192474629075]
renderView1.CameraFocalPoint = [2.1922574427684838, 0.018226216790868725, 4.552429939096159e-13]
renderView1.CameraParallelScale = 0.06142870916705136
renderView1.CameraParallelProjection = 1


##--------------------------------------------
## You may need to add some code at the end of this python script depending on your usage, eg:
#
## Render all views to see them appears
# RenderAllViews()
#
## Interact with the view, usefull when running from pvpython
# Interact()
#
## Save a screenshot of the active view
# SaveScreenshot("path/to/screenshot.png")
#
## Save a screenshot of a layout (multiple splitted view)
# SaveScreenshot("path/to/screenshot.png", GetLayout())
#
## Save all "Extractors" from the pipeline browser
# SaveExtracts()
#
## Save a animation of the current active view
# SaveAnimation()
#
## Please refer to the documentation of paraview.simple
## https://www.paraview.org/paraview-docs/latest/python/paraview.simple.html
##--------------------------------------------