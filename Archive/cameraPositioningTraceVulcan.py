# trace generated using paraview version 6.0.0
#import paraview
#paraview.compatibility.major = 6
#paraview.compatibility.minor = 0

#### import the simple module from the paraview
from paraview.simple import *
#### disable automatic camera reset on 'Show'
paraview.simple._DisableFirstRenderCameraReset()

# create a new 'VisIt Tecplot Binary Reader'
vulcan_solutionplt = VisItTecplotBinaryReader(registrationName='vulcan_solution.plt', FileName=['E:\\Boller CFD\\VULCAN Data\\SSWT\\CAVmix_SSWT_r0_noinject\\iteration-009\\Plot_files\\vulcan_solution.plt'])
vulcan_solutionplt.Set(
    MeshStatus=['zone1'],
    PointArrayStatus=[],
)

# get animation scene
animationScene1 = GetAnimationScene()

# update animation scene based on data timesteps
animationScene1.UpdateAnimationUsingDataTimeSteps()

# Properties modified on vulcan_solutionplt
vulcan_solutionplt.Set(
    MeshStatus=['zone1', 'zone2'],
    PointArrayStatus=['Mach_Number', 'Pressure_Pa', 'Temperature_K'],
)

# get active view
renderView1 = GetActiveViewOrCreate('RenderView')

# show data in view
vulcan_solutionpltDisplay = Show(vulcan_solutionplt, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
vulcan_solutionpltDisplay.Set(
    Representation='Surface',
    ColorArrayName=[None, ''],
    OSPRayScaleArray='Mach_Number',
    Assembly='Hierarchy',
    ScaleFactor=0.08953499794006348,
    SelectScaleArray='Mach_Number',
    GlyphTableIndexArray='Mach_Number',
    GaussianRadius=0.004476749897003174,
    SetScaleArray=['POINTS', 'Mach_Number'],
    OpacityArray=['POINTS', 'Mach_Number'],
    ScalarOpacityUnitDistance=0.003820739888097924,
    OpacityArrayName=['POINTS', 'Mach_Number'],
    SelectInputVectors=[None, ''],
)

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
vulcan_solutionpltDisplay.ScaleTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.2067766189575195, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
vulcan_solutionpltDisplay.OpacityTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.2067766189575195, 1.0, 0.5, 0.0]

# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# get the material library
materialLibrary1 = GetMaterialLibrary()

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(vulcan_solutionpltDisplay, ('FIELD', 'vtkBlockColors'))

# show color bar/color legend
vulcan_solutionpltDisplay.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'vtkBlockColors'
vtkBlockColorsLUT = GetColorTransferFunction('vtkBlockColors')
vtkBlockColorsLUT.Set(
    InterpretValuesAsCategories=1,
    AnnotationsInitialized=1,
    Annotations=['0', '0', '1', '1', '2', '2', '3', '3', '4', '4', '5', '5', '6', '6', '7', '7', '8', '8', '9', '9', '10', '10', '11', '11'],
    ActiveAnnotatedValues=['0', '1', '2', '3', '4', '5'],
    IndexedColors=[1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.63, 0.63, 1.0, 0.67, 0.5, 0.33, 1.0, 0.5, 0.75, 0.53, 0.35, 0.7, 1.0, 0.75, 0.5],
)

# get opacity transfer function/opacity map for 'vtkBlockColors'
vtkBlockColorsPWF = GetOpacityTransferFunction('vtkBlockColors')

# get 2D transfer function for 'vtkBlockColors'
vtkBlockColorsTF2D = GetTransferFunction2D('vtkBlockColors')

# create a new 'Slice'
slice1 = Slice(registrationName='Slice1', Input=vulcan_solutionplt)
slice1.SliceOffsetValues = [0.0]

# init the 'Plane' selected for 'SliceType'
slice1.SliceType.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# init the 'Plane' selected for 'HyperTreeGridSlicer'
slice1.HyperTreeGridSlicer.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# Properties modified on slice1.SliceType
slice1.SliceType.Origin = [0.5, 0.0, 0.0]

# show data in view
slice1Display = Show(slice1, renderView1, 'GeometryRepresentation')

# trace defaults for the display properties.
slice1Display.Set(
    Representation='Surface',
    ColorArrayName=[None, ''],
    OSPRayScaleArray='Mach_Number',
    Assembly='Hierarchy',
    ScaleFactor=0.017570471204817296,
    SelectScaleArray='Mach_Number',
    GlyphTableIndexArray='Mach_Number',
    GaussianRadius=0.0008785235602408647,
    SetScaleArray=['POINTS', 'Mach_Number'],
    OpacityArray=['POINTS', 'Mach_Number'],
    SelectInputVectors=[None, ''],
)

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
slice1Display.ScaleTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.1086997985839844, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
slice1Display.OpacityTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.1086997985839844, 1.0, 0.5, 0.0]

# hide data in view
Hide(vulcan_solutionplt, renderView1)

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(slice1Display, ('FIELD', 'vtkBlockColors'))

# show color bar/color legend
slice1Display.SetScalarBarVisibility(renderView1, True)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=slice1.SliceType)

# change representation type
slice1Display.SetRepresentationType('Surface LIC')

# set scalar coloring
ColorBy(slice1Display, ('POINTS', 'Mach_Number'))

# Hide the scalar bar for this color map if no visible data is colored by it.
HideScalarBarIfNotNeeded(vtkBlockColorsLUT, renderView1)

# rescale color and/or opacity maps used to include current data range
slice1Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
slice1Display.SetScalarBarVisibility(renderView1, True)

# get color transfer function/color map for 'Mach_Number'
mach_NumberLUT = GetColorTransferFunction('Mach_Number')
mach_NumberLUT.Set(
    RGBPoints=GenerateRGBPoints(
        range_min=0.0,
        range_max=2.110368490219116,
    ),
    ScalarRangeInitialized=1.0,
)

# get opacity transfer function/opacity map for 'Mach_Number'
mach_NumberPWF = GetOpacityTransferFunction('Mach_Number')
mach_NumberPWF.Set(
    Points=[0.0, 0.0, 0.5, 0.0, 2.110368490219116, 1.0, 0.5, 0.0],
    ScalarRangeInitialized=1,
)

# get 2D transfer function for 'Mach_Number'
mach_NumberTF2D = GetTransferFunction2D('Mach_Number')

# change representation type
slice1Display.SetRepresentationType('Surface')

# get color legend/bar for mach_NumberLUT in view renderView1
mach_NumberLUTColorBar = GetScalarBar(mach_NumberLUT, renderView1)
mach_NumberLUTColorBar.Set(
    Title='Mach_Number',
    ComponentTitle='',
)

# change scalar bar placement
mach_NumberLUTColorBar.Set(
    WindowLocation='Any Location',
    Position=[0.6675919500346981, 0.35205992509363293],
    ScalarBarLength=0.33000000000000007,
)

# change scalar bar placement
mach_NumberLUTColorBar.Position = [0.6419153365718251, 0.35205992509363293]

# create new layout object 'Layout #2'
layout2 = CreateLayout(name='Layout #2')

# set active view
SetActiveView(None)

# Create a new 'Render View'
renderView2 = CreateView('RenderView')
renderView2.Set(
    StereoType='Crystal Eyes',
    CameraFocalDisk=1.0,
    BackEnd='OSPRay raycaster',
    OSPRayMaterialLibrary=materialLibrary1,
)

# assign view to a particular cell in the layout
AssignViewToLayout(view=renderView2, layout=layout2, hint=0)

# set active source
SetActiveSource(vulcan_solutionplt)

# set active source
SetActiveSource(slice1)

# set active source
SetActiveSource(vulcan_solutionplt)

# create a new 'Slice'
slice2 = Slice(registrationName='Slice2', Input=vulcan_solutionplt)
slice2.SliceOffsetValues = [0.0]

# init the 'Plane' selected for 'SliceType'
slice2.SliceType.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# init the 'Plane' selected for 'HyperTreeGridSlicer'
slice2.HyperTreeGridSlicer.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# set active source
SetActiveSource(slice2)

# show data in view
slice2Display = Show(slice2, renderView2, 'GeometryRepresentation')

# trace defaults for the display properties.
slice2Display.Set(
    Representation='Surface',
    ColorArrayName=[None, ''],
    OSPRayScaleArray='Mach_Number',
    Assembly='Hierarchy',
    ScaleFactor=0.015503384824842216,
    SelectScaleArray='Mach_Number',
    GlyphTableIndexArray='Mach_Number',
    GaussianRadius=0.0007751692412421107,
    SetScaleArray=['POINTS', 'Mach_Number'],
    OpacityArray=['POINTS', 'Mach_Number'],
    SelectInputVectors=[None, ''],
)

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
slice2Display.ScaleTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.085301637649536, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
slice2Display.OpacityTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.085301637649536, 1.0, 0.5, 0.0]

#changing interaction mode based on data extents
renderView2.Set(
    InteractionMode='2D',
    CameraPosition=[0.9670383813325316, 0.0748830777592957, 0.01269999984651804],
    CameraFocalPoint=[0.4476749897003174, 0.0748830777592957, 0.01269999984651804],
    CameraViewUp=[0.0, 0.0, 1.0],
)

# reset view to fit data
renderView2.ResetCamera(False, 0.9)

renderView2.ResetActiveCameraToNegativeZ()

# reset view to fit data
renderView2.ResetCamera(False, 0.9)

# Properties modified on slice2.SliceType
slice2.SliceType.Set(
    Origin=[0.5, 0.0, 0.0],
    Normal=[0.0, 0.0, 1.0],
)

# show data in view
slice2Display = Show(slice2, renderView2, 'GeometryRepresentation')

# reset view to fit data
renderView2.ResetCamera(False, 0.9)

#changing interaction mode based on data extents
renderView2.InteractionMode = '3D'

# update the view to ensure updated data information
renderView1.Update()

# update the view to ensure updated data information
renderView2.Update()

# Properties modified on slice2.SliceType
slice2.SliceType.Origin = [0.5, 0.0, 0.0127]

# update the view to ensure updated data information
renderView2.Update()

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=slice2.SliceType)

# set scalar coloring
ColorBy(slice2Display, ('POINTS', 'Mach_Number'))

# rescale color and/or opacity maps used to include current data range
slice2Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
slice2Display.SetScalarBarVisibility(renderView2, True)

# get color legend/bar for mach_NumberLUT in view renderView2
mach_NumberLUTColorBar_1 = GetScalarBar(mach_NumberLUT, renderView2)
mach_NumberLUTColorBar_1.Set(
    Title='Mach_Number',
    ComponentTitle='',
)

# change scalar bar placement
mach_NumberLUTColorBar_1.Set(
    Orientation='Horizontal',
    WindowLocation='Any Location',
    Position=[0.3329077029840388, 0.0898876404494382],
    ScalarBarLength=0.32999999999999985,
)

# set active view
SetActiveView(renderView1)

# set active view
SetActiveView(renderView2)

# create new layout object 'Layout #3'
layout3 = CreateLayout(name='Layout #3')

# set active view
SetActiveView(None)

# Create a new 'Render View'
renderView3 = CreateView('RenderView')
renderView3.Set(
    StereoType='Crystal Eyes',
    CameraFocalDisk=1.0,
    BackEnd='OSPRay raycaster',
    OSPRayMaterialLibrary=materialLibrary1,
)

# assign view to a particular cell in the layout
AssignViewToLayout(view=renderView3, layout=layout3, hint=0)

# set active source
SetActiveSource(vulcan_solutionplt)

# set active source
SetActiveSource(slice2)

# set active source
SetActiveSource(vulcan_solutionplt)

# create a new 'Slice'
slice3 = Slice(registrationName='Slice3', Input=vulcan_solutionplt)
slice3.SliceOffsetValues = [0.0]

# init the 'Plane' selected for 'SliceType'
slice3.SliceType.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# init the 'Plane' selected for 'HyperTreeGridSlicer'
slice3.HyperTreeGridSlicer.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# get display properties
slice3Display = GetRepresentation(slice3, view=renderView3)

# hide data in view
Hide(slice3, renderView3)

# set active source
SetActiveSource(slice3)

# show data in view
slice3Display = Show(slice3, renderView3, 'GeometryRepresentation')

#changing interaction mode based on data extents
renderView3.Set(
    InteractionMode='2D',
    CameraPosition=[0.4476749897003174, 0.06435919553041458, 3.0121224308386445],
    CameraFocalPoint=[0.4476749897003174, 0.06435919553041458, 0.01269999984651804],
)

# reset view to fit data
renderView3.ResetCamera(False, 0.9)

# toggle interactive widget visibility (only when running from the GUI)
HideInteractiveWidgets(proxy=slice3.SliceType)

# set scalar coloring
ColorBy(slice3Display, ('POINTS', 'Pressure_Pa'))

# rescale color and/or opacity maps used to include current data range
slice3Display.RescaleTransferFunctionToDataRange(True, False)

# show color bar/color legend
slice3Display.SetScalarBarVisibility(renderView3, True)

# get color transfer function/color map for 'Pressure_Pa'
pressure_PaLUT = GetColorTransferFunction('Pressure_Pa')
pressure_PaLUT.Set(
    RGBPoints=GenerateRGBPoints(
        range_min=13327.0947265625,
        range_max=32431.7421875,
    ),
    ScalarRangeInitialized=1.0,
)

# get opacity transfer function/opacity map for 'Pressure_Pa'
pressure_PaPWF = GetOpacityTransferFunction('Pressure_Pa')
pressure_PaPWF.Set(
    Points=[13327.0947265625, 0.0, 0.5, 0.0, 32431.7421875, 1.0, 0.5, 0.0],
    ScalarRangeInitialized=1,
)

# get 2D transfer function for 'Pressure_Pa'
pressure_PaTF2D = GetTransferFunction2D('Pressure_Pa')

renderView3.ResetActiveCameraToNegativeZ()

# reset view to fit data
renderView3.ResetCamera(False, 0.9)

#change interaction mode for render view
renderView3.InteractionMode = '3D'

# get color legend/bar for pressure_PaLUT in view renderView3
pressure_PaLUTColorBar = GetScalarBar(pressure_PaLUT, renderView3)
pressure_PaLUTColorBar.Set(
    Title='Pressure_Pa',
    ComponentTitle='',
)

# change scalar bar placement
pressure_PaLUTColorBar.Set(
    Orientation='Horizontal',
    WindowLocation='Any Location',
    Position=[0.31070090215128393, 0.07490636704119849],
    ScalarBarLength=0.32999999999999946,
)

#================================================================
# addendum: following script captures some of the application
# state to faithfully reproduce the visualization during playback
#================================================================

# get layout
layout1 = GetLayoutByName("Layout #1")

#--------------------------------
# saving layout sizes for layouts

# layout/tab size in pixels
layout1.SetSize(1441, 534)

# layout/tab size in pixels
layout3.SetSize(1441, 534)

# layout/tab size in pixels
layout2.SetSize(1441, 534)

#-----------------------------------
# saving camera placements for views

# current camera placement for renderView1
renderView1.Set(
    CameraPosition=[0.9120590004774782, 0.06435919553041458, 0.01269999984651804],
    CameraFocalPoint=[0.4476749897003174, 0.06435919553041458, 0.01269999984651804],
    CameraParallelScale=0.4564267410905977,
)

# current camera placement for renderView2
renderView2.Set(
    CameraPosition=[0.4476749897003174, 0.06435919553041458, 0.8285855560611272],
    CameraFocalPoint=[0.4476749897003174, 0.06435919553041458, 0.01269999984651804],
    CameraParallelScale=0.5477120893087172,
)

# current camera placement for renderView3
renderView3.Set(
    CameraPosition=[0.5052304592990174, -0.007906881310699177, 0.16060976619697473],
    CameraFocalPoint=[0.5052304592990174, -0.007906881310699177, 0.01269999984651804],
    CameraParallelScale=0.4562500191632675,
)


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