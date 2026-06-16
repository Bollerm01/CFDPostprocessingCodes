Description of Pressure Data Processing Codes:
- DataFFT.m : Pure FFT function code to iterate through mics and calculate the FFT of the unsteady pressures (inherited)
- DataFFT_overlap.m : Provides a binning overlap to the above function (inherited)
- DataFFTv2_allCFDKulites.m : Iterates through CFD Kulite *.dat files and plots an overlaid FFT spectrum
- DataFFTv2.m : Single CFD unsteady pressure *.dat probe plotting 
- datFilePlotter.py : Plots Pressure vs. time for a given CFD *.dat file
- datFilePlotter_dP.py : Plots the RMS/deltaP vs. time for a given CFD *.dat file. Also provides the RMS value
- DATfilderTrimmer.m : Used to get the latest X CTUs of data for a CFD kulite file
- FFTpadCode_Brooks.m : Slade's FFT code to data pad for upsampling of acoustic data
- KuliteCalibratorCode.m : Used to take in raw voltage signal and adjust gain for calibrating Kulite sensors to known dP from tone generator
- KuliteCalibratorCode_tunnelData.m : Takes tunnel Kulite data, sets the voltage offset, and plots the data as overlaid FFTs 
- read_and_plot_csv.m : Takes in CSVs of CFD probe data and plots specific indices for large data sets (500 probe lines)
- rossiterModeCalc.py : Calculates dominant Rossiter frequency modes (May need adjusting to Heller modified formula)

