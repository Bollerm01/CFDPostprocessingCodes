#!/usr/bin/env pvpython

## Extracts the cavity ramp surface data from the latest.volcano file for a given run
from paraview.simple import *

# ============================================================
# USER INPUTS
# ============================================================
rootDir = "/home/bollerma/LESdata/SSWT/fullCav/RDsteps/RD09/RD09_001" # RD09 case

input_file = f"{rootDir}/latest.volcano"

output_csv = f"{rootDir}/cavRampSurfacePressureData.csv"

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
surface.SlicePoint = [2.216868, 0.009481, 0.0] # Intersects first cell of cav ramp @ the midpoint of the ramp plane
surface.SliceNormal = [-0.382683, 0.923880, 0.0] # normal to the 22.5 deg ramp pointing US
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