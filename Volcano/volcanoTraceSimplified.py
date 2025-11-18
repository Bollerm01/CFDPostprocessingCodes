from paraview.simple import *
#### disable automatic camera reset on 'Show'
paraview.simple._DisableFirstRenderCameraReset()

#### READS IN THE VOLCANO FILE ####
# reads the volcano file
volcanoPath = '/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/latest.volcano'
latestvolcano = FileSeriesReader(registrationName='latest.volcano', FileNames=[volcanoPath])

#### PULLS IN THE CELL ARRAYS ####
# pulls the cell values 
latestvolcano.CellArrayStatus = ['reynoldsstressxx', 'reynoldsstressyy', 'reynoldsstresszz']

#### CREATES AND DISPLAYS SLICE ####
# create a new 'Volcano Slice'
volcanoSlice1 = VolcanoSlice(registrationName='VolcanoSlice1', Input=latestvolcano)

# Gets rid of crinkle on volcanoSlice1
volcanoSlice1.MinMaxField = 'reynoldsstressxx'
volcanoSlice1.Crinkle = 0
volcanoSlice1.InterpolatedField = 'reynoldsstressxx'

# get active view
renderView1 = GetActiveViewOrCreate('RenderView')
renderView1.Update()
# reset view to fit data
renderView1.ResetCamera(False, 0.9)

# show data in view
volcanoSlice1Display = Show(volcanoSlice1, renderView1, 'UnstructuredGridRepresentation')

# trace defaults for the display properties.
volcanoSlice1Display.Representation = 'Surface'

# set scalar coloring
ColorBy(volcanoSlice1Display, ('POINTS', 'reynoldsstressxx'))

#### EXTRACTS POINTS ALONG LINE [x1,y1,z1] -> [x2,y2,z2] ####
extractCellsAlongLine1 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1)

extractCellsAlongLine1.Point1 = [-0.18222, 0.06, -0.03810000000000013]
extractCellsAlongLine1.Point2 = [-0.18222, 0.02, -0.03809999999999994]


# Create a new 'SpreadSheet View'
spreadSheetView1 = CreateView('SpreadSheetView')
spreadSheetView1.ColumnToSort = ''
spreadSheetView1.BlockSize = 1024

# update the view to ensure updated data information
spreadSheetView1.Update()

#### EXPORTING CELLS ALONG LINE DATA ####

# create a new 'Extract Cells Along Line'
extractCellsAlongLine1_4 = ExtractCellsAlongLine(registrationName='ExtractCellsAlongLine1', Input=volcanoSlice1_1)

# get display properties
extractCellsAlongLine1_4Display = GetDisplayProperties(extractCellsAlongLine1_4, view=renderView1)

# set active source
SetActiveSource(extractCellsAlongLine1_4)

# rename source object (not needed if properly named)
RenameSource('yyUS', extractCellsAlongLine1_4)

# show data in view
extractCellsAlongLine1_4Display_1 = Show(extractCellsAlongLine1_4, spreadSheetView1, 'SpreadSheetRepresentation')

# export view
ExportView('/home/bollerma/LESdata/fullCD_RCM2Domain/cleanCav/test21/test21_000/uvxData/US/yyUS.csv', view=spreadSheetView1)

#### ADDITIONAL MISC FUNCTIONS ####

# Setting camera for views 
# current camera placement for renderView1
renderView1.CameraPosition = [-0.2937593749999998, 0.03526799999999993, 0.8951381476653495]
renderView1.CameraFocalPoint = [-0.2937593749999998, 0.03526799999999993, -0.03810000000000004]
renderView1.CameraParallelScale = 0.7580553819861734