%% extract_and_plot_TKE_script.m
% -------------------------------------------------------------------------
% Standalone script to:
% 1) Prompt for 2 Volcano and 2 VULCAN Excel workbooks (different geometries)
% 2) For each Volcano workbook:
%       - Use only sheets whose names end with '_MP'
%       - Extract xL from sheet name using regex (e.g., '0p03' -> 0.03)
%       - From each sheet, get:
%           * max TKE over all Y_norm
%           * Y_norm location of that max TKE
% 3) For each VULCAN workbook:
%       - Treat all sheets as planes (no '_MP' filter)
%       - Same max TKE and Y_norm logic
% 4) Cross-plot:
%       - Figure 1: max TKE vs x/L
%       - Figure 2: Y_norm location of max TKE vs x/L
%       - Volcano = blue lines
%       - VULCAN  = red lines
%       - Legend labels customized by workbook name
% 5) Save figures as .fig, vector .pdf, and .png
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

%% 2. Process Volcano files (max TKE and Y location)
volcanoData = struct('xL',[],'TKEmax',[],'Y_of_TKEmax',[],'label','');
for i = 1:2
    fullFile = fullfile(volcanoPath, volcanoFiles{i});
    volcanoData(i) = processVolcanoWorkbook_MaxTKE(fullFile, geomLabelsVolcano{i});
end

%% 3. Process VULCAN files (max TKE and Y location)
vulcanData = struct('xL',[],'TKEmax',[],'Y_of_TKEmax',[],'label','');
for i = 1:2
    fullFile = fullfile(vulcanPath, vulcanFiles{i});
    vulcanData(i) = processVulcanWorkbook_MaxTKE(fullFile, geomLabelsVulcan{i});
end

%% 4. Plotting: Figure 1 - Max TKE vs x/L
figure('Color','w'); hold on; grid on; box on;

% Colors per solution type (requested: Volcano blue, VULCAN red)
colVolcano = [0.0  0.45 0.74];  % blue-ish
colVulcan  = [0.85 0.10 0.10];  % red-ish

% Markers / linestyles for the two geometries
markers = {'o','s'};
lines   = {'-','--'};

% Plot Volcano data (blue)
for i = 1:2
    plot(volcanoData(i).xL, volcanoData(i).TKEmax,...
        'Color', colVolcano,...
        'LineStyle', lines{i},...
        'Marker', markers{i},...
        'LineWidth', 1.5,...
        'DisplayName', volcanoData(i).label);
end

% Plot VULCAN data (red)
for i = 1:2
    plot(vulcanData(i).xL, vulcanData(i).TKEmax,...
        'Color', colVulcan,...
        'LineStyle', lines{i},...
        'Marker', markers{i},...
        'LineWidth', 1.5,...
        'DisplayName', vulcanData(i).label);
end

% Axis labels and title (bold)
hX = xlabel('x/L','Interpreter','none', 'FontWeight','bold');
hY = ylabel('Max TKE','Interpreter','none', 'FontWeight','bold');
hT = title('VULCAN vs. Volcano: Max Shear Layer TKE vs x/L','Interpreter','none', 'FontWeight','bold');
set([hX hY hT],'FontWeight','bold');
set(hT, 'Visible', 'off');   % hides the title

legend('Location','best','Interpreter','none');

% 5. Save Figure 1
outNameBase1 = 'MaxTKE_vs_xL_Volcano_VULCAN';

savefig([outNameBase1 '.fig']);
set(gcf,'Renderer','Painters');
% print(gcf, outNameBase1, '-dpdf','-r300');
exportgraphics(gcf, [outNameBase1 '.pdf'], 'ContentType','vector');
print(gcf, outNameBase1, '-dpng','-r300');

fprintf('Figure 1 saved as:\n  %s.fig\n  %s.pdf\n  %s.png\n',...
    outNameBase1, outNameBase1, outNameBase1);

%% 6. Plotting: Figure 2 - Y location of max TKE vs x/L
figure('Color','w'); hold on; grid on; box on;

% Volcano (blue)
for i = 1:2
    plot(volcanoData(i).xL, volcanoData(i).Y_of_TKEmax,...
        'Color', colVolcano,...
        'LineStyle', lines{i},...
        'Marker', markers{i},...
        'LineWidth', 1.5,...
        'DisplayName', [volcanoData(i).label ' - y/D location']);
end

% VULCAN (red)
for i = 1:2
    plot(vulcanData(i).xL, vulcanData(i).Y_of_TKEmax,...
        'Color', colVulcan,...
        'LineStyle', lines{i},...
        'Marker', markers{i},...
        'LineWidth', 1.5,...
        'DisplayName', [vulcanData(i).label ' - y/D location']);
end

hX2 = xlabel('x/L','Interpreter','none', 'FontWeight','bold');
hY2 = ylabel('y/D of max TKE ','Interpreter','none', 'FontWeight','bold');
hT2 = title('VULCAN vs. Volcano: y/D location of Max TKE vs x/L','Interpreter','none', 'FontWeight','bold');
set([hX2 hY2 hT2],'FontWeight','bold');
set(hT2, 'Visible', 'off');   % hides the title

legend('Location','best','Interpreter','none');

% Save Figure 2
outNameBase2 = 'Yloc_of_MaxTKE_vs_xL_Volcano_VULCAN';

savefig([outNameBase2 '.fig']);
set(gcf,'Renderer','Painters');
% print(gcf, outNameBase2, '-dpdf','-r300');
exportgraphics(gcf, [outNameBase2 '.pdf'], 'ContentType','vector')
print(gcf, outNameBase2, '-dpng','-r300');

fprintf('Figure 2 saved as:\n  %s.fig\n  %s.pdf\n  %s.png\n',...
    outNameBase2, outNameBase2, outNameBase2);

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

function out = processVolcanoWorkbook_MaxTKE(filename, labelStr)
    % Process a Volcano workbook:
    %   - only sheets whose names end with '_MP'
    %   - extract xL from sheet name
    %   - for each sheet, find:
    %       * max TKE over all Y_norm
    %       * Y_norm location of that max

    fprintf('\nProcessing Volcano workbook (max TKE): %s\n', filename);
    [~, base, ~] = fileparts(filename);
    
    [status,sheets] = xlsfinfo(filename);
    if isempty(status)
        error('Could not read Excel file: %s', filename);
    end
    
    xL_list        = [];
    TKEmax_list    = [];
    Y_of_TKEmax    = [];
    
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
        yCol   = find(strcmpi(T.Properties.VariableNames,'Y_norm'), 1);
        tkeCol = find(strcmpi(T.Properties.VariableNames,'tke'), 1);
        if isempty(tkeCol)
            tkeCol = find(strcmpi(T.Properties.VariableNames,'TKE'), 1);
        end
        
        if isempty(yCol) || isempty(tkeCol)
            fprintf('Warning: Missing Y_norm or TKE column in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        y       = T{:, yCol};
        tkeData = T{:, tkeCol};
        
        if isempty(y) || isempty(tkeData)
            fprintf('Warning: Empty data in sheet "%s" of %s. Skipping.\n', sheetName, base);
            continue;
        end
        
        % Find max TKE and its Y_norm location
        [tkeMaxVal, idxMax] = max(tkeData, [], 'omitnan');
        if isempty(idxMax) || isnan(tkeMaxVal)
            fprintf('Warning: Could not find max TKE in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        yAtMax = y(idxMax);
        
        xL_list(end+1,1)     = xLval;     %#ok<AGROW>
        TKEmax_list(end+1,1) = tkeMaxVal; %#ok<AGROW>
        Y_of_TKEmax(end+1,1) = yAtMax;    %#ok<AGROW>
    end
    
    % Sort by xL
    [xL_sorted, idx] = sort(xL_list);
    TKEmax_sorted    = TKEmax_list(idx);
    Y_sorted         = Y_of_TKEmax(idx);
    
    out.xL          = xL_sorted;
    out.TKEmax      = TKEmax_sorted;
    out.Y_of_TKEmax = Y_sorted;
    out.label       = labelStr;
    
    fprintf('  Extracted %d planes from %s\n', numel(xL_sorted), base);
end

function out = processVulcanWorkbook_MaxTKE(filename, labelStr)
    % Process a VULCAN workbook:
    %   - all sheets treated as planes
    %   - extract xL from sheet name
    %   - for each sheet, find:
    %       * max TKE over all Y_norm
    %       * Y_norm location of that max

    fprintf('\nProcessing VULCAN workbook (max TKE): %s\n', filename);
    [~, base, ~] = fileparts(filename);
    
    [status,sheets] = xlsfinfo(filename);
    if isempty(status)
        error('Could not read Excel file: %s', filename);
    end
    
    xL_list        = [];
    TKEmax_list    = [];
    Y_of_TKEmax    = [];
    
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
        
        yCol   = find(strcmpi(T.Properties.VariableNames,'Y_norm'), 1);
        tkeCol = find(strcmpi(T.Properties.VariableNames,'tke'), 1);
        if isempty(tkeCol)
            tkeCol = find(strcmpi(T.Properties.VariableNames,'TKE'), 1);
        end
        
        if isempty(yCol) || isempty(tkeCol)
            fprintf('Warning: Missing Y_norm or TKE column in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        y       = T{:, yCol};
        tkeData = T{:, tkeCol};
        
        if isempty(y) || isempty(tkeData)
            fprintf('Warning: Empty data in sheet "%s" of %s. Skipping.\n', sheetName, base);
            continue;
        end
        
        [tkeMaxVal, idxMax] = max(tkeData, [], 'omitnan');
        if isempty(idxMax) || isnan(tkeMaxVal)
            fprintf('Warning: Could not find max TKE in sheet "%s" of %s. Skipping.\n',...
                sheetName, base);
            continue;
        end
        
        yAtMax = y(idxMax);
        
        xL_list(end+1,1)     = xLval;     %#ok<AGROW>
        TKEmax_list(end+1,1) = tkeMaxVal; %#ok<AGROW>
        Y_of_TKEmax(end+1,1) = yAtMax;    %#ok<AGROW>
    end
    
    % Sort by xL
    [xL_sorted, idx] = sort(xL_list);
    TKEmax_sorted    = TKEmax_list(idx);
    Y_sorted         = Y_of_TKEmax(idx);
    
    out.xL          = xL_sorted;
    out.TKEmax      = TKEmax_sorted;
    out.Y_of_TKEmax = Y_sorted;
    out.label       = labelStr;
    
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