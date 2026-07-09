Workflow of Volcano ScaLES postprocessing for SSWT
See "VolcanoSlicingCoords.xlsx" for slicing coordinates in the domain
1) Generate screenshot slices of mid- and crossplanes using "volcanoShearProcessorV3.py" (run on Linux)
2) If necessary: Use "volcanoProbeExtractor.py" to extract cavity line probe data as .CSV's from a Volcano File (run on Linux)
3) Sort raw data using "volcanoProbeCondenser.py" using folder of raw .csv's on Windows machine
4) Generate shear layer thickness final data and figures using "volcanoVelocityThresholder.py" on Windows machine
5) Cross plot the final data across cases using "AVIATIONprocessing/volcano_shear_thickness_processor_RDsweep_X" codes 
    (full and slice domain codes, see AVIATIONprocessing README for more details)
6) Process temporal pressure probe data using "FFT_PSD.m" (See "PressureDataVolcano" folder)
7) Process Kulite data using "X_KuliteFFTPlotter.m" (See "PressureDataVolcano" folder)
8) Run axial and vertical 50kHz FFTs using "highFreqLocPlotter" folder codes
9) Generate flow viz plane movie from in-situ viz *.plt files using "movieGenerator.py"