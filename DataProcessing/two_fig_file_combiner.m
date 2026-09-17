%% two_fig_file_combiner.m
% Prompts the user to select two .fig files, extracts their plotted
% data, and combines everything onto a single new plot.

clear; clc; close all;

%% --- Prompt user to select the two .fig files ---
[file1, path1] = uigetfile('*.fig', 'Select the FIRST .fig file');
if isequal(file1, 0)
    disp('No file selected. Script cancelled.');
    return;
end
fig1_path = fullfile(path1, file1);

[file2, path2] = uigetfile('*.fig', 'Select the SECOND .fig file');
if isequal(file2, 0)
    disp('No file selected. Script cancelled.');
    return;
end
fig2_path = fullfile(path2, file2);

fprintf('File 1: %s\n', fig1_path);
fprintf('File 2: %s\n', fig2_path);

%% --- Load figures invisibly ---
fig1 = openfig(fig1_path, 'invisible');
fig2 = openfig(fig2_path, 'invisible');

%% --- Create new combined figure ---
combinedFig = figure('Name', 'Combined Plot');
combinedAx = axes(combinedFig);
hold(combinedAx, 'on');

colors = lines(20); % color palette

%% --- Extract and plot data from both figures ---
[~, name1] = fileparts(file1);
[~, name2] = fileparts(file2);

idx = 1;
idx = plot_all_data(fig1, combinedAx, name1, colors, idx);
idx = plot_all_data(fig2, combinedAx, name2, colors, idx); %#ok<NASGU>

hold(combinedAx, 'off');
legend(combinedAx, 'show', 'Location', 'best');
grid(combinedAx, 'on');

%% --- Copy axis labels from source figures ---
copy_axis_labels(fig1, fig2, combinedAx);

%% --- Show combined figure ---
set(combinedFig, 'Visible', 'on');

%% --- Prompt to save the combined figure ---
saveChoice = questdlg('Save the combined figure?', ...
    'Save Combined Plot', 'Yes', 'No', 'Yes');

if strcmp(saveChoice, 'Yes')
    [saveFile, savePath] = uiputfile('*.fig', 'Save Combined Figure As', ...
        'combined_plot.fig');
    if ~isequal(saveFile, 0)
        savefig(combinedFig, fullfile(savePath, saveFile));
        fprintf('Combined plot saved to: %s\n', fullfile(savePath, saveFile));
    end
end

%% --- Clean up invisible source figures ---
close(fig1);
close(fig2);


%% ================= LOCAL FUNCTIONS =================

function idx = plot_all_data(sourceFig, targetAx, label, colors, idx)
    ax = findall(sourceFig, 'Type', 'axes');
    n = size(colors, 1);

    for i = 1:numel(ax)
        % Lines
        lns = findobj(ax(i), 'Type', 'line');
        for j = 1:numel(lns)
            x = get(lns(j), 'XData');
            y = get(lns(j), 'YData');
            dispName = get(lns(j), 'DisplayName');
            if isempty(dispName)
                dispName = sprintf('%s - data%d', label, j);
            end
            plot(targetAx, x, y, ...
                'Color', colors(mod(idx-1, n) + 1, :), ...
                'LineWidth', 1.5, ...
                'DisplayName', dispName);
            idx = idx + 1;
        end

        % Scatter plots
        scs = findobj(ax(i), 'Type', 'scatter');
        for j = 1:numel(scs)
            x = get(scs(j), 'XData');
            y = get(scs(j), 'YData');
            dispName = get(scs(j), 'DisplayName');
            if isempty(dispName)
                dispName = sprintf('%s - scatter%d', label, j);
            end
            scatter(targetAx, x, y, 36, ...
                colors(mod(idx-1, n) + 1, :), 'filled', ...
                'DisplayName', dispName);
            idx = idx + 1;
        end
    end
end

function copy_axis_labels(fig1, fig2, targetAx)
    ax1 = findall(fig1, 'Type', 'axes');
    ax2 = findall(fig2, 'Type', 'axes');

    src = [];
    if ~isempty(ax1)
        src = ax1(1);
    elseif ~isempty(ax2)
        src = ax2(1);
    end

    if ~isempty(src)
        xlabel(targetAx, get(get(src, 'XLabel'), 'String'));
        ylabel(targetAx, get(get(src, 'YLabel'), 'String'));
        title(targetAx, 'Combined Plot');
    end
end