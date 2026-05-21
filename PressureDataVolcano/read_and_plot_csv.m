%% ========================================================================
%  read_and_plot_csv.m
%
%  Reads a CSV file containing:
%    time, nondimtime,
%    ###_density,
%    ###_pressure,
%    ###_velocityX,
%    ###_velocityY,
%    ###_velocityZ,
%    ###_velocityMag,
%    ###_machnumber,
%    ###_machnumberavg,
%    etc...
%
%  and plots time traces for selected variables and probe indices.
%
%  Works with very large CSV files and hundreds of probe locations.
%
%  ========================================================================

clear;
clc;
close all;

%% ---------------- USER SETTINGS ----------------------------------------

% CSV file name
[filename, path] = uigetfile("Select the CSV to process");

% Time variable to use:
%   'time'
%   'nondimtime'
timeVar = 'time';

% Variable family to plot:
%   'density'
%   'pressure'
%   'pressureavg'
%   'machnumber'
%   'machnumberavg'
%   'velocityX'
%   'velocityY'
%   'velocityZ'
%   'velocityMag'
%   'velocityMagavg'
varType = 'pressure';

% Probe indices to plot
% Example:
%   [0 1 2]
%   [10 50 100]
%   0:10:100
probeIDs = [0 50 100 200 300 400 499];

% Plot all probes automatically?
plotAll = false;

%% -----------------------------------------------------------------------

fprintf('Reading CSV file...\n');

% Preserve original variable names exactly as written in CSV
opts = detectImportOptions(fullfile(path,filename));
opts.VariableNamingRule = 'preserve';

T = readtable(fullfile(path,filename), opts);

fprintf('Finished reading file.\n');

%% ---------------- GET TIME VECTOR --------------------------------------

if ~ismember(timeVar, T.Properties.VariableNames)
    error('Time variable "%s" not found.', timeVar);
end

time = T.(timeVar);

%% ---------------- FIND VARIABLES ---------------------------------------

allNames = T.Properties.VariableNames;

% Match columns like:
%   000_pressure
%   123_pressure
pattern = ['^\d+_' varType '$'];

isMatch = ~cellfun(@isempty, regexp(allNames, pattern, 'once'));

matchedVars = allNames(isMatch);

if isempty(matchedVars)
    error('No variables found for "%s".', varType);
end

%% ---------------- EXTRACT PROBE IDS ------------------------------------

probeNumbers = zeros(length(matchedVars),1);

for i = 1:length(matchedVars)

    token = regexp(matchedVars{i}, '^(\d+)_', 'tokens');

    probeNumbers(i) = str2double(token{1}{1});

end

% Sort by probe number
[probeNumbers, sortIdx] = sort(probeNumbers);
matchedVars = matchedVars(sortIdx);

%% ---------------- SELECT PROBES ----------------------------------------

if plotAll
    selectedVars = matchedVars;
    selectedProbeNumbers = probeNumbers;
else

    selectedVars = {};
    selectedProbeNumbers = [];

    for i = 1:length(probeIDs)

        idx = find(probeNumbers == probeIDs(i));

        if ~isempty(idx)
            selectedVars{end+1} = matchedVars{idx}; %#ok<SAGROW>
            selectedProbeNumbers(end+1) = probeNumbers(idx); %#ok<SAGROW>
        else
            warning('Probe %d not found.', probeIDs(i));
        end

    end
end

%% ---------------- PLOT -------------------------------------------------

figure;
hold on;
grid on;
box on;

for i = 1:length(selectedVars)

    y = T.(selectedVars{i});

    plot(time, y, 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%03d', selectedProbeNumbers(i)));

end

xlabel(timeVar, 'Interpreter', 'none');
ylabel(varType, 'Interpreter', 'none');

title(sprintf('%s Time Trace', varType), ...
    'Interpreter', 'none');

legend('Location', 'best');

set(gca, 'FontSize', 12);

%% ---------------- OPTIONAL: HEATMAP ------------------------------------
% Creates a time-vs-probe contour plot for the selected variable family
% Uncomment to use

%{
fprintf('Generating heatmap...\n');

% Build matrix
dataMatrix = zeros(length(time), length(matchedVars));

for i = 1:length(matchedVars)
    dataMatrix(:,i) = T.(matchedVars{i});
end

figure;

imagesc(probeNumbers, time, dataMatrix);

axis xy;
colorbar;

xlabel('Probe Index');
ylabel(timeVar);

title([varType ' Heatmap']);

set(gca, 'FontSize', 12);
%}

%% ---------------- OPTIONAL: FFT OF A SINGLE PROBE ----------------------
% Uncomment to use

%{
probeFFT = 100;

varName = sprintf('%03d_%s', probeFFT, varType);

if ismember(varName, T.Properties.VariableNames)

    signal = T.(varName);

    dt = mean(diff(time));
    Fs = 1/dt;

    N = length(signal);

    Y = fft(signal - mean(signal));

    f = (0:N-1)*(Fs/N);

    figure;
    plot(f(1:floor(N/2)), abs(Y(1:floor(N/2))));

    xlabel('Frequency');
    ylabel('Amplitude');

    title(sprintf('FFT of %s', varName), ...
        'Interpreter', 'none');

    grid on;

else
    warning('FFT probe not found.');
end
%}

fprintf('Done.\n');