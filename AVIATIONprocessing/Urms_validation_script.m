% MATLAB Script: Urms_validation_script.m
% Purpose: Plot 4 overlayed y/d vs Urms/Uinf graphs (one per sheet)
% Author: Matt Boller (adapted)
% Date: 4/14/26
% -------------------------------------------------------------------------
clear all; close all; clc;

% === USER SETTINGS ===
filename  = 'SSWT_UrmsValidation_FigureData.xlsx';  % <-- New Excel file
mainTitle = 'Normalized Cavity Depth vs. Normalized RMS X-Velocity ';

% Legend entries for the 3 overlaid curves
legendEntries = {...
    'Volcano',...
    'Fureby et. al.',...
    'Tuttle et. al.'...
};

% Output image filename (change as desired)
outputFile = 'SSWT_Urms_Validation.jpg';  % <-- New output name
outputDPI  = 300;                                      % Resolution in DPI

% === READ SHEETS ===
[~, sheetNames] = xlsfinfo(filename);
numSheets = numel(sheetNames);

% Create figure and tiled layout (1x4)
fig = figure('Name', 'Overlayed y/d vs $U_{rms}$/$U_{inf}$', 'NumberTitle', 'off');
tiledlayout(fig, 1, numSheets, 'TileSpacing', 'compact', 'Padding', 'compact');

allLineHandles = []; % For shared legend

for i = 1:numSheets
    % Read data
    data = readtable(filename, 'Sheet', sheetNames{i});
    
    % Remove completely empty columns
    data = data(:, any(~ismissing(data)));

    % Compute number of y/U pairs
    numCols = width(data);
    numPairs = floor(numCols / 2);

    % Safety: if the sheet has more than 3 pairs, only use the first 3
    numPairs = min(numPairs, 3);

    % Select next tile
    nexttile;
    hold on; grid on; box on;

    % Plot each pair of columns
    localLineHandles = gobjects(1, numPairs);
    for j = 1:numPairs
        UOverUinf = data{:, 2*j - 1};
        yOverd    = data{:, 2*j};

        % Use circles for 3rd dataset, lines otherwise
        if j == 3
            localLineHandles(j) = plot(UOverUinf, yOverd, 'o',...
                                       'LineWidth', 1.2, 'MarkerSize', 6);
        else
            localLineHandles(j) = plot(UOverUinf, yOverd, 'LineWidth', 1.5);
        end
    end

    % Save handles from first subplot for legend
    if i == 1
        allLineHandles = localLineHandles;
    end

    % Axis and labels
    xlim([-0.1, 0.3]);   % Extended x-bounds
    ylim([-1, 1]);
    xlabel('U_{rms} / U_{\infty}');
    ylabel('y / d');

    % Title with “xL” → “x/L”
    title(strrep(sheetNames{i}, 'xL', 'x/L'), 'Interpreter', 'none');

    hold off;
end

% Shared legend (based on first subplot’s handles)
if ~isempty(allLineHandles)
    numPairs = length(allLineHandles);
    if length(legendEntries) >= numPairs
        lg = legend(allLineHandles, legendEntries(1:numPairs),...
                    'Orientation', 'horizontal', 'Box', 'off');
    else
        lg = legend(allLineHandles,...
                    arrayfun(@(x) sprintf('Dataset %d', x), 1:numPairs, 'UniformOutput', false),...
                    'Orientation', 'horizontal', 'Box', 'off');
    end

    % Position legend below all subplots
    lg.Layout.Tile = 'south';
    lg.FontSize = 12;
end

% Add shared main title
sgtitle(mainTitle, 'FontSize', 14, 'FontWeight', 'bold');

% === SAVE HIGH-RES JPG ===
set(fig, 'PaperPositionMode', 'auto');  % Ensure proper sizing
exportgraphics(fig, outputFile, 'Resolution', outputDPI);

fprintf('Figure saved as "%s" at %d DPI.\n', outputFile, outputDPI);