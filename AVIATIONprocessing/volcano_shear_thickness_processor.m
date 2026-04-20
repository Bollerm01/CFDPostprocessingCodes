%% ============================================================
%  Volcano Shear Layer Thickness Processing Script 
% ============================================================

clc;

%% Excel GUI inputs
[filename, pathname] = uigetfile('*.xlsx', 'Select Input Excel Workbook');
if isequal(filename,0)
    errordlg('No Excel file selected.', 'Error');
    return;
end

excel_file = fullfile(pathname, filename);

% Gets file edge geometry type (before first underscore)
parts = strsplit(filename, '_');
geometryType = parts{1};

% Uses the same directory as the workbook
output_dir = fullfile(pathname, ['ShearResults_' geometryType]);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Create subfolders
dat_dir   = fullfile(output_dir, 'DAT_Files');
plots_dir = fullfile(output_dir, 'Plots');
if ~exist(dat_dir, 'dir')
    mkdir(dat_dir);
end
if ~exist(plots_dir, 'dir')
    mkdir(plots_dir);
end

%% COLUMN NAMES (EDIT IF NEEDED)
Y_COL         = 'Y_norm';
VELX_COL      = 'velocityx';
VELXAVG_COL   = 'velocityxavg';
VELMAG_COL    = 'velocitymag';
VELMAGAVG_COL = 'velocitymagavg';

VELOCITY_COLS = {VELX_COL, VELXAVG_COL, VELMAG_COL, VELMAGAVG_COL};

THRESHOLDS = [0.95 0.05; 0.90 0.10];  % rows = [upper lower]

% Locations for freestream sheets and per-location results
LOCATIONS = {'MP', 'z25', 'z75'};  % corresponding to sheets US_MP, US_z25, US_z75


%% LOAD WORKBOOK (sheet names)
[status, sheets] = xlsfinfo(excel_file);
if isempty(status)
    errordlg('Unable to read Excel file or no sheets found.', 'Error');
    return;
end

%% FREESTREAM CALCULATION FROM US_{loc} SHEETS
freestream_mag = containers.Map();  % freestream velocitymagavg per loc
freestream_x   = containers.Map();  % freestream velocityx per loc

for iLoc = 1:numel(LOCATIONS)
    loc = LOCATIONS{iLoc};
    fs_sheet = ['US_' loc];

    if ~ismember(fs_sheet, sheets)
        errordlg(['Freestream sheet "' fs_sheet '" not found.'], 'Error');
        return;
    end

    df_fs = readtable(excel_file, 'Sheet', fs_sheet);
    if ~ismember(Y_COL, df_fs.Properties.VariableNames)
        errordlg(['Column "' Y_COL '" not found in sheet "' fs_sheet '".'], 'Error');
        return;
    end

    df_fs = sortrows(df_fs, Y_COL);

    % tail (second half)
    nRows = height(df_fs);
    df_fs_tail = df_fs( floor(nRows/2)+1 : end, : );

    if ~ismember(VELMAGAVG_COL, df_fs_tail.Properties.VariableNames)
        errordlg(['Column "' VELMAGAVG_COL '" not found in sheet "' fs_sheet '".'], 'Error');
        return;
    end
    if ~ismember(VELX_COL, df_fs_tail.Properties.VariableNames)
        errordlg(['Column "' VELX_COL '" not found in sheet "' fs_sheet '".'], 'Error');
        return;
    end

    freestream_mag(loc) = mean(df_fs_tail.(VELMAGAVG_COL), 'omitnan');
    freestream_x(loc)   = mean(df_fs_tail.(VELX_COL), 'omitnan');

    fprintf('========================================\n');
    fprintf('Freestream values for %s\n', loc);
    fprintf('velocitymagavg_fs_%s = %.6f\n', loc, freestream_mag(loc));
    fprintf('velocityx_fs_%s      = %.6f\n', loc, freestream_x(loc));
    fprintf('========================================\n');
end

%% NORMALIZED XLSX OUTPUT (ONE WORKBOOK PER LOCATION)
writers = containers.Map();  % store file names

for iLoc = 1:numel(LOCATIONS)
    loc = LOCATIONS{iLoc};
    norm_xlsx = fullfile(output_dir, sprintf('normalized_velocity_profiles_%s.xlsx', loc));
    writers(loc) = norm_xlsx;

    % Freestream table
    freestream_tbl = table(...
        {'velocitymagavg'; 'velocityxavg'},...
        [freestream_mag(loc); freestream_x(loc)],...
        'VariableNames', {'quantity', 'value'}...
    );
    % Write as first sheet
    writetable(freestream_tbl, norm_xlsx, 'Sheet', 'freestream', 'WriteMode', 'overwrite');
end

%% MAP OF NORMALIZED COLS
normalized_cols = containers.Map();
normalized_cols('velocityx_norm')      = '$$V_x$$';
normalized_cols('velocityxavg_norm')   = '$$\bar{V_x}$$';
normalized_cols('velocitymag_norm')    = '$$|V|$$';
normalized_cols('velocitymagavg_norm') = '$$|\bar{V}|$$';

norm_col_keys = keys(normalized_cols);

% results(loc)[(norm_col, threshold)] -> list of rows [xL thickness lower_vel]
results = struct();
for iLoc = 1:numel(LOCATIONS)
    loc = LOCATIONS{iLoc};
    results.(loc) = struct();
    for iNorm = 1:numel(norm_col_keys)
        norm_col = norm_col_keys{iNorm};
        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            key = make_key(norm_col, upper, lower);
            results.(loc).(key) = [];
        end
    end
end

%% PROCESS AXIAL SHEETS (GROUPED BY LOCATION)

% Axial sheets: everything that starts with 'xL'
all_axial_sheets = sheets(startsWith(sheets, 'xL'));

% Group axial sheets by plane/location based on suffix (_MP, _z25, _z75)
axial_sheets_by_loc = struct();
for iLoc = 1:numel(LOCATIONS)
    loc = LOCATIONS{iLoc};
    axial_sheets_by_loc.(loc) = {};
end

for iS = 1:numel(all_axial_sheets)
    sname = all_axial_sheets{iS};
    loc = get_loc_from_sheet_MATLAB(sname, LOCATIONS);
    if ~isempty(loc)
        axial_sheets_by_loc.(loc){end+1} = sname; %#ok<AGROW>
    end
end

% Process sheets per location (each sheet only contributes to its own plane)
for iLoc = 1:numel(LOCATIONS)
    loc = LOCATIONS{iLoc};
    sheet_list = axial_sheets_by_loc.(loc);
    for iS = 1:numel(sheet_list)
        sheet = sheet_list{iS};
        xL = parse_xL_MATLAB(sheet);
        if xL < 0 || xL > 1.1
            fprintf('Skipping sheet %s (x/L = %.3f)\n', sheet, xL);
            continue;
        end

        df = readtable(excel_file, 'Sheet', sheet);

        % Basic cleaning
        df_clean = clean_velocity_dataframe_MATLAB(df, Y_COL, VELOCITY_COLS, VELMAGAVG_COL);

        % Pruning ONLY (no interpolation)
        df_pruned = prune_profile_keep_first_y_MATLAB(df_clean, Y_COL, VELOCITY_COLS, VELMAGAVG_COL, VELXAVG_COL);

        % Use pruned y for thickness calculations
        y = df_pruned.(Y_COL);

        % Normalize this pruned profile using freestream for THIS loc only
        df_loc = df_pruned;
        df_loc.velocityx_norm      = df_loc.(VELX_COL)./ freestream_x(loc);
        df_loc.velocityxavg_norm   = df_loc.(VELXAVG_COL)./ freestream_x(loc);
        df_loc.velocitymag_norm    = df_loc.(VELMAG_COL)./ freestream_mag(loc);
        df_loc.velocitymagavg_norm = df_loc.(VELMAGAVG_COL)./ freestream_mag(loc);

        % Write normalized data into the location-specific workbook
        norm_xlsx = writers(loc);
        writetable(df_loc, norm_xlsx, 'Sheet', sheet, 'WriteMode', 'overwrite');

        % Thickness calculations for all normalized columns
        for iNorm = 1:numel(norm_col_keys)
            norm_col = norm_col_keys{iNorm};
            vel_used = df_loc.(norm_col);
            for iThr = 1:size(THRESHOLDS,1)
                upper = THRESHOLDS(iThr,1);
                lower = THRESHOLDS(iThr,2);
                [thickness, lower_vel_for_dat] = find_thickness_robust_MATLAB(y, vel_used, upper, lower);

                key = make_key(norm_col, upper, lower);
                results.(loc).(key) = [...
                    results.(loc).(key);...
                    xL, thickness, lower_vel_for_dat...
                ];
            end
        end
    end
end

%% OUTPUT DAT FILES + OVERLAID PLOTS (PNG + FIG) FOR EACH LOCATION

for iLoc = 1:numel(LOCATIONS)
    loc = LOCATIONS{iLoc};

    % 1) Write DAT files for all normalized quantities and thresholds
    for iNorm = 1:numel(norm_col_keys)
        norm_col = norm_col_keys{iNorm};
        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            key = make_key(norm_col, upper, lower);
            data = results.(loc).(key);
            if isempty(data)
                continue;
            end

            % Sort by xL (col 1)
            data = sortrows(data, 1);

            dat_path = fullfile(dat_dir,...
                sprintf('thickness_%s_%d_%d_%s_Volcano.dat', norm_col, round(upper*100), round(lower*100), loc));
            % data columns: xL, thickness, lower_vel_for_dat
            writematrix(data, dat_path, 'Delimiter', ' ');
            % add header manually (rewrite file with header)
            add_header_to_dat(dat_path, 'xL thickness lower_vel_for_dat');
        end
    end

    % 2) Overlaid plots ONLY for average quantities per location
    avg_norm_cols = {'velocityxavg_norm', 'velocitymagavg_norm'};
    for iNorm = 1:numel(avg_norm_cols)
        norm_col = avg_norm_cols{iNorm};
        nice_name = normalized_cols(norm_col);

        hfig = figure('Visible','off');
        hold on;
        has_data = false;

        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            key = make_key(norm_col, upper, lower);
            data = results.(loc).(key);
            if isempty(data)
                continue;
            end
            data = sortrows(data, 1); % sort by xL
            % Step 1: make basic percent text (sprintf needs %% to print %)
            pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
            % pct_text is now e.g. '90%/10%'
        
            % Step 2: escape % for LaTeX: % -> \%
            pct_text = strrep(pct_text, '%', '\%');
            % pct_text is now '90\%/10\%'
        
            % Step 3: append LaTeX math for U/U_infinity
            label = sprintf('%s $V_x/V_{x,\\infty}$', pct_text);
            plot(data(:,1), data(:,2), '-o', 'DisplayName', label, 'LineWidth',1.5);
            has_data = true;
        end

        if ~has_data
            close(hfig);
            continue;
        end

        % Location Labelling
        switch loc
            case 'MP'
                locLabel = '$$z/w = 0.50$$';
            case 'z25'
                locLabel = '$$z/w = 0.25$$';
            case 'z75'
                locLabel = '$$z/w = 0.75$$';
        end

        xlabel('x/L', 'Interpreter', 'latex');
        ylabel('Normalized Shear Layer Thickness', 'Interpreter', 'latex');
        title(sprintf('%s Thickness, %s', nice_name, locLabel), 'Interpreter', 'latex');
        grid on;
        legend('Location', 'best');
        hold off;

        % PNG (overlaid thresholds, averages only)
        plot_path_png = fullfile(plots_dir,...
            sprintf('shearThick_%s_overlaid_%s_Volcano.png', norm_col, loc));
        print(hfig, '-dpng', '-r300', plot_path_png);

        % FIG (MATLAB figure)
        plot_path_fig = fullfile(plots_dir,...
            sprintf('shearThick_%s_overlaid_%s_Volcano.fig', norm_col, loc));
        savefig(hfig, plot_path_fig);

        close(hfig);
    end
end

%% OVERLAY ALL PLANES FOR EACH AVG VARIABLE

avg_norm_cols = {'velocityxavg_norm', 'velocitymagavg_norm'};

% Define unique colors for each plane
colorMap = containers.Map();
colorMap('MP')  = [0.00, 0.45, 0.74];  % blue
colorMap('z25') = [0.85, 0.33, 0.10];  % reddish
colorMap('z75') = [0.47, 0.67, 0.19];  % greenish

% Define line styles for thresholds (same for all planes)
% THRESHOLDS rows are [upper lower] in order
lineStyles = {'-', '--'};  % e.g., 95/5 solid, 90/10 dashed

for iNorm = 1:numel(avg_norm_cols)
    norm_col = avg_norm_cols{iNorm};
    nice_name = normalized_cols(norm_col);

    hfig = figure('Visible','off');
    hold on;
    has_data = false;

    % Loop over planes and thresholds and overlay all on one plot
    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};

        % Location label text
        switch loc
            case 'MP'
                locLabel = 'z/w = 0.50';
            case 'z25'
                locLabel = 'z/w = 0.25';
            case 'z75'
                locLabel = 'z/w = 0.75';
            otherwise
                locLabel = loc;
        end

        % Color for this plane
        if isKey(colorMap, loc)
            thisColor = colorMap(loc);
        else
            thisColor = [0 0 0]; % fallback: black
        end

        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            key   = make_key(norm_col, upper, lower);
            data  = results.(loc).(key);
            if isempty(data)
                continue;
            end
            data = sortrows(data, 1);

            % Step 1: make basic percent text (sprintf needs %% to print %)
            pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
            % pct_text is now e.g. '90%/10%'
        
            % Step 2: escape % for LaTeX: % -> \%
            pct_text = strrep(pct_text, '%', '\%');
            % pct_text is now '90\%/10\%'
        
            % Step 3: append LaTeX math for U/U_infinity
            label = sprintf('%s, %s $V_x/V_{x,\\infty}$', locLabel, pct_text);


            % Choose line style by threshold index
            ls = lineStyles{min(iThr, numel(lineStyles))};

            plot(data(:,1), data(:,2),...
                 'LineStyle', ls,...
                 'Color', thisColor,...
                 'Marker', 'o',...
                 'LineWidth', 1.5,...
                 'DisplayName', label);

            has_data = true;
        end
    end

    if ~has_data
        close(hfig);
        continue;
    end

    % Geometry label text
    switch geometryType
        case 'RD00'
            geoLabel = 'R/D = 0.0';
        case 'RD17'
            geoLabel = 'R/D = 0.17';
        case 'RD52'
            geoLabel = 'R/D = 0.52';
        otherwise
            geoLabel = '';
    end

    xlabel('x/L', 'Interpreter', 'latex');
    ylabel('Normalized Shear Layer Thickness', 'Interpreter', 'latex');
    title(sprintf('%s Thickness, %s', nice_name, geoLabel), 'Interpreter', 'latex');
    grid on;
    legend('Location', 'best', 'Interpreter','latex');  % let MATLAB choose best in-axes position
    % Catch to display legend not overtop Vx avg data
    if strcmp(norm_col, 'velocityxavg_norm')
        ylim([0.4 1.6])
    end

    hold off;

    % Save combined-all-planes plots
    plot_path_png = fullfile(plots_dir,...
        sprintf('shearThick_%s_allPlanes_Volcano.png', norm_col));
    print(hfig, '-dpng', '-r300', plot_path_png);

    plot_path_fig = fullfile(plots_dir,...
        sprintf('shearThick_%s_allPlanes_Volcano.fig', norm_col));
    savefig(hfig, plot_path_fig);

    close(hfig);
end

fprintf('Processing complete.\nFiles stored at: %s\n', output_dir);


%% ============================================================
%  LOCAL HELPER FUNCTIONS (allowed after script since R2016b)
% ============================================================

function key = make_key(norm_col, upper, lower)
    key = sprintf('%s_%g_%g', norm_col, upper, lower);
    key = strrep(key, '.', 'p');
    key = strrep(key, '-', 'm');
end

function xL = parse_xL_MATLAB(sheet_name)
    base = regexprep(sheet_name, '_(MP|z25|z75)$', '');

    if any(strcmp(base, {'xL_neg2','xLneg2'}))
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

function loc = get_loc_from_sheet_MATLAB(sheet_name, valid_locs)
    parts = strsplit(sheet_name, '_');
    if isempty(parts)
        loc = '';
        return;
    end
    suffix = parts{end};
    if any(strcmp(suffix, valid_locs))
        loc = suffix;
    else
        loc = '';
    end
end

function df_clean = clean_velocity_dataframe_MATLAB(df, y_col, velocity_cols, duplicate_ref_col)
    required_cols = [{y_col}, velocity_cols(:)'];
    missing = setdiff(required_cols, df.Properties.VariableNames);
    if ~isempty(missing)
        error('Missing required columns: %s', strjoin(missing, ', '));
    end

    df_clean = df(:, required_cols);

    nanMask = any(ismissing(df_clean), 2);
    df_clean(nanMask, :) = [];

    df_clean = sortrows(df_clean, y_col);

    [~, ia] = unique(df_clean.(duplicate_ref_col), 'first');
    df_clean = df_clean(ia, :);
end

function df_pruned = prune_profile_keep_first_y_MATLAB(df, y_col, velocity_cols, VELMAGAVG_COL, VELXAVG_COL)
    df_sorted = sortrows(df, y_col);

    [~, ia] = unique(df_sorted.(VELMAGAVG_COL), 'first');
    df_pruned = df_sorted(ia, :);

    [~, ia2] = unique(df_pruned.(VELXAVG_COL), 'first');
    df_pruned = df_pruned(ia2, :);

    df_pruned = sortrows(df_pruned, y_col);

    required_cols = [{y_col}, velocity_cols(:)'];
    df_pruned = df_pruned(:, required_cols);
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