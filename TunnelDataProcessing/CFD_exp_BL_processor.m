%% Processing code for Exp Boundary Layer Data vs. CFD (Volcano)
% Inputs: 3x SSWT BL run data (processed from process_BL_sweep_multiRun.m)
% Output: Processed, combined Excel sheet and cross-plotted Y/D vs. Mach figures

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
% Uses the same directory as the workbook
output_dir = fullfile(excelPath, 'BoundaryLayerComparison');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Base name (no extension)
baseName = "BoundaryLayerComparison";

% Specifies the output Excel file name (with extension)
outputExcel = fullfile(output_dir, baseName + ".xlsx");

% Figure files for dimensional and non-dimensional Mach
figFile_dim = fullfile(output_dir, baseName + "_Mach.fig");
pngFile_dim = fullfile(output_dir, baseName + "_Mach.png");

figFile_nd  = fullfile(output_dir, baseName + "_MachND.fig");
pngFile_nd  = fullfile(output_dir, baseName + "_MachND.png");

%% Constants
maxY_cm = 2.59;   % 1.02 inches ≈ 2.59 cm

%% NEW: Ask user for characteristic length D (in cm)
% prompt   = {'Enter characteristic length D (cm) for Y/D:'};
% dlgtitle = 'Characteristic Length Input';
% dims     = [1 50];
% definput = {'2.59'};  % default example; adjust as desired
% answer   = inputdlg(prompt, dlgtitle, dims, definput);
% 
% if isempty(answer)
%     error('No characteristic length D provided. Script terminated.');
% end

D_cm = 1.8593; %cavity depth, cm
if isnan(D_cm) || D_cm <= 0
    error('Characteristic length D must be a positive number (cm).');
end

%% Storage for processed datasets
excelY        = cell(1, numel(excelFiles));   % will store Y/D
excelMach     = cell(1, numel(excelFiles));   % dimensional Mach_BL
excelMach_nd  = cell(1, numel(excelFiles));   % non-dimensional Mach_BL / Mach_FS

csvY          = [];   % will store Y/D
csvMach       = [];   % dimensional
csvMach_nd    = [];   % non-dimensional

%% ---- Process the Excel files ----
for k = 1:numel(excelFiles)
    T = readtable(excelFiles{k});

    % Extract columns (assumed names)
    y_cm   = T.Y_shift_cm;   % already in cm
    M_BL   = T.Mach_BL;
    M_FS   = T.Mach_FS;      % freestream Mach column

    % Remove NaNs (any NaN in Y, BL, or FS)
    valid = ~isnan(y_cm) & ~isnan(M_BL) & ~isnan(M_FS);
    y_cm = y_cm(valid);
    M_BL = M_BL(valid);
    M_FS = M_FS(valid);

    % Average Mach_BL and Mach_FS at duplicated Y locations
    [yUnique, ~, idxGrp] = unique(y_cm);

    M_BL_avg = accumarray(idxGrp, M_BL, [], @mean);
    M_FS_avg = accumarray(idxGrp, M_FS, [], @mean);

    % Non-dimensional Mach after averaging
    M_nd_avg = M_BL_avg./ M_FS_avg;

    % Make lowest y-value zero
    yUnique = yUnique - min(yUnique);

    % Keep only values <= 2.59 cm (1.02 in)
    keep = yUnique <= maxY_cm;
    yUnique  = yUnique(keep);
    M_BL_avg = M_BL_avg(keep);
    M_nd_avg = M_nd_avg(keep);

    %% NEW: Non-dimensionalize Y by D (still using cm)
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

% ---- Remove duplicate Y values first (keep first occurrence) ----
[~, idxFirstY] = unique(Y_cm, 'stable');
Y_cm  = Y_cm(idxFirstY);
Mcsv  = Mcsv(idxFirstY);

% ---- Sort by Y for consistency ----
[Y_cm, sortIdx] = sort(Y_cm);
Mcsv = Mcsv(sortIdx);

% ---- Optionally remove duplicate Mach values (now in Y-sorted order) ----
[~, idxFirstM] = unique(Mcsv, 'stable');
Y_cm  = Y_cm(idxFirstM);
Mcsv  = Mcsv(idxFirstM);

% ---- Compute freestream Mach from middle 20 points of this de-duplicated set ----
Ndedup = numel(Mcsv);
if Ndedup >= 20
    midStart = floor(Ndedup/2) - 9;  % attempt center 20
    if midStart < 1
        midStart = 1;
    end
    midEnd = midStart + 19;
    if midEnd > Ndedup
        midEnd = Ndedup;
        midStart = max(1, midEnd - 19);
    end
    M_FS_csv = mean(Mcsv(midStart:midEnd));
else
    % Fallback: average all if fewer than 20 points
    M_FS_csv = mean(Mcsv);
end

% ---- Now shift Y, apply cutoff, and interpolate ----

% Make lowest y-value zero (still in cm)
Y_cm = Y_cm - min(Y_cm);

% Keep only values <= 2.59 cm (1.02 in)
keep = Y_cm <= maxY_cm;
Y_cm  = Y_cm(keep);
Mcsv  = Mcsv(keep);

% Ensure ascending Y (should already be, but keep it explicit)
[Y_cm, sortIdx] = sort(Y_cm);
Mcsv = Mcsv(sortIdx);

% ---- Interpolate CSV data to more points (dimensional & non-dimensional) ----
interpFactor = 10;  % e.g., 10× more points than current
nInterp = max(interpFactor * numel(Y_cm), 2); % ensure at least 2 points

% New Y grid for interpolation (cm)
Y_cm_interp = linspace(min(Y_cm), max(Y_cm), nInterp).';

% Interpolate dimensional Mach onto this new Y grid
Mcsv_interp = interp1(Y_cm, Mcsv, Y_cm_interp, 'pchip');

% Non-dimensional Mach using freestream Mach
Mcsv_nd_interp = Mcsv_interp./ M_FS_csv;

%% NEW: Non-dimensionalize the interpolated Y by D
Y_over_D_csv = Y_cm_interp./ D_cm;

% Store for later saving/plotting
csvY       = Y_over_D_csv;   % Y/D
csvMach    = Mcsv_interp;
csvMach_nd = Mcsv_nd_interp;

%% ---- Save processed data to a single Excel file (multiple sheets) ----

% Excel sheets for each processed dataset
for k = 1:numel(excelFiles)
    % Save both Y_cm and Y_over_D if you want; here we save Y_over_D
    TblOut = table(excelY{k}, excelMach{k}, excelMach_nd{k},...
        'VariableNames', {'Y_over_D', 'Mach', 'Mach_nd'});
    sheetName = sprintf('Excel_%d', k);
    writetable(TblOut, outputExcel, 'Sheet', sheetName, 'WriteMode', 'overwrite');
end

% CSV processed (interpolated) data
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

xlabel('Mach number');                          % unchanged (dimensional)
ylabel('Y/D');                                  % NEW
title('Experimental versus CFD Incident Boundary Layers');  % NEW
legend('Location', 'best');
set(gca, 'YDir', 'normal');

% Save dimensional Mach figure
savefig(fig_dim, figFile_dim);
saveas(fig_dim, pngFile_dim);

%% ---- Plot 2: Non-dimensional Mach vs Y/D ----
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

xlabel('M / M_\infty');                         % NEW: removed "(non-dimensional)"
ylabel('Y/D');                                  % NEW
title('Experimental versus CFD Incident Boundary Layers');  % NEW
legend('Location', 'best');
set(gca, 'YDir', 'normal');

% Save non-dimensional Mach figure
savefig(fig_nd, figFile_nd);
saveas(fig_nd, pngFile_nd);

%% ---- Summary messages ----
disp(['Processed data saved to: ' char(outputExcel)]);
disp(['Dimensional Mach figure saved as: ' char(figFile_dim) ' and ' char(pngFile_dim)]);
disp(['Non-dimensional Mach figure saved as: ' char(figFile_nd) ' and ' char(pngFile_nd)]);