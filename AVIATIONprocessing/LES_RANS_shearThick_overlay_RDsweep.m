%% LES_RANS_shearThick_overlay_RDsweep.m
%  - Overlays TWO velocityx*.fig files onto ONE figure (multi-select GUI).
%  - Each file name must contain either "_VULCAN" or "_Volcano".
%  - Geometry (R/D) is taken from the line DisplayName / legend text.
%  - Colors:
%       * Fixed PER GEOMETRY (R/D) across both files.
%       * R/D values are colored in ascending order (smallest R/D uses
%         the first color, typically blue, e.g., R/D = 0.0).
%  - Line spec (style/marker):
%       * Fixed PER SOLUTION TYPE (VULCAN vs Volcano).
%  - Legend text:
%       * Original legend text + " - <SolutionType>"
%       * Legend entries are ordered by ascending R/D.
%  - Additional:
%       * Creates a second figure where thickness (y-values) are plotted as
%         a normalized value relative to the first y-value of the R/D = 0.0
%         line for each solution type:
%            yNorm = y / y0
%       * Lines on the normalized plot are thicker.
%       * Creates a third figure where the data are normalized to the
%         MAXIMUM thickness value of the R/D = 0.0 case per solution type:
%            yNormMax = y / yMax0
%         where yMax0 is the maximum y-value of the R/D = 0.0 curve
%         for that solution type.

clear; close all; clc;

%% ------------------------------------------------------------------------
%% MULTI-SELECT TWO.FIG FILES

[fn, pth] = uigetfile('*.fig',...
    'Select TWO.fig files (one _VULCAN, one _Volcano)',...
    'MultiSelect', 'on');

if isequal(fn,0)
    error('No files selected. Script terminated.');
end

% Normalize output of uigetfile to a cell array of filenames
if ischar(fn)
    fn = {fn};
end

if numel(fn) ~= 2
    error('You must select exactly TWO.fig files (one VULCAN, one Volcano).');
end

file1 = fullfile(pth, fn{1});
file2 = fullfile(pth, fn{2});

% Extract base names (without extension)
[~, base1, ~] = fileparts(file1);
[~, base2, ~] = fileparts(file2);

% Solution types from filename suffix (_VULCAN or _Volcano)
solType1 = local_getSolutionType_fromName(base1);
solType2 = local_getSolutionType_fromName(base2);

% Normalize casing
solType1 = local_normalizeSolutionType(solType1);
solType2 = local_normalizeSolutionType(solType2);

% Basic check: we expect one VULCAN and one Volcano
if ~( (strcmp(solType1,'VULCAN') && strcmp(solType2,'Volcano')) ||...
      (strcmp(solType1,'Volcano') && strcmp(solType2,'VULCAN')) )
    warning('Selected files do not appear to be exactly one VULCAN and one Volcano file.');
end

%% ------------------------------------------------------------------------
%% OPEN FIRST FIGURE TO GET AXES LABELS / TITLE

tmpFig0 = openfig(file1, 'invisible');
srcAx0 = findall(tmpFig0, 'Type', 'axes');
if isempty(srcAx0)
    close(tmpFig0);
    error('No axes found in %s.', file1);
end
mainAx0 = srcAx0(1);

origTitleObj  = get(mainAx0, 'Title');
origTitleStr  = origTitleObj.String;

origXLabelObj = get(mainAx0, 'XLabel');
origXLabelStr = origXLabelObj.String;

origYLabelObj = get(mainAx0, 'YLabel');
origYLabelStr = origYLabelObj.String;

%% ------------------------------------------------------------------------
%% CREATE OVERLAY FIGURE (UN-NORMALIZED)

overlayFig = figure('Name', 'Overlay: velocityx (Two Files)', 'NumberTitle', 'off');
% Widen the figure so large text and bottom legend don't get clipped
set(overlayFig, 'Units','pixels', 'Position',[100 100 1200 650]);

ax = axes('Parent', overlayFig);
hold(ax, 'on');
grid(ax, 'on');

% --- Font size settings for overlay figure ---
ax.FontSize    = 14;  % tick labels
labelFontSize  = 18;  % axis labels
titleFontSize  = 20;  % title
legendFontSize = 14;  % legend

allLineHandles = [];

%% ------------------------------------------------------------------------
%% COLOR MAP FOR GEOMETRIES & LINE SPECS FOR SOLUTIONS

% Map: geometry key (e.g., 'R/D = 0.17') -> [R G B]
geomColors = containers.Map;

% Predefine some colors (extend as needed)
baseColors = lines(10);  % up to 10 geometries
nextColorIdx = 1;

% Line specs for solutions
solLineSpec = struct;
% Volcano: dashed + circle
solLineSpec.Volcano.LineStyle = '--';
solLineSpec.Volcano.Marker    = 'o';

% VULCAN: solid + square
solLineSpec.VULCAN.LineStyle  = '-';
solLineSpec.VULCAN.Marker     = 's';

%% ------------------------------------------------------------------------
%% STORAGE FOR NORMALIZATION DATA

% We will store info for every line we plot so we can build
% the normalized plots later.
lineInfo = struct(...
    'sol',        {},...
    'geomKey',    {},...
    'X',          {},...
    'Y',          {},...
    'Color',      {},...
    'LineStyle',  {},...
    'Marker',     {},...
    'LegendText', {} );

%% ------------------------------------------------------------------------
%% PROCESS BOTH FILES

fileList   = {file1, file2};
solTypes   = {solType1, solType2};

for f = 1:2
    thisFile = fileList{f};
    thisSol  = solTypes{f};
    
    % Open source figure invisibly
    tmpFig = openfig(thisFile, 'invisible');
    srcAxes = findall(tmpFig, 'Type', 'axes');
    
    for a = 1:numel(srcAxes)
        srcChildren = findall(srcAxes(a), 'Type', 'line');
        
        for c = 1:numel(srcChildren)
            hObj = srcChildren(c);
            
            % Original legend label
            origName = get(hObj, 'DisplayName');
            if isempty(origName)
                origName = sprintf('Line %d', c);
            end
            
            % Extract geometry key from legend (e.g., "R/D = 0.0", "R/D = 0.17")
            geomKey = local_extractGeometryKey(origName);
            if isempty(geomKey)
                % If no geometry is found, fall back to 'UnknownGeom'
                geomKey = 'UnknownGeom';
            end
            
            % Assign color for this geometry (temporary; will be reordered later)
            if isKey(geomColors, geomKey)
                clr = geomColors(geomKey);
            else
                if nextColorIdx > size(baseColors,1)
                    % If you have more geometries than baseColors,
                    % wrap around or generate new colors as needed.
                    clr = rand(1,3);
                else
                    clr = baseColors(nextColorIdx,:);
                    nextColorIdx = nextColorIdx + 1;
                end
                geomColors(geomKey) = clr;
            end
            
            % Line style & marker based on solution type
            if isfield(solLineSpec, thisSol)
                ls = solLineSpec.(thisSol).LineStyle;
                mk = solLineSpec.(thisSol).Marker;
            else
                % Fallback if an unknown solution type appears
                ls = '-';
                mk = 'o';
            end
            
            % Get data from the original line
            xData = get(hObj, 'XData');
            yData = get(hObj, 'YData');
            
            % Copy to overlay axes (original data)
            newObj = copyobj(hObj, ax);
            
            % Style by geometry (color) and solution (line/marker)
            if isprop(newObj, 'Color')
                newObj.Color = clr;
            end
            if isprop(newObj, 'LineStyle')
                newObj.LineStyle = ls;
            end
            if isprop(newObj, 'Marker')
                newObj.Marker = mk;
            end
            
            % Legend text: original + solution type
            legendText = sprintf('%s - %s', origName, thisSol);
            set(newObj, 'DisplayName', legendText);
            
            allLineHandles(end+1) = newObj; %#ok<AGROW>
            
            % Store info for normalized plots
            li.sol        = thisSol;
            li.geomKey    = geomKey;
            li.X          = xData;
            li.Y          = yData;
            li.Color      = clr;
            li.LineStyle  = ls;
            li.Marker     = mk;
            li.LegendText = legendText;
            
            lineInfo(end+1) = li; %#ok<SAGROW>
        end
    end
    
    close(tmpFig);
end

%% ------------------------------------------------------------------------
%% REASSIGN COLORS BY ASCENDING R/D (GEOMETRY)

geomKeysRaw  = {lineInfo.geomKey};
geomKeysCell = cellfun(@char, geomKeysRaw, 'UniformOutput', false);
geomKeysUnique = unique(geomKeysCell);
nGeom = numel(geomKeysUnique);

if nGeom > size(baseColors,1)
    warning('More geometries than predefined colors. Some colors will be reused or random.');
end

% Compute numeric R/D for each geometry key
geomRDVals = zeros(nGeom,1);
for i = 1:nGeom
    geomRDVals(i) = local_getRDValue(geomKeysUnique{i});
end

% Sort geometries by numeric R/D
[~, idxGeomSort] = sort(geomRDVals);
geomKeysSorted = geomKeysUnique(idxGeomSort);

% Build new color map using sorted geometries
newGeomColors = containers.Map;
for j = 1:nGeom
    if j <= size(baseColors,1)
        clr = baseColors(j,:);
    else
        clr = rand(1,3);
    end
    newGeomColors(geomKeysSorted{j}) = clr;
end

% Apply new colors to lineInfo and plotted lines
for k = 1:numel(lineInfo)
    gKey = lineInfo(k).geomKey;
    if isKey(newGeomColors, gKey)
        clr = newGeomColors(gKey);
        lineInfo(k).Color = clr;
        if k <= numel(allLineHandles)
            hLine = allLineHandles(k);
            if isgraphics(hLine) && isprop(hLine, 'Color')
                set(hLine, 'Color', clr);
            end
        end
    end
end

% Replace geomColors with the ordered version
geomColors = newGeomColors;

%% ------------------------------------------------------------------------
%% PRECOMPUTE LEGEND SORT ORDER:
%  Volcano: left column, ascending R/D
%  VULCAN : right column, ascending R/D

nLines = numel(lineInfo);
rdValsLegend   = zeros(nLines,1);
solNamesLegend = cell(nLines,1);

for i = 1:nLines
    rdValsLegend(i)   = local_getRDValue(lineInfo(i).geomKey);
    solNamesLegend{i} = lineInfo(i).sol;
end

idxVolcano = find(strcmp(solNamesLegend, 'Volcano'));
idxVULCAN  = find(strcmp(solNamesLegend, 'VULCAN'));

[~, sv] = sort(rdValsLegend(idxVolcano));
idxVolcanoSorted = idxVolcano(sv);

[~, sv2] = sort(rdValsLegend(idxVULCAN));
idxVULCANSorted = idxVULCAN(sv2);

sortIdxLegend = [idxVolcanoSorted; idxVULCANSorted];

%% ------------------------------------------------------------------------
%% LABELS AND TITLE FOR ORIGINAL (UN-NORMALIZED) OVERLAY

xlabel(ax, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter, 'FontSize', labelFontSize);
ylabel(ax, origYLabelStr, 'Interpreter', origYLabelObj.Interpreter, 'FontSize', labelFontSize);

newTitleStrLatex = sprintf('\\bf{%s vs. %s - $V_x/V_{x,\\infty}$ Thickness}',...
    solType1, solType2);
title(ax, newTitleStrLatex, 'Interpreter', 'latex', 'FontSize', titleFontSize);

% Legend: handles sorted by ascending R/D, then solution type
if ~isempty(allLineHandles)
    sortedHandles = allLineHandles(sortIdxLegend);
    lgd = legend(ax, sortedHandles);
    set(lgd, 'Interpreter', 'latex');
    set(lgd, 'Location', 'southoutside');
    set(lgd, 'NumColumns', 2);
    set(lgd, 'FontSize', legendFontSize);
end

%% ------------------------------------------------------------------------
%% SAVE OVERLAY FIGURE (UN-NORMALIZED)

outFolder = pth;
outBase = fullfile(outFolder, sprintf('%s_vs_%s_velocityx_overlay', solType1, solType2));
outBaseChar = char(outBase);
savefig(overlayFig, [outBaseChar '.fig']);
exportgraphics(overlayFig, [outBaseChar '.png']);
exportgraphics(overlayFig, [outBaseChar '.pdf'], 'ContentType','vector');

%% ------------------------------------------------------------------------
%% BUILD NORMALIZED PLOTS (y / y0)

allSols = {lineInfo.sol};
uniqueSols = unique(allSols);

baselineMap = containers.Map;

for iSol = 1:numel(uniqueSols)
    sol = uniqueSols{iSol};
    idxSol = find(strcmp(allSols, sol));
    
    baselineFound = false;
    for k = idxSol
        gKey = lineInfo(k).geomKey;
        if local_isZeroRD(gKey)
            y = lineInfo(k).Y;
            if ~isempty(y)
                baselineMap(sol) = y(1);
                baselineFound = true;
                break;
            end
        end
    end
    
    if ~baselineFound
        warning('No R/D = 0.0 line found for solution "%s". Normalization for this solution will be skipped.', sol);
    end
end

%% Normalized figure

normFig = figure('Name', 'Overlay: velocityx (Normalized to R/D = 0.0)', 'NumberTitle', 'off');
set(normFig, 'Units','pixels', 'Position',[150 120 1200 650]);

axN = axes('Parent', normFig);
hold(axN, 'on');
grid(axN, 'on');

axN.FontSize    = 14;
labelFontSizeN  = 18;
titleFontSizeN  = 20;
legendFontSizeN = 14;

normLineHandles = [];

for k = 1:numel(lineInfo)
    sol    = lineInfo(k).sol;
    xData  = lineInfo(k).X;
    yData  = lineInfo(k).Y;
    clr    = lineInfo(k).Color;
    ls     = lineInfo(k).LineStyle;
    mk     = lineInfo(k).Marker;
    lgText = lineInfo(k).LegendText;
    
    if isKey(baselineMap, sol)
        y0 = baselineMap(sol);
        if y0 ~= 0
            yNorm = yData./ y0;
        else
            yNorm = yData;
        end
    else
        yNorm = nan(size(yData));
    end
    
    hN = plot(axN, xData, yNorm,...
        'Color', clr,...
        'LineStyle', ls,...
        'Marker', mk,...
        'LineWidth', 1.5);
    
    set(hN, 'DisplayName', lgText);
    normLineHandles(end+1) = hN; %#ok<AGROW>
end

xlabel(axN, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter, 'FontSize', labelFontSizeN);
ylabel(axN, '$\delta_{SL} / \delta_{SL,R/D=0}$', 'Interpreter', 'latex', 'FontSize', labelFontSizeN);

normTitleStrLatex = sprintf('\\bf{Normalized: %s vs. %s - $V_x/V_{x,\\infty}$ Thickness}',...
    solType1, solType2);
title(axN, normTitleStrLatex, 'Interpreter', 'latex', 'FontSize', titleFontSizeN);

if ~isempty(normLineHandles)
    sortedHandlesN = normLineHandles(sortIdxLegend);
    lgdN = legend(axN, sortedHandlesN);
    set(lgdN, 'Interpreter', 'latex');
    set(lgdN, 'Location', 'southoutside');
    set(lgdN, 'NumColumns', 2);
    set(lgdN, 'FontSize', legendFontSizeN);
end

outBaseNorm = fullfile(outFolder, sprintf('%s_vs_%s_velocityx_overlay_normalized', solType1, solType2));
outBaseNormChar = char(outBaseNorm);
savefig(normFig, [outBaseNormChar '.fig']);
exportgraphics(normFig, [outBaseNormChar '.png']);
exportgraphics(normFig, [outBaseNormChar '.pdf'], 'ContentType','vector');

%% ------------------------------------------------------------------------
%% Max-normalized (y / max(y0))

maxBaselineMap = containers.Map;

for iSol = 1:numel(uniqueSols)
    sol = uniqueSols{iSol};
    idxSol = find(strcmp(allSols, sol));

    maxFound = false;
    yMax0 = -inf;
    for k = idxSol
        gKey = lineInfo(k).geomKey;
        if local_isZeroRD(gKey)
            y = lineInfo(k).Y;
            if ~isempty(y)
                thisMax = max(y(:));
                if thisMax > yMax0
                    yMax0 = thisMax;
                    maxFound = true;
                end
            end
        end
    end

    if maxFound && isfinite(yMax0)
        maxBaselineMap(sol) = yMax0;
    else
        warning(['No valid R/D = 0.0 data found to compute MAX baseline '...
                 'for solution "%s". Max-normalized plot for this solution will be NaN.'], sol);
    end
end

normMaxFig = figure('Name', 'Overlay: velocityx (Max R/D=0 Normalized)', 'NumberTitle', 'off');
set(normMaxFig, 'Units','pixels', 'Position',[200 140 1200 650]);

axNM = axes('Parent', normMaxFig);
hold(axNM, 'on');
grid(axNM, 'on');

axNM.FontSize     = 14;
labelFontSizeNM   = 18;
titleFontSizeNM   = 20;
legendFontSizeNM  = 14;

normMaxLineHandles = [];

for k = 1:numel(lineInfo)
    sol    = lineInfo(k).sol;
    xData  = lineInfo(k).X;
    yData  = lineInfo(k).Y;
    clr    = lineInfo(k).Color;
    ls     = lineInfo(k).LineStyle;
    mk     = lineInfo(k).Marker;
    lgText = lineInfo(k).LegendText;

    if isKey(maxBaselineMap, sol)
        yMax0 = maxBaselineMap(sol);
        if yMax0 ~= 0
            yNormMax = yData./ yMax0;
        else
            yNormMax = yData;
        end
    else
        yNormMax = nan(size(yData));
    end

    hNM = plot(axNM, xData, yNormMax,...
        'Color', clr,...
        'LineStyle', ls,...
        'Marker', mk,...
        'LineWidth', 1.5);

    set(hNM, 'DisplayName', lgText);
    normMaxLineHandles(end+1) = hNM; %#ok<AGROW>
end

xlabel(axNM, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter, 'FontSize', labelFontSizeNM);
ylabel(axNM, '$\delta_{SL} / \max(\delta_{SL,R/D=0})$', 'Interpreter', 'latex', 'FontSize', labelFontSizeNM);

normMaxTitleStrLatex = sprintf('\\bf{Max-Normalized: %s vs. %s - $V_x/V_{x,\\infty}$ Thickness}',...
    solType1, solType2);
title(axNM, normMaxTitleStrLatex, 'Interpreter', 'latex', 'FontSize', titleFontSizeNM);

if ~isempty(normMaxLineHandles)
    sortedHandlesNM = normMaxLineHandles(sortIdxLegend);
    lgdNM = legend(axNM, sortedHandlesNM);
    set(lgdNM, 'Interpreter', 'latex');
    set(lgdNM, 'Location', 'southoutside');
    set(lgdNM, 'NumColumns', 2);
    set(lgdNM, 'FontSize', legendFontSizeNM);
end

outBaseNormMax = fullfile(outFolder, sprintf('%s_vs_%s_velocityx_overlay_maxRD0_normalized', solType1, solType2));
outBaseNormMaxChar = char(outBaseNormMax);
savefig(normMaxFig, [outBaseNormMaxChar '.fig']);
exportgraphics(normMaxFig, [outBaseNormMaxChar '.png']);
exportgraphics(normMaxFig, [outBaseNormMaxChar '.pdf'], 'ContentType','vector');

hold(axNM, 'off');
hold(axN, 'off');
hold(ax, 'off');
close(tmpFig0);

disp('Overlay, normalized overlay, and max-R/D=0 normalized overlay of two velocityx*.fig files complete.');

%% ========================================================================
%% Local function: get solution type from base file name
function solType = local_getSolutionType_fromName(baseName)
    parts = strsplit(baseName, '_');
    if isempty(parts)
        solType = 'Unknown';
    else
        solType = parts{end};
    end
end

%% Local function: normalize solution type to canonical forms
function solTypeOut = local_normalizeSolutionType(solTypeIn)
    s = lower(strtrim(solTypeIn));
    if contains(s, 'vulcan')
        solTypeOut = 'VULCAN';
    elseif contains(s, 'volcano')
        solTypeOut = 'Volcano';
    else
        solTypeOut = solTypeIn;
    end
end

%% Local function: extract geometry key (R/D) from legend string
function geomKey = local_extractGeometryKey(legendStr)
    geomKey = '';
    if isempty(legendStr)
        geomKey = '';
        return;
    end
    
    s = char(legendStr);
    idx = strfind(lower(s), 'r/d');
    if ~isempty(idx)
        sub = s(idx(1):end);
        sub = strtrim(sub);
        tokens = regexp(sub, '^[^,;|]*', 'match', 'once');
        geomKey = strtrim(tokens);
        geomKey = char(geomKey);
        return;
    end
    geomKey = char(strtrim(s));
end

%% Local function: detect if a geometry key corresponds to R/D = 0.0
function isZero = local_isZeroRD(geomKey)
    isZero = false;
    if isempty(geomKey)
        return;
    end
    
    s = lower(strtrim(geomKey));
    if contains(s, 'r/d')
        sNum = regexprep(s, 'r/d', '', 'ignorecase');
        sNum = strrep(sNum, '=', '');
        sNum = strtrim(sNum);
        val = str2double(sNum);
        if ~isnan(val) && abs(val) < 1e-6
            isZero = true;
        end
    elseif strcmpi(strtrim(geomKey), 'rd00')
        isZero = true;
    end
end

%% Local function: extract numeric R/D value from geometry key
function rdVal = local_getRDValue(geomKey)
    rdVal = inf;
    if isempty(geomKey)
        return;
    end
    
    s = char(geomKey);
    sLower = lower(strtrim(s));
    
    expr = 'r/d\s*=\s*([+-]?\d*\.?\d+([eE][+-]?\d+)?)';
    tokens = regexp(sLower, expr, 'tokens', 'once');
    if ~isempty(tokens)
        rdValTmp = str2double(tokens{1});
        if ~isnan(rdValTmp)
            rdVal = rdValTmp;
            return;
        end
    end
    
    expr2 = 'rd\s*([0-9]+)';
    tokens2 = regexp(sLower, expr2, 'tokens', 'once');
    if ~isempty(tokens2)
        rdValTmp = str2double(tokens2{1});
        if ~isnan(rdValTmp)
            rdVal = rdValTmp / 100;
            return;
        end
    end
end