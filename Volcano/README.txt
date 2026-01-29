Workflow of Volcano ScaLES postprocessing for SSWT
See "VolcanoSlicingCoords.xlsx" for slicing coordinates in the domain
1) Generate screenshot slices of mid- and crossplanes using "volcanoShearProcessorV3.py" (run on Linux)
2) If necessary: Use "volcanoProbeExtractor.py" to extract cavity line probe data as .CSV's from a Volcano File (run on Linux)
3) Sort raw data using "volcanoProbeCondenser.py" using folder of raw .csv's on Windows machine
4) Generate shear layer thickness final data and figures using "volcanoVelocityThresholder.py" on Windows machine
5) Cross plot the final data across cases using "XXX.m" (NEEDS WRITTEN AS OF 1/9/26)
6) Process temporal pressure probe data using "FFT_PSD.m" (See "PressureDataVolcano" folder)
7) Process Kulite data using "XXX.m" (See "PressureDataVolcano" folder)