Workflow for AVIATION figure processing
1) Run "aviationExtractorVolcano.py" on volparaview to pull the time averaged and additional data directly from the latest volcano file
2) Copy the test data into folders on the processing machine (if not already there)
3) Run "dataCombiner_fullProfiles.py" to pull all the data from the average line probes into one singular .xlsx file (each sheet is a different profile)
4) Run "process_500kHz_folder.m" to calculate the RMS velocity and pressure fluctuations with the 5 CTUs of 500kHz sampling for 4 lines (Fureby Comparison)
5) Run "dataCombiner_highFreqProfiles.py" to pull all the data from the 500 kHz shear layer data into one singular .xlsx file FOR EACH LINE (each sheet is a different point over time)
6) Change file paths, and run "BoundaryLayerProbeExtractor.py" to pull the BL thickness information at the SSWT BL probe location (3.375" US of injector)
7) Run "Volcano/volcanoShearProcessorV3.py" to get visual profiles from Paraview
8) Run "velocity_validation_script.m" in MATLAB to cross-plot VULCAN, Volcano, Tuttle, Fureby (currently just digitized) normalized data
9) Run "Urms_validation_script.m" to cross-plot Volcano, Tuttle, and Fureby Uxrms
10) Run "volcano_location_turbulence_plotter.m" and "volcano_RD_turbulence_plotter.m" to generate all of the Volcano Rij and TKE figures for specified locations and R/Ds 
11) Run "VULCAN_location_turbulence_plotter.m" and "VULCAN_RD_turbulence_plotter.m" to generate all of the VULCAN Rij and TKE figures for specified locations and R/Ds
12) Run "LES_RANS_turb_overlay.m" to cross plot the Volcano and VULCAN results from the output .fig files from (10) and (11) 
13) Run "process_BL_sweep_multiRun.m" to process the SSWT BL run data and "CFD_exp_BL_Processor.m" to format and cross-plot with the Volcano
14) Run "volcano_shear_thickness_processor.m" and "VULCAN_shear_thickness_processor.m" to extract shear thickness data from Volcano and VULCAN full probe Excels for each of the desired R/Ds
15) Run "LES_RANS_shearThick_overlay.m" to cross plot the Volcano and VULCAN shear thickness data