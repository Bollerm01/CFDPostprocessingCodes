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

% Legend labels: plain text (no LaTeX, no bold)
legendLabels = {'R/D = 0.0','R/D = 0.17','R/D = 0.52'};

%% ------------------------------------------------------------------------
% 3) Axial locations of interest
%    Must match the axial ID portion in the sheet names
% -------------------------------------------------------------------------
axialLocs = {'xL0p17', 'xL0p59', 'xL0p86', 'xL1'};

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
                    % Bold LaTeX for x-label
                    xLabelStr = '$\mathbf{TKE\ (J/kg)}$';
                case 'Rxx'
                    xLabelStr = '$\mathbf{R_{xx}\ (Pa)}$';
                case 'Ryy'
                    xLabelStr = '$\mathbf{R_{yy}\ (Pa)}$';
                case 'Rzz'
                    xLabelStr = '$\mathbf{R_{zz}\ (Pa)}$';
            end
            % Bold LaTeX for y-label
            yLabelStr = '$\mathbf{y/D}$';

            % These are now bold because of \mathbf in the string
            xlabel(xLabelStr, 'Interpreter','latex');
            ylabel(yLabelStr, 'Interpreter','latex');

            % Sets them all from [-1 1]
            ylim([-1 1]);

            % -------- Title (bold, non-LaTeX, no plane in text) --------
            % axialLabelLatex is a LaTeX string; extract plain part
            % Example axialLabelLatex: '$$x/L = 0.17$$' -> 'x/L = 0.17'
            axialPlain = regexprep(axialLabelLatex, '[$]', '');

            % Build plain-text title (no plane)
            % Example: 'TKE vs y/D at x/L = 0.17'
            titleStr = sprintf('y/D vs %s at %s', qName, axialPlain);
            title(titleStr, 'Interpreter','none', 'FontWeight','bold');

            % Legend: plain text, no LaTeX, not bold
            if ~isempty(legendEntries)
                lgd = legend(legendEntries,...
                             'Interpreter','none',...
                             'Location','best');
                set(lgd, 'FontWeight','normal');
            end

            % Filename pattern: <Q>_<plane>_<axial>_RDsweep (plane only in filename)
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

        if startsWith(sName, 'US', 'IgnoreCase', true) ||...
           startsWith(sName, 'DS', 'IgnoreCase', true)
            continue;
        end

        underscoreIdx = strfind(sName, '_');
        if isempty(underscoreIdx)
            continue;
        end

        axialPart   = sName(1:underscoreIdx(end)-1);
        planeSuffix = sName(underscoreIdx(end)+1:end);   % MP, z25, z75, etc.

        if ~ismember(planeSuffix, {'MP','z25','z75'})
            continue;
        end

        if ~ismember(axialPart, axialLocs)
            continue;
        end

        try
            T = readtable(excelFile, 'Sheet', sName);
        catch ME
            warning('Could not read sheet "%s" in "%s": %s', sName, excelFile, ME.message);
            continue;
        end

        missing = setdiff(neededCols, T.Properties.VariableNames);
        if ~isempty(missing)
            warning('Sheet "%s" missing columns (%s). Skipping.', sName, strjoin(missing, ', '));
            continue;
        end

        Tsel = T(:, neededCols);

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
    axialID = strtrim(axialID);

    if startsWith(axialID, 'xL')
        numStr = axialID(3:end);           
        numStr = strrep(numStr, 'p', '.'); 
        lbl = sprintf('$$x/L = %s$$', numStr);
    else
        lbl = axialID;
    end
end