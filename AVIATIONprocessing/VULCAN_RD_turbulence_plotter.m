%% VULCAN_RD_turbulence_plotter.m
% Script to:
%   1) Select 3 Excel workbooks via GUI of complete VULCAN cavity data.
%   2) For EACH sheet (e.g. xL_0p03) in the workbook, assumed to represent
%      a unique axial location, extract:
%          - Y_norm
%          - Density
%          - TKE
%          - Rxx
%          - Ryy
%          - Rzz
%   3) For each (axial location, quantity), generate overlaid plots of
%      quantity vs Y_norm (quantity on x-axis, Y_norm on y-axis) where each
%      line is one geometry (3 total).
%   4) Save figures to a root directory.

clear; clc;

%% ------------------------------------------------------------------------
% 1) GUI SELECTION OF 3 EXCEL FILES
% -------------------------------------------------------------------------
[filenames, pathname] = uigetfile({...
    '*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'},...
    'Select 3 VULCAN Excel files (one per edge case)',...
    'MultiSelect', 'on');

if isequal(filenames,0) || isequal(pathname,0)
    disp('User canceled file selection. Exiting script.');
    return;
end

% Ensure filenames is a cell array
if ischar(filenames)
    filenames = {filenames};
end

if numel(filenames) ~= 3
    errordlg('You must select exactly 3 Excel files. Please run again.','File Selection Error');
    return;
end

excelFiles = cellfun(@(f) fullfile(pathname, f), filenames, 'UniformOutput', false);

fprintf('Selected Excel files:\n');
for k = 1:numel(excelFiles)
    fprintf('  %s\n', excelFiles{k});
end
fprintf('\n');

%% ------------------------------------------------------------------------
% 2) GEOMETRY LABELS (BASE) AND LEGEND LABELS
% -------------------------------------------------------------------------
geomLabels = {'RD00','RD17','RD52'};

if numel(geomLabels) ~= numel(excelFiles)
    error('geomLabels must have the same length as the number of selected files (3).');
end

legendLabels = {'$$R/D = 0.0$$','$$R/D = 0.17$$','$$R/D = 0.52$$'};

%% ------------------------------------------------------------------------
% 3) DETERMINE AXIAL LOCATIONS FROM SHEET NAMES
%    We assume every sheet (except US/DS etc.) is one axial location.
%    Sheet naming example: "xL_0p03" -> $$x/L = 0.03$$
% -------------------------------------------------------------------------
[firstDir,~,~] = fileparts(excelFiles{1});
if isempty(firstDir)
    firstDir = pwd;
end

try
    [~, sheetNames1] = xlsfinfo(excelFiles{1});
catch ME
    error('Error reading Excel file "%s": %s', excelFiles{1}, ME.message);
end

if isempty(sheetNames1)
    error('No sheets found in first Excel file: %s', excelFiles{1});
end

% Filter out US/DS or other unwanted prefixes if needed
axialLocs = {'xL_0p17', 'xL_0p59', 'xL_0p86', 'xL_1p2'};


fprintf('Using axial locations:\n  %s\n\n', strjoin(axialLocs, ', '));

%% ------------------------------------------------------------------------
% 4) Root output directory
% -------------------------------------------------------------------------
rootOutDir = fullfile(firstDir, 'TurbulenceFigures_RD');
if ~exist(rootOutDir,'dir')
    mkdir(rootOutDir);
end

% Quantities and fields (table column names expected in each sheet)
% NOTE: Rxx/Ryy/Rzz will be transformed in plotting stage by /(-Density)
qtyNames  = {'TKE','Rxx','Ryy','Rzz'};

%% ------------------------------------------------------------------------
% 5) READ AND ORGANIZE DATA FROM EACH WORKBOOK
% dataStruct(g).(axialID) = table(Y_norm, Density, TKE, Rxx, Ryy, Rzz)
% -------------------------------------------------------------------------
nGeom = numel(excelFiles);
dataStruct = cell(nGeom,1);

for g = 1:nGeom
    excelFile = excelFiles{g};
    fprintf('Reading workbook %d/%d: %s\n', g, nGeom, excelFile);
    dataStruct{g} = readWorkbookAllSheets(excelFile, axialLocs);
end

%% ------------------------------------------------------------------------
% 6) PLOTTING: OVERLAYS ACROSS GEOMETRIES
% For each axial location and quantity:
%   plot quantity vs Y_norm for all 3 geometries on the same figure
%   Logic:
%     1) Remove duplicates in quantity
%     2) Sort by Y_norm
%     3) Remove NaNs
%     4) Interpolate vs Y_norm
% -------------------------------------------------------------------------

geomColors = lines(nGeom);   % nGeom x 3 RGB matrix
lineWidth  = 1.8;

for iA = 1:numel(axialLocs)
    axialID = axialLocs{iA};
    axialLabelLatex = formatAxialLabel(axialID);  % e.g. '$$x/L = 0.03$$'

    for iQ = 1:numel(qtyNames)
        qName  = qtyNames{iQ};

        fig = figure('Visible','off');
        hold on; grid on; box on;
        set(fig, 'Color','w');

        legendEntries = {};

        % Loop over geometries
        for g = 1:nGeom
            geomData = dataStruct{g};

            % Check if this axialID exists for this geometry
            if ~isfield(geomData, axialID)
                continue;
            end

            T = geomData.(axialID);
            neededCols = {'Y_norm','Density','TKE','Rxx','Ryy','Rzz'};
            if isempty(T) || ~all(ismember(neededCols, T.Properties.VariableNames))
                continue;
            end

            y = T.Y_norm;

            % Select quantity and apply transformation for Reynolds stresses
            switch qName
                case 'TKE'
                    qv = T.TKE;
                case 'Rxx'
                    qv = T.Rxx./ (-T.Density);  % Rxx_plot = Rxx / (-Density)
                case 'Ryy'
                    qv = T.Ryy./ (-T.Density);
                case 'Rzz'
                    qv = T.Rzz./ (-T.Density);

                otherwise
                    continue;
            end

            % ---------------------------------------------------------
            % Cleaning and Interpolation Logic:
            %   1) Remove duplicates in quantity
            %   2) Sort by Y_norm
            %   3) Remove NaN
            %   4) Interpolate to smooth Y_norm grid
            % ---------------------------------------------------------

            % 1) Remove duplicates in the quantity (keep first occurrence)
            [qv_unique, ia] = unique(qv, 'stable');
            y_unique = y(ia);

            % 2) Sort by Y_norm
            [y_sorted, idxSort] = sort(y_unique);
            q_sorted = qv_unique(idxSort);

            % 3) Remove NaN entries
            valid = ~isnan(y_sorted) & ~isnan(q_sorted);
            y_valid = y_sorted(valid);
            q_valid = q_sorted(valid);

            if numel(y_valid) < 2
                % Not enough points to interpolate
                if ~isempty(y_valid)
                    plot(q_valid, y_valid, 'o',...
                        'LineWidth', lineWidth,...
                        'Color', geomColors(g,:));
                    legendEntries{end+1} = legendLabels{g}; %#ok<AGROW>
                end
                continue;
            end

            % 4) Interpolate to a smooth Y_norm grid
            yq = linspace(min(y_valid), max(y_valid), 300);
            q_interp = interp1(y_valid, q_valid, yq, 'linear', 'extrap');

            % Plot quantity on x-axis, Y_norm on y-axis
            plot(q_interp, yq,...
                'LineWidth', lineWidth,...
                'Color', geomColors(g,:));

            legendEntries{end+1} = legendLabels{g}; %#ok<AGROW>
        end

        % Axis labeling (quantity on x, Y_norm on y)
        switch qName
            case 'TKE'
                xLabelStr = '$$TKE$$ (J/kg)';
            case 'Rxx'
                xLabelStr = '$$R_{xx}$$ (Pa)';
            case 'Ryy'
                xLabelStr = '$$R_{yy}$$ (Pa)';
            case 'Rzz'
                xLabelStr = '$$R_{zz}$$ (Pa)';
        end
        yLabelStr = '$$Y/D$$';

        xlabel(xLabelStr, 'Interpreter','latex');
        ylabel(yLabelStr, 'Interpreter','latex');

        % Title with formatted axial ID
        % Example: 'Rxx/(-rho) vs Y_norm at x/L = 0.03'
        titleStr = sprintf('%s vs $$Y/D$$ at %s', qName, axialLabelLatex);
        title(titleStr, 'Interpreter','latex');

        if ~isempty(legendEntries)
            legend(legendEntries, 'Interpreter','latex', 'Location','best');
        end

        % Filename pattern: <Q>_<axial>_RDsweep
        safeAxial = strrep(axialID, '/', '_');
        baseName  = sprintf('%s_%s_RDsweep', qName, safeAxial);
        pngFile   = fullfile(rootOutDir, [baseName '.png']);
        figFile   = fullfile(rootOutDir, [baseName '.fig']);

        saveas(fig, pngFile);
        savefig(fig, figFile);
        close(fig);
    end
end

fprintf('\nAll figures saved under:\n  %s\n', rootOutDir);

%% ========================================================================
% LOCAL FUNCTION: READ ONE WORKBOOK (ALL SHEETS)
% ========================================================================
function geomData = readWorkbookAllSheets(excelFile, axialLocs)
% readWorkbookAllSheets
%   Reads a single Excel workbook, extracts tables for requested axial
%   locations (each sheet), and stores them as:
%
%   geomData.(axialID) = table(Y_norm, Density, TKE, Rxx, Ryy, Rzz)

    geomData = struct();

    try
        [~, sheetNames] = xlsfinfo(excelFile);
    catch ME
        error('Error reading Excel file "%s": %s', excelFile, ME.message);
    end

    if isempty(sheetNames)
        warning('No sheets found in Excel file: %s', excelFile);
        return;
    end

    neededCols = {'Y_norm','Density','TKE','Rxx','Ryy','Rzz'};

    for iS = 1:numel(sheetNames)
        sName = sheetNames{iS};

        % Only keep requested axial locations (from first workbook)
        if ~ismember(sName, axialLocs)
            continue;
        end

        % Read sheet
        try
            T = readtable(excelFile, 'Sheet', sName);
        catch ME
            warning('Could not read sheet "%s" in "%s": %s', sName, excelFile, ME.message);
            continue;
        end

        % Ensure needed columns exist
        missing = setdiff(neededCols, T.Properties.VariableNames);
        if ~isempty(missing)
            warning('Sheet "%s" in "%s" missing columns (%s). Skipping.',...
                sName, excelFile, strjoin(missing, ', '));
            continue;
        end

        Tsel = T(:, neededCols);
        geomData.(sName) = Tsel;
    end
end

%% ========================================================================
% LOCAL FUNCTION: FORMAT AXIAL LABEL
% ========================================================================
function lbl = formatAxialLabel(axialID)
% formatAxialLabel
% Convert an axial ID like 'xL_0p03' to a LaTeX string '$$x/L = 0.03$$'.
% If the pattern is not recognized, just return the raw axialID.
%
% Expected pattern examples:
%   'xL0p03'   -> 0.03
%   'xL_0p03'  -> 0.03
%   'xL1p00'   -> 1.00

    axialID = strtrim(axialID);

    % Remove optional underscore after 'xL'
    if startsWith(axialID, 'xL_')
        numStr = axialID(4:end);           % strip 'xL_'
    elseif startsWith(axialID, 'xL')
        numStr = axialID(3:end);           % strip 'xL'
    else
        % Fallback: return the axialID as-is (no special formatting)
        lbl = axialID;
        return;
    end

    numStr = strrep(numStr, 'p', '.'); % replace 'p' with '.'
    lbl = sprintf('$$x/L = %s$$', numStr);
end