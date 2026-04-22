%% volcano_RD_turbulence_plotter.m
% Script to:
%   1) Select 3 Excel workbooks via GUI of complete cavity data.
%   2) For specified axial locations (e.g. xL0p17, xL0p59, xL1), and for each
%      spanwise plane (MP, z25, z75), extract:
%          - Y_norm
%          - tke
%          - reynoldsstressxx
%          - reynoldsstressyy
%          - reynoldsstresszz
%   3) For each (axial location, plane, quantity), generate overlaid plots of
%      quantity vs Y_norm (quantity on x-axis, Y_norm on y-axis) where each
%      line is one geometry (3 total).
%   4) Save figures to a root directory with subdirectories for each plane:
%         <rootOutDir>/Plane_MP/...
%         <rootOutDir>/Plane_z25/...
%         <rootOutDir>/Plane_z75/...

clear; clc;

%% ------------------------------------------------------------------------
% 1) GUI SELECTION OF 3 EXCEL FILES
% -------------------------------------------------------------------------
[filenames, pathname] = uigetfile({...
    '*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'},...
    'Select 3 Volca probe Excel files (one per geometry)',...
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
% Base geometry labels (edit as needed)
geomLabels = {'RD00','RD17','RD52'};

if numel(geomLabels) ~= numel(excelFiles)
    error('geomLabels must have the same length as the number of selected files (3).');
end

% Legend labels (customizable by user if desired)
% (Currently hard-coded; uncomment inputdlg section if you want GUI input)

% prompt   = {...
%     'Legend label for geometry 1:',...
%     'Legend label for geometry 2:',...
%     'Legend label for geometry 3:'...
%     };
% dlgTitle = 'Customize Legend Labels (optional)';
% numLines = 1;
% defaultAns = geomLabels;
% 
% answer = inputdlg(prompt, dlgTitle, numLines, defaultAns);
% 
% if isempty(answer)
%     % If user cancels, fall back to geomLabels
%     legendLabels = geomLabels;
% else
%     legendLabels = answer(:)';   % row cell array
% end

legendLabels = {'$$R/D = 0.0$$','$$R/D = 0.17$$','$$R/D = 0.52$$'};

%% ------------------------------------------------------------------------
% 3) Axial locations of interest
%    Must match the axial ID portion in the sheet names
% -------------------------------------------------------------------------
axialLocs = {'xL0p17', 'xL0p59', 'xL0p86', 'xL1p2'};

% Optional: GUI prompt for axial locations
% prompt   = {'Axial location 1 (sheet prefix):',...
%             'Axial location 2 (sheet prefix):',...
%             'Axial location 3 (sheet prefix):'};
% dlgTitle = 'Specify 3 axial locations';
% defAns   = axialLocs;
% answerAx = inputdlg(prompt, dlgTitle, 1, defAns);
% if isempty(answerAx)
%     disp('User canceled axial location input. Exiting script.');
%     return;
% end
% axialLocs = answerAx(:)';

% if numel(axialLocs) ~= 3
%     error('You must specify exactly 3 axial locations.');
% end

fprintf('Using axial locations:\n  %s\n\n', strjoin(axialLocs, ', '));

%% ------------------------------------------------------------------------
% 4) Root output directory
% -------------------------------------------------------------------------
[firstDir,~,~] = fileparts(excelFiles{1});
if isempty(firstDir)
    firstDir = pwd;
end
rootOutDir = fullfile(firstDir, 'TurbulenceFigures_RD');

if ~exist(rootOutDir,'dir')
    mkdir(rootOutDir);
end

% Subdirectories for each plane
planeNames  = {'MP','z25','z75'};
planeDirs   = struct();
for iP = 1:numel(planeNames)
    pName = planeNames{iP};
    subDir = fullfile(rootOutDir, ['Plane_' pName]);
    if ~exist(subDir,'dir'); mkdir(subDir); end
    planeDirs.(pName) = subDir;
end

% Quantities and fields
qtyNames  = {'TKE','Rxx','Ryy','Rzz'};
qtyFields = {'tke','reynoldsstressxx','reynoldsstressyy','reynoldsstresszz'};

%% ------------------------------------------------------------------------
% 5) READ AND ORGANIZE DATA FROM EACH WORKBOOK
% dataStruct(g).plane(planeName).(axialID) = table(Y_norm, tke, Rxx, Ryy, Rzz)
% -------------------------------------------------------------------------
nGeom = numel(excelFiles);
dataStruct = cell(nGeom,1);

for g = 1:nGeom
    excelFile = excelFiles{g};
    fprintf('Reading workbook %d/%d: %s\n', g, nGeom, excelFile);
    dataStruct{g} = readWorkbookForPlanes(excelFile, axialLocs);
end

%% ------------------------------------------------------------------------
% 6) PLOTTING: OVERLAYS ACROSS GEOMETRIES
% For each plane (MP,z25,z75), axial location, and quantity:
%   plot quantity vs Y_norm for all 3 geometries on the same figure
%   Using interpolation and de-duplication consistent with volcano script:
%     1) Remove duplicates in quantity
%     2) Sort by Y_norm
%     3) Remove NaNs
%     4) Interpolate vs Y_norm
% -------------------------------------------------------------------------

geomColors = lines(nGeom);   % nGeom x 3 RGB matrix
lineWidth  = 1.8;

for iP = 1:numel(planeNames)
    plane = planeNames{iP};
    planeOutDir = planeDirs.(plane);

    for iA = 1:numel(axialLocs)
        axialID = axialLocs{iA};
        axialLabelLatex = formatAxialLabel(axialID);  % e.g. '$$x/L = 0.17$$'

        for iQ = 1:numel(qtyNames)
            qName  = qtyNames{iQ};
            qField = qtyFields{iQ};

            fig = figure('Visible','off');
            hold on; grid on; box on;
            set(fig, 'Color','w');

            legendEntries = {};

            % Loop over geometries
            for g = 1:nGeom
                geomData = dataStruct{g};

                % Check if this plane/axialID exists for this geometry
                if ~isfield(geomData.(plane), axialID)
                    continue;
                end

                T = geomData.(plane).(axialID);
                if isempty(T) || ~ismember('Y_norm', T.Properties.VariableNames)...
                              || ~ismember(qField, T.Properties.VariableNames)
                    continue;
                end

                y  = T.Y_norm;
                qv = T.(qField);

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

            % Spanwise label for title (LaTeX)
            switch plane
                case 'z25'
                    spanTitle = '$$z/w = 0.25$$';
                case 'MP'
                    spanTitle = '$$z/w = 0.50$$';
                case 'z75'
                    spanTitle = '$$z/w = 0.75$$';
                otherwise
                    spanTitle = plane;
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
            yLabelStr = '$$ y/D$$';

            xlabel(xLabelStr, 'Interpreter','latex');
            ylabel(yLabelStr, 'Interpreter','latex');
            % Sets them all from [-1 1]
            ylim([-1 1]);

            % Title with formatted axial ID and span label
            % Example: 'TKE vs Y_norm at x/L = 0.17, z/w = 0.50'
            titleStr = sprintf('%s vs $$ y/D$$ at %s, %s',...
                               qName, axialLabelLatex, spanTitle);
            title(titleStr, 'Interpreter','latex');

            if ~isempty(legendEntries)
                legend(legendEntries, 'Interpreter','latex', 'Location','best');
            end

            % Filename pattern: <Q>_<plane>_<axial>_RDsweep
            safeAxial = strrep(axialID, '/', '_');
            baseName  = sprintf('%s_%s_%s_RDsweep_volcano', qName, plane, safeAxial);
            pngFile   = fullfile(planeOutDir, [baseName '.png']);
            figFile   = fullfile(planeOutDir, [baseName '.fig']);
            pdfFile   = fullfile(planeOutDir, [baseName '.pdf']);

            saveas(fig, pngFile);
            savefig(fig, figFile);
            exportgraphics(fig, pdfFile, 'ContentType','vector');
            close(fig);
        end
    end
end

fprintf('\nAll figures saved under:\n  %s\n', rootOutDir);

%% ========================================================================
% LOCAL FUNCTION: READ ONE WORKBOOK
% ========================================================================
function geomData = readWorkbookForPlanes(excelFile, axialLocs)
% readWorkbookForPlanes
%   Reads a single Excel workbook, extracts tables for requested axial
%   locations and three spanwise planes (MP, z25, z75).
%
%   geomData.MP.(axialID)  = table(...)
%   geomData.z25.(axialID) = table(...)
%   geomData.z75.(axialID) = table(...)

    % Initialize empty structures
    geomData.MP  = struct();
    geomData.z25 = struct();
    geomData.z75 = struct();

    try
        [~, sheetNames] = xlsfinfo(excelFile);
    catch ME
        error('Error reading Excel file "%s": %s', excelFile, ME.message);
    end

    if isempty(sheetNames)
        warning('No sheets found in Excel file: %s', excelFile);
        return;
    end

    neededCols = {'Y_norm','reynoldsstressxx','reynoldsstressyy','reynoldsstresszz','tke'};

    for iS = 1:numel(sheetNames)
        sName = sheetNames{iS};

        % Skip upstream/downstream sheets starting with US/DS
        if startsWith(sName, 'US', 'IgnoreCase', true) ||...
           startsWith(sName, 'DS', 'IgnoreCase', true)
            continue;
        end

        % Parse axialID and plane suffix
        underscoreIdx = strfind(sName, '_');
        if isempty(underscoreIdx)
            continue;
        end

        axialPart   = sName(1:underscoreIdx(end)-1);
        planeSuffix = sName(underscoreIdx(end)+1:end);   % MP, z25, z75, etc.

        % Only keep the three planes of interest
        if ~ismember(planeSuffix, {'MP','z25','z75'})
            continue;
        end

        % Only keep requested axial locations
        if ~ismember(axialPart, axialLocs)
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
            warning('Sheet "%s" missing columns (%s). Skipping.', sName, strjoin(missing, ', '));
            continue;
        end

        Tsel = T(:, neededCols);

        % Store in geomData
        switch planeSuffix
            case 'MP'
                geomData.MP.(axialPart) = Tsel;
            case 'z25'
                geomData.z25.(axialPart) = Tsel;
            case 'z75'
                geomData.z75.(axialPart) = Tsel;
        end
    end
end

%% ========================================================================
% LOCAL FUNCTION: FORMAT AXIAL LABEL
% ========================================================================
function lbl = formatAxialLabel(axialID)
% formatAxialLabel
% Convert an axial ID like 'xL0p03' to a LaTeX string '$$x/L = 0.03$$'.
% If the pattern is not recognized, just return the raw axialID.
%
% Expected pattern: 'xL' + number with 'p' as decimal point
%   e.g., 'xL0p03' -> 0.03, 'xL1p00' -> 1.00

    axialID = strtrim(axialID);

    if startsWith(axialID, 'xL')
        numStr = axialID(3:end);           % strip 'xL'
        numStr = strrep(numStr, 'p', '.'); % replace 'p' with '.'
        lbl = sprintf('$$x/L = %s$$', numStr);
    else
        % Fallback: return the axialID as-is (no special formatting)
        lbl = axialID;
    end
end