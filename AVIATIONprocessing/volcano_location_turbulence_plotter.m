%% volcano_location_turbulence_plotter.m
% Script to:
%   1) Select Excel file via GUI
%   2) Specify 3 axial locations via GUI
%   3) Generate turbulence plots (Y_norm vs TKE/Rxx/Ryy/Rzz)
%      using the logic in the core function below.

clear; clc;

%% ------------------------------------------------------------------------
% 1. Select Excel file via GUI
% -------------------------------------------------------------------------
[filename, pathname] = uigetfile({'*.xlsx;*.xls','Excel Files (*.xlsx, *.xls)'},...
                                 'Select the Volcano probe Excel file');
if isequal(filename,0) || isequal(pathname,0)
    disp('User canceled file selection. Exiting script.');
    return;
end

excelFile = fullfile(pathname, filename);
fprintf('Selected Excel file:\n  %s\n\n', excelFile);

%% ------------------------------------------------------------------------
% 2. Get 3 axial locations via GUI
%    These must match the prefixes used in the sheet names (before "_MP",
%    "_z25", "_z75"), e.g., "x10", "x20", "x30" or "0.1", "0.2", "0.3".
% -------------------------------------------------------------------------
% prompt = {...
%     'Axial location 1 (sheet prefix before underscore):',...
%     'Axial location 2 (sheet prefix before underscore):',...
%     'Axial location 3 (sheet prefix before underscore):'...
%     };
% dlgTitle = 'Specify 3 axial locations';
% numLines = 1;
% defaultAns = {'x10','x20','x30'};  % edit as you like
% 
% answer = inputdlg(prompt, dlgTitle, numLines, defaultAns);
% 
% if isempty(answer)
%     disp('User canceled axial location input. Exiting script.');
%     return;
% end

% axialLocsForSpanwise = answer(:)';  % row cell array of 3 strings
axialLocsForSpanwise = {'xL0p17', 'xL0p59','xL1'};
if numel(axialLocsForSpanwise) ~= 3
    error('You must specify exactly 3 axial locations.');
end

fprintf('Using axial locations:\n  %s\n\n', strjoin(axialLocsForSpanwise, ', '));

%% ------------------------------------------------------------------------
% 3. Call the core plotting routine
% -------------------------------------------------------------------------
volcano_location_turbulence_plotter_core(excelFile, filename, axialLocsForSpanwise);

%% ========================================================================
% Local function: core logic (based on your provided function)
% ========================================================================
function volcano_location_turbulence_plotter_core(excelFile, filename, axialLocsForSpanwise)
% volcano_location_turbulence_plotter_core
% 
% PARAMETERS
%   excelFile            : Full or relative path to the input.xlsx file
%   filename             : Name of the file string
%   axialLocsForSpanwise : Cell array of strings with 3 axial locations to compare
%                          e.g. {'x10','x20','x30'} or {'0.1','0.2','0.3'}
%
% FUNCTIONALITY
%   1. Reads all sheets from the Excel file.
%   2. Ignores sheets whose names start with 'US' or 'DS'.
%   3. Extracts columns:
%        - Y_norm
%        - reynoldsstressxx
%        - reynoldsstressyy
%        - reynoldsstresszz
%        - tke
%   4. Builds three tables grouping data by sheet suffix:
%        - *_MP
%        - *_z25
%        - *_z75
%   5. For each spanwise group (_MP, _z25, _z75), creates overlay plots of
%        - Y_norm vs TKE 
%        - Y_norm vs Rxx 
%        - Y_norm vs Ryy
%        - Y_norm vs Rzz
%      where each line corresponds to an axial location (from sheet name).
%   6. For three specified axial locations, creates spanwise comparison figures:
%        - Y_norm vs TKE
%        - Y_norm vs Rxx
%        - Y_norm vs Ryy
%        - Y_norm vs Rzz
%      where each figure has 9 lines:
%        (3 axial locations) x (3 spanwise locations: MP, z25, z75)
%   7. Saves figures as.png and.fig under:
%        <excelDir>/Turbulence Figures/...
%
% NOTE: Plots are "inverted" relative to your original description:
%       quantity (TKE/Rxx/Ryy/Rzz) on x-axis, Y_norm on y-axis.

    if nargin < 2
        error('You must provide excelFile and axialLocsForSpanwise (3 axial IDs).');
    end
    if numel(axialLocsForSpanwise) ~= 3
        error('axialLocsForSpanwise must be a cell array with exactly 3 axial location strings.');
    end

    %----------------------------------------------------------------------
    % Setup paths and output folders
    %----------------------------------------------------------------------
    [excelDir, ~, ~] = fileparts(excelFile);
    if isempty(excelDir)
        excelDir = pwd;
    end

    nameParts = strsplit(filename, '_');

    rootOutDir = fullfile(excelDir, sprintf('Turbulence Figures %s',string(nameParts(1))));
    if ~exist(rootOutDir, 'dir')
        mkdir(rootOutDir);
    end

    % Subfolders for axial overlays
    spanOverlayDir = fullfile(rootOutDir, 'VolcanoAxialOverlays');
    if ~exist(spanOverlayDir, 'dir'); mkdir(spanOverlayDir); end

    % Subfolders for spanwise comparison at specific axial locations
    axialSpanCompDir = fullfile(rootOutDir, 'VolcanoSpanwiseOverlays');
    if ~exist(axialSpanCompDir, 'dir'); mkdir(axialSpanCompDir); end

    % Further organize by quantity
    qtyNames = {'TKE','Rxx','Ryy','Rzz'};
    qtyFields = {'tke','reynoldsstressxx','reynoldsstressyy','reynoldsstresszz'};
    qtySpanDir = struct();
    qtyAxialSpanDir = struct();
    for iQ = 1:numel(qtyNames)
        qName = qtyNames{iQ};
        sDir = fullfile(spanOverlayDir, qName);
        aDir = fullfile(axialSpanCompDir, qName);
        if ~exist(sDir, 'dir'); mkdir(sDir); end
        if ~exist(aDir, 'dir'); mkdir(aDir); end
        qtySpanDir.(qName) = sDir;
        qtyAxialSpanDir.(qName) = aDir;
    end

    %----------------------------------------------------------------------
    % Read sheet names
    %----------------------------------------------------------------------
    try
        [~, sheetNames] = xlsfinfo(excelFile);
    catch ME
        error('Error reading Excel file "%s": %s', excelFile, ME.message);
    end

    if isempty(sheetNames)
        error('No sheets found in Excel file: %s', excelFile);
    end

    %----------------------------------------------------------------------
    % Containers for data by spanwise suffix: _MP, _z25, _z75
    %----------------------------------------------------------------------
    data_MP  = struct();
    data_z25 = struct();
    data_z75 = struct();

    %----------------------------------------------------------------------
    % Loop over sheets and load data
    %----------------------------------------------------------------------
    for iS = 1:numel(sheetNames)
        sName = sheetNames{iS};

        % Skip sheets beginning with "US" or "DS"
        if startsWith(sName, 'US', 'IgnoreCase', true) ||...
           startsWith(sName, 'DS', 'IgnoreCase', true)
            continue;
        end

        % Parse sheet name to separate axial and span suffix
        underscoreIdx = strfind(sName, '_');
        if isempty(underscoreIdx)
            warning('Sheet "%s" ignored because it has no underscore.', sName);
            continue;
        end

        axialPart = sName(1:underscoreIdx(end)-1);
        spanSuffix = sName(underscoreIdx(end)+1:end);

        % Keep only the suffix variants of interest
        if ~ismember(spanSuffix, {'MP','z25','z75'})
            continue;
        end

        % Read the sheet as table
        try
            T = readtable(excelFile, 'Sheet', sName);
        catch ME
            warning('Could not read sheet "%s": %s', sName, ME.message);
            continue;
        end

        % Check necessary columns exist
        neededCols = {'Y_norm','reynoldsstressxx','reynoldsstressyy','reynoldsstresszz','tke'};
        missing = setdiff(neededCols, T.Properties.VariableNames);
        if ~isempty(missing)
            warning('Sheet "%s" missing columns: %s. Skipping.', sName, strjoin(missing, ', '));
            continue;
        end

        % Keep only the relevant columns
        Tsel = T(:, neededCols);

        % Assign into corresponding struct
        switch spanSuffix
            case 'MP'
                data_MP.(axialPart) = Tsel;
            case 'z25'
                data_z25.(axialPart) = Tsel;
            case 'z75'
                data_z75.(axialPart) = Tsel;
        end
    end

    %----------------------------------------------------------------------
    % Convert structs to tables describing the mapping (metadata tables)
    %----------------------------------------------------------------------
    tbl_MP  = buildCollectionTable(data_MP);
    tbl_z25 = buildCollectionTable(data_z25);
    tbl_z75 = buildCollectionTable(data_z75);

    %----------------------------------------------------------------------
    % 1) Overlay plots by spanwise location (MP, z25, z75)
    %----------------------------------------------------------------------
    createSpanwiseOverlays(tbl_MP,  'MP',  qtyNames, qtyFields, qtySpanDir);
    createSpanwiseOverlays(tbl_z25,'z25', qtyNames, qtyFields, qtySpanDir);
    createSpanwiseOverlays(tbl_z75,'z75', qtyNames, qtyFields, qtySpanDir);

    %----------------------------------------------------------------------
    % 2) For 3 specified axial locations, create spanwise comparison plots
    %----------------------------------------------------------------------
    dataMap.MP  = structToMap(data_MP);
    dataMap.z25 = structToMap(data_z25);
    dataMap.z75 = structToMap(data_z75);

    createAxialSpanwiseComparisons(axialLocsForSpanwise, dataMap, qtyNames, qtyFields, qtyAxialSpanDir);

    fprintf('Processing complete. Figures saved under:\n  %s\n', rootOutDir);
end

%% ========================================================================
% Helper: Build a metadata table from a struct of tables
% ========================================================================
function tbl = buildCollectionTable(S)
    axialNames = fieldnames(S);
    n = numel(axialNames);
    AxialLocation = strings(n,1);
    Data = cell(n,1);
    for i = 1:n
        AxialLocation(i) = axialNames{i};
        Data{i} = S.(axialNames{i});
    end
    tbl = table(AxialLocation, Data, 'VariableNames', {'AxialLocation','Data'});
end

%% ========================================================================
% Helper: Convert a struct of tables into a containers.Map
% ========================================================================
function M = structToMap(S)
    M = containers.Map;
    f = fieldnames(S);
    for i = 1:numel(f)
        M(f{i}) = S.(f{i});
    end
end

%% ========================================================================
% Helper: Create overlay plots for all axial locations at a given spanwise
%          location (_MP, _z25, _z75).
%          (Inverted: quantity on x-axis, Y_norm on y-axis)
% ========================================================================
function createSpanwiseOverlays(tbl, spanSuffix, qtyNames, qtyFields, qtySpanDir)
    if isempty(tbl)
        return;
    end

    % Line style pattern: groups of 3
    lineStyles = {'-','--',':'};
    % Color pattern per group of 3 curves (you can customize)
    baseColors = lines(3);   % will be cycled if more than 9 lines

    for iQ = 1:numel(qtyNames)
        qName  = qtyNames{iQ};
        qField = qtyFields{iQ};
        outDir = qtySpanDir.(qName);

        fig = figure('Visible','off');
        hold on; grid on; box on;
        set(fig, 'Color','w');

        legends = cell(height(tbl),1);

        for iRow = 1:height(tbl)
            axial = tbl.AxialLocation(iRow);
            T = tbl.Data{iRow};

            if ~ismember(qField, T.Properties.VariableNames)
                continue;
            end

            y  = T.Y_norm;
            qv = T.(qField);

            % --- 1) PRUNE DUPLICATE VALUES FOR THIS QUANTITY ----------------
            [qv_unique, ia] = unique(qv, 'stable');
            y_unique = y(ia);
            % -----------------------------------------------------------------

            % --- 2) SORT BY Y_norm AND REMOVE NaNs ---------------------------
            [y_sorted, idxSort] = sort(y_unique);
            q_sorted = qv_unique(idxSort);

            valid = ~isnan(y_sorted) & ~isnan(q_sorted);
            y_valid = y_sorted(valid);
            q_valid = q_sorted(valid);
            % -----------------------------------------------------------------

            if numel(y_valid) < 2
                if ~isempty(y_valid)
                    % Assign style/color even for single points
                    groupIdx   = floor((iRow-1)/3);                     % 0,1,2,...
                    colorIdx   = mod(groupIdx, size(baseColors,1)) + 1; % cycle colors
                    styleIdx   = mod(iRow-1, 3) + 1;                     % 1,2,3 repeat

                    plot(q_valid, y_valid, 'o',...
                        'LineWidth', 1.5,...
                        'Color', baseColors(colorIdx,:),...
                        'LineStyle', lineStyles{styleIdx});

                    legends{iRow} = formatAxialLabel(char(axial));
                end
                continue;
            end

            % --- 3) INTERPOLATE TO A SMOOTH Y_norm GRID ---------------------
            yq = linspace(min(y_valid), max(y_valid), 300);
            q_interp = interp1(y_valid, q_valid, yq, 'linear', 'extrap');
            % -----------------------------------------------------------------

            % Determine color and line style for this axial location
            groupIdx   = floor((iRow-1)/3);                     % 0,1,2,...
            colorIdx   = mod(groupIdx, size(baseColors,1)) + 1; % cycle colors per 3
            styleIdx   = mod(iRow-1, 3) + 1;                     % -, --, : within group

            % INVERTED: quantity on x-axis, Y_norm on y-axis
            plot(q_interp, yq,...
                 'LineWidth', 1.5,...
                 'Color', baseColors(colorIdx,:),...
                 'LineStyle', lineStyles{styleIdx});

            % LaTeX legend label for this axial location (e.g. '$$x/L = 0.03$$')
            legends{iRow} = formatAxialLabel(char(axial));
        end

        % Spanwise label for title
        switch spanSuffix
            case 'z25'
                spanTitle = 'z/w = 0.25';
            case 'MP'
                spanTitle = 'z/w = 0.50';
            case 'z75'
                spanTitle = 'z/w = 0.75';
            otherwise
                spanTitle = spanSuffix;
        end

        % Axis labels and titles
        switch qName
            case 'TKE'
                xlabel('$$TKE$$ (J/kg)', 'Interpreter','latex');
                title(sprintf('$$TKE$$ vs $$Y/D$$ at %s', spanTitle), 'Interpreter','latex');
                xlim([0 20000])
            case 'Rxx'
                xlabel('$$R_{xx}$$ (Pa)', 'Interpreter','latex');
                title(sprintf('$$R_{xx}$$ vs $$Y/D$$ at %s', spanTitle), 'Interpreter','latex');
                xlim([0 25000])
            case 'Ryy'
                xlabel('$$R_{yy}$$ (Pa)', 'Interpreter','latex');
                title(sprintf('$$R_{yy}$$ vs $$Y/D$$ at %s', spanTitle), 'Interpreter','latex');
                xlim([0 10000])
            case 'Rzz'
                xlabel('$$R_{zz}$$ (Pa)', 'Interpreter','latex');
                title(sprintf('$$R_{zz}$$ vs $$Y/D$$ at %s', spanTitle), 'Interpreter','latex');
                xlim([0 25000])
        end
        ylabel('$$Y/D$$', 'Interpreter','latex');
        

        legends = legends(~cellfun(@isempty, legends));
        if ~isempty(legends)
            legend(legends, 'Interpreter','latex', 'Location','best');
        end

        baseFileName = sprintf('%s_%s_overlay_volcano', qName, spanSuffix); 
        pngFile = fullfile(outDir, [baseFileName '.png']);
        figFile = fullfile(outDir, [baseFileName '.fig']);

        saveas(fig, pngFile);
        savefig(fig, figFile);
        close(fig);
    end
end

%% ========================================================================
% Helper: Create spanwise comparison plots for specified axial locations.
%          (Inverted: quantity on x-axis, Y_norm on y-axis)
% ========================================================================
function createAxialSpanwiseComparisons(axialLocs, dataMap, qtyNames, qtyFields, qtyAxialDir)

    spanNames   = {'MP','z25','z75'};
    % Legend labels for planes
    spanLabels  = {'z/w = 0.5','z/w = 0.25','z/w = 0.75'};
    % Fixed colors per plane (MP, z25, z75)
    planeColors = lines(3);  % planeColors(1,:) -> MP, (2,:) -> z25, (3,:) -> z75

    % Line styles per axial location
    lineStyles = {'-','--',':'};  % axialLocs{1}, axialLocs{2}, axialLocs{3}

    for iQ = 1:numel(qtyNames)
        qName  = qtyNames{iQ};
        qField = qtyFields{iQ};
        outDir = qtyAxialDir.(qName);

        fig = figure('Visible','off');
        hold on; grid on; box on;
        set(fig, 'Color','w');

        legendEntries = {};

        for iA = 1:numel(axialLocs)
            axialID = axialLocs{iA};
            styleIdx = min(iA, numel(lineStyles)); % safety

            for iS = 1:numel(spanNames)
                spanKey = spanNames{iS}; % 'MP','z25','z75'
                mapForSpan = dataMap.(spanKey);

                if ~isKey(mapForSpan, axialID)
                    continue;
                end

                T = mapForSpan(axialID);
                if ~ismember(qField, T.Properties.VariableNames)
                    continue;
                end

                y  = T.Y_norm;
                qv = T.(qField);

                % --- 1) PRUNE DUPLICATE VALUES FOR THIS QUANTITY ------------
                [qv_unique, ia] = unique(qv, 'stable');
                y_unique = y(ia);
                % -----------------------------------------------------------------

                % --- 2) SORT BY Y_norm AND REMOVE NaNs -----------------------
                [y_sorted, idxSort] = sort(y_unique);
                q_sorted = qv_unique(idxSort);

                valid = ~isnan(y_sorted) & ~isnan(q_sorted);
                y_valid = y_sorted(valid);
                q_valid = q_sorted(valid);
                % -----------------------------------------------------------------

                if numel(y_valid) < 2
                    if ~isempty(y_valid)
                        plot(q_valid, y_valid, 'o',...
                             'LineWidth', 1.5,...
                             'Color', planeColors(iS,:));
                        axialLbl = formatAxialLabel(axialID);
                        legendEntries{end+1} = sprintf('%s, %s', axialLbl, spanLabels{iS}); %#ok<AGROW>
                    end
                    continue;
                end

                % --- 3) INTERPOLATE TO A SMOOTH Y_norm GRID -----------------
                % yq = linspace(min(y_valid), max(y_valid), 300);
                % q_interp = interp1(y_valid, q_valid, yq, 'linear', 'extrap');
                % -----------------------------------------------------------------

                % INVERTED: quantity on x-axis, Y_norm on y-axis
                plot(q_valid, y_valid,...
                     'LineWidth', 1.5,...
                     'Color', planeColors(iS,:),...      % same color for same plane
                     'LineStyle', lineStyles{styleIdx});  % line style by axial location

                % Legend entry: axial + plane
                axialLbl = formatAxialLabel(axialID);
                legendEntries{end+1} = sprintf('%s, %s', axialLbl, spanLabels{iS}); %#ok<AGROW>
            end
        end

        % Axis labels / titles + x-limits
        switch qName
            case 'TKE'
                xlabel('$$TKE$$ (J/kg)', 'Interpreter','latex');
                title('$$TKE$$ vs $$Y/D$$, Spanwise Comparison',...
                      'Interpreter','latex');
                xlim([0 25000])
            case 'Rxx'
                xlabel('$$R_{xx}$$ (Pa)', 'Interpreter','latex');
                title('$$R_{xx}$$ vs $$Y/D$$, Spanwise Comparison',...
                      'Interpreter','latex');
                xlim([0 25000])
            case 'Ryy'
                xlabel('$$R_{yy}$$ (Pa)', 'Interpreter','latex');
                title('$$R_{yy}$$ vs $$Y/D$$, Spanwise Comparison',...
                      'Interpreter','latex');
                xlim([0 10000])
            case 'Rzz'
                xlabel('$$R_{zz}$$ (Pa)', 'Interpreter','latex');
                title('$$R_{zz}$$ vs $$Y/D$$, Spanwise Comparison',...
                      'Interpreter','latex');
                xlim([0 20000])
        end
        ylabel('$$Y/D$$', 'Interpreter','latex');

        if ~isempty(legendEntries)
            legend(legendEntries, 'Interpreter','latex', 'Location','best');
        end

        axialTag = strjoin(axialLocs, '_');
        baseFileName = sprintf('%s_spanwiseComparison_%s_volcano', qName, axialTag);
        pngFile = fullfile(outDir, [baseFileName '.png']);
        figFile = fullfile(outDir, [baseFileName '.fig']);

        saveas(fig, pngFile);
        savefig(fig, figFile);
        close(fig);
    end
end

function lbl = formatAxialLabel(axialID)
% formatAxialLabel
% Convert an axial ID like 'xL0p03' to a LaTeX string '\frac{x}{L} = 0.03'.
% If the pattern is not recognized, just return the raw axialID.
%
% Expected pattern: 'xL' + number with 'p' as decimal point
%   e.g., 'xL0p03' -> 0.03, 'xL1p00' -> 1.00

    axialID = strtrim(axialID);

    if startsWith(axialID, 'xL')
        numStr = axialID(3:end);          % strip 'xL'
        numStr = strrep(numStr, 'p', '.');% replace 'p' with '.'
        lbl = sprintf('$$x/L = %s$$', numStr);
    else
        % Fallback: return the axialID as-is (no special formatting)
        lbl = axialID;
    end
end