%% zero_run_data_with_flatfield.m
%
% SCRIPT (run directly, no inputs needed).
%
% Prompts the user with file-selection dialogs to choose:
%   1) the flat field (zero-reading) CSV
%   2) the run data CSV
%
% Then subtracts the flat field average of pressure channels CHAN1-CHAN9
% from the corresponding channels in the run data, and writes out a new
% CSV identical in format to the run data, except CHAN1-CHAN9 have been
% replaced by their zeroed values.
%
% Expected CSV format (Scanivalve export), comma-delimited with header:
%   FRAME, TIME(S), TIME(nS), CHAN1, CHAN2, ..., CHAN16, TEMP1, ..., TEMP16

clear; clc;

%% ---------------- Settings ----------------
channelsToZero = 1:9;   % CHAN1 - CHAN9

%% ---------------- Select flat field file ----------------
[ffName, ffPath] = uigetfile({'*.csv', 'CSV Files (*.csv)'}, ...
    'Select the FLAT FIELD CSV file');
if isequal(ffName, 0)
    disp('No flat field file selected. Script cancelled.');
    return;
end
flatfieldFile = fullfile(ffPath, ffName);

%% ---------------- Select run data file ----------------
[runName, runPath] = uigetfile({'*.csv', 'CSV Files (*.csv)'}, ...
    'Select the RUN DATA CSV file', ffPath);
if isequal(runName, 0)
    disp('No run data file selected. Script cancelled.');
    return;
end
runFile = fullfile(runPath, runName);

%% ---------------- Select output file ----------------
[defPath, defName, ~] = fileparts(runFile);
defaultOutName = [defName '_zeroed.csv'];
[outName, outPath] = uiputfile({'*.csv', 'CSV Files (*.csv)'}, ...
    'Save zeroed run data as', fullfile(defPath, defaultOutName));
if isequal(outName, 0)
    disp('No output file specified. Script cancelled.');
    return;
end
outputFile = fullfile(outPath, outName);

%% ---------------- Read header line + data from flat field file ----------------
[ffHeader, ffData] = readScanivalveCSV(flatfieldFile);

%% ---------------- Read header line + data from run data file ----------------
[runHeader, runData] = readScanivalveCSV(runFile);

% Sanity check: column layouts should match
if numel(ffHeader) ~= numel(runHeader)
    error('Flat field file and run data file do not have the same number of columns.');
end

%% ---------------- Compute flat field averages for CHAN1-CHAN9 ----------------
ffAverages = zeros(1, numel(channelsToZero));
for i = 1:numel(channelsToZero)
    colIdx = findChannelColumn(ffHeader, channelsToZero(i));
    ffAverages(i) = mean(ffData(:, colIdx), 'omitnan');
end

%% ---------------- Subtract averages from run data, channel by channel ----------------
zeroedData = runData;   % copy -> preserves every other column untouched
for i = 1:numel(channelsToZero)
    colIdx = findChannelColumn(runHeader, channelsToZero(i));
    zeroedData(:, colIdx) = runData(:, colIdx) - ffAverages(i);
end

%% ---------------- Write output CSV (same header + format as run data) ----------------
writeScanivalveCSV(outputFile, runHeader, zeroedData);

%% ---------------- Report ----------------
fprintf('Flat field file: %s\n', flatfieldFile);
fprintf('Run data file:   %s\n', runFile);
fprintf('\nFlat field averages (CHAN1-CHAN9):\n');
for i = 1:numel(channelsToZero)
    fprintf('  CHAN%d: %.6f\n', channelsToZero(i), ffAverages(i));
end
fprintf('\nZeroed run data written to:\n  %s\n', outputFile);

msgbox(sprintf('Zeroed run data written to:\n%s', outputFile), ...
    'Done', 'help');


%% ============================== HELPER FUNCTIONS ==============================

function [headerNames, dataMatrix] = readScanivalveCSV(filename)
% Reads the raw header line (trimmed column names, in order) and the
% numeric data block from a Scanivalve-format CSV.

    if ~isfile(filename)
        error('File not found: %s', filename);
    end

    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open file: %s', filename);
    end
    headerLine = fgetl(fid);
    fclose(fid);

    headerNames = strtrim(strsplit(headerLine, ','));

    % Read the numeric data beneath the header line
    dataMatrix = readmatrix(filename, 'NumHeaderLines', 1, 'Delimiter', ',');
end

function colIdx = findChannelColumn(headerNames, chanNum)
% Finds the column index for "CHANx" (exact match, case-insensitive,
% ignoring surrounding whitespace).

    target = sprintf('CHAN%d', chanNum);
    colIdx = find(strcmpi(strtrim(headerNames), target), 1);
    if isempty(colIdx)
        error('Column %s not found in header.', target);
    end
end

function writeScanivalveCSV(filename, headerNames, dataMatrix)
% Writes the data matrix to CSV using the original header line and
% the same numeric formatting style as the source files (%.6f).

    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open output file for writing: %s', filename);
    end

    % Header line (rebuild with ", " spacing to match original style)
    fprintf(fid, '%s\n', strjoin(headerNames, ', '));

    % Data rows
    nCols = size(dataMatrix, 2);
    rowFormat = [strjoin(repmat({'%f'}, 1, nCols), ','), '\n'];
    for r = 1:size(dataMatrix, 1)
        fprintf(fid, rowFormat, dataMatrix(r, :));
    end

    fclose(fid);
end