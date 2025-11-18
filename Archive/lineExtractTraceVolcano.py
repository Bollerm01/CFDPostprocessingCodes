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
latestvolcano.CellArrayStatus = ['reynoldsstressxx', 'reynoldsstressyy', 'reynoldsstresszz']

# create a new 'Volcano Slice'
volcanoSlice1 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)

# rename source object
RenameSource('RxxMidplane', volcanoSlice1)

# Properties modified on volcanoSlice1
volcanoSlice1.MinMaxField = 'reynoldsstressxx'
volcanoSlice1.Crinkle = 0
volcanoSlice1.InterpolatedField = 'reynoldsstressxx'

# get active view
renderView1 = GetActiveViewOrCreate('RenderView')

# show data in view
volcanoSlice1Display = Show(volcanoSlice1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1Display.Representation = 'Surface'

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(volcanoSlice1Display, ('POINTS', 'reynoldsstressxx'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice1Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice1Display.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'reynoldsstressxx'
reynoldsstressxxLUT = GetColorTransferFunction('reynoldsstressxx')

# get opacity transfer function/opacity map for 'reynoldsstressxx'
reynoldsstressxxPWF = GetOpacityTransferFunction('reynoldsstressxx')

# get 2D transfer function for 'reynoldsstressxx'
reynoldsstressxxTF2D = GetTransferFunction2D('reynoldsstressxx')

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1)

# Properties modified on extractCellsAlongLine1
extractCellsAlongLine1.Point1 = [-0.18222, 0.06, -0.03810000000000013]
extractCellsAlongLine1.Point2 = [-0.18222, 0.02, -0.03809999999999994]

# show data in view
extractCellsAlongLine1Display = Show(extractCellsAlongLine1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
extractCellsAlongLine1Display.Representation = 'Surface'

# hide data in view
Hide(volcanoSlice1, renderView1)

# show color bar/color legend
extractCellsAlongLine1Display.SetScalarBarVisibility(renderView1, True)

# update the view to ensure updated data information
renderView1.Update()

# create a new 'Plot Over Line'
plotOverLine1 = PlotOverLine(registrationName='PlotOverLine1', Input=extractCellsAlongLine1)

# set active source
SetActiveSource(extractCellsAlongLine1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=plotOverLine1)

# destroy plotOverLine1
Delete(plotOverLine1)
del plotOverLine1

# get animation scene
animationScene1 = GetAnimationScene()

# update animation scene based on data timesteps
animationScene1.UpdateAnimationUsingDataTimeSteps()

# set active source
SetActiveSource(extractCellsAlongLine1)

# set active source
SetActiveSource(latestvolcano)

# set active source
SetActiveSource(volcanoSlice1)

# create a new 'Integrate Variables'
integrateVariables1 = IntegrateVariables(registrationName='IntegrateVariables1', Input=volcanoSlice1)

# Create a new 'SpreadSheet View'
spreadSheetView1 = CreateView('SpreadSheetView')
spreadSheetView1.ColumnToSort = ''
spreadSheetView1.BlockSize = 1024

# show data in view
integrateVariables1Display = Show(integrateVariables1, spreadSheetView1, 'SpreadSheetRepresentation')

# get layout
layout1 = GetLayoutByName("Layout #1")

# add view to a layout so it's visible in UI
AssignViewToLayout(view=spreadSheetView1, layout=layout1, hint=0)

# update the view to ensure updated data information
renderView1.Update()

# update the view to ensure updated data information
spreadSheetView1.Update()

# show data in view
extractCellsAlongLine1Display_1 = Show(extractCellsAlongLine1, spreadSheetView1, 'SpreadSheetRepresentation')

# set active source
SetActiveSource(extractCellsAlongLine1)

# rename source object
RenameSource('0p03', extractCellsAlongLine1)

# set active source
SetActiveSource(volcanoSlice1)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_1 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1)

# show data in view
extractCellsAlongLine1_1Display = Show(extractCellsAlongLine1_1, spreadSheetView1, 'SpreadSheetRepresentation')

# rename source object
RenameSource('US', extractCellsAlongLine1_1)

# set active source
SetActiveSource(extractCellsAlongLine1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_1)

# set active source
SetActiveSource(extractCellsAlongLine1_1)

# set active source
SetActiveSource(latestvolcano)

# set active source
SetActiveSource(extractCellsAlongLine1)

# set active source
SetActiveSource(extractCellsAlongLine1_1)

# Properties modified on extractCellsAlongLine1_1
extractCellsAlongLine1_1.Point1 = [-0.2604, 0.06, -0.03810000000000013]
extractCellsAlongLine1_1.Point2 = [-0.2604, 0.02, -0.03809999999999994]

# update the view to ensure updated data information
spreadSheetView1.Update()

# set active source
SetActiveSource(volcanoSlice1)

# set active source
SetActiveSource(extractCellsAlongLine1_1)

# set active source
SetActiveSource(volcanoSlice1)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_2 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1)

# show data in view
extractCellsAlongLine1_2Display = Show(extractCellsAlongLine1_2, spreadSheetView1, 'SpreadSheetRepresentation')

# rename source object
RenameSource('0p3', extractCellsAlongLine1_2)

# rename source object
RenameSource('0p73', extractCellsAlongLine1_2)

# Properties modified on extractCellsAlongLine1_2
extractCellsAlongLine1_2.Point1 = [-0.13512, 0.06, -0.03810000000000013]
extractCellsAlongLine1_2.Point2 = [-0.13512, 0.02, -0.03809999999999994]

# update the view to ensure updated data information
spreadSheetView1.Update()

# Properties modified on spreadSheetView1
spreadSheetView1.HiddenColumnLabels = ['Block Number', 'Point ID']

# Properties modified on spreadSheetView1
spreadSheetView1.HiddenColumnLabels = []

# set active source
SetActiveSource(extractCellsAlongLine1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_2)

# hide data in view
Hide(extractCellsAlongLine1_2, spreadSheetView1)

# set active source
SetActiveSource(extractCellsAlongLine1_2)

# show data in view
extractCellsAlongLine1_2Display = Show(extractCellsAlongLine1_2, spreadSheetView1, 'SpreadSheetRepresentation')

# show data in view
extractCellsAlongLine1_2Display = Show(extractCellsAlongLine1_2, spreadSheetView1, 'SpreadSheetRepresentation')

# set active source
SetActiveSource(volcanoSlice1)

# set active source
SetActiveSource(latestvolcano)

# create a new 'Volcano Slice'
volcanoSlice1_1 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)

# show data in view
volcanoSlice1_1Display = Show(volcanoSlice1_1, spreadSheetView1, 'SpreadSheetRepresentation')

# rename source object
RenameSource('RyyMidplane', volcanoSlice1_1)

# Properties modified on volcanoSlice1_1
volcanoSlice1_1.MinMaxField = 'reynoldsstressyy'
volcanoSlice1_1.InterpolatedField = 'reynoldsstressyy'

# update the view to ensure updated data information
spreadSheetView1.Update()

# set active view
SetActiveView(renderView1)

# set active source
SetActiveSource(volcanoSlice1_1)

# show data in view
volcanoSlice1_1Display_1 = Show(volcanoSlice1_1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1_1Display_1.Representation = 'Surface'

# hide data in view
Hide(extractCellsAlongLine1, renderView1)

# set scalar coloring
ColorBy(volcanoSlice1_1Display_1, ('POINTS', 'reynoldsstressyy'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice1_1Display_1.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice1_1Display_1.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'reynoldsstressyy'
reynoldsstressyyLUT = GetColorTransferFunction('reynoldsstressyy')

# get opacity transfer function/opacity map for 'reynoldsstressyy'
reynoldsstressyyPWF = GetOpacityTransferFunction('reynoldsstressyy')

# get 2D transfer function for 'reynoldsstressyy'
reynoldsstressyyTF2D = GetTransferFunction2D('reynoldsstressyy')

# set active source
SetActiveSource(volcanoSlice1_1)

# set active source
SetActiveSource(extractCellsAlongLine1)

# set active source
SetActiveSource(volcanoSlice1_1)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_3 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_1)

# hide data in view
Hide(volcanoSlice1_1, renderView1)

# get display properties
extractCellsAlongLine1_3Display = GetDisplayProperties(extractCellsAlongLine1_3, view=renderView1)

# rename source object
RenameSource('0p03', extractCellsAlongLine1_3)

# set active source
SetActiveSource(extractCellsAlongLine1_1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_3)

# set active source
SetActiveSource(volcanoSlice1_1)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_4 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_1)

# hide data in view
Hide(volcanoSlice1_1, renderView1)

# get display properties
extractCellsAlongLine1_4Display = GetDisplayProperties(extractCellsAlongLine1_4, view=renderView1)

# rename source object
RenameSource('US', extractCellsAlongLine1_4)

# set active source
SetActiveSource(volcanoSlice1_1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_4)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_5 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_1)

# hide data in view
Hide(volcanoSlice1_1, renderView1)

# get display properties
extractCellsAlongLine1_5Display = GetDisplayProperties(extractCellsAlongLine1_5, view=renderView1)

# set active source
SetActiveSource(volcanoSlice1_1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_5)

# hide data in view
Hide(extractCellsAlongLine1_5, renderView1)

# show data in view
volcanoSlice1_1Display_1 = Show(volcanoSlice1_1, renderView1, 'UnstructuredGridRepresentation')

# show color bar/color legend
volcanoSlice1_1Display_1.SetScalarBarVisibility(renderView1, True)

# destroy extractCellsAlongLine1_5
Delete(extractCellsAlongLine1_5)
del extractCellsAlongLine1_5

# update animation scene based on data timesteps
animationScene1.UpdateAnimationUsingDataTimeSteps()

# hide data in view
Hide(extractCellsAlongLine1_3, renderView1)

# hide data in view
Hide(volcanoSlice1_1, renderView1)

# set active source
SetActiveSource(extractCellsAlongLine1_2)

# set active source
SetActiveSource(volcanoSlice1_1)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_5 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_1)

# hide data in view
Hide(volcanoSlice1_1, renderView1)

# get display properties
extractCellsAlongLine1_5Display = GetDisplayProperties(extractCellsAlongLine1_5, view=renderView1)

# rename source object
RenameSource('0p73', extractCellsAlongLine1_5)

# hide data in view
Hide(extractCellsAlongLine1_4, renderView1)

# hide data in view
Hide(extractCellsAlongLine1_5, renderView1)

# set active source
SetActiveSource(volcanoSlice1_1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_5)

# set active source
SetActiveSource(volcanoSlice1)

# set active source
SetActiveSource(latestvolcano)

# create a new 'Volcano Slice'
volcanoSlice1_2 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)

# get display properties
volcanoSlice1_2Display = GetDisplayProperties(volcanoSlice1_2, view=renderView1)

# rename source object
RenameSource('RzzMidplane', volcanoSlice1_2)

# set active source
SetActiveSource(extractCellsAlongLine1_4)

# set active source
SetActiveSource(volcanoSlice1_2)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_6 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_2)

# hide data in view
Hide(volcanoSlice1_2, renderView1)

# get display properties
extractCellsAlongLine1_6Display = GetDisplayProperties(extractCellsAlongLine1_6, view=renderView1)

# rename source object
RenameSource('US', extractCellsAlongLine1_6)

# set active source
SetActiveSource(extractCellsAlongLine1_3)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_6)

# set active source
SetActiveSource(volcanoSlice1_2)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_7 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_2)

# hide data in view
Hide(volcanoSlice1_2, renderView1)

# get display properties
extractCellsAlongLine1_7Display = GetDisplayProperties(extractCellsAlongLine1_7, view=renderView1)

# rename source object
RenameSource('0p03', extractCellsAlongLine1_7)

# set active source
SetActiveSource(volcanoSlice1_2)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_7)

# set active source
SetActiveSource(extractCellsAlongLine1_5)

# set active source
SetActiveSource(volcanoSlice1_2)

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_8 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_2)

# hide data in view
Hide(volcanoSlice1_2, renderView1)

# get display properties
extractCellsAlongLine1_8Display = GetDisplayProperties(extractCellsAlongLine1_8, view=renderView1)

# rename source object
RenameSource('op73', extractCellsAlongLine1_8)

# rename source object
RenameSource('0p73', extractCellsAlongLine1_8)

# hide data in view
Hide(extractCellsAlongLine1_6, renderView1)

# hide data in view
Hide(extractCellsAlongLine1_7, renderView1)

# set active source
SetActiveSource(volcanoSlice1_2)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=extractCellsAlongLine1_8)

# update the view to ensure updated data information
renderView1.Update()

# set active source
SetActiveSource(volcanoSlice1_2)

# show data in view
volcanoSlice1_2Display = Show(volcanoSlice1_2, renderView1, 'UnstructuredGridRepresentation')

# hide data in view
Hide(extractCellsAlongLine1_8, renderView1)

# set scalar coloring
ColorBy(volcanoSlice1_2Display, ('POINTS', 'reynoldsstressyy'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice1_2Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice1_2Display.SetScalarBarVisibility(renderView1, True)

# turn off scalar coloring
ColorBy(volcanoSlice1_2Display, None)

# Hide the scalar bar for this color map if no visible data is colored by it.
HideScalarBarIfNotNeeded(reynoldsstressyyLUT, renderView1)

# Properties modified on volcanoSlice1_2
volcanoSlice1_2.MinMaxField = 'reynoldsstresszz'
volcanoSlice1_2.InterpolatedField = 'reynoldsstresszz'

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(volcanoSlice1_2Display, ('POINTS', 'reynoldsstresszz'))

# rescale color and/or opacity maps used to include current data range
volcanoSlice1_2Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
volcanoSlice1_2Display.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'reynoldsstresszz'
reynoldsstresszzLUT = GetColorTransferFunction('reynoldsstresszz')

# get opacity transfer function/opacity map for 'reynoldsstresszz'
reynoldsstresszzPWF = GetOpacityTransferFunction('reynoldsstresszz')

# get 2D transfer function for 'reynoldsstresszz'
reynoldsstresszzTF2D = GetTransferFunction2D('reynoldsstresszz')

# set active view
SetActiveView(spreadSheetView1)

# Properties modified on spreadSheetView1
spreadSheetView1.ColumnToSort = 'reynoldsstressyy'
spreadSheetView1.InvertOrder = 1

# Properties modified on spreadSheetView1
spreadSheetView1.InvertOrder = 0

# Properties modified on spreadSheetView1
spreadSheetView1.ColumnToSort = 'Points_1'
spreadSheetView1.InvertOrder = 1

SelectIDs(IDs=[-1, 49308], FieldType=1, ContainingCells=0)

# set active source
SetActiveSource(volcanoSlice1_1)

# Properties modified on spreadSheetView1
spreadSheetView1.ColumnToSort = 'Points_2'

# set active source
SetActiveSource(extractCellsAlongLine1)

# rename source object
RenameSource('xx0p03', extractCellsAlongLine1)

# set active source
SetActiveSource(extractCellsAlongLine1_1)

# rename source object
RenameSource('xxUS', extractCellsAlongLine1_1)

# set active source
SetActiveSource(extractCellsAlongLine1_2)

# rename source object
RenameSource('xx0p73', extractCellsAlongLine1_2)

# set active source
SetActiveSource(extractCellsAlongLine1_3)

# rename source object
RenameSource('yy0p03', extractCellsAlongLine1_3)

# set active source
SetActiveSource(extractCellsAlongLine1_4)

# rename source object
RenameSource('yyUS', extractCellsAlongLine1_4)

# set active source
SetActiveSource(extractCellsAlongLine1_5)

# rename source object
RenameSource('yy0p73', extractCellsAlongLine1_5)

# set active source
SetActiveSource(extractCellsAlongLine1_6)

# rename source object
RenameSource('zzUS', extractCellsAlongLine1_6)

# set active source
SetActiveSource(extractCellsAlongLine1_7)

# rename source object
RenameSource('zz0p03', extractCellsAlongLine1_7)

# set active source
SetActiveSource(extractCellsAlongLine1_8)

# rename source object
RenameSource('zz0p73', extractCellsAlongLine1_8)

# resize frame
layout1.SetSplitFraction(0, 0.561744966442953)

# show data in view
extractCellsAlongLine1Display_1 = Show(extractCellsAlongLine1, spreadSheetView1, 'SpreadSheetRepresentation')

# show data in view
extractCellsAlongLine1_1Display = Show(extractCellsAlongLine1_1, spreadSheetView1, 'SpreadSheetRepresentation')

# Properties modified on spreadSheetView1
spreadSheetView1.ColumnToSort = 'vtkOriginalIndices'

# Properties modified on spreadSheetView1
spreadSheetView1.InvertOrder = 0

SelectIDs(IDs=[-1, 0], FieldType=1, ContainingCells=0)

# clear all selections
ClearSelection()

# set active source
SetActiveSource(extractCellsAlongLine1_1)

# Properties modified on spreadSheetView1
spreadSheetView1.InvertOrder = 1

# Properties modified on spreadSheetView1
spreadSheetView1.InvertOrder = 0

SelectIDs(IDs=[-1, 0], FieldType=1, ContainingCells=0)

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/US/xxUS.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_4Display_1 = Show(extractCellsAlongLine1_4, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/US/yyUS.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_6Display_1 = Show(extractCellsAlongLine1_6, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/US/zzUS.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1Display_1 = Show(extractCellsAlongLine1, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/0p03/xx0p03.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_3Display_1 = Show(extractCellsAlongLine1_3, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/0p03/yy0p03.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_7Display_1 = Show(extractCellsAlongLine1_7, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/0p03/zz0p03.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_2Display = Show(extractCellsAlongLine1_2, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/0p73/xx0p73.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_5Display_1 = Show(extractCellsAlongLine1_5, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/0p73/yy0p73.csv', view=spreadSheetView1)

# show data in view
extractCellsAlongLine1_8Display_1 = Show(extractCellsAlongLine1_8, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/0p73/zz0p73.csv', view=spreadSheetView1)

#================================================================
# addendum: following script captures some of the application
# state to faithfully reproduce the visualization during playback
#================================================================

#--------------------------------
# saving layout sizes for layouts

# layout/tab size in pixels
layout1.SetSize(1230, 782)

#-----------------------------------
# saving camera placements for views

# current camera placement for renderView1
renderView1.CameraPosition = [-0.2937593749999998, 0.03526799999999993, 0.8951381476653495]
renderView1.CameraFocalPoint = [-0.2937593749999998, 0.03526799999999993, -0.03810000000000004]
renderView1.CameraParallelScale = 0.7580553819861734


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