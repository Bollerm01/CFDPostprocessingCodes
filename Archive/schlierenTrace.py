# trace generated using paraview version 5.13.1
#import paraview
#paraview.compatibility.major = 5
#paraview.compatibility.minor = 13

#### import the simple module from the paraview
from paraview.simple import *
#### disable automatic camera reset on 'Show'
paraview.simple._DisableFirstRenderCameraReset()

# create a new 'File Series Reader'
latestvolcano = FileSeriesReader(registrationName='latest.volcano', FileNames=['/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/latest.volcano'])

# Properties modified on latestvolcano
latestvolcano.CellArrayStatus = ['density']

# create a new 'Volcano Slice'
volcanoSlice1 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)

# Properties modified on volcanoSlice1
volcanoSlice1.MinMaxField = 'None'

# get active view
renderView1 = GetActiveViewOrCreate('RenderView')

# show data in view
volcanoSlice1Display = Show(volcanoSlice1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1Display.Representation = 'Surface'

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# show data in view
volcanoSlice1Display_1 = Show(OutputPort(volcanoSlice1, 1), renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1Display_1.Representation = 'Surface'

# update the view to ensure updated data information
renderView1.Update()

# Properties modified on volcanoSlice1
volcanoSlice1.MinMaxField = 'density'
volcanoSlice1.Crinkle = 0
volcanoSlice1.InterpolatedField = 'density'

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(volcanoSlice1Display, ('POINTS', 'density'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice1Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice1Display.SetScalarBarVisibility(renderView1, True)

# get 2D transfer function for 'density'
densityTF2D = GetTransferFunction2D('density')

# get color transfer function/color map for 'density'
densityLUT = GetColorTransferFunction('density')
densityLUT.TransferFunction2D = densityTF2D
densityLUT.RGBPoints = [0.2784711718559265, 0.231373, 0.298039, 0.752941, 1.5655361115932465, 0.865003, 0.865003, 0.865003, 2.8526010513305664, 0.705882, 0.0156863, 0.14902]
densityLUT.ScalarRangeInitialized = 1.0

# get opacity transfer function/opacity map for 'density'
densityPWF = GetOpacityTransferFunction('density')
densityPWF.Points = [0.2784711718559265, 0.0, 0.5, 0.0, 2.8526010513305664, 1.0, 0.5, 0.0]
densityPWF.ScalarRangeInitialized = 1

# create a new 'Gradient'
gradient1 = Gradient(registrationName='Gradient1', Input=volcanoSlice1)

# rename source object
RenameSource('DensityGradient', gradient1)

# Properties modified on gradient1
gradient1.ResultArrayName = 'delRho'

# show data in view
gradient1Display = Show(gradient1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
gradient1Display.Representation = 'Surface'

# hide data in view
Hide(volcanoSlice1, renderView1)

# show color bar/color legend
gradient1Display.SetScalarBarVisibility(renderView1, True)

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(gradient1Display, ('POINTS', 'delRho', 'Magnitude'))

# Hide the scalar bar for this color map if no visible data is colored by it.
HideScalarBarIfNotNeeded(densityLUT, renderView1)

# rescale color and/or opacity maps used to include current data range
gradient1Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
gradient1Display.SetScalarBarVisibility(renderView1, True)

# get 2D transfer function for 'delRho'
delRhoTF2D = GetTransferFunction2D('delRho')

# get color transfer function/color map for 'delRho'
delRhoLUT = GetColorTransferFunction('delRho')
delRhoLUT.TransferFunction2D = delRhoTF2D
delRhoLUT.RGBPoints = [0.0003289510077485593, 0.231373, 0.298039, 0.752941, 196.44506170062394, 0.865003, 0.865003, 0.865003, 392.8897944502401, 0.705882, 0.0156863, 0.14902]
delRhoLUT.ScalarRangeInitialized = 1.0

# get opacity transfer function/opacity map for 'delRho'
delRhoPWF = GetOpacityTransferFunction('delRho')
delRhoPWF.Points = [0.0003289510077485593, 0.0, 0.5, 0.0, 392.8897944502401, 1.0, 0.5, 0.0]
delRhoPWF.ScalarRangeInitialized = 1

# create a new 'Calculator'
calculator1 = Calculator(registrationName='Calculator1', Input=gradient1)

# set active source
SetActiveSource(gradient1)

# set active source
SetActiveSource(volcanoSlice1)

# set active source
SetActiveSource(volcanoSlice1)

# set active source
SetActiveSource(volcanoSlice1)

# set active source
SetActiveSource(gradient1)

# set active source
SetActiveSource(calculator1)

# rename source object
RenameSource('magDelRho', calculator1)

# set active source
SetActiveSource(gradient1)

# set active source
SetActiveSource(calculator1)

# Properties modified on calculator1
calculator1.ResultArrayName = 'magDelRho'
calculator1.Function = 'mag(delRho)'

# show data in view
calculator1Display = Show(calculator1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
calculator1Display.Representation = 'Surface'

# hide data in view
Hide(gradient1, renderView1)

# show color bar/color legend
calculator1Display.SetScalarBarVisibility(renderView1, True)

# update the view to ensure updated data information
renderView1.Update()

# get 2D transfer function for 'magDelRho'
magDelRhoTF2D = GetTransferFunction2D('magDelRho')

# get color transfer function/color map for 'magDelRho'
magDelRhoLUT = GetColorTransferFunction('magDelRho')
magDelRhoLUT.TransferFunction2D = magDelRhoTF2D
magDelRhoLUT.RGBPoints = [0.0003289510077485593, 0.231373, 0.298039, 0.752941, 196.44506170062394, 0.865003, 0.865003, 0.865003, 392.8897944502401, 0.705882, 0.0156863, 0.14902]
magDelRhoLUT.ScalarRangeInitialized = 1.0

# get opacity transfer function/opacity map for 'magDelRho'
magDelRhoPWF = GetOpacityTransferFunction('magDelRho')
magDelRhoPWF.Points = [0.0003289510077485593, 0.0, 0.5, 0.0, 392.8897944502401, 1.0, 0.5, 0.0]
magDelRhoPWF.ScalarRangeInitialized = 1

renderView1.ResetActiveCameraToNegativeZ()

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# get color legend/bar for magDelRhoLUT in view renderView1
magDelRhoLUTColorBar = GetScalarBar(magDelRhoLUT, renderView1)
magDelRhoLUTColorBar.Title = 'magDelRho'
magDelRhoLUTColorBar.ComponentTitle = ''

# change scalar bar placement
magDelRhoLUTColorBar.WindowLocation = 'Any Location'
magDelRhoLUTColorBar.Position = [0.7195121951219512, 0.0]
magDelRhoLUTColorBar.ScalarBarLength = 0.33000000000000007

# change scalar bar placement
magDelRhoLUTColorBar.Position = [0.7161862527716186, 0.0017167381974248497]

renderView1.ResetActiveCameraToNegativeZ()

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# change scalar bar placement
magDelRhoLUTColorBar.Orientation = 'Horizontal'
magDelRhoLUTColorBar.Position = [0.3845232815964523, 0.25665236051502144]
magDelRhoLUTColorBar.ScalarBarLength = 0.33000000000000007

# set active source
SetActiveSource(volcanoSlice1)

renderView1.ResetActiveCameraToNegativeZ()

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# reset view to fit data bounds
renderView1.ResetCamera(-1.0477750301361084, 0.46037501096725464, -0.04296400025486946, 0.11349999904632568, -0.038100000470876694, -0.038100000470876694, False, 0.9)

# reset view to fit data bounds
renderView1.ResetCamera(-1.0477750301361084, 0.46037501096725464, -0.04296400025486946, 0.11349999904632568, -0.038100000470876694, -0.038100000470876694, False, 0.9)

# change scalar bar placement
magDelRhoLUTColorBar.Position = [0.32687361419068733, 0.12618025751072956]
magDelRhoLUTColorBar.ScalarBarLength = 0.3300000000000001

#================================================================
# addendum: following script captures some of the application
# state to faithfully reproduce the visualization during playback
#================================================================

# get layout
layout1 = GetLayout()

#--------------------------------
# saving layout sizes for layouts

# layout/tab size in pixels
layout1.SetSize(1804, 1165)

#-----------------------------------
# saving camera placements for views

# current camera placement for renderView1
renderView1.CameraPosition = [-0.2937000095844269, 0.03526799939572811, 2.891059535434184]
renderView1.CameraFocalPoint = [-0.12205592988481274, 0.08448946342723503, 0.14737991561864744]
renderView1.CameraViewAngle = 3.891352549889135
renderView1.CameraParallelScale = 0.7581222740358906


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