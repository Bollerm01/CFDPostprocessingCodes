%% ============================================================
%  VULCAN Shear Layer Thickness - Velocity_X_Norm
%  Single Plane (MP), MULTI-GEOMETRY
%
%  For VULCAN sheet setup:
%    Sheets: xL_0p03, xL_0p17,..., xL_2, xL_neg0p5, xL_neg1, xL_neg2
%    Columns: X, Y, Z, Velocity_X_Norm, Velocity_X_RMS,..., Y_norm
% ============================================================

clc;

%% Excel GUI inputs (MULTI-FILE)
[filenames, pathname] = uigetfile('*.xlsx',...
    'Select Input Excel Workbooks (Multiple Geometries)',...
    'MultiSelect', 'on');

if isequal(filenames,0)
    errordlg('No Excel file selected.', 'Error');
    return;
end

% Ensure filenames is a cell array
if ischar(filenames)
    filenames = {filenames};
end

% Containers for cross-geometry data
all_results      = struct();  % all_results.(geometryType).(key) = [xL thickness lower_vel]
all_output_dirs  = struct();  % per-geometry output dir
all_geometryType = cell(1, numel(filenames));

%% COLUMN NAMES
Y_COL_raw     = 'Y_norm';
VELX_NORM_COL = 'Velocity_X_Norm';

% Internal name for the normalized velocity used everywhere
VEL_USED_COL  = 'velocityx_norm';

% Thickness bounds
THRESHOLDS = [0.95 0.05];  % rows = [upper lower]

%% LOOP OVER GEOMETRY FILES
for iFile = 1:numel(filenames)

    filename   = filenames{iFile};
    excel_file = fullfile(pathname, filename);

    % File edge geometry type (after first underscore for VULCAN)
    parts = strsplit(filename, {'_','.'});
    if numel(parts) < 2
        error('Could not parse geometryType from filename: %s', filename);
    end
    geometryType = parts{2};
    all_geometryType{iFile} = geometryType;

    % Output directory
    output_dir = fullfile(pathname, ['ShearResults_' geometryType]);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    all_output_dirs.(geometryType) = output_dir;

    % Subfolders
    dat_dir   = fullfile(output_dir, 'DAT_Files');
    plots_dir = fullfile(output_dir, 'Plots');
    if ~exist(dat_dir, 'dir')
        mkdir(dat_dir);
    end
    if ~exist(plots_dir, 'dir')
        mkdir(plots_dir);
    end

    %% LOAD WORKBOOK (sheet names)
    [status, sheets] = xlsfinfo(excel_file);
    if isempty(status)
        errordlg(['Unable to read Excel file or no sheets found: ' excel_file], 'Error');
        return;
    end

    %% FREESTREAM (ASSUMED)
    % Velocity_X_Norm is already normalized; assume freestream = 1
    freestream_val = 1.0;
    fprintf('========================================\n');
    fprintf('Geometry: %s\n', geometryType);
    fprintf('Freestream (assumed) for single plane MP:\n');
    fprintf('velocityx_norm_fs_MP = %.2f\n', freestream_val);
    fprintf('========================================\n');

    %% NORMALIZED XLSX OUTPUT (SINGLE WORKBOOK, PER GEOMETRY)
    norm_xlsx = fullfile(output_dir, sprintf('normalized_velocity_profiles_MP_%s.xlsx', geometryType));

    freestream_tbl = table(...
        {'velocityx_norm'}',...
        [freestream_val]',...
        'VariableNames', {'quantity', 'value'}...
    );
    writetable(freestream_tbl, norm_xlsx, 'Sheet', 'freestream', 'WriteMode', 'overwrite');

    %% SINGLE NORMALIZED COLUMN LABEL
    nice_name = '$$\bar{V_x}$$';  % for plots/labels

    % results[(upper, lower)] -> [xL thickness lower_vel]
    results = struct();
    for iThr = 1:size(THRESHOLDS,1)
        upper = THRESHOLDS(iThr,1);
        lower = THRESHOLDS(iThr,2);
        key = make_key(VEL_USED_COL, upper, lower);
        results.(key) = [];
    end

    %% PROCESS AXIAL SHEETS (ALL xL_*)

    axial_sheets = sheets(startsWith(sheets, 'xL'));

    for iS = 1:numel(axial_sheets)
        sheet = axial_sheets{iS};
        xL = parse_xL_new(sheet);

        % skips US and DS locations 
        if xL < 0 || xL > 1.1
            fprintf('Skipping sheet %s (x/L = %.3f) in %s\n', sheet, xL, geometryType);
            continue;
        end

        df_raw = readtable(excel_file, 'Sheet', sheet);

        % Check required raw columns
        required_raw = {Y_COL_raw, VELX_NORM_COL};
        missing_raw = setdiff(required_raw, df_raw.Properties.VariableNames);
        if ~isempty(missing_raw)
            error('Missing required raw columns in sheet %s (%s): %s',...
                  sheet, geometryType, strjoin(missing_raw, ', '));
        end

        % Build minimal table: Y_norm + velocityx_norm
        df = table();
        df.Y_norm         = df_raw.(Y_COL_raw);
        vx_norm_raw       = df_raw.(VELX_NORM_COL);
        df.(VEL_USED_COL) = vx_norm_raw;  % already normalized

        % Cleaning: remove NaNs, sort by y, de-duplicate on velocity
        df_clean = clean_velocity_minimal(df, 'Y_norm', VEL_USED_COL);

        % Use cleaned y and velocity for thickness calculations
        y        = df_clean.Y_norm;
        vel_used = df_clean.(VEL_USED_COL);

        % Write cleaned/normalized data to workbook
        df_loc = df_clean;
        writetable(df_loc, norm_xlsx, 'Sheet', sheet, 'WriteMode', 'overwrite');

        % Thickness calculations for each threshold pair
        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            [thickness, lower_vel_for_dat] = find_thickness_robust_MATLAB(y, vel_used, upper, lower);

            key = make_key(VEL_USED_COL, upper, lower);
            results.(key) = [...
                results.(key);...
                xL, thickness, lower_vel_for_dat...
            ];
        end
    end

    %% OUTPUT DAT FILES + OVERLAID PLOT (PER GEOMETRY)

    keys_list = fieldnames(results);
    for iK = 1:numel(keys_list)
        key = keys_list{iK};
        data = results.(key);
        if isempty(data)
            continue;
        end

        data = sortrows(data, 1);  % sort by xL
        [upper, lower] = parse_bounds_from_key(key);

        dat_path = fullfile(dat_dir,...
            sprintf('thickness_%s_%d_%d_MP_%s_VULCAN.dat',...
                VEL_USED_COL, round(upper*100), round(lower*100), geometryType));

        % data columns: xL, thickness, lower_vel_for_dat
        writematrix(data, dat_path, 'Delimiter', ' ');
        add_header_to_dat(dat_path, 'xL thickness lower_vel_for_dat');
    end

    % Overlaid thickness plot for all thresholds (within this geometry)
    hfig = figure('Visible','off');
    hold on;
    has_data = false;

    for iThr = 1:size(THRESHOLDS,1)
        upper = THRESHOLDS(iThr,1);
        lower = THRESHOLDS(iThr,2);
        key   = make_key(VEL_USED_COL, upper, lower);
        data  = results.(key);
        if isempty(data)
            continue;
        end
        data = sortrows(data, 1);

        pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
        pct_text = strrep(pct_text, '%', '\%');
        label = sprintf('%s $V_x/V_{x,\\infty}$', pct_text);

        plot(data(:,1), data(:,2), '-o', 'DisplayName', label, 'LineWidth', 1.5);
        has_data = true;
    end

    if has_data
        locLabel = '$$z/w = 0.50$$';  % single plane MP

        xlabel('x/L', 'Interpreter', 'latex');
        ylabel('Normalized Shear Layer Thickness', 'Interpreter', 'latex');
        title(sprintf('%s Thickness, %s (%s)', nice_name, locLabel, geometryType), 'Interpreter', 'latex');
        grid on;
        legend('Location', 'best', 'Interpreter','latex');
        hold off;

        plot_path_png = fullfile(plots_dir,...
            sprintf('shearThick_%s_overlaid_MP_%s_VULCAN.png', VEL_USED_COL, geometryType));
        print(hfig, '-dpng', '-r300', plot_path_png);

        plot_path_fig = fullfile(plots_dir,...
            sprintf('shearThick_%s_overlaid_MP_%s_VULCAN.fig', VEL_USED_COL, geometryType));
        savefig(hfig, plot_path_fig);

        plot_path_pdf = fullfile(plots_dir,...
            sprintf('shearThick_%s_overlaid_MP_%s_VULCAN.pdf', VEL_USED_COL, geometryType));
        exportgraphics(hfig, plot_path_pdf, 'ContentType','vector');
    end
    if isvalid(hfig)
        close(hfig);
    end

    fprintf('Processing complete for %s.\nFiles stored at: %s\n', geometryType, output_dir);

    % Store this geometry's results for cross-geometry overlay
    all_results.(geometryType) = results;

end  % end loop over geometries

%% ============================================================
%  CROSS-GEOMETRY OVERLAYS (SINGLE PLANE, SINGLE VARIABLE)
% ============================================================

% colors per geometry (adjust as needed)
colorMapGeom = containers.Map();
colorMapGeom('RD00') = [0.00, 0.45, 0.74];  % blue
colorMapGeom('RD17') = [0.85, 0.33, 0.10];  % red
colorMapGeom('RD52') = [0.47, 0.67, 0.19];  % green

% line styles for different thresholds
lineStyles = {'-', '--', ':'};

% use plots_dir from first geometry to store "global" overlays
firstGeom = all_geometryType{1};
plots_dir_global = fullfile(all_output_dirs.(firstGeom), 'Plots_Global');
if ~exist(plots_dir_global, 'dir')
    mkdir(plots_dir_global);
end

locLabelLatex = '$$z/w = 0.50$$';
locLabelPlain = 'MP';

for iThr = 1:size(THRESHOLDS,1)
    upper = THRESHOLDS(iThr,1);
    lower = THRESHOLDS(iThr,2);
    key   = make_key(VEL_USED_COL, upper, lower);

    hfig = figure('Visible','off');
    hold on;
    has_data = false;

    for iFile = 1:numel(all_geometryType)
        geometryType = all_geometryType{iFile};

        if ~isfield(all_results, geometryType)
            continue;
        end
        resultsGeom = all_results.(geometryType);
        if ~isfield(resultsGeom, key)
            continue;
        end

        data = resultsGeom.(key);
        if isempty(data)
            continue;
        end
        data = sortrows(data, 1);

        if isKey(colorMapGeom, geometryType)
            thisColor = colorMapGeom(geometryType);
        else
            thisColor = [0 0 0];
        end

        % label per geometry
        switch geometryType
            case 'RD00'
                geoLabel = 'R/D = 0.0';
            case 'RD17'
                geoLabel = 'R/D = 0.17';
            case 'RD52'
                geoLabel = 'R/D = 0.52';
            otherwise
                geoLabel = geometryType;
        end

        pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
        pct_text = strrep(pct_text, '%', '\%');
        label = sprintf('%s, %s', geoLabel, pct_text);

        ls = lineStyles{min(iThr, numel(lineStyles))};

        plot(data(:,1), data(:,2),...
             'Color', thisColor,...
             'LineStyle', ls,...
             'Marker', 'o',...
             'LineWidth', 1.5,...
             'DisplayName', label);

        has_data = true;
    end

    if ~has_data
        close(hfig);
        continue;
    end

    xlabel('x/L', 'Interpreter', 'latex');
    ylabel('$$\delta_{SL}/D$$', 'Interpreter', 'latex');
    title(sprintf('$$V_x/V_{x,\\infty}$$ Thickness, %s', locLabelLatex), 'Interpreter', 'latex');
    grid on;
    legend('Location', 'best', 'Interpreter','latex');
    hold off;

    plot_name_png = sprintf('shearThick_%s_MP_upper%d_lower%d_allGeometries_VULCAN.png',...
        VEL_USED_COL, round(upper*100), round(lower*100));
    plot_name_fig = strrep(plot_name_png, '.png', '.fig');
    plot_name_pdf = strrep(plot_name_png, '.png', '.pdf');

    print(hfig, '-dpng', '-r300', fullfile(plots_dir_global, plot_name_png));
    savefig(hfig, fullfile(plots_dir_global, plot_name_fig));
    exportgraphics(hfig, fullfile(plots_dir_global, plot_name_pdf), 'ContentType','vector');
    close(hfig);
end

fprintf('Cross-geometry overlays complete.\nGlobal plots stored at: %s\n', plots_dir_global);

%% ============================================================
%  LOCAL HELPER FUNCTIONS
% ============================================================

function key = make_key(norm_col, upper, lower)
    key = sprintf('%s_%g_%g', norm_col, upper, lower);
    key = strrep(key, '.', 'p');
    key = strrep(key, '-', 'm');
end

function [upper, lower] = parse_bounds_from_key(key)
    % key like 'velocityx_norm_0p95_0p05'
    parts = strsplit(key, '_');
    if numel(parts) < 4
        error('Unexpected key format: %s', key);
    end
    up_str  = strrep(parts{end-1}, 'p', '.');
    low_str = strrep(parts{end},   'p', '.');

    upper = str2double(up_str);
    lower = str2double(low_str);
end

function xL = parse_xL_new(sheet_name)
    base = sheet_name;

    % Explicit special cases for negative positions used in this dataset
    if strcmp(base, 'xL_neg0p5')
        xL = -0.5;
        return;
    elseif strcmp(base, 'xL_neg1')
        xL = -1.0;
        return;
    elseif any(strcmp(base, {'xL_neg2','xLneg2'}))
        xL = -2.0;
        return;
    end

    tokens = regexp(base, 'xL_?(-?\d+)p(\d+)$', 'tokens');
    if ~isempty(tokens)
        t = tokens{1};
        xL = str2double([t{1} '.' t{2}]);
        return;
    end

    tokens = regexp(base, 'xL_?(-?\d+)$', 'tokens');
    if ~isempty(tokens)
        t = tokens{1};
        xL = str2double(t{1});
        return;
    end

    error('Could not parse xL from sheet name: %s', sheet_name);
end

function df_clean = clean_velocity_minimal(df, y_col, vel_col)
    required_cols = {y_col, vel_col};
    missing = setdiff(required_cols, df.Properties.VariableNames);
    if ~isempty(missing)
        error('Missing required columns: %s', strjoin(missing, ', '));
    end

    df_clean = df(:, required_cols);

    % Remove any rows with NaNs
    nanMask = any(ismissing(df_clean), 2);
    df_clean(nanMask, :) = [];

    % Sort by y
    df_clean = sortrows(df_clean, y_col);

    % De-duplicate based on velocity
    [~, ia] = unique(df_clean.(vel_col), 'first');
    df_clean = df_clean(ia, :);
end

function [thickness, lower_vel_for_dat] = find_thickness_robust_MATLAB(y, vel_norm, upper, lower, min_sep)
    if nargin < 5
        min_sep = 1e-9;
    end

    y   = y(:);
    vel = vel_norm(:);

    below = vel < lower;
    above = vel > upper;

    lower_vel_for_dat = NaN;

    if ~any(above)
        thickness = NaN;
        lower_vel_for_dat = NaN;
        return;
    end

    if any(below)
        idx_below = find(below);
        i_low = idx_below(end);
        if i_low >= numel(vel)
            thickness = NaN;
            lower_vel_for_dat = NaN;
            return;
        end

        y1 = y(i_low);
        y2 = y(i_low + 1);
        v1 = vel(i_low);
        v2 = vel(i_low + 1);
        if v2 == v1
            thickness = NaN;
            lower_vel_for_dat = NaN;
            return;
        end
        y_lower = y1 + (lower - v1) * (y2 - y1) / (v2 - v1);
        lower_vel_for_dat = NaN;
    else
        if numel(vel) <= 5
            thickness = NaN;
            lower_vel_for_dat = NaN;
            return;
        end
        vel_tail = vel(6:end);
        [~, idx_min_tail] = min(vel_tail);
        i_min = idx_min_tail + 5;
        i_low = i_min;

        y_lower = y(i_low);
        lower_vel_for_dat = vel(i_low);
    end

    idx_above = find(above);
    i_up = idx_above(1);
    if i_up == 1
        thickness = NaN;
        return;
    end

    y1 = y(i_up - 1);
    y2 = y(i_up);
    v1 = vel(i_up - 1);
    v2 = vel(i_up);
    if v2 == v1
        thickness = NaN;
        return;
    end

    y_upper = y1 + (upper - v1) * (y2 - y1) / (v2 - v1);

    thickness = y_upper - y_lower;
    if thickness <= min_sep
        thickness = NaN;
    end
end

function add_header_to_dat(filename, header)
    txt = fileread(filename);
    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open file %s for writing header.', filename);
    end
    fprintf(fid, '%s\n', header);
    fprintf(fid, '%s', txt);
    fclose(fid);
end