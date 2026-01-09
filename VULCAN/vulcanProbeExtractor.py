# Template file for the purpose of extracting lines from the VULCAN .plt files
# Output: Format of "XXXDdataCombined.xlsx" from dataCombiner_fullRunV2.py
# Input: VULCAN .plt file

## TEMPLATE CODE - NEED TO CHANGE ##
from paraview.simple import *
import os
import numpy as np
import csv
import pandas as pd

# ---------------- USER SETTINGS ----------------
INPUT_ROOT = r"E:\Boller CFD\VULCAN Data\SSWT"
CASE = "CAVmix_SSWT_r0p5_noinject"
INPUT_FILE = rf"{INPUT_ROOT}\{CASE}\iteration-009\Plot_files\vulcan_solution.plt"

OUTPUT_ROOT = r"E:\Boller CFD\AVIATION CFD\output\VulcanProcessingOutput\probeData"
OUTPUT_DIR = os.path.join(OUTPUT_ROOT, CASE)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Variables to load from the VULCAN file ---
POINT_ARRAYS = ['U_velocity_m_s', 
                'V_velocity_m_s', 
                'W_velocity_m_s', 
                'X', 
                'Y', 
                'Z', 
                'zone2/U_velocity_m_s', 
                'zone2/V_velocity_m_s', 
                'zone2/W_velocity_m_s', 
                'zone2/X', 
                'zone2/Y', 
                'zone2/Z']

# --- Z-plane slice location ---
SLICE_Z = 0.0

# --- Line resolution ---
LINE_RESOLUTION = 500

# --- Probe line definitions ---
# label : {start:[x,y,z], end:[x,y,z]}
PROBE_LINES = {
    "xL_neg2": {
        "start": [0.327131, 0.0, 0.0127],
        "end":   [0.327131, 0.037186, 0.0127],
    },
    "xL_neg1": {
        "start": [0.395304, -0.00035, 0.0127],
        "end":   [0.395304, 0.036839, 0.0127],
    },
    "xL_neg0p5": {
        "start": [0.429391, -0.00184, 0.0127],
        "end":   [0.429391, 0.03535, 0.0127],
    },
    "xL_0p03": {
        "start": [0.465522, -0.0218, 0.0127],
        "end":   [0.465522, 0.015387, 0.0127],
    },
    "xL_0p17": {
        "start": [0.475066, -0.02222, 0.0127],
        "end":   [0.475066, 0.01497, 0.0127],
    },
    "xL_0p3": {
        "start": [0.483929, -0.0226, 0.0127],
        "end":   [0.483929, 0.014583, 0.0127],
    },
    "xL_0p45": {
        "start": [0.494155, -0.02305, 0.0127],
        "end":   [0.494155, 0.014136, 0.0127],
    },
    "xL_0p59": {
        "start": [0.503699, -0.02347, 0.0127],
        "end":   [0.503699, 0.01372, 0.0127],
    },
    "xL_0p73": {
        "start": [0.513243, -0.022, 0.0127],
        "end":   [0.513243, 0.015182, 0.0127],
    },
    "xL_0p86": {
        "start": [0.522106, -0.01878, 0.0127],
        "end":   [0.522106, 0.018408, 0.0127],
    },
    "xL_1": {
        "start": [0.53165, -0.0153, 0.0127],
        "end":   [0.53165, 0.021882, 0.0127],
    },
    "xL_2": {
        "start": [0.622184, -0.01025, 0.0127],
        "end":   [0.622184, 0.026933, 0.0127],
    }
}




# Zones to include
#ACTIVE_ZONES = ["zone1", "zone2"]
ACTIVE_ZONES = ["zone2"]

# ---------------- LOAD Tecplot ----------------
reader = VisItTecplotBinaryReader(
    registrationName='RC19_full_width_domain.plt',
    FileName=[INPUT_FILE]
)
reader.Set(
    MeshStatus=ACTIVE_ZONES,
    PointArrayStatus=POINT_ARRAYS
)
reader.UpdatePipeline()

# ---------------- CALCULATES THE VELOCITY MAG --------------
velocityVect = Calculator(registrationName='Velocity_Vect', Input=reader)
velocityVect.Function = '"zone2/U_velocity_m_s"*iHat + "zone2/V_velocity_m_s"*jHat +"zone2/W_velocity_m_s"*kHat'
velocityVect.ResultArrayName = "Velocity_Vect"
velocityVect.UpdatePipeline()

velocityMag = Calculator(registrationName='Velocity_Mag', Input=velocityVect)
velocityMag.Function = 'mag(Velocity_Vect)'
velocityMag.ResultArrayName = "Velocity_Mag_m_s"
velocityMag.UpdatePipeline()

# ---------------- PULLS THE EXPORTED DATA ------------------
pa = PassArrays(registrationName='ExportData', Input=velocityMag)
pa.PointDataArrays = ['Velocity_Mag_m_s', 'Velocity_Vect', 'zone2/X', 'zone2/Y', 'zone2/Z']
pa.UpdatePipeline()

# ---------------- FUNCTION: LINE EXTRACTION ----------------
def extract_line_filtered(input_proxy, line_def, label):
    """
    Extracts line data along Y at fixed X,Z and removes rows
    where both zones have NaN for all Reynolds stresses and TKE.
    """
    pol = PlotOverLine(Input=input_proxy)
    pol.Point1 = line_def["start"]
    pol.Point2 = line_def["end"]
    pol.Resolution = LINE_RESOLUTION
    RenameSource(label, pol)

    pol.UpdatePipeline()

    output_file = os.path.join(
        OUTPUT_DIR, f"{label}.csv"
    )

    #Export to Excel
    SaveData(
        output_file,
        proxy=pol,
        Precision=6
    )

    #Delete(pol)

# ---------------- GENERATE CLEAN LINE PROFILES ----------------
for label, line_def in PROBE_LINES.items():
    extract_line_filtered(pa, line_def, label)

print(f"\nClean velocity profiles extracted successfully.")
print(f"   Zones used: {ACTIVE_ZONES}")
print(f"   Variables: {pa.PointDataArrays}")
print(f"   Output directory: {OUTPUT_DIR}")
