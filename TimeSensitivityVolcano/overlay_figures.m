%% ================================================================
%  Script: overlay_figures.m
%  Purpose: Load 3 MATLAB FIG files and overlay their line data using
%           the original legend entries stored in each figure.
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
    
    % Open figure invisibly (no GUI popup)
    fig = openfig(figFile, 'invisible');
    
    % Find all lines
    lines = findobj(fig, 'Type', 'line');
    
    % Reverse them because MATLAB stores them backwards in children list
    lines = flipud(lines);
    
    % Loop through all lines in the figure
    for k = 1:length(lines)
        allX{end+1} = lines(k).XData;
        allY{end+1} = lines(k).YData;

        % Extract the original DisplayName (legend text)
        label = lines(k).DisplayName;

        % If no DisplayName was set, fall back to a structured name
        if isempty(label)
            [~, figName] = fileparts(files{i});
            label = sprintf('%s - Line %d', figName, k);
        end

        allLabels{end+1} = label;
    end

    close(fig);
end

%% --- Plot the combined overlay ---
figure('Color', 'w', 'Name', 'Overlay of All Lines');
hold on; grid on;

for n = 1:length(allX)
    plot(allX{n}, allY{n}, 'LineWidth', 2);
end

title('Pressure Test Overlay', 'Interpreter','none');
xlabel('Pressure (Pa)');
ylabel('Y');

% Use original legend names
legend(allLabels, 'Interpreter','none', 'Location','bestoutside');

disp('Overlay plot created with original legend entries.');

