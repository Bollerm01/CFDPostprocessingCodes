Workflow for the TimeMeshSensitivityProcessing of HPWT runs (works with additional input where the data is .dat file for line probes)
See "VolcanoHPWTSlicingCoords.xlsx" for the slicing coordinates in the domain (NEED TO ADD)
See "SetupHPWT" subfolder for an example simulation setup for use with this workflow (NEED TO ADD)
1) Copy the test data into folders for the parametric study on the processing machine (if not already there)
2) Run "dataCombiner_fullRunV2.py" to pull all the data from the probe into one singular .xlsx file
3) Run "xlsxSorterv3.py" to sort the .xlsx files by probe location for any number of lines
4) Run "import_and_plot_excel.m" in MATLAB to pull from each of the folders and plot the specified data overlaid
5) For contours and other profiles, execute "volcanoProcessorHPWT.py" on the computer containing the .volcano file (NEED TO UPDATE)