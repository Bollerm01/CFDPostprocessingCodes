Workflow of Volcano ScaLES postprocessing
1) Generate screenshot slices of mid- and crossplanes using "volcanoShearProcessorV3.py" (run on Linux)
2) If necessary: Use "velocityProbeExtractor.py" to extract cavity line probe data as .CSV's from a Volcano File (run on Linux)
3) Sort raw data using "volcanoProbeCondenser.py" using folder of raw .csv's on Windows machine
4) Generate shear layer thickness final data and figures using "volcanoVelocityThresholder.py" on Windows machine