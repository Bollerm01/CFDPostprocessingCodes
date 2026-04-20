%% LES_RANS_shearThick_overlay_allVelocityX.m
%  - Overlays ALL velocityx*.fig files in the folder onto ONE figure
%  - Filename structure:
%       * Split by '_'
%       * First token: velocityx*, velocityxavg, etc. (used only to select)
%       * Last token: solution type (e.g. Volcano, VULCAN)
%  - Only files whose first token starts with 'velocityx' are included.
%  - Legends: keep original legend text, append " - <SolutionType>"
%  - Colors: fixed per solution type (same color across thresholds)
%  - Line spec (linestyle/marker): fixed per threshold (same across solutions)
%
%  Example legend in source figs:
%       "95%/5% Bounds"
%       "90%/10% Bounds"
%
%  Output:
%    - A single overlay figure saved in the same folder.

clear; close all; clc;

%% SELECT FOLDER

figFolder = uigetdir(pwd, 'Select folder containing.fig files');
figSplit = split(figFolder, '\');
geometry = figSplit(end);
if isequal(figFolder, 0)
    error('No folder selected. Script terminated.');
end
% figFolder = "E:\Boller CFD\AVIATION CFD\Paper Results\finalData\LESRANScompare\VulcanVolcanoShearOverlay";

figFiles = dir(fullfile(figFolder, '*.fig'));
if isempty(figFiles)
    error('No.fig files found in the selected folder.');
end

%% OUTPUT FOLDER (same as input)

outFolder = figFolder;

%% FILTER: ONLY velocityx* FILES

velFiles = {};
for k = 1:numel(figFiles)
    fname = figFiles(k).name;
    [~, baseName, ~] = fileparts(fname);
    
    parts = strsplit(baseName, '_');
    if isempty(parts)
        continue;
    end
    
    firstTok = parts{2};
    if startsWith(lower(firstTok), 'velocityx')
        velFiles{end+1} = fullfile(figFolder, fname); %#ok<AGROW>
    end
end

if isempty(velFiles)
    error('No velocityx*.fig files found in the selected folder.');
end

%% HELPERS

% Extract solution type from filename (last token)
getSolutionType = @(baseName) local_getSolutionType_fromName(baseName);

% Determine line style & marker from threshold legend text
getLineSpecForThreshold = @local_getLineSpecForThreshold;

%% OPEN FIRST velocityx FIG TO GET AXES LABELS / TITLE

firstFigPath = velFiles{1};
tmpFig0 = openfig(firstFigPath, 'invisible');
srcAx0 = findall(tmpFig0, 'Type', 'axes');
if isempty(srcAx0)
    close(tmpFig0);
    error('No axes found in %s.', firstFigPath);
end
mainAx0 = srcAx0(1);

origTitleObj  = get(mainAx0, 'Title');
origTitleStr  = origTitleObj.String;

origXLabelObj = get(mainAx0, 'XLabel');
origXLabelStr = origXLabelObj.String;

origYLabelObj = get(mainAx0, 'YLabel');
origYLabelStr = origYLabelObj.String;

%% CREATE OVERLAY FIGURE (ONE FOR ALL velocityx*)

overlayFig = figure('Name', 'Overlay: velocityx', 'NumberTitle', 'off');
ax = axes('Parent', overlayFig);
hold(ax, 'on');
grid(ax, 'on');

allLineHandles = [];

% Fixed colors for solutions (adjust as desired)
solColors = containers.Map;
solColors('Volcano') = [0.0000, 0.4470, 0.7410];  % MATLAB blue
solColors('VULCAN')  = [0.8500, 0.3250, 0.0980];  % MATLAB orange

%% LOOP OVER ALL velocityx* FILES

for f = 1:numel(velFiles)
    thisFile = velFiles{f};
    [~, shortName, ~] = fileparts(thisFile);
    
    solType = getSolutionType(shortName);
    lowSol = lower(solType);
    if contains(lowSol, 'vulcan')
        solType = 'VULCAN';
    elseif contains(lowSol, 'volcano')
        solType = 'Volcano';
    end
    
    % Assign color for this solution
    if isKey(solColors, solType)
        clr = solColors(solType);
    else
        clr = [0 0 0]; % fallback
    end
    
    % Open source figure invisibly
    tmpFig = openfig(thisFile, 'invisible');
    srcAxes = findall(tmpFig, 'Type', 'axes');
    
    for a = 1:numel(srcAxes)
        srcChildren = findall(srcAxes(a), 'Type', 'line');
        
        for c = 1:numel(srcChildren)
            hObj = srcChildren(c);
            
            % Original legend label (e.g., "95%/5% Bounds")
            origName = get(hObj, 'DisplayName');
            if isempty(origName)
                origName = sprintf('Line %d', c);
            end
            
            % Determine line spec for this threshold
            [ls, mk] = getLineSpecForThreshold(origName, solType);
            
            % Copy to overlay axes
            newObj = copyobj(hObj, ax);
            
            % Style
            if isprop(newObj, 'Color')
                newObj.Color = clr;
            end
            if isprop(newObj, 'LineStyle')
                newObj.LineStyle = ls;
            end
            if isprop(newObj, 'Marker')
                newObj.Marker = mk;
            end
            
            % Legend text: keep original, append solution type and file index
            % (file index helps if you have many axial locations)
            legendText = sprintf('%s - %s', origName, solType);
            set(newObj, 'DisplayName', legendText);
            
            allLineHandles(end+1) = newObj; %#ok<AGROW>
        end
    end
    
    close(tmpFig);
end

%% LABELS AND TITLE
% Geometry Labeling
switch string(geometry)
    case 'RD00'
        geoLabel = 'R/D = 0.0';
    case 'RD17'
        geoLabel = 'R/D = 0.17';
    case 'RD52'
        geoLabel = 'R/D = 0.52';
    otherwise
        geoLabel = '';
end

xlabel(ax, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter);
ylabel(ax, origYLabelStr, 'Interpreter', origYLabelObj.Interpreter);

newTitleStr = sprintf('Volcano vs. VULCAN: %s, %s', origTitleStr, geoLabel);
title(ax, newTitleStr, 'Interpreter', origTitleObj.Interpreter);

if ~isempty(allLineHandles)
    lgd = legend(ax, allLineHandles);
    set(lgd, 'Interpreter', 'latex');
    set(lgd, 'Location', 'best'); % move outside if crowded
end

% Save overlay figure
outBase = fullfile(outFolder, sprintf('velocityx_allSolutions_overlay_%s',string(geometry)));
outBaseChar = char(outBase);
savefig(overlayFig, [outBaseChar '.fig']);
saveas(overlayFig, [outBaseChar '.png']);

hold(ax, 'off');
close(tmpFig0);

disp('Overlay of ALL velocityx* figures complete.');

%% ------------------------------------------------------------------------
%% Local function: get solution type (last token in base name)
function solType = local_getSolutionType_fromName(baseName)
    parts = strsplit(baseName, '_');
    if isempty(parts)
        solType = 'Unknown';
    else
        solType = parts{end};
    end
end


%% Local function: determine line spec (linestyle & marker) from
%% threshold legend AND solution type.
%  Assumes legend strings like:
%     "95%/5% Bounds"
%     "90%/10% Bounds"
%  and solType like:
%     "Volcano", "VULCAN"
function [ls, mk] = local_getLineSpecForThreshold(origLegend, solType)

    % Default style (fallback)
    ls = '-';
    mk = 'o';

    s = lower(strtrim(origLegend));
    st = lower(strtrim(solType));

    is95 = contains(s, '95%/5');
    is90 = contains(s, '90%/10');

    % -----------------------------
    % Volcano styles
    % -----------------------------
    if contains(st, 'volcano')
        if is95
            % Volcano 95/5
            ls = '-';     % solid
            mk = 'o';     % circle
            return;
        elseif is90
            % Volcano 90/10
            ls = '--';    % dashed
            mk = 'o';     % circle
            return;
        end
    end

    % -----------------------------
    % VULCAN styles
    % -----------------------------
    if contains(st, 'vulcan')
        if is95
            % VULCAN 95/5
            ls = '-';     % solid
            mk = 'o';     % circle
            return;
        elseif is90
            % VULCAN 90/10
            ls = '--';    % dashed
            mk = 'o';     % circle
            return;
        end
    end

    % You can extend for other solutions/thresholds here if needed.

end