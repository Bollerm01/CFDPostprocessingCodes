%% extract_and_plot_TKE_script.m
% -------------------------------------------------------------------------
% Standalone script to:
% 1) Prompt for 2 Volcano and 2 VULCAN Excel workbooks (different geometries)
% 2) For each Volcano workbook:
%       - Use only sheets whose names end with '_MP'
%       - Extract xL from sheet name using regex (e.g., '0p03' -> 0.03)
%       - From each sheet, get a representative TKE at Y_norm ~ 0:
%           * Prefer exact Y_norm = 0
%           * Otherwise find the inflection (sign change) from negative to
%             positive Y_norm and treat that as "zero"
%           * Average TKE in ±5 rows around that index
% 3) For each VULCAN workbook:
%       - Treat all sheets as planes (no '_MP' filter)
%       - Same averaging logic around Y_norm ~ 0
% 4) Cross-plot TKE vs x/L:
%       - Volcano = blue lines
%       - VULCAN  = red lines
%       - Legend labels customized by workbook name
% 5) Save figure as.fig, vector.pdf, and.png
% -------------------------------------------------------------------------

clear; close all; clc;

%% 1. File selection
fprintf('Select 2 Volcano workbooks (different geometries)...\n');
[volcanoFiles, volcanoPath] = uigetfile({'*.xlsx;*.xls','Excel Files'},...
    'Select 2 Volcano Workbooks', 'MultiSelect', 'on');
volcanoFiles = ensureCell(volcanoFiles);
if numel(volcanoFiles) ~= 2
    error('You must select exactly 2 Volcano workbooks.');
end

fprintf('Select 2 VULCAN workbooks (different geometries)...\n');
[vulcanFiles, vulcanPath] = uigetfile({'*.xlsx;*.xls','Excel Files'},...
    'Select 2 VULCAN Workbooks', 'MultiSelect', 'on');
vulcanFiles = ensureCell(vulcanFiles);
if numel(vulcanFiles) ~= 2
    error('You must select exactly 2 VULCAN workbooks.');
end

% Geometry / legend labels derived from filenames with custom mapping
geomLabelsVolcano = cell(1,2);
geomLabelsVulcan  = cell(1,2);

for i = 1:2
    [~, nameVol, ~] = fileparts(volcanoFiles{i});
    [~, nameVul, ~] = fileparts(vulcanFiles{i});
    
    % Volcano legend labels
    geomLabelsVolcano{i} = mapLegendLabel(nameVol, 'Volcano');
    % VULCAN legend labels
    geomLabelsVulcan{i}  = mapLegendLabel(nameVul, 'VULCAN');
end

%% 2. Process Volcano files
volcanoData = struct('xL',[],'TKE',[],'label','');
for i = 1:2
    fullFile = fullfile(volcanoPath, volcanoFiles{i});
    volcanoData(i) = processVolcanoWorkbook(fullFile, geomLabelsVolcano{i});
end

%% 3. Process VULCAN files
vulcanData = struct('xL',[],'TKE',[],'label','');
for i = 1:2
    fullFile = fullfile(vulcanPath, vulcanFiles{i});
    vulcanData(i) = processVulcanWorkbook(fullFile, geomLabelsVulcan{i});
end

%% 4. Plotting
figure('Color','w'); hold on; grid on; box on;

% Colors per solution type (requested: Volcano blue, VULCAN red)
colVolcano = [0.0  0.45 0.74];  % blue-ish
colVulcan  = [0.85 0.10 0.10];  % red-ish

% Markers / linestyles for the two geometries
markers = {'o','s'};
lines   = {'-','--'};

% Plot Volcano data (blue)
for i = 1:2
    plot(volcanoData(i).xL, volcanoData(i).TKE,...
        'Color', colVolcano,...
        'LineStyle', lines{i},...
        'Marker', markers{i},...
        'LineWidth', 1.5,...
        'DisplayName', volcanoData(i).label);
end

% Plot VULCAN data (red)
for i = 1:2
    plot(vulcanData(i).xL, vulcanData(i).TKE,...
        'Color', colVulcan,...
        'LineStyle', lines{i},...
        'Marker', markers{i},...
        'LineWidth', 1.5,...
        'DisplayName', vulcanData(i).label);
end

% Axis labels and title (bold)
hX = xlabel('x/L','Interpreter','none', 'FontWeight','bold');
hY = ylabel('TKE','Interpreter','none', 'FontWeight','bold');
hT = title('VULCAN vs. Volcano: Shear Layer TKE vs x/L','Interpreter','none', 'FontWeight','bold');
set([hX hY hT],'FontWeight','bold');

legend('Location','best','Interpreter','none');

%% 5. Save figure in multiple formats
outNameBase = 'TKE_vs_xL_Volcano_VULCAN';

%.fig
savefig([outNameBase '.fig']);

% Vectorized PDF
set(gcf,'Renderer','Painters');
print(gcf, outNameBase, '-dpdf','-r300');

%.png
print(gcf, outNameBase, '-dpng','-r300');

fprintf('Figure saved as:\n  %s.fig\n  %s.pdf\n  %s.png\n',...
    outNameBase, outNameBase, outNameBase);

%% ------------------------------------------------------------------------
%% Local helper functions
%% ------------------------------------------------------------------------

function c = ensureCell(f)
    % Convert char to cellstr for single-file selection
    if ischar(f)
        c = {f};
    else
        c = f;
    end
end

function label = mapLegendLabel(baseName, solverType)
    % Map specific workbook base names to requested legend labels.
    % solverType is 'Volcano' or 'VULCAN'.
    
    label = sprintf('%s - %s', baseName, solverType); % default
    
    switch baseName
        case 'VolcanoCondensedProbeData_RD00'
            label = sprintf('R/D = 0 - %s', solverType);
        case 'VolcanoCondensedProbeData_RD52'
            label = sprintf('R/D = 0.52 - %s', solverType);
        case 'VULCANCondensedProbeData_RD00'
            label = sprintf('R/D = 0 - %s', solverType);
        case 'VULCANCondensedProbeData_RD52'
            label = sprintf('R/D = 0.52 - %s', solverType);
    end
end

function out = processVolcanoWorkbook(filename, labelStr)
    % Process a Volcano workbook:
    %   - only sheets whose names end with '_MP'
    %   - extract xL from sheet name
    %   - average TKE in ±5 rows around Y_norm ~ 0

    fprintf('\nProcessing Volcano workbook: %s\n', filename);
    [~, base, ~] = fileparts(filename);
    
    [status,sheets] = xlsfinfo(filename);
    if isempty(status)
        error('Could not read Excel file: %s', filename);
    end
    
    xL_list  = [];
    TKE_list = [];
    
    for iSheet = 1:numel(sheets)
        sheetName = sheets{iSheet};
        
        % Only process sheets ending in '_MP'
        if ~endsWith(sheetName, '_MP','IgnoreCase',true)
            continue;
        end
        
        % Extract xL from sheet name (e.g., '0p03' -> 0.03)
        xLval = parse_xL_from_name(sheetName);
        if isnan(xLval)
            fprintf('Warning: Could not parse xL from sheet "%s" in %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        % Read sheet as table
        T = readtable(filename, 'Sheet', sheetName);
        
        % Identify columns
        yCol  = find(strcmpi(T.Properties.VariableNames,'Y_norm'), 1);
        tkeCol = find(strcmpi(T.Properties.VariableNames,'tke'), 1);
        if isempty(tkeCol)
            tkeCol = find(strcmpi(T.Properties.VariableNames,'TKE'), 1);
        end
        
        if isempty(yCol) || isempty(tkeCol)
            fprintf('Warning: Missing Y_norm or TKE column in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        y  = T{:, yCol};
        tkeData = T{:, tkeCol};
        
        [tkeAvg, success] = averageAroundYzero(y, tkeData, 5);
        if ~success
            fprintf('Warning: Could not determine Y_norm ~ 0 in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        xL_list(end+1,1)  = xLval;    %#ok<AGROW>
        TKE_list(end+1,1) = tkeAvg;   %#ok<AGROW>
    end
    
    % Sort by xL
    [xL_sorted, idx] = sort(xL_list);
    TKE_sorted = TKE_list(idx);
    
    out.xL    = xL_sorted;
    out.TKE   = TKE_sorted;
    out.label = labelStr;
    
    fprintf('  Extracted %d planes from %s\n', numel(xL_sorted), base);
end

function out = processVulcanWorkbook(filename, labelStr)
    % Process a VULCAN workbook:
    %   - all sheets treated as planes
    %   - extract xL from sheet name
    %   - average TKE in ±5 rows around Y_norm ~ 0

    fprintf('\nProcessing VULCAN workbook: %s\n', filename);
    [~, base, ~] = fileparts(filename);
    
    [status,sheets] = xlsfinfo(filename);
    if isempty(status)
        error('Could not read Excel file: %s', filename);
    end
    
    xL_list  = [];
    TKE_list = [];
    
    for iSheet = 1:numel(sheets)
        sheetName = sheets{iSheet};
        
        % No '_MP' requirement here
        xLval = parse_xL_from_name(sheetName);
        if isnan(xLval)
            fprintf('Warning: Could not parse xL from sheet "%s" in %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        T = readtable(filename, 'Sheet', sheetName);
        
        yCol  = find(strcmpi(T.Properties.VariableNames,'Y_norm'), 1);
        tkeCol = find(strcmpi(T.Properties.VariableNames,'tke'), 1);
        if isempty(tkeCol)
            tkeCol = find(strcmpi(T.Properties.VariableNames,'TKE'), 1);
        end
        
        if isempty(yCol) || isempty(tkeCol)
            fprintf('Warning: Missing Y_norm or TKE column in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        y = T{:, yCol};
        tkeData = T{:, tkeCol};
        
        [tkeAvg, success] = averageAroundYzero(y, tkeData, 5);
        if ~success
            fprintf('Warning: Could not determine Y_norm ~ 0 in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        xL_list(end+1,1)  = xLval;    %#ok<AGROW>
        TKE_list(end+1,1) = tkeAvg;   %#ok<AGROW>
    end
    
    % Sort by xL
    [xL_sorted, idx] = sort(xL_list);
    TKE_sorted = TKE_list(idx);
    
    out.xL    = xL_sorted;
    out.TKE   = TKE_sorted;
    out.label = labelStr;
    
    fprintf('  Extracted %d planes from %s\n', numel(xL_sorted), base);
end

function xL = parse_xL_from_name(sheetName)
    % Parse xL from sheet name.
    % Looks for tokens like '0p03', '1p0', '0p5', '0', '1', etc.
    % Returns NaN if no recognizable token is found.

    token = regexp(sheetName, '(?<num>\d+p?\d*)', 'names', 'once');
    
    if isempty(token)
        xL = NaN;
        return;
    end
    
    raw = token.num;
    if contains(raw, 'p')
        raw = strrep(raw, 'p', '.');
    end
    xL = str2double(raw);
    
    if isnan(xL)
        xL = NaN;
    end
end

function [tkeAvg, success] = averageAroundYzero(y, tkeData, nRows)
    % Robust averaging of TKE around Y_norm ≈ 0
    %
    % Strategy:
    %   1) If any y == 0, use the first such index as idxZero.
    %   2) Otherwise, look for a sign change from negative to positive:
    %        - Find indices i where y(i) < 0 and y(i+1) > 0.
    %        - Use i+1 (first positive after negative) as idxZero.
    %   3) If neither is found, fall back to the point closest to zero.
    %   4) Average TKE over [idxZero-nRows : idxZero+nRows] intersected
    %      with [1 : length(y)].

    success = false;
    tkeAvg  = NaN;
    
    if isempty(y) || isempty(tkeData) || numel(y) ~= numel(tkeData)
        return;
    end
    
    % 1) Exact zero if available
    idxZero = find(y == 0, 1, 'first');
    
    % 2) If no exact zero, look for sign change from negative to positive
    if isempty(idxZero)
        yNeg = y(1:end-1) < 0;
        yPos = y(2:end)   > 0;
        signChangeIdx = find(yNeg & yPos, 1, 'first');  % y(i)<0 & y(i+1)>0
        
        if ~isempty(signChangeIdx)
            idxZero = signChangeIdx + 1;  % first positive index after negative
        end
    end
    
    % 3) If still nothing, fall back to nearest-to-zero
    if isempty(idxZero)
        [~, idxZero] = min(abs(y));
    end
    
    if isempty(idxZero) || isnan(idxZero)
        return;
    end
    
    n = numel(y);
    idxStart = max(1, idxZero - nRows);
    idxEnd   = min(n, idxZero + nRows);
    
    if idxEnd < idxStart
        idxStart = idxZero;
        idxEnd   = idxZero;
    end
    
    tkeWindow = tkeData(idxStart:idxEnd);
    tkeAvg    = mean(tkeWindow, 'omitnan');
    success   = true;
end