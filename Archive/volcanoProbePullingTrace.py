# trace generated using paraview version 5.13.1
#import paraview
#paraview.compatibility.major = 5
#paraview.compatibility.minor = 13

#### import the simple module from the paraview
from paraview.simple import *
#### disable automatic camera reset on 'Show'
paraview.simple._DisableFirstRenderCameraReset()

# create a new 'File Series Reader'
latestvolcano = FileSeriesReader(registrationName='latest.volcano', FileNames=['/home/bollerma/LESdata/SSWT/fullCav/meshStudy/test5/test5M2SSWT_001/latest.volcano'])
latestvolcano.CellArrayStatus = []
latestvolcano.ComputableCellArrayStatus = []
latestvolcano.PointArrayStatus = []

# rename source object
RenameSource('test5', latestvolcano)

# Properties modified on latestvolcano
latestvolcano.CellArrayStatus = ['velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']

# create a new 'Volcano Slice'
volcanoSlice1 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)
volcanoSlice1.MinMaxField = ''

# Properties modified on volcanoSlice1
volcanoSlice1.MinMaxField = 'None'

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
volcanoSlice1Display.OSPRayScaleFunction = 'Piecewise Function'
volcanoSlice1Display.Assembly = ''
volcanoSlice1Display.SelectedBlockSelectors = ['']
volcanoSlice1Display.SelectOrientationVectors = 'None'
volcanoSlice1Display.ScaleFactor = 0.2549
volcanoSlice1Display.SelectScaleArray = 'None'
volcanoSlice1Display.GlyphType = 'Arrow'
volcanoSlice1Display.GlyphTableIndexArray = 'None'
volcanoSlice1Display.GaussianRadius = 0.012745
volcanoSlice1Display.SetScaleArray = [None, '']
volcanoSlice1Display.ScaleTransferFunction = 'Piecewise Function'
volcanoSlice1Display.OpacityArray = [None, '']
volcanoSlice1Display.OpacityTransferFunction = 'Piecewise Function'
volcanoSlice1Display.DataAxesGrid = 'Grid Axes Representation'
volcanoSlice1Display.PolarAxes = 'Polar Axes Representation'
volcanoSlice1Display.ScalarOpacityUnitDistance = 0.04279032142880863
volcanoSlice1Display.OpacityArrayName = ['CELLS', 'MMID']
volcanoSlice1Display.SelectInputVectors = [None, '']
volcanoSlice1Display.WriteLog = ''

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
volcanoSlice1Display_1.ScalarOpacityUnitDistance = 1.1328447884304118
volcanoSlice1Display_1.OpacityArrayName = [None, '']
volcanoSlice1Display_1.SelectInputVectors = [None, '']
volcanoSlice1Display_1.WriteLog = ''

# update the view to ensure updated data information
renderView1.Update()

# rename source object
RenameSource('midplaneSlice', volcanoSlice1)

# create a new 'Plot Data'
plotData1 = PlotData(registrationName='PlotData1', Input=volcanoSlice1)

# rename source object
RenameSource('veliocityXdata', plotData1)

# rename source object
RenameSource('velocityXdata', plotData1)

# Create a new 'Line Chart View'
lineChartView1 = CreateView('XYChartView')

# show data in view
plotData1Display = Show(plotData1, lineChartView1, 'XYChartRepresentation')

# trace defaults for the display properties.
plotData1Display.AttributeType = 'Cell Data'
plotData1Display.XArrayName = 'doublelevel'
plotData1Display.SeriesVisibility = ['doublelevel', 'dx', 'level', 'MMID', 'velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']
plotData1Display.SeriesLabel = ['Points_X', 'Points_X', 'Points_Y', 'Points_Y', 'Points_Z', 'Points_Z', 'Points_Magnitude', 'Points_Magnitude', 'doublelevel', 'doublelevel', 'dx', 'dx', 'level', 'level', 'MMID', 'MMID', 'velocitymag', 'velocitymag', 'velocitymagavg', 'velocitymagavg', 'velocityx', 'velocityx', 'velocityxavg', 'velocityxavg']
plotData1Display.SeriesColor = ['Points_X', '0', '0', '0', 'Points_Y', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'Points_Z', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'Points_Magnitude', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'doublelevel', '0.6', '0.3100022888532845', '0.6399938963912413', 'dx', '1', '0.5000076295109483', '0', 'level', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867', 'MMID', '0', '0', '0', 'velocitymag', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'velocitymagavg', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'velocityx', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'velocityxavg', '0.6', '0.3100022888532845', '0.6399938963912413']
plotData1Display.SeriesOpacity = ['Points_X', '1.0', 'Points_Y', '1.0', 'Points_Z', '1.0', 'Points_Magnitude', '1.0', 'doublelevel', '1.0', 'dx', '1.0', 'level', '1.0', 'MMID', '1.0', 'velocitymag', '1.0', 'velocitymagavg', '1.0', 'velocityx', '1.0', 'velocityxavg', '1.0']
plotData1Display.SeriesPlotCorner = ['Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0']
plotData1Display.SeriesLabelPrefix = ''
plotData1Display.SeriesLineStyle = ['Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1']
plotData1Display.SeriesLineThickness = ['Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'Points_Magnitude', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'MMID', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2']
plotData1Display.SeriesMarkerStyle = ['Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0']
plotData1Display.SeriesMarkerSize = ['Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'Points_Magnitude', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'MMID', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4']

# get layout
layout1 = GetLayoutByName("Layout #1")

# add view to a layout so it's visible in UI
AssignViewToLayout(view=lineChartView1, layout=layout1, hint=0)

# Properties modified on plotData1Display
plotData1Display.SeriesOpacity = ['Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1']
plotData1Display.SeriesPlotCorner = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0']
plotData1Display.SeriesLineStyle = ['MMID', '1', 'Points_Magnitude', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1']
plotData1Display.SeriesLineThickness = ['MMID', '2', 'Points_Magnitude', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2']
plotData1Display.SeriesMarkerStyle = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0']
plotData1Display.SeriesMarkerSize = ['MMID', '4', 'Points_Magnitude', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4']

# create new layout object 'Layout #2'
layout2 = CreateLayout(name='Layout #2')

# set active view
SetActiveView(None)

# Create a new 'SpreadSheet View'
spreadSheetView1 = CreateView('SpreadSheetView')
spreadSheetView1.ColumnToSort = ''
spreadSheetView1.BlockSize = 1024

# show data in view
plotData1Display_1 = Show(plotData1, spreadSheetView1, 'SpreadSheetRepresentation')

# trace defaults for the display properties.
plotData1Display_1.Assembly = ''

# assign view to a particular cell in the layout
AssignViewToLayout(view=spreadSheetView1, layout=layout2, hint=0)

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Cell Data'

SelectIDs(IDs=[-1, 3], FieldType=0, ContainingCells=0)

# set active source
SetActiveSource(plotData1)

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Point Data'

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Cell Data'

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Point Data'

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Cell Data'

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Point Data'

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Cell Data'

# rename source object
RenameSource('allData', plotData1)

# create a new 'Cell Data to Point Data'
cellDatatoPointData1 = CellDatatoPointData(registrationName='CellDatatoPointData1', Input=plotData1)
cellDatatoPointData1.CellDataArraytoprocess = ['MMID', 'doublelevel', 'dx', 'level', 'velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']

# Properties modified on cellDatatoPointData1
cellDatatoPointData1.PassCellData = 1

# show data in view
cellDatatoPointData1Display = Show(cellDatatoPointData1, spreadSheetView1, 'SpreadSheetRepresentation')

# trace defaults for the display properties.
cellDatatoPointData1Display.Assembly = ''

# hide data in view
Hide(plotData1, spreadSheetView1)

# update the view to ensure updated data information
spreadSheetView1.Update()

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Point Data'

# create a new 'Plot Over Line'
plotOverLine1 = PlotOverLine(registrationName='PlotOverLine1', Input=cellDatatoPointData1)
plotOverLine1.Point1 = [0.0, -8.734968772406738e-06, -5.551115123125783e-17]
plotOverLine1.Point2 = [2.549, 0.48099126503122785, 0.007999999999999986]

# set active source
SetActiveSource(cellDatatoPointData1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=plotOverLine1)

# set active source
SetActiveSource(plotOverLine1)

# set active source
SetActiveSource(cellDatatoPointData1)

# destroy plotOverLine1
Delete(plotOverLine1)
del plotOverLine1

# get animation scene
animationScene1 = GetAnimationScene()

# update animation scene based on data timesteps
animationScene1.UpdateAnimationUsingDataTimeSteps()

# set active source
SetActiveSource(plotData1)

# hide data in view
Hide(cellDatatoPointData1, spreadSheetView1)

# show data in view
plotData1Display_1 = Show(plotData1, spreadSheetView1, 'SpreadSheetRepresentation')

# destroy cellDatatoPointData1
Delete(cellDatatoPointData1)
del cellDatatoPointData1

# update animation scene based on data timesteps
animationScene1.UpdateAnimationUsingDataTimeSteps()

# show data in view
plotData1Display_1 = Show(plotData1, spreadSheetView1, 'SpreadSheetRepresentation')

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Cell Data'

# create a new 'Plot Over Line'
plotOverLine1 = PlotOverLine(registrationName='PlotOverLine1', Input=plotData1)
plotOverLine1.Point1 = [0.0, -8.734968772406738e-06, -5.551115123125783e-17]
plotOverLine1.Point2 = [2.549, 0.48099126503122785, 0.007999999999999986]

# set active view
SetActiveView(renderView1)

# Properties modified on plotOverLine1
plotOverLine1.Resolution = 500
plotOverLine1.Point1 = [2.15058, 0.03719, 0.0]
plotOverLine1.Point2 = [2.15058, 0.0, 0.0]

# show data in view
plotOverLine1Display = Show(plotOverLine1, renderView1, 'GeometryRepresentation')

# trace defaults for the display properties.
plotOverLine1Display.Representation = 'Surface'
plotOverLine1Display.ColorArrayName = [None, '']
plotOverLine1Display.SelectNormalArray = 'None'
plotOverLine1Display.SelectTangentArray = 'None'
plotOverLine1Display.SelectTCoordArray = 'None'
plotOverLine1Display.TextureTransform = 'Transform2'
plotOverLine1Display.OSPRayScaleArray = 'MMID'
plotOverLine1Display.OSPRayScaleFunction = 'Piecewise Function'
plotOverLine1Display.Assembly = ''
plotOverLine1Display.SelectedBlockSelectors = ['']
plotOverLine1Display.SelectOrientationVectors = 'None'
plotOverLine1Display.ScaleFactor = 0.003719000145792961
plotOverLine1Display.SelectScaleArray = 'MMID'
plotOverLine1Display.GlyphType = 'Arrow'
plotOverLine1Display.GlyphTableIndexArray = 'MMID'
plotOverLine1Display.GaussianRadius = 0.00018595000728964807
plotOverLine1Display.SetScaleArray = ['POINTS', 'MMID']
plotOverLine1Display.ScaleTransferFunction = 'Piecewise Function'
plotOverLine1Display.OpacityArray = ['POINTS', 'MMID']
plotOverLine1Display.OpacityTransferFunction = 'Piecewise Function'
plotOverLine1Display.DataAxesGrid = 'Grid Axes Representation'
plotOverLine1Display.PolarAxes = 'Polar Axes Representation'
plotOverLine1Display.SelectInputVectors = [None, '']
plotOverLine1Display.WriteLog = ''

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
plotOverLine1Display.ScaleTransferFunction.Points = [-1.0, 0.0, 0.5, 0.0, 0.0, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
plotOverLine1Display.OpacityTransferFunction.Points = [-1.0, 0.0, 0.5, 0.0, 0.0, 1.0, 0.5, 0.0]

# Create a new 'Line Chart View'
lineChartView2 = CreateView('XYChartView')

# show data in view
plotOverLine1Display_1 = Show(plotOverLine1, lineChartView2, 'XYChartRepresentation')

# trace defaults for the display properties.
plotOverLine1Display_1.UseIndexForXAxis = 0
plotOverLine1Display_1.XArrayName = 'arc_length'
plotOverLine1Display_1.SeriesVisibility = ['doublelevel', 'dx', 'level', 'MMID', 'velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']
plotOverLine1Display_1.SeriesLabel = ['arc_length', 'arc_length', 'doublelevel', 'doublelevel', 'dx', 'dx', 'level', 'level', 'MMID', 'MMID', 'velocitymag', 'velocitymag', 'velocitymagavg', 'velocitymagavg', 'velocityx', 'velocityx', 'velocityxavg', 'velocityxavg', 'vtkValidPointMask', 'vtkValidPointMask', 'Points_X', 'Points_X', 'Points_Y', 'Points_Y', 'Points_Z', 'Points_Z', 'Points_Magnitude', 'Points_Magnitude']
plotOverLine1Display_1.SeriesColor = ['arc_length', '0', '0', '0', 'doublelevel', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'dx', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'level', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'MMID', '0.6', '0.3100022888532845', '0.6399938963912413', 'velocitymag', '1', '0.5000076295109483', '0', 'velocitymagavg', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867', 'velocityx', '0', '0', '0', 'velocityxavg', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'vtkValidPointMask', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'Points_X', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'Points_Y', '0.6', '0.3100022888532845', '0.6399938963912413', 'Points_Z', '1', '0.5000076295109483', '0', 'Points_Magnitude', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867']
plotOverLine1Display_1.SeriesOpacity = ['arc_length', '1.0', 'doublelevel', '1.0', 'dx', '1.0', 'level', '1.0', 'MMID', '1.0', 'velocitymag', '1.0', 'velocitymagavg', '1.0', 'velocityx', '1.0', 'velocityxavg', '1.0', 'vtkValidPointMask', '1.0', 'Points_X', '1.0', 'Points_Y', '1.0', 'Points_Z', '1.0', 'Points_Magnitude', '1.0']
plotOverLine1Display_1.SeriesPlotCorner = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1Display_1.SeriesLabelPrefix = ''
plotOverLine1Display_1.SeriesLineStyle = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1Display_1.SeriesLineThickness = ['arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'MMID', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'Points_Magnitude', '2']
plotOverLine1Display_1.SeriesMarkerStyle = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1Display_1.SeriesMarkerSize = ['arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'MMID', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'Points_Magnitude', '4']

# add view to a layout so it's visible in UI
AssignViewToLayout(view=lineChartView2, layout=layout1, hint=1)

# Properties modified on plotOverLine1Display_1
plotOverLine1Display_1.SeriesOpacity = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1Display_1.SeriesPlotCorner = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1Display_1.SeriesLineStyle = ['MMID', '1', 'Points_Magnitude', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1']
plotOverLine1Display_1.SeriesLineThickness = ['MMID', '2', 'Points_Magnitude', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2']
plotOverLine1Display_1.SeriesMarkerStyle = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1Display_1.SeriesMarkerSize = ['MMID', '4', 'Points_Magnitude', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4']

# set active view
SetActiveView(spreadSheetView1)

# show data in view
plotOverLine1Display_2 = Show(plotOverLine1, spreadSheetView1, 'SpreadSheetRepresentation')

# trace defaults for the display properties.
plotOverLine1Display_2.Assembly = ''

# Properties modified on spreadSheetView1
spreadSheetView1.FieldAssociation = 'Point Data'

# export view
ExportView('/home/bollerma/LESdata/SSWT/fullCav/meshStudy/test5/test5M2SSWT_001/sampleProbeLinex0p03.csv', view=spreadSheetView1)

# rename source object
RenameSource('x0p03Line', plotOverLine1)

# set active source
SetActiveSource(plotData1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=plotOverLine1)

# set active source
SetActiveSource(plotOverLine1)

# set active source
SetActiveSource(plotData1)

# create a new 'Plot Over Line'
plotOverLine1_1 = PlotOverLine(registrationName='PlotOverLine1', Input=plotData1)
plotOverLine1_1.Point1 = [0.0, -8.734968772406738e-06, -5.551115123125783e-17]
plotOverLine1_1.Point2 = [2.549, 0.48099126503122785, 0.007999999999999986]

# show data in view
plotOverLine1_1Display = Show(plotOverLine1_1, spreadSheetView1, 'SpreadSheetRepresentation')

# trace defaults for the display properties.
plotOverLine1_1Display.Assembly = ''

# rename source object
RenameSource('x0p17Line', plotOverLine1_1)

# set active view
SetActiveView(lineChartView1)

# set active source
SetActiveSource(plotOverLine1_1)

# show data in view
plotOverLine1_1Display_1 = Show(plotOverLine1_1, lineChartView1, 'XYChartRepresentation')

# trace defaults for the display properties.
plotOverLine1_1Display_1.UseIndexForXAxis = 0
plotOverLine1_1Display_1.XArrayName = 'arc_length'
plotOverLine1_1Display_1.SeriesVisibility = ['doublelevel', 'dx', 'level', 'MMID', 'velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']
plotOverLine1_1Display_1.SeriesLabel = ['arc_length', 'arc_length', 'doublelevel', 'doublelevel', 'dx', 'dx', 'level', 'level', 'MMID', 'MMID', 'velocitymag', 'velocitymag', 'velocitymagavg', 'velocitymagavg', 'velocityx', 'velocityx', 'velocityxavg', 'velocityxavg', 'vtkValidPointMask', 'vtkValidPointMask', 'Points_X', 'Points_X', 'Points_Y', 'Points_Y', 'Points_Z', 'Points_Z', 'Points_Magnitude', 'Points_Magnitude']
plotOverLine1_1Display_1.SeriesColor = ['arc_length', '0', '0', '0', 'doublelevel', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'dx', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'level', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'MMID', '0.6', '0.3100022888532845', '0.6399938963912413', 'velocitymag', '1', '0.5000076295109483', '0', 'velocitymagavg', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867', 'velocityx', '0', '0', '0', 'velocityxavg', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'vtkValidPointMask', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'Points_X', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'Points_Y', '0.6', '0.3100022888532845', '0.6399938963912413', 'Points_Z', '1', '0.5000076295109483', '0', 'Points_Magnitude', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867']
plotOverLine1_1Display_1.SeriesOpacity = ['arc_length', '1.0', 'doublelevel', '1.0', 'dx', '1.0', 'level', '1.0', 'MMID', '1.0', 'velocitymag', '1.0', 'velocitymagavg', '1.0', 'velocityx', '1.0', 'velocityxavg', '1.0', 'vtkValidPointMask', '1.0', 'Points_X', '1.0', 'Points_Y', '1.0', 'Points_Z', '1.0', 'Points_Magnitude', '1.0']
plotOverLine1_1Display_1.SeriesPlotCorner = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1_1Display_1.SeriesLabelPrefix = ''
plotOverLine1_1Display_1.SeriesLineStyle = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1_1Display_1.SeriesLineThickness = ['arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'MMID', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'Points_Magnitude', '2']
plotOverLine1_1Display_1.SeriesMarkerStyle = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1_1Display_1.SeriesMarkerSize = ['arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'MMID', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'Points_Magnitude', '4']

# Properties modified on plotOverLine1_1Display_1
plotOverLine1_1Display_1.SeriesOpacity = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1_1Display_1.SeriesPlotCorner = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1_1Display_1.SeriesLineStyle = ['MMID', '1', 'Points_Magnitude', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1']
plotOverLine1_1Display_1.SeriesLineThickness = ['MMID', '2', 'Points_Magnitude', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2']
plotOverLine1_1Display_1.SeriesMarkerStyle = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1_1Display_1.SeriesMarkerSize = ['MMID', '4', 'Points_Magnitude', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4']

# hide data in view
Hide(plotOverLine1_1, lineChartView1)

# show data in view
plotOverLine1_1Display_1 = Show(plotOverLine1_1, lineChartView1, 'XYChartRepresentation')

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=plotOverLine1_1)

# toggle interactive widget visibility (only when running from the GUI)
ShowInteractiveWidgets(proxy=plotOverLine1_1)

# Properties modified on plotOverLine1_1
plotOverLine1_1.Point1 = [2.16016, 0.03719, 0.0]
plotOverLine1_1.Point2 = [2.16016, 0.0, 0.0]

# update the view to ensure updated data information
lineChartView1.Update()

# update the view to ensure updated data information
spreadSheetView1.Update()

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=plotOverLine1_1)

# toggle interactive widget visibility (only when running from the GUI)
ShowInteractiveWidgets(proxy=plotOverLine1_1)

# set active view
SetActiveView(spreadSheetView1)

# set active view
SetActiveView(lineChartView1)

# set active source
SetActiveSource(plotOverLine1)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=plotOverLine1_1)

# show data in view
plotOverLine1Display_3 = Show(plotOverLine1, lineChartView1, 'XYChartRepresentation')

# trace defaults for the display properties.
plotOverLine1Display_3.UseIndexForXAxis = 0
plotOverLine1Display_3.XArrayName = 'arc_length'
plotOverLine1Display_3.SeriesVisibility = ['doublelevel', 'dx', 'level', 'MMID', 'velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']
plotOverLine1Display_3.SeriesLabel = ['arc_length', 'arc_length', 'doublelevel', 'doublelevel', 'dx', 'dx', 'level', 'level', 'MMID', 'MMID', 'velocitymag', 'velocitymag', 'velocitymagavg', 'velocitymagavg', 'velocityx', 'velocityx', 'velocityxavg', 'velocityxavg', 'vtkValidPointMask', 'vtkValidPointMask', 'Points_X', 'Points_X', 'Points_Y', 'Points_Y', 'Points_Z', 'Points_Z', 'Points_Magnitude', 'Points_Magnitude']
plotOverLine1Display_3.SeriesColor = ['arc_length', '0', '0', '0', 'doublelevel', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'dx', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'level', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'MMID', '0.6', '0.3100022888532845', '0.6399938963912413', 'velocitymag', '1', '0.5000076295109483', '0', 'velocitymagavg', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867', 'velocityx', '0', '0', '0', 'velocityxavg', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'vtkValidPointMask', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'Points_X', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'Points_Y', '0.6', '0.3100022888532845', '0.6399938963912413', 'Points_Z', '1', '0.5000076295109483', '0', 'Points_Magnitude', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867']
plotOverLine1Display_3.SeriesOpacity = ['arc_length', '1.0', 'doublelevel', '1.0', 'dx', '1.0', 'level', '1.0', 'MMID', '1.0', 'velocitymag', '1.0', 'velocitymagavg', '1.0', 'velocityx', '1.0', 'velocityxavg', '1.0', 'vtkValidPointMask', '1.0', 'Points_X', '1.0', 'Points_Y', '1.0', 'Points_Z', '1.0', 'Points_Magnitude', '1.0']
plotOverLine1Display_3.SeriesPlotCorner = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1Display_3.SeriesLabelPrefix = ''
plotOverLine1Display_3.SeriesLineStyle = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1Display_3.SeriesLineThickness = ['arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'MMID', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'Points_Magnitude', '2']
plotOverLine1Display_3.SeriesMarkerStyle = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1Display_3.SeriesMarkerSize = ['arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'MMID', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'Points_Magnitude', '4']

# Properties modified on plotOverLine1Display_3
plotOverLine1Display_3.SeriesOpacity = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1Display_3.SeriesPlotCorner = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1Display_3.SeriesLineStyle = ['MMID', '1', 'Points_Magnitude', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1']
plotOverLine1Display_3.SeriesLineThickness = ['MMID', '2', 'Points_Magnitude', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2']
plotOverLine1Display_3.SeriesMarkerStyle = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1Display_3.SeriesMarkerSize = ['MMID', '4', 'Points_Magnitude', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4']

# hide data in view
Hide(plotOverLine1_1, lineChartView1)

# set active source
SetActiveSource(plotOverLine1_1)

# show data in view
plotOverLine1_1Display_1 = Show(plotOverLine1_1, lineChartView1, 'XYChartRepresentation')

# hide data in view
Hide(plotOverLine1_1, lineChartView1)

# hide data in view
Hide(plotOverLine1, lineChartView1)

# set active view
SetActiveView(lineChartView2)

# show data in view
plotOverLine1_1Display_2 = Show(plotOverLine1_1, lineChartView2, 'XYChartRepresentation')

# trace defaults for the display properties.
plotOverLine1_1Display_2.UseIndexForXAxis = 0
plotOverLine1_1Display_2.XArrayName = 'arc_length'
plotOverLine1_1Display_2.SeriesVisibility = ['doublelevel', 'dx', 'level', 'MMID', 'velocitymag', 'velocitymagavg', 'velocityx', 'velocityxavg']
plotOverLine1_1Display_2.SeriesLabel = ['arc_length', 'arc_length', 'doublelevel', 'doublelevel', 'dx', 'dx', 'level', 'level', 'MMID', 'MMID', 'velocitymag', 'velocitymag', 'velocitymagavg', 'velocitymagavg', 'velocityx', 'velocityx', 'velocityxavg', 'velocityxavg', 'vtkValidPointMask', 'vtkValidPointMask', 'Points_X', 'Points_X', 'Points_Y', 'Points_Y', 'Points_Z', 'Points_Z', 'Points_Magnitude', 'Points_Magnitude']
plotOverLine1_1Display_2.SeriesColor = ['arc_length', '0', '0', '0', 'doublelevel', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'dx', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'level', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'MMID', '0.6', '0.3100022888532845', '0.6399938963912413', 'velocitymag', '1', '0.5000076295109483', '0', 'velocitymagavg', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867', 'velocityx', '0', '0', '0', 'velocityxavg', '0.8899977111467154', '0.10000762951094835', '0.1100022888532845', 'vtkValidPointMask', '0.220004577706569', '0.4899977111467155', '0.7199969481956207', 'Points_X', '0.30000762951094834', '0.6899977111467155', '0.2899977111467155', 'Points_Y', '0.6', '0.3100022888532845', '0.6399938963912413', 'Points_Z', '1', '0.5000076295109483', '0', 'Points_Magnitude', '0.6500038147554742', '0.3400015259021897', '0.16000610360875867']
plotOverLine1_1Display_2.SeriesOpacity = ['arc_length', '1.0', 'doublelevel', '1.0', 'dx', '1.0', 'level', '1.0', 'MMID', '1.0', 'velocitymag', '1.0', 'velocitymagavg', '1.0', 'velocityx', '1.0', 'velocityxavg', '1.0', 'vtkValidPointMask', '1.0', 'Points_X', '1.0', 'Points_Y', '1.0', 'Points_Z', '1.0', 'Points_Magnitude', '1.0']
plotOverLine1_1Display_2.SeriesPlotCorner = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1_1Display_2.SeriesLabelPrefix = ''
plotOverLine1_1Display_2.SeriesLineStyle = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1_1Display_2.SeriesLineThickness = ['arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'MMID', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'Points_Magnitude', '2']
plotOverLine1_1Display_2.SeriesMarkerStyle = ['arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'MMID', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'Points_Magnitude', '0']
plotOverLine1_1Display_2.SeriesMarkerSize = ['arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'MMID', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'Points_Magnitude', '4']

# Properties modified on plotOverLine1_1Display_2
plotOverLine1_1Display_2.SeriesOpacity = ['arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'MMID', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'Points_Magnitude', '1']
plotOverLine1_1Display_2.SeriesPlotCorner = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1_1Display_2.SeriesLineStyle = ['MMID', '1', 'Points_Magnitude', '1', 'Points_X', '1', 'Points_Y', '1', 'Points_Z', '1', 'arc_length', '1', 'doublelevel', '1', 'dx', '1', 'level', '1', 'velocitymag', '1', 'velocitymagavg', '1', 'velocityx', '1', 'velocityxavg', '1', 'vtkValidPointMask', '1']
plotOverLine1_1Display_2.SeriesLineThickness = ['MMID', '2', 'Points_Magnitude', '2', 'Points_X', '2', 'Points_Y', '2', 'Points_Z', '2', 'arc_length', '2', 'doublelevel', '2', 'dx', '2', 'level', '2', 'velocitymag', '2', 'velocitymagavg', '2', 'velocityx', '2', 'velocityxavg', '2', 'vtkValidPointMask', '2']
plotOverLine1_1Display_2.SeriesMarkerStyle = ['MMID', '0', 'Points_Magnitude', '0', 'Points_X', '0', 'Points_Y', '0', 'Points_Z', '0', 'arc_length', '0', 'doublelevel', '0', 'dx', '0', 'level', '0', 'velocitymag', '0', 'velocitymagavg', '0', 'velocityx', '0', 'velocityxavg', '0', 'vtkValidPointMask', '0']
plotOverLine1_1Display_2.SeriesMarkerSize = ['MMID', '4', 'Points_Magnitude', '4', 'Points_X', '4', 'Points_Y', '4', 'Points_Z', '4', 'arc_length', '4', 'doublelevel', '4', 'dx', '4', 'level', '4', 'velocitymag', '4', 'velocitymagavg', '4', 'velocityx', '4', 'velocityxavg', '4', 'vtkValidPointMask', '4']

# hide data in view
Hide(plotOverLine1_1, lineChartView2)

# hide data in view
Hide(plotOverLine1, lineChartView2)

# show data in view
plotOverLine1_1Display_2 = Show(plotOverLine1_1, lineChartView2, 'XYChartRepresentation')

# hide data in view
Hide(plotOverLine1_1, lineChartView2)

# set active view
SetActiveView(spreadSheetView1)

# export view
ExportView('/home/bollerma/LESdata/SSWT/fullCav/meshStudy/test5/test5M2SSWT_001/sampleProbeLinex0p17.csv', view=spreadSheetView1)

SelectIDs(IDs=[-1, 488], FieldType=1, ContainingCells=0)

# clear all selections
ClearSelection()

SelectIDs(IDs=[-1, 494], FieldType=1, ContainingCells=0)

#================================================================
# addendum: following script captures some of the application
# state to faithfully reproduce the visualization during playback
#================================================================

#--------------------------------
# saving layout sizes for layouts

# layout/tab size in pixels
layout2.SetSize(400, 400)

# layout/tab size in pixels
layout1.SetSize(1475, 536)

#-----------------------------------
# saving camera placements for views

# current camera placement for renderView1
renderView1.CameraPosition = [1.2745, 0.24049126503122772, 1.6007289552516422]
renderView1.CameraFocalPoint = [1.2745, 0.24049126503122772, 0.003999999999999965]
renderView1.CameraParallelScale = 1.296999036237113


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