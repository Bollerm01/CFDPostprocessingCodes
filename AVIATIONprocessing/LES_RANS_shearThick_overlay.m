%% LES_RANS_shearThick_overlay.m
%  - Overlays two.fig files per "case" (one per solution type)
%  - Grouping:
%       * Filename is split by '_'
%       * Last token  = solution type (e.g. Volcano, VULCAN)
%       * First token: if it starts with 'velocityx', normalize to 'velocityx'
%       * Group key = all (possibly normalized) tokens except the last
%         so files that differ only by solution type (and e.g. velocityx vs
%         velocityxavg) are overlaid.
%  - Legends: keep original legend text, append " - <SolutionType>"
%  - Colors: fixed per solution type (same color across thresholds)
%  - Line spec (linestyle/marker): fixed per threshold (same across solutions)
%
%  Example legend in source figs:
%       "95%/5% Bounds"
%       "90%/10% Bounds"
%
%  Output:
%    - One overlay figure per group, saved in "VulcanVolcanoOverlays"

clear; close all; clc;

%% SELECT FOLDER

% figFolder = uigetdir(pwd, 'Select folder containing.fig files');
% if isequal(figFolder, 0)
%     error('No folder selected. Script terminated.');
% end
figFolder = "E:\Boller CFD\AVIATION CFD\Paper Results\finalData\LESRANScompare\VulcanVolcanoShearOverlay";

figFiles = dir(fullfile(figFolder, '*.fig'));
if isempty(figFiles)
    error('No.fig files found in the selected folder.');
end

%% OUTPUT FOLDER FOR OVERLAYS

outFolder = figFolder; % same as input

%% GROUP FILES BY "BASE WITHOUT SOLUTION TYPE"
% with normalization of 'velocityx*' -> 'velocityx' in the first token

pairGroups = containers.Map('KeyType', 'char', 'ValueType', 'any');

for k = 1:numel(figFiles)
    fname = figFiles(k).name;
    [~, baseName, ~] = fileparts(fname);
    
    parts = strsplit(baseName, '_');
    if numel(parts) < 2
        continue;  % need at least data type + solution
    end
    
    % Normalize first token: velocityx*, velocityxavg, etc. -> velocityx
    firstTok = parts{1};
    if startsWith(lower(firstTok), 'velocityx')
        parts{1} = 'velocityx';
    end
    
    % Last token is solution type
    % (we still use it later, but not in the grouping key)
    
    % Group key: everything except the last token
    baseKeyParts = parts(1:end-1);
    baseKey = strjoin(baseKeyParts, '_');
    
    fullPath = fullfile(figFolder, fname);
    
    if isKey(pairGroups, baseKey)
        tmp = pairGroups(baseKey);
        tmp{end+1} = fullPath;
        pairGroups(baseKey) = tmp;
    else
        pairGroups(baseKey) = {fullPath};
    end
end

if isempty(pairGroups.keys)
    error('No valid.fig filenames found for grouping.');
end

%% HELPERS

% Extract solution type from filename (last token)
getSolutionType = @(baseName) local_getSolutionType_fromName(baseName);

% Determine line style & marker from threshold legend text
getLineSpecForThreshold = @local_getLineSpecForThreshold;

%% OVERLAY PLOTS FOR EACH GROUP

groupKeys = pairGroups.keys;

for g = 1:numel(groupKeys)
    key = groupKeys{g};
    filesInGroup = pairGroups(key);
    
    % Expect at least 2 solutions per group
    % if numel(filesInGroup) < 2
    %     fprintf('Skipping group %s (only %d file(s)).\n', key, numel(filesInGroup));
    %     continue;
    % end
    
    % For naming, pull out the data type as the 2nd token of the key (if exists)
    keyParts = strsplit(key, '_');
    if numel(keyParts) >= 2
        dataType = keyParts{2};
    else
        dataType = key; % fallback
    end
    
    % Open the first figure just to grab axes labels, title, etc.
    firstFigPath = filesInGroup{1};
    tmpFig0 = openfig(firstFigPath, 'invisible');
    srcAx0 = findall(tmpFig0, 'Type', 'axes');
    if isempty(srcAx0)
        close(tmpFig0);
        fprintf('No axes found in %s, skipping.\n', firstFigPath);
        continue;
    end
    mainAx0 = srcAx0(1);
    
    origTitleObj  = get(mainAx0, 'Title');
    origTitleStr  = origTitleObj.String;
    
    origXLabelObj = get(mainAx0, 'XLabel');
    origXLabelStr = origXLabelObj.String;
    
    origYLabelObj = get(mainAx0, 'YLabel');
    origYLabelStr = origYLabelObj.String;
    
    % Create overlay figure
    figName = sprintf('Overlay: %s', key);
    overlayFig = figure('Name', figName, 'NumberTitle', 'off');
    ax = axes('Parent', overlayFig);
    hold(ax, 'on');
    grid(ax, 'on');
    
    allLineHandles = [];
    
    % Fixed colors for solutions (adjust as desired)
    solColors = containers.Map;
    solColors('Volcano') = [0.0000, 0.4470, 0.7410];  % MATLAB blue
    solColors('VULCAN')  = [0.8500, 0.3250, 0.0980];  % MATLAB orange
    
    % Loop over solution files in this group
    for f = 1:numel(filesInGroup)
        thisFile = filesInGroup{f};
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
                [ls, mk] = getLineSpecForThreshold(origName);
                
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
                
                % Legend text: keep original, append solution type
                legendText = sprintf('%s - %s', origName, solType);
                set(newObj, 'DisplayName', legendText);
                
                allLineHandles(end+1) = newObj; %#ok<AGROW>
            end
        end
        
        close(tmpFig);
    end
    
    % Labels and title: use original, but prepend Volcano vs VULCAN
    xlabel(ax, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter);
    ylabel(ax, origYLabelStr, 'Interpreter', origYLabelObj.Interpreter);
    
    newTitleStr = sprintf('Volcano vs. VULCAN: %s', origTitleStr);
    title(ax, newTitleStr, 'Interpreter', origTitleObj.Interpreter);
    
    if ~isempty(allLineHandles)
        lgd = legend(ax, allLineHandles);
        set(lgd, 'Interpreter', 'none');
        set(lgd, 'Location', 'best');
    end
    
    % Save overlay figure
    outBase = fullfile(outFolder, sprintf('%s_overlay', key));
    outBaseChar = char(outBase);
    savefig(overlayFig, [outBaseChar '.fig']);
    saveas(overlayFig, [outBaseChar '.png']);
    
    hold(ax, 'off');
    close(tmpFig0);
end

disp('Two-solution overlay generation (velocityx* grouped) complete.');

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

%% ------------------------------------------------------------------------
%% Local function: determine line spec (linestyle & marker) from threshold legend
%  Assumes legend strings like:
%     "95%/5% Bounds"
%     "90%/10% Bounds"
function [ls, mk] = local_getLineSpecForThreshold(origLegend)
    % DEFAULT
    ls = '-';
    mk = 'o';
    
    s = lower(strtrim(origLegend));
    
    % 95%/5% bounds -> solid circle
    if contains(s, '95%/5')
        ls = '-';
        mk = 'o';
        return;
    end
    
    % 90%/10% bounds -> dashed square
    if contains(s, '90%/10')
        ls = '--';
        mk = 's';
        return;
    end
    
    % extend here for more thresholds if needed
end