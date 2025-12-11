%% ================================================================
%  Script: overlay_figures.m
%  Purpose: Load 3 MATLAB FIG files, extract their lines, preserve
%           legend names, and assign a unique color to each line.
% ================================================================

clear; clc; close all;

%% --- Select the 3 FIG files ---
[files, path] = uigetfile('*.fig', ...
                          'Select 3 MATLAB FIG Files', ...
                          'MultiSelect', 'on');

if isequal(files, 0)
    disp('No files selected.');
    return;
end

if ischar(files)
    files = {files};
end

if numel(files) ~= 3
    error('You must select exactly 3 FIG files.');
end

%% Storage for all extracted data
allX = {};
allY = {};
allLabels = {};

%% --- Extract data & legend names from each figure ---
for i = 1:3
    
    figFile = fullfile(path, files{i});
    
    % Open figure invisibly
    fig = openfig(figFile, 'invisible');
    
    % Find all line objects (reverse order to preserve plotting order)
    lineObjs = flipud(findobj(fig, 'Type', 'line'));
    
    for k = 1:length(lineObjs)
        allX{end+1} = lineObjs(k).XData;
        allY{end+1} = lineObjs(k).YData;

        % Extract legend label
        label = lineObjs(k).DisplayName;

        % If missing, create fallback label
        if isempty(label)
            [~, figName] = fileparts(files{i});
            label = sprintf('%s - Line %d', figName, k);
        end

        allLabels{end+1} = label;
    end

    close(fig);
end

%% --- Guarantee EXACTLY 12 different colors ---
numLines = length(allX);

if numLines ~= 12
    error('Expected 12 lines (3 figures × 4 lines), but found %d.', numLines);
end

colorMap = lines(12);   % 12 visually distinct colors

%% --- Plot the combined overlay ---
figure('Color', 'w', 'Name', 'Overlay of All Lines');
hold on; grid on;

for n = 1:12
    plot(allX{n}, allY{n}, 'LineWidth', 2, 'Color', colorMap(n,:));
end

title('Overlay of Test 1-12 Pressure Data', 'Interpreter','none');
xlabel('Pressure (Pa)');
ylabel('Y');

legend(allLabels, 'Interpreter','none', 'Location','bestoutside');

disp('Overlay plot created with 12 unique colors.');


