# CFDPostprocessingCodes
Postprocessing codes for various CFD platforms for Boller M.S. work

## Folders
- Archive: Various codes for processing (AVIATION abstract codes, figure generators, and various traces from Paraview)
- AVIATIONprocessing: Codes and figures from the Boller et. al. AVIATION 2026 work incl. shear layer thickness and validation across Volcano and VULCAN file formats
- DataProcessing: Misc. codes for one-off processing jobs
- PressureDataVolcano: FFT and other pressure and frequency processing codes for examination of shear layer modes in Volcano data. Includes both CFD and experimental codes for SSWT Scanivalve and Kulite cavity measurements. "Crossplotters" contains codes for plotting different combinations of CFD/experimental Kulite measurements
- TimeMeshSensitivityCodes: Codes used by all the geometries to sort and process output
- TimeMeshSensitivityVolcanoHPWT: Codes used to perform the time & mesh sensitivity processing specific to the coordinates and geometery of the UC HPWT in Volcano ScaLES
    - SetupHPWT: Folder that contains .step surface and volume files and a .yaml simulation file for example usage for the HPWT cavity
- TimeMeshSensitivityVolcanoRC19: Codes used to perform the time & mesh sensitivity processing specific to the coordinates and geometery of the Mach 2 AFRL RC-19 cavity in Volcano ScaLES
    - SetupRC19: Folder that contains .step surface and volume files and a .yaml simulation file for example usage for the RC19 cavity
- TimeMeshSensitivityVolcanoSSWT: Codes used to perform the time & mesh sensitivity processing specific to the coordinates and geometery of the UC Aerolab SSWT in Volcano ScaLES
    - SetupSSWT: Folder that contains .step surface and volume files and a .yaml simulation file for example usage for the SSWT cavity insert
- TunnelDataProcessing: Contains all traverse SSWT boundary layer data with processing codes for crossplotting data and viewing tunnel steady state conditions
- Volcano: Used for extracting data, condensing output Excel files, and generating figures specific to the 'volparaview' interface in Paraview (See embedded README)
- VULCAN: Used for extracting data, condensing output Excel files, and generating figures specific to .plt files in Paraview (See embedded README)


