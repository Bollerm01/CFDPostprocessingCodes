% MATLAB Script: Urms_validation_script_2books.m
% Purpose: Plot overlayed y/d vs Urms/Uinf graphs (one per sheet),
%          overlaying the FIRST dataset from TWO Excel workbooks
%          (2 lines per subplot instead of 4 datasets from one book)
% Author: Matt Boller (adapted)
% Date: 7/17/26
% -------------------------------------------------------------------------
clear all; close all; clc;

% === USER SETTINGS ===
filename1 = 'SSWT_SliceUxValidation_FigureData.xlsx';   % <-- Workbook 1
filename2 = 'SSWT_FullUxValidation_FigureData.xlsx';    % <-- Workbook 2

mainTitle = 'Normalized Cavity Depth vs. Normalized X-Velocity';

% Legend entries — one per workbook (2 lines per subplot now)
legendEntries = {...
    'Volcano Slice',...
    'Volcano Full'...
    };

% Output image filename (change as desired)
outputFile = 'SSWT_Ux_Validation_SliceFull';
outputDPI  = 300;   % Resolution in DPI

% === READ SHEET NAMES (use workbook 1 as the reference list) ===
[~, sheetNames1] = xlsfinfo(filename1);
[~, sheetNames2] = xlsfinfo(filename2);
numSheets = numel(sheetNames1);

% Sanity check: warn if workbook 2 doesn't have matching sheet names
missingSheets = setdiff(sheetNames1, sheetNames2);
if ~isempty(missingSheets)
    warning('The following sheets from workbook 1 were not found in workbook 2: %s', ...
        strjoin(missingSheets, ', '));
end

% Create figure and tiled layout (1 x numSheets)
fig = figure('Name', 'Overlayed y/d vs Vx/Vxinf (2 Workbooks)', 'NumberTitle', 'off');
tiledlayout(fig, 1, numSheets, 'TileSpacing', 'compact', 'Padding', 'compact');

allLineHandles = []; % For shared legend

for i = 1:numSheets

    sheetName = sheetNames1{i};

    % --- Read data from workbook 1 ---
    data1 = readtable(filename1, 'Sheet', sheetName);
    data1 = data1(:, any(~ismissing(data1)));  % remove empty columns

    % --- Read data from workbook 2 (match by sheet name) ---
    if ismember(sheetName, sheetNames2)
        data2 = readtable(filename2, 'Sheet', sheetName);
        data2 = data2(:, any(~ismissing(data2)));
    else
        data2 = [];
    end

    % Select next tile
    nexttile;
    hold on; grid on; box on;

    localLineHandles = gobjects(1, 2);

    % --- Plot first pair from workbook 1 ---
    if width(data1) >= 2
        UOverUinf1 = data1{:, 1};
        yOverd1    = data1{:, 2};
        localLineHandles(1) = plot(UOverUinf1, yOverd1, 'LineWidth', 2.5);
    end

    % --- Plot first pair from workbook 2 ---
    if ~isempty(data2) && width(data2) >= 2
        UOverUinf2 = data2{:, 1};
        yOverd2    = data2{:, 2};
        localLineHandles(2) = plot(UOverUinf2, yOverd2, 'LineWidth', 2.5);
    end

    % Save handles from first subplot for legend
    if i == 1
        allLineHandles = localLineHandles;
    end

    % Axis and labels
    % xlim([-0.1, 0.3]);
    xlim([-0.3, 1.1]);   % Extended x-bounds
    ylim([-1, 1]);
    h = xlabel('V_{x,rms} / V_{x,\infty}');
    set(h, 'FontWeight', 'bold');

    % Label the first y-axis only
    if i == 1
        ylabel('y/D', 'Interpreter', 'none', 'FontWeight', 'bold');
    else
        ylabel('');
    end

    % Title with "xL" -> "x/L"
    title(strrep(sheetName, 'xL', 'x/L'), 'Interpreter', 'none');
    hold off;
end

% Shared legend (based on first subplot's handles)
validHandles = allLineHandles(isgraphics(allLineHandles));
if ~isempty(validHandles)
    numLines = length(validHandles);
    if length(legendEntries) >= numLines
        lg = legend(validHandles, legendEntries(1:numLines), ...
            'Orientation', 'horizontal', 'Box', 'off');
    else
        lg = legend(validHandles, ...
            arrayfun(@(x) sprintf('Dataset %d', x), 1:numLines, 'UniformOutput', false), ...
            'Orientation', 'horizontal', 'Box', 'off');
    end
    lg.Layout.Tile = 'south';
    lg.FontSize = 12;
end

% Add shared main title
% sgtitle(mainTitle, 'FontSize', 14, 'FontWeight', 'bold');

% === SAVE HIGH-RES OUTPUT ===
set(fig, 'PaperPositionMode', 'auto');
exportgraphics(fig, [outputFile '.jpg'], 'Resolution', outputDPI);
exportgraphics(fig, [outputFile '.pdf'], 'ContentType', 'vector');
fprintf('Figure saved as "%s" at %d DPI.\n', outputFile, outputDPI);