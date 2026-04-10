%% clear on runtime
clc; clear all; close all;
%% Simple Data Visualization for SSWT

headers1 = [...
    "Stagnation Pressure",...
    "Static Pressure",...
    "Stagnation Temperature",...
    "Manifold Pressure",...
    "Tank Pressure",...
    "Mach Number",...
    "Velocity",...
    "Static Temperature",...
    "Mass Flow",...
    "Static Density",...
    "Reynold's Number",...
    "BL Pstatic",...
    "Time",...
    "X",...
    "Y"...
];

headers2 = {...
    "psia",...      % Stagnation Pressure
    "psia",...      % Static Pressure
    "degF",...      % Stagnation Temperature
    "psig",...      % Manifold Pressure
    "psig",...      % Tank Pressure
    "N/A",...       % Mach Number
    "m/s",...       % Velocity
    "degF",...      % Static Temperature
    "kg/s",...      % Mass Flow
    "kg/m^3",...    % Static Density
    "N/A",...       % Reynold's Number
    "psig",...      % BL Pstatic
    "sec",...       % Time
    "in",...        % X
    "in"...         % Y
};
txtFileName = uigetfile('*.txt', 'Select the data file');
filename = getFile;
fileID = fopen(filename,'r');
formatSpec = '%f';
a = findFirstLineOfData(fileID);

T = readtable(filename,"NumHeaderLines",a,"ReadVariableNames",false); %make data into table with no headers
T.Properties.VariableNames = headers1; %create headers

%% plot whatever 

figure;
% hold on;
% plot(T.Time, T.("Y"));
% yyaxis right;
% plot(T.Time, T.("BL Pstatic"));
% title("Boundary Layer Pressure vs Time");
% %legend("Y", "BL Pstatic");
% grid on;
% xlabel("Time (s)");
% ylabel("Pressure (psig)");
% yyaxis left;
% ylabel("Y Location (in)")
plot(T.Y, T.("BL Pstatic"))
title("Boundary Layer Pressure vs Position");
xlabel("Y Location (in)")
ylabel("Pressure (psig)")
grid on;


%% functions
function foundFile = getFile(txtName)
    directoryPath = "E:\Boller CFD\SSWT BL Validation Data";
    filePattern = "*.txt";
    if nargin == 0 %if no text file is provided
        fileList = dir(fullfile(directoryPath,filePattern)); %get all files in the default save directory
        [~,sorted] = sort([fileList.datenum],'descend'); %sort all of the files in the default directory by the datenum.  
        % Datenum is "A serial date number that represents the whole and fractional number of days from a fixed, preset date (January 0, 0000) in the proleptic ISO calendar."
        mostRecent = fileList(sorted(1)); %get the file from the top of the sorted list
        file = fullfile(directoryPath,mostRecent.name); %get full file path of the most recent file
        fprintf("File Name not provided, pulling most recent file, named %s\n",mostRecent.name)
    else %if text file name is provided
        fprintf("Trying to open %s\%s",directoryPath,txtName)
        wh = which(fullfile(directoryPath,txtName)); %try and file the file with the given path and filename
        if ~isempty(wh) %if wh is found to exist
            file = wh;
        else %if the file can't be found
            warning('MATLAB:fileNotFound', 'File was not found: %s', txtName);
            file = "E:\Boller CFD\SSWT BL Validation Data\BLsweep24Mar26_Data_run2.txt"; %set path to default file name
        end
    end
    foundFile = file; %return path for most recent file
end

function firstDataLine = findFirstLineOfData(fileID) %find row where data starts
    count = 0;
    
    while 1
        count = count + 1;
        tline = fgetl(fileID);
        if ~ischar(tline)
            fprintf(tline)
            break
        end
        celldata = textscan(tline,'%f %f %f %f %f');
        cellCount = 0;
        for i=1:length(celldata)
   
            if isempty(celldata{i})
                break
            end
            cellCount = cellCount+1;
        end
        if cellCount == 5
            break
        end
    end

    firstDataLine = count;
end