%% ============================================================
% ARCHIVED DUE TO NO LONGER USING EVEN SPLIT ACROSS CAVITY (Split is across shear layer w specified probe #s)
% 
% Trim Probe CSVs to Selected Probe Numbers
%
% Keeps:
%   time
%   nondimtime
%   0_*
%   125_*
%   250_*
%   374_*
%   499_*
%
%% ============================================================

clear; clc;

%% Select folder

inputFolder = uigetdir(pwd,'Select folder containing CSV files');

if isequal(inputFolder,0)
    error('No folder selected.');
end

outputFolder = fullfile(inputFolder,'Trimmed');

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

%% Probe numbers to retain

keepProbes = [0 125 250 374 499];

%% Get CSV files

files = dir(fullfile(inputFolder,'*.csv'));

fprintf('Found %d CSV files\n\n',length(files));

%% Loop through files

for f = 1:length(files)

    fileName = files(f).name;

    fprintf('Processing: %s\n',fileName);

    T = readtable(fullfile(inputFolder,fileName));

    headers = T.Properties.VariableNames;

    keepCols = false(size(headers));

    for c = 1:numel(headers)

        h = headers{c};

        %% Always keep time columns

        if strcmpi(h,'time') || strcmpi(h,'nondimtime')
            keepCols(c) = true;
            continue
        end

        %% Match columns of form:
        %  125_pressure
        %  250_velocityX
        %  374_density
        %

        tokens = regexp(h,'^(\d+)_','tokens','once');

        if ~isempty(tokens)

            probeNum = str2double(tokens{1});

            if ismember(probeNum,keepProbes)
                keepCols(c) = true;
            end

        end

    end

    %% Trim table

    Ttrim = T(:,keepCols);

    %% Write output

    writetable( ...
        Ttrim, ...
        fullfile(outputFolder,fileName));

    fprintf('  Kept %d of %d columns\n', ...
        width(Ttrim), width(T));

end

fprintf('\nDone.\n');
fprintf('Output folder:\n%s\n',outputFolder);