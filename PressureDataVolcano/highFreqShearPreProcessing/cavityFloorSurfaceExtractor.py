#!/usr/bin/env pvpython

## Extracts the cavity floor surface data from the latest.volcano file for a given run
from paraview.simple import *

# ============================================================
# USER INPUTS
# ============================================================
rootDir = "/home/bollerma/LESdata/SSWT/fullCav/revisedMeshStudy/test3m/test3mSSWTM2_002"

input_file = f"{rootDir}/latest.volcano"

output_csv = f"{rootDir}/cavFloorSurfacePressureData.csv"

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
surface.SlicePoint = [0.0, 0.0002, 0.0] # Intersects first cell of cav floor
surface.SliceNormal = [0, 1, 0]
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