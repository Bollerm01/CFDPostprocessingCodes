# trace generated using paraview version 6.0.0
#import paraview
#paraview.compatibility.major = 6
#paraview.compatibility.minor = 0

#### import the simple module from the paraview
from paraview.simple import *
#### disable automatic camera reset on 'Show'
paraview.simple._DisableFirstRenderCameraReset()

# create a new 'VisIt Tecplot Binary Reader'
vulcan_solutionplt = VisItTecplotBinaryReader(registrationName='vulcan_solution.plt', FileName=['D:\\BollerCFD\\Paper CFD\\AVIATION CFD\\CAVmix_SSWT_r1_noinject\\vulcan_solution.plt'])
vulcan_solutionplt.Set(
    MeshStatus=['zone1'],
    PointArrayStatus=[],
)

# get animation scene
animationScene1 = GetAnimationScene()

# update animation scene based on data timesteps
animationScene1.UpdateAnimationUsingDataTimeSteps()

# Properties modified on vulcan_solutionplt
vulcan_solutionplt.PointArrayStatus = ['Mach_Number', 'Pressure_Pa', 'Viscosity_Pa*s', 'greekt_greeksubxx_subsupt_sup', 'greekt_greeksubxy_subsupt_sup', 'greekt_greeksubxz_subsupt_sup', 'greekt_greeksubyy_subsupt_sup', 'greekt_greeksubyz_subsupt_sup', 'greekt_greeksubzz_subsupt_sup']

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
    ScalarOpacityUnitDistance=0.010718092594214327,
    OpacityArrayName=['POINTS', 'Mach_Number'],
    SelectInputVectors=[None, ''],
)

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
vulcan_solutionpltDisplay.ScaleTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.226088523864746, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
vulcan_solutionpltDisplay.OpacityTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.226088523864746, 1.0, 0.5, 0.0]

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
    ActiveAnnotatedValues=['0', '1', '2', '3', '4'],
    IndexedColors=[1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.63, 0.63, 1.0, 0.67, 0.5, 0.33, 1.0, 0.5, 0.75, 0.53, 0.35, 0.7, 1.0, 0.75, 0.5],
)

# get opacity transfer function/opacity map for 'vtkBlockColors'
vtkBlockColorsPWF = GetOpacityTransferFunction('vtkBlockColors')

# get 2D transfer function for 'vtkBlockColors'
vtkBlockColorsTF2D = GetTransferFunction2D('vtkBlockColors')

# Properties modified on vulcan_solutionplt
vulcan_solutionplt.MeshStatus = ['zone1', 'zone2']

# update the view to ensure updated data information
renderView1.Update()

# create a new 'Slice'
slice1 = Slice(registrationName='Slice1', Input=vulcan_solutionplt)
slice1.SliceOffsetValues = [0.0]

# init the 'Plane' selected for 'SliceType'
slice1.SliceType.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# init the 'Plane' selected for 'HyperTreeGridSlicer'
slice1.HyperTreeGridSlicer.Origin = [0.4476749897003174, 0.06435919553041458, 0.01269999984651804]

# Properties modified on slice1.SliceType
slice1.SliceType.Origin = [0.7, 0.064364216109278, 0.01269999984651804]

# show data in view
slice1Display = Show(slice1, renderView1, 'GeometryRepresentation')

# trace defaults for the display properties.
slice1Display.Set(
    Representation='Surface',
    ColorArrayName=[None, ''],
    OSPRayScaleArray='Mach_Number',
    Assembly='Hierarchy',
    ScaleFactor=0.01660505970939994,
    SelectScaleArray='Mach_Number',
    GlyphTableIndexArray='Mach_Number',
    GaussianRadius=0.0008302529854699969,
    SetScaleArray=['POINTS', 'Mach_Number'],
    OpacityArray=['POINTS', 'Mach_Number'],
    SelectInputVectors=[None, ''],
)

# init the 'Piecewise Function' selected for 'ScaleTransferFunction'
slice1Display.ScaleTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.164905071258545, 1.0, 0.5, 0.0]

# init the 'Piecewise Function' selected for 'OpacityTransferFunction'
slice1Display.OpacityTransferFunction.Points = [0.0, 0.0, 0.5, 0.0, 2.164905071258545, 1.0, 0.5, 0.0]

# hide data in view
Hide(vulcan_solutionplt, renderView1)

# update the view to ensure updated data information
renderView1.Update()

# set scalar coloring
ColorBy(slice1Display, ('FIELD', 'vtkBlockColors'))

# show color bar/color legend
slice1Display.SetScalarBarVisibility(renderView1, True)

#================================================================
# addendum: following script captures some of the application
# state to faithfully reproduce the visualization during playback
#================================================================

# get layout
layout1 = GetLayout()

#--------------------------------
# saving layout sizes for layouts

# layout/tab size in pixels
layout1.SetSize(1423, 516)

#-----------------------------------
# saving camera placements for views

# current camera placement for renderView1
renderView1.Set(
    CameraPosition=[0.4476749897003174, 0.06435919553041458, 1.7761975079599672],
    CameraFocalPoint=[0.4476749897003174, 0.06435919553041458, 0.01269999984651804],
    CameraParallelScale=0.4564267410905977,
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