Workflow of VULCAN postprocessing
See "VulcanSlicingCoords.xlsx" for slicing coordinates in the domain
1) Generate screenshot slices of mid- and crossplanes using "vulcanShearProcessorV2.py"
2) Use "vulcanProbeExtractor.py" to extract cavity line probe data as .CSV's from a VULCAN file
3) Sort raw data using "vulcanProbeCondenser.py" using folder of raw .csv's on Windows machine
4) Generate shear layer thickness final data and figures using "vulcanVelocityThresholder.py" on Windows machine
5) Cross plot the shear layer thickness data using "XXX.m" (NEEDS WRITTEN AS OF 1/9/26)