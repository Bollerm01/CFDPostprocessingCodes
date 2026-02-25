Workflow for AVIATION figure processing
1) Copy the test data into folders on the processing machine (if not already there)
2) Run "dataCombiner_fullProfiles.py" to pull all the data from the average line probes into one singular .xlsx file (each sheet is a different profile)
3) Run "dataCombiner_highFreqProfiles.py" to pull all the data from the 500 kHz shear one singular .xlsx file FOR EACH LINE (each sheet is a different point over time) (NEEDS UPDATED)
4) Change file paths, and run "BoundaryLayerProbeExtractor.py" to pull the BL thickness information at the SSWT BL probe location (3.375" US of injector)
5) Run "Volcano/volcanoShearProcessorV3.py" to get visual profiles from Paraview (ADAPT IF NEEDED)
6) Run "velocity_validation_plotter.m" in MATLAB to cross-plot VULCAN, Volcano, Tuttle, Fureby (currently just digitized) normalized data
7) [INSERT MATLAB CODE FOR NORMALIZED Rxij/TKE PLOTTING]
8) [INSERT CODE TO PROCESS THE SHEAR GROWTH BEHAVIOR]