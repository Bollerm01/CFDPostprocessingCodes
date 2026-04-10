Workflow for AVIATION figure processing
1) Run "aviationExtractorVolcano.py" on volparaview to pull the time averaged and additional data directly from the latest volcano file
2) Copy the test data into folders on the processing machine (if not already there)
3) Run "dataCombiner_fullProfiles.py" to pull all the data from the average line probes into one singular .xlsx file (each sheet is a different profile)
**4) Run "process_500kHz_folder.m" to calculate the RMS velocity and pressure fluctuations with the 5 CTUs of 500kHz sampling for 4 lines (Fureby Comparison) (EDIT WHEN DATA AVAIL)
5) Run "dataCombiner_highFreqProfiles.py" to pull all the data from the 500 kHz shear layer data into one singular .xlsx file FOR EACH LINE (each sheet is a different point over time)
6) Change file paths, and run "BoundaryLayerProbeExtractor.py" to pull the BL thickness information at the SSWT BL probe location (3.375" US of injector)
**7) Run "Volcano/volcanoShearProcessorV3.py" to get visual profiles from Paraview (ADAPT TO GET 3D AXIAL VIEW)
**8) Run "velocity_validation_script.m" in MATLAB to cross-plot VULCAN, Volcano, Tuttle, Fureby (currently just digitized) normalized data (Maybe add UxRMS?)
9) [INSERT MATLAB CODE FOR NORMALIZED Rxij/TKE PLOTTING]
10) [INSERT CODE TO PROCESS THE SHEAR GROWTH BEHAVIOR]