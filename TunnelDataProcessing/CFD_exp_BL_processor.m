%% Processing code for Exp Boundary Layer Data vs. CFD (Volcano)
% Adapted to:
% - Non-dimensionalize Mach by the average of the last 5 points.
% - Plot: Y/D vs. Mach and Y/D vs. M/M_max.
% - Save plots as vectorized PDFs.

% --- Select Excel files (3 files) ---
[excelNames, excelPath] = uigetfile(...
    {'*.xlsx;*.xls;*.xlsm', 'Excel Files (*.xlsx, *.xls, *.xlsm)'},...
    'Select 3 Excel files',...
    'MultiSelect', 'on');

if isequal(excelNames, 0)
    error('No Excel files selected. Script terminated.');
end

if ischar(excelNames)
    excelNames = {excelNames};
end

if numel(excelNames) ~= 3
    error('You must select exactly 3 Excel files. You selected %d.', numel(excelNames));
end

excelFiles = fullfile(excelPath, excelNames);

% --- Select CSV file ---
[csvName, csvPath] = uigetfile(...
    {'*.csv', 'CSV Files (*.csv)'},...
    'Select the CSV file');

if isequal(csvName, 0)
    error('No CSV file selected. Script terminated.');
end

csvFile = fullfile(csvPath, csvName);

%% Ask where to save outputs (Excel + figures)
output_dir = fullfile(excelPath, 'BoundaryLayerComparison');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Base name (no extension)
baseName = "BoundaryLayerComparison";

% Output Excel file name
outputExcel = fullfile(output_dir, baseName + ".xlsx");

% Figure files (vectorized PDFs)
pdfFile_dim = fullfile(output_dir, baseName + "_Mach.pdf");
pdfFile_nd  = fullfile(output_dir, baseName + "_MachND.pdf");

%% Constants
maxY_cm = 2.59;   % 1.02 inches ≈ 2.59 cm

%% Characteristic length D (cm) for Y/D
D_cm = 1.8593; % cavity depth, cm
if isnan(D_cm) || D_cm <= 0
    error('Characteristic length D must be a positive number (cm).');
end

%% Storage for processed datasets
excelY        = cell(1, numel(excelFiles));   % Y/D
excelMach     = cell(1, numel(excelFiles));   % Mach (dimensional)
excelMach_nd  = cell(1, numel(excelFiles));   % M / M_max

csvY          = [];   % Y/D
csvMach       = [];   % Mach (dimensional)
csvMach_nd    = [];   % M / M_max

%% ---- Process the Excel files ----
for k = 1:numel(excelFiles)
    T = readtable(excelFiles{k});

    % Extract columns (assumed names)
    y_cm   = T.Y_shift_cm;   % already in cm
    M_BL   = T.Mach_BL;      % boundary-layer Mach

    % Remove NaNs
    valid = ~isnan(y_cm) & ~isnan(M_BL);
    y_cm = y_cm(valid);
    M_BL = M_BL(valid);

    % Average Mach_BL at duplicated Y locations
    [yUnique, ~, idxGrp] = unique(y_cm);

    M_BL_avg = accumarray(idxGrp, M_BL, [], @mean);

    % Make lowest y-value zero
    yUnique = yUnique - min(yUnique);

    % Keep only values <= 2.59 cm
    keep = yUnique <= maxY_cm;
    yUnique  = yUnique(keep);
    M_BL_avg = M_BL_avg(keep);

    % Sort by y (just to be safe)
    [yUnique, sortIdx] = sort(yUnique);
    M_BL_avg = M_BL_avg(sortIdx);

    % --- NEW: Non-dimensionalize by average of last 5 points ---
    nPts = numel(M_BL_avg);
    nTail = min(5, nPts);
    M_max_BL = mean(M_BL_avg(end-nTail+1:end));   % average of last up-to-5 points
    M_nd_avg = M_BL_avg./ M_max_BL;

    % Non-dimensionalize Y by D
    Y_over_D = yUnique./ D_cm;

    % Store
    excelY{k}       = Y_over_D;
    excelMach{k}    = M_BL_avg;
    excelMach_nd{k} = M_nd_avg;
end

%% ---- Process the CSV file ----
Tcsv = readtable(csvFile);

% Extract columns:
%   Points_1       -> Y in meters
%   machnumberavg  -> Mach
Y_m  = Tcsv.("Points_1");        % meters
Mcsv = Tcsv.machnumberavg;       % Mach

% Remove NaNs
valid = ~isnan(Y_m) & ~isnan(Mcsv);
Y_m   = Y_m(valid);
Mcsv  = Mcsv(valid);

% Convert Y from meters to cm
Y_cm = Y_m * 100;

% Remove duplicate Y values (keep first occurrence)
[~, idxFirstY] = unique(Y_cm, 'stable');
Y_cm  = Y_cm(idxFirstY);
Mcsv  = Mcsv(idxFirstY);

% Sort by Y for consistency
[Y_cm, sortIdx] = sort(Y_cm);
Mcsv = Mcsv(sortIdx);

% Optionally remove duplicate Mach values (now in Y-sorted order)
[~, idxFirstM] = unique(Mcsv, 'stable');
Y_cm  = Y_cm(idxFirstM);
Mcsv  = Mcsv(idxFirstM);

% Make lowest y-value zero
Y_cm = Y_cm - min(Y_cm);

% Keep only values <= 2.59 cm
keep = Y_cm <= maxY_cm;
Y_cm  = Y_cm(keep);
Mcsv  = Mcsv(keep);

% Ensure ascending Y (should already be)
[Y_cm, sortIdx] = sort(Y_cm);
Mcsv = Mcsv(sortIdx);

% Interpolate CSV data to more points (dimensional & non-dimensional)
interpFactor = 10;  % e.g., 10× more points than current
nInterp = max(interpFactor * numel(Y_cm), 2); % ensure at least 2 points

% New Y grid for interpolation (cm)
Y_cm_interp = linspace(min(Y_cm), max(Y_cm), nInterp).';

% Interpolate dimensional Mach onto this new Y grid
Mcsv_interp = interp1(Y_cm, Mcsv, Y_cm_interp, 'pchip');

% --- NEW: Non-dimensional Mach using average of last 5 interpolated points ---
nPts_csv = numel(Mcsv_interp);
nTail_csv = min(5, nPts_csv);
M_max_csv = mean(Mcsv_interp(end-nTail_csv+1:end));  % average of last up-to-5 points
Mcsv_nd_interp = Mcsv_interp./ M_max_csv;

% Non-dimensionalize Y by D
Y_over_D_csv = Y_cm_interp./ D_cm;

% Store for later saving/plotting
csvY       = Y_over_D_csv;   % Y/D
csvMach    = Mcsv_interp;    % dimensional Mach
csvMach_nd = Mcsv_nd_interp; % M / M_max

%% ---- Save processed data to a single Excel file (multiple sheets) ----

for k = 1:numel(excelFiles)
    TblOut = table(excelY{k}, excelMach{k}, excelMach_nd{k},...
        'VariableNames', {'Y_over_D', 'Mach', 'Mach_nd'});
    sheetName = sprintf('Excel_%d', k);
    writetable(TblOut, outputExcel, 'Sheet', sheetName, 'WriteMode', 'overwrite');
end

TblCSV = table(csvY, csvMach, csvMach_nd,...
    'VariableNames', {'Y_over_D', 'Mach', 'Mach_nd'});
writetable(TblCSV, outputExcel, 'Sheet', 'CSV', 'WriteMode', 'overwrite');

%% ---- Build legend labels from Excel filenames ----
excelLegendLabels = cell(1, numel(excelNames));
for k = 1:numel(excelNames)
    [~, fname, ~] = fileparts(excelNames{k});
    parts = strsplit(fname, '_');
    excelLegendLabels{k} = parts{end};   % last token after "_"
end

% CSV legend label (custom)
csvLegendLabel = 'Volcano';

%% ---- Plot 1: Dimensional Mach vs Y/D ----
fig_dim = figure;
hold on; grid on; box on;

colors = lines(numel(excelFiles) + 1);

% Excel datasets (dimensional Mach)
for k = 1:numel(excelFiles)
    plot(excelMach{k}, excelY{k}, '-o',...
        'Color', colors(k,:),...
        'MarkerSize', 4,...
        'DisplayName', excelLegendLabels{k});
end

% CSV dataset (dimensional Mach) as a continuous line
plot(csvMach, csvY, '-sq',...
    'Color', colors(end,:),...
    'MarkerSize', 5,...
    'DisplayName', csvLegendLabel);

xlabel('$$M$$','Interpreter','latex');
ylabel('$$y/D$$','Interpreter','latex');
title('Experimental vs. CFD Incident Boundary Layers','Interpreter','none');
legend('Location', 'best');
set(gca, 'YDir', 'normal');

% Save dimensional Mach figure as vectorized PDF
exportgraphics(fig_dim, pdfFile_dim, 'ContentType', 'vector');

%% ---- Plot 2: Non-dimensional Mach vs Y/D (M/M_max) ----
fig_nd = figure;
hold on; grid on; box on;

colors = lines(numel(excelFiles) + 1);

% Excel datasets (non-dimensional Mach)
for k = 1:numel(excelFiles)
    plot(excelMach_nd{k}, excelY{k}, '-o',...
        'Color', colors(k,:),...
        'MarkerSize', 4,...
        'DisplayName', excelLegendLabels{k});
end

% CSV dataset (non-dimensional Mach) as a continuous line
plot(csvMach_nd, csvY, '-sq',...
    'Color', colors(end,:),...
    'MarkerSize', 5,...
    'DisplayName', csvLegendLabel);

xlabel('$$M/M_{max}$$','Interpreter','latex');
ylabel('$$y/D$$','Interpreter','latex');
title('Non-Dimensional Experimental vs. CFD Incident Boundary Layers','Interpreter','none');
legend('Location', 'best');
set(gca, 'YDir', 'normal');

% Save non-dimensional Mach figure as vectorized PDF
exportgraphics(fig_nd, pdfFile_nd, 'ContentType', 'vector');

%% ---- Summary messages ----
disp(['Processed data saved to: ' char(outputExcel)]);
disp(['Dimensional Mach PDF saved as: ' char(pdfFile_dim)]);
disp(['Non-dimensional Mach PDF saved as: ' char(pdfFile_nd)]);