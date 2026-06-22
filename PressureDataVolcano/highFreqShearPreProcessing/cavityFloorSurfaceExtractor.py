#!/usr/bin/env pvpython

## Extracts the cavity floor surface data from the latest.volcano file for a given run
from paraview.simple import *

# ============================================================
# USER INPUTS
# ============================================================

input_file = "/home/bollerma/LESdata/SSWT/fullCav/revisedMeshStudy/test1m/test1mSSWTM2_002/latest.volcano"

output_csv = "/home/bollerma/LESdata/SSWT/fullCav/revisedMeshStudy/test1m/test1mSSWTM2_002/cavFloorSurfacePressureData.csv"

# ============================================================
# READ VOLCANO FILE
# ============================================================

volcano = FileSeriesReader(
    registrationName='volcano',
    FileNames=[input_file]
)


# Only load pressureavg
volcano.CellArrayStatus = ['pressureavg']

# ------------------------------------------------------------------
# Extract surface
# ------------------------------------------------------------------
surface = VolcanoSlice(
    registrationName='SurfaceData',
    Input=volcano
)

surface.MinMaxField = 'pressureavg'
surface.InterpolatedField = 'pressureavg'
surface.Crinkle = 0

# Force pipeline update
UpdatePipeline()

# ============================================================
# CREATE SPREADSHEET VIEW
# ============================================================

spreadsheet = CreateView('SpreadSheetView')

Show(surface, spreadsheet)

# ============================================================
# EXPORT CSV
# ============================================================

ExportView(output_csv, view=spreadsheet)

print(f"Export complete: {output_csv}")