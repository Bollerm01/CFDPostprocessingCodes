%% LES_RANS_shearThick_overlay_RDsweep.m
%  - Overlays TWO velocityx*.fig files onto ONE figure (multi-select GUI).
%  - Each file name must contain either "_VULCAN" or "_Volcano".
%  - Geometry (R/D) is taken from the line DisplayName / legend text.
%  - Colors:
%       * Fixed PER GEOMETRY (R/D) across both files.
%  - Line spec (style/marker):
%       * Fixed PER SOLUTION TYPE (VULCAN vs Volcano).
%  - Legend text:
%       * Original legend text + " - <SolutionType>"
%  - Additional:
%       * Creates a second figure where thickness (y-values) are plotted as
%         a normalized value relative to the first y-value of the R/D = 0.0
%         line for each solution type:
%            yNorm = y / y0
%       * Lines on the normalized plot are thicker.
%  - NEW:
%       * Creates a third figure where a solution-type-specific offset is
%         applied in physical units FIRST, then the result is normalized:
%            yOffsetNorm = (y - deltaSol) / y0
%         with deltaSol customizable per solution type (e.g.,
%         VULCAN: 0.2537, Volcano: 0.7124).

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
ax = axes('Parent', overlayFig);
hold(ax, 'on');
grid(ax, 'on');

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
            
            % Assign color for this geometry
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
%% LABELS AND TITLE FOR ORIGINAL (UN-NORMALIZED) OVERLAY

xlabel(ax, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter);
ylabel(ax, origYLabelStr, 'Interpreter', origYLabelObj.Interpreter);

% Override title to a LaTeX-style thickness label (stored as string)
origTitleStr = '$$V_x/V_{x,\infty}$$ Thickness';

% Make a plain-text version for a bold, non-LaTeX title
plainCoreTitle = regexprep(origTitleStr, '[$]', '');  % remove $$

newTitleStr = sprintf('%s vs. %s - %s', solType1, solType2, plainCoreTitle);

% Bold title, no LaTeX interpreter (so FontWeight works)
title(ax, newTitleStr, 'Interpreter', 'none', 'FontWeight', 'bold');

if ~isempty(allLineHandles)
    lgd = legend(ax, allLineHandles);
    set(lgd, 'Interpreter', 'latex');
    set(lgd, 'Location', 'southoutside');
    set(lgd, 'NumColumns', 2); 
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
%% BUILD NORMALIZED PLOTS
% For each solution type, find the FIRST y-value of the R/D = 0.0 line
% and use it as the baseline y0.
%
% Normalized value for any line of that solution:
%   yNorm = y / y0
%
% Additional functionality:
%   Create a second normalized plot where we:
%       1) SUBTRACT a solution-type-specific offset in physical units:
%            yShifted = y - deltaSol
%       2) Normalize the shifted data:
%            yOffsetNorm = yShifted / y0

% Identify unique solutions in lineInfo
allSols = {lineInfo.sol};
uniqueSols = unique(allSols);

% Baseline map: solution -> baseline thickness at R/D = 0.0 (first y-value)
baselineMap = containers.Map;

for iSol = 1:numel(uniqueSols)
    sol = uniqueSols{iSol};
    
    % Find all lines for this solution
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

%% User-defined OFFSETS (thickness) per solution type for normalized data
% These are interpreted in the SAME UNITS as the original yData.
% They are applied BEFORE normalization: yShifted = y - deltaSol.
solOffset = containers.Map;
solOffset('VULCAN')  = 0.2537;   % physical offset to subtract for VULCAN
solOffset('Volcano') = 0.7124;   % physical offset to subtract for Volcano
% If you have additional solution types, add them here, e.g.:
% solOffset('LES') = 0.1;

%% ------------------------------------------------------------------------
%% Create normalized figure (pure y/y0, original behavior)

normFig = figure('Name', 'Overlay: velocityx (Normalized to R/D = 0.0)', 'NumberTitle', 'off');
axN = axes('Parent', normFig);
hold(axN, 'on');
grid(axN, 'on');

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
            yNorm = yData./ y0;   % pure division by baseline
        else
            yNorm = yData;         % fallback if baseline is zero
        end
    else
        % No baseline for this solution; set NaN or just use original
        yNorm = nan(size(yData));
    end
    
    % Plot normalized data with thicker lines
    hN = plot(axN, xData, yNorm,...
        'Color', clr,...
        'LineStyle', ls,...
        'Marker', mk,...
        'LineWidth', 1.5);  % thicker lines for normalized plot
    
    set(hN, 'DisplayName', lgText);
    
    normLineHandles(end+1) = hN; %#ok<AGROW>
end

% Labels and title for normalized plot
xlabel(axN, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter);
ylabel(axN, '$$\delta_{SL} / \delta_{SL,R/D=0}$$', 'Interpreter', 'latex');

% Use the same plainCoreTitle (no $$) to build a bold, non-LaTeX title
normTitleStr = sprintf('Normalized: %s vs. %s - %s', solType1, solType2, plainCoreTitle);
title(axN, normTitleStr, 'Interpreter', 'none', 'FontWeight', 'bold');

if ~isempty(normLineHandles)
    lgdN = legend(axN, normLineHandles);
    set(lgdN, 'Interpreter', 'latex');
    set(lgdN, 'Location', 'southoutside');
    set(lgdN, 'NumColumns', 2); 
end

% Save normalized figure
outBaseNorm = fullfile(outFolder, sprintf('%s_vs_%s_velocityx_overlay_normalized', solType1, solType2));
outBaseNormChar = char(outBaseNorm);
savefig(normFig, [outBaseNormChar '.fig']);
exportgraphics(normFig, [outBaseNormChar '.png']);
exportgraphics(normFig, [outBaseNormChar '.pdf'], 'ContentType','vector');

%% ------------------------------------------------------------------------
%% Create offset-first-then-normalized figure: (y - deltaSol)/y0

normOffFig = figure('Name', 'Overlay: velocityx (Offset-First Normalized)', 'NumberTitle', 'off');
axNO = axes('Parent', normOffFig);
hold(axNO, 'on');
grid(axNO, 'on');

normOffLineHandles = [];

for k = 1:numel(lineInfo)
    sol    = lineInfo(k).sol;
    xData  = lineInfo(k).X;
    yData  = lineInfo(k).Y;
    clr    = lineInfo(k).Color;
    ls     = lineInfo(k).LineStyle;
    mk     = lineInfo(k).Marker;
    lgText = lineInfo(k).LegendText;
    
    % Require a baseline to normalize
    if isKey(baselineMap, sol)
        y0 = baselineMap(sol);
    else
        y0 = NaN;
    end
    
    if ~isnan(y0) && (y0 ~= 0)
        % Apply solution-specific offset in PHYSICAL units FIRST
        if isKey(solOffset, sol)
            deltaSol = solOffset(sol);
            yShifted = yData - deltaSol;
        else
            % If no offset defined for this solution, no shift
            yShifted = yData;
            deltaSol = 0.0;
        end
        
        % Then normalize
        yOffsetNorm = yShifted./ y0;
    else
        % If we cannot normalize, set NaN
        yOffsetNorm = nan(size(yData));
        deltaSol = isKey(solOffset, sol) * solOffset(sol); %#ok<NASGU>
    end
    
    % Plot offset-first normalized data (also thick lines)
    hNO = plot(axNO, xData, yOffsetNorm,...
        'Color', clr,...
        'LineStyle', ls,...
        'Marker', mk,...
        'LineWidth', 1.5);
    
    % Legend text indicating offset-first normalization
    lgTextOff = sprintf('%s', lgText);
   
    set(hNO, 'DisplayName', lgTextOff);
    
    normOffLineHandles(end+1) = hNO; %#ok<AGROW>
end

% Labels and title for offset-first normalized plot
xlabel(axNO, origXLabelStr, 'Interpreter', origXLabelObj.Interpreter);
ylabel(axNO, '$$(y - \Delta_{sol}) / y_{0,R/D=0}$$', 'Interpreter', 'latex');

normOffTitleStr = sprintf('Offset Normalized: %s vs. %s - %s', solType1, solType2, plainCoreTitle);
title(axNO, normOffTitleStr, 'Interpreter', 'none', 'FontWeight', 'bold');

if ~isempty(normOffLineHandles)
    lgdNO = legend(axNO, normOffLineHandles);
    set(lgdNO, 'Interpreter', 'latex');
    set(lgdNO, 'Location', 'southoutside');
    set(lgdNO, 'NumColumns', 2); 
end

% Save offset-first normalized figure
outBaseNormOff = fullfile(outFolder, sprintf('%s_vs_%s_velocityx_overlay_offsetFirst_normalized', solType1, solType2));
outBaseNormOffChar = char(outBaseNormOff);
savefig(normOffFig, [outBaseNormOffChar '.fig']);
exportgraphics(normOffFig, [outBaseNormOffChar '.png']);
exportgraphics(normOffFig, [outBaseNormOffChar '.pdf'], 'ContentType','vector');

hold(axNO, 'off');
hold(axN, 'off');
hold(ax, 'off');
close(tmpFig0);

disp('Overlay, normalized overlay, and offset-first normalized overlay of two velocityx*.fig files complete.');

%% ========================================================================
%% Local function: get solution type from base file name
%  Assumes filename ends with something like "..._VULCAN" or "..._Volcano".
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
        solTypeOut = solTypeIn;  % leave as-is if unknown
    end
end

%% Local function: extract geometry key (R/D) from legend string
%  Returns a consistent text key for the same geometry across both figures.
%  Modify this to match your legend format if needed.
function geomKey = local_extractGeometryKey(legendStr)
    geomKey = '';
    if isempty(legendStr)
        return;
    end
    
    s = string(legendStr);
    idx = strfind(s, 'R/D');
    if ~isempty(idx)
        % Take from 'R/D' to end
        sub = extractBetween(s, idx(1), strlength(s));
        sub = strip(sub);
        
        % Trim at first comma/semicolon/pipe if present
        parts = split(sub, {',',';','|'});
        geomKey = strtrim(parts(1));
        return;
    end
    
    % If your geometry appears as something else (e.g., "RD00", "RD17"),
    % add extra parsing logic here as needed.
end

%% Local function: detect if a geometry key corresponds to R/D = 0.0
function isZero = local_isZeroRD(geomKey)
    isZero = false;
    if isempty(geomKey)
        return;
    end
    
    % Simple checks that work with common formats:
    % e.g., "R/D = 0.0", "R/D=0.0", "R/D = 0.00"
    s = lower(strtrim(geomKey));
    if contains(s, 'r/d')
        % Try to pull off the numeric part:
        % remove 'r/d', '=', and spaces
        sNum = regexprep(s, 'r/d', '');
        sNum = strrep(sNum, '=', '');
        sNum = strtrim(sNum);
        
        % Convert to number if possible
        val = str2double(sNum);
        if ~isnan(val) && abs(val) < 1e-6
            isZero = true;
        end
    elseif strcmpi(strtrim(geomKey), 'rd00')
        % Example of alternate encoding
        isZero = true;
    end
end