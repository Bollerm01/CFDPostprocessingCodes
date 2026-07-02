%0. Pulls the .fig files using a GUI (assumes same folder)
[figFiles, figPath] = uigetfile(".fig","Select the 3 fig files", "MultiSelect","on");

% 1. Open the three .fig files (keep them hidden so they don't pop up)
fig1 = openfig(fullfile(figPath,figFiles{1}), 'invisible');
fig2 = openfig(fullfile(figPath,figFiles{2}), 'invisible');
fig3 = openfig(fullfile(figPath,figFiles{3}), 'invisible');

% 2. Get the axes handles for each
ax1 = gca(fig1);
ax2 = gca(fig2);
ax3 = gca(fig3);

% 3. Extract text metadata from the first figure
plotTitle  = ax1.Title.String;
xLabelText = ax1.XLabel.String;
yLabelText = ax1.YLabel.String;

% 4. Extract the graphical line/scatter objects
ch1 = get(ax1, 'Children');
ch2 = get(ax2, 'Children');
ch3 = get(ax3, 'Children');

% Calculate total number of lines/series being overlaid
totalSeries = numel(ch1) + numel(ch2) + numel(ch3);

% 5. Prompt the user for custom legend entries via an input dialog
prompt = {sprintf('Enter %d legend entries separated by commas:', totalSeries)};
dlgTitle = 'Legend Settings';
numLines = 1;
defaultAns = {'File 1, File 2, File 3'}; % Template example

userInput = inputdlg(prompt, dlgTitle, numLines, defaultAns);

% Process user input or generate a fallback if they cancel the dialog
if ~isempty(userInput)
    % Split the comma-separated string into a cell array of strings
    masterLabels = strsplit(userInput{1}, ',');
    % Trim whitespace from around the entries
    masterLabels = strtrim(masterLabels);
else
    % Fallback if user cancels the prompt window
    masterLabels = cell(1, totalSeries);
    for i = 1:totalSeries
        masterLabels{i} = sprintf('Series %d', i);
    end
end

% 6. Create a new master figure and axis
masterFig = figure();
masterAx = axes(masterFig);

% 7. Copy all plot elements sequentially onto the master axis
copyobj(ch1, masterAx);
hold(masterAx, 'on');
copyobj(ch2, masterAx);
copyobj(ch3, masterAx);
hold(masterAx, 'off');

% 8. Apply the copied Title and Axis Labels to the new master plot
title(masterAx, plotTitle);
xlabel(masterAx, xLabelText);
ylabel(masterAx, yLabelText);
masterAx.XScale = 'log';

% 9. Apply the custom user-provided labels to the master legend
legend(masterAx, masterLabels(1:min(totalSeries, numel(masterLabels))));

% 10. Close the source hidden figures to clean up RAM
close([fig1, fig2, fig3]);