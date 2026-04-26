%% ============================================================
%  Volcano Shear Layer Thickness Processing Script (3 Geometries)
% ============================================================

clc;

%% Excel GUI inputs (MULTI-FILE)
[filenames, pathname] = uigetfile('*.xlsx', 'Select 3 Input Excel Workbooks', 'MultiSelect', 'on');

if isequal(filenames,0)
    errordlg('No Excel files selected.', 'Error');
    return;
end

% Ensure filenames is a cell array
if ischar(filenames)
    filenames = {filenames};
end

if numel(filenames) ~= 3
    errordlg('Please select exactly 3 Excel files (one per geometry).', 'Error');
    return;
end

% Pre-allocate containers to hold results across geometries
all_results      = struct();  % all_results.(geometryType).(loc).(key) = [xL thickness lower_vel]
all_output_dirs  = struct();  % output directory per geometry
all_geometryType = cell(1, numel(filenames));

%% COLUMN NAMES (EDIT IF NEEDED)
Y_COL         = 'Y_norm';
VELX_COL      = 'velocityx';
VELXAVG_COL   = 'velocityxavg';
VELMAG_COL    = 'velocitymag';
VELMAGAVG_COL = 'velocitymagavg';

VELOCITY_COLS = {VELX_COL, VELXAVG_COL, VELMAG_COL, VELMAGAVG_COL};

% THRESHOLDS = [0.95 0.05; 0.9 0.1];  % rows = [upper lower]
THRESHOLDS = [0.95 0.05];
% Locations for freestream sheets and per-location results
% LOCATIONS = {'MP', 'z25', 'z75'};  % corresponding to sheets US_MP, US_z25, US_z75
LOCATIONS = {'MP'}; 

%% MAP OF NORMALIZED COLS (LABELS)
% These use $$...$$, but we strip $$ before putting into $...$ for titles.
normalized_cols = containers.Map();
normalized_cols('velocityx_norm')      = '$$V_x/V_{x,\infty}$$';
normalized_cols('velocityxavg_norm')   = '$$\bar{V_x}/V_{x,\infty}$$';
normalized_cols('velocitymag_norm')    = '$$|V|/V_{\infty}$$';
normalized_cols('velocitymagavg_norm') = '$$|\bar{V}|/V_{\infty}$$';

norm_col_keys = keys(normalized_cols);

%% LOOP OVER GEOMETRY FILES
for iFile = 1:numel(filenames)

    filename   = filenames{iFile};
    excel_file = fullfile(pathname, filename);

    % Gets file edge geometry type (before first underscore)
    parts = strsplit(filename, {'_','.'});
    geometryType = parts{2};
    all_geometryType{iFile} = geometryType;

    % Uses the same directory as the workbook, with geometry-specific folder
    output_dir = fullfile(pathname, ['ShearResults_' geometryType]);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    all_output_dirs.(geometryType) = output_dir;

    % Create subfolders (per-geometry)
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

    %% FREESTREAM CALCULATION FROM US_{loc} SHEETS
    freestream_mag = containers.Map();  % freestream velocitymagavg per loc
    freestream_x   = containers.Map();  % freestream velocityx per loc

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};
        fs_sheet = ['US_' loc];

        if ~ismember(fs_sheet, sheets)
            errordlg(['Freestream sheet "' fs_sheet '" not found in ' filename '.'], 'Error');
            return;
        end

        df_fs = readtable(excel_file, 'Sheet', fs_sheet);
        if ~ismember(Y_COL, df_fs.Properties.VariableNames)
            errordlg(['Column "' Y_COL '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
            return;
        end

        df_fs = sortrows(df_fs, Y_COL);

        % High res: last 5 rows
        nRows = height(df_fs);
        df_fs_tail = df_fs( max(1,nRows-5) : nRows, : );

        if ~ismember(VELMAGAVG_COL, df_fs_tail.Properties.VariableNames)
            errordlg(['Column "' VELMAGAVG_COL '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
            return;
        end
        if ~ismember(VELX_COL, df_fs_tail.Properties.VariableNames)
            errordlg(['Column "' VELX_COL '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
            return;
        end

        freestream_mag(loc) = mean(df_fs_tail.(VELMAGAVG_COL), 'omitnan');
        freestream_x(loc)   = mean(df_fs_tail.(VELX_COL), 'omitnan');

        fprintf('========================================\n');
        fprintf('Freestream values for %s (%s)\n', loc, geometryType);
        fprintf('velocitymagavg_fs_%s = %.6f\n', loc, freestream_mag(loc));
        fprintf('velocityx_fs_%s      = %.6f\n', loc, freestream_x(loc));
        fprintf('========================================\n');
    end

    %% NORMALIZED XLSX OUTPUT (ONE WORKBOOK PER LOCATION)
    writers = containers.Map();  % store file names

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};
        norm_xlsx = fullfile(output_dir, sprintf('normalized_velocity_profiles_%s_%s.xlsx', loc, geometryType));
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

    %% RESULTS STRUCT FOR THIS GEOMETRY
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
    all_axial_sheets = sheets(startsWith(sheets, 'xL'));

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
                fprintf('Skipping sheet %s (x/L = %.3f) in %s\n', sheet, xL, geometryType);
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

    %% OUTPUT DAT FILES + OVERLAID PLOTS (PNG + FIG) FOR EACH LOCATION (THIS GEOMETRY ONLY)

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
                    sprintf('thickness_%s_%d_%d_%s_%s_Volcano.dat', norm_col, round(upper*100), round(lower*100), loc, geometryType));
                % data columns: xL, thickness, lower_vel_for_dat
                writematrix(data, dat_path, 'Delimiter', ' ');
                % add header manually (rewrite file with header)
                add_header_to_dat(dat_path, 'xL thickness lower_vel_for_dat');
            end
        end

        % 2) Overlaid plots ONLY for average quantities per location (THIS geometry)
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

                pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
                pct_text = strrep(pct_text, '%', '\%');
                label = sprintf('%s $V_x/V_{x,\\infty}$', pct_text);

                plot(data(:,1), data(:,2), '-o', 'DisplayName', label, 'LineWidth',1.5);
                has_data = true;
            end

            if ~has_data
                close(hfig);
                continue;
            end

            switch loc
                case 'MP'
                    locLabel = '$$z/w = 0.50$$';
                case 'z25'
                    locLabel = '$$z/w = 0.25$$';
                case 'z75'
                    locLabel = '$$z/w = 0.75$$';
                otherwise
                    locLabel = loc;
            end

            % Axes labels (you can keep or adjust these)
            xlabel('$x/L$', 'Interpreter', 'latex');
            ylabel('Normalized Shear Layer Thickness', 'Interpreter', 'latex');

            % -------- TITLE (FIXED LATEX) --------
            % nice_name and locLabel contain $$...$$; strip and embed in $...$
            nice_core = regexprep(nice_name, '[$]', '');   % e.g. 'V_x/V_{x,\infty}'
            loc_core  = regexprep(locLabel,  '[$]', '');   % e.g. 'z/w = 0.50'

            % Put main quantity in math, rest as text
            % Example: '$V_x/V_{x,\infty}$ Thickness, z/w = 0.50 (RD00)'
            title_str = sprintf('$%s$ Thickness, %s (%s)',...
                                nice_core, loc_core, geometryType);
            title(title_str, 'Interpreter', 'latex');

            grid on;
            legend('Location', 'best');
            hold off;

            plot_path_png = fullfile(plots_dir,...
                sprintf('shearThick_%s_overlaid_%s_%s_Volcano.png', norm_col, loc, geometryType));
            print(hfig, '-dpng', '-r300', plot_path_png);

            plot_path_fig = fullfile(plots_dir,...
                sprintf('shearThick_%s_overlaid_%s_%s_Volcano.fig', norm_col, loc, geometryType));
            savefig(hfig, plot_path_fig);

            plot_path_pdf = fullfile(plots_dir,...
                sprintf('shearThick_%s_overlaid_%s_%s_Volcano.pdf', norm_col, loc, geometryType));
            exportgraphics(hfig, plot_path_pdf, 'ContentType','vector');

            close(hfig);
        end
    end

    %% OVERLAY ALL PLANES FOR EACH AVG VARIABLE (WITHIN THIS GEOMETRY)

    avg_norm_cols = {'velocityxavg_norm', 'velocitymagavg_norm'};

    % Define unique colors for each plane
    colorMapPlanes = containers.Map();
    colorMapPlanes('MP')  = [0.00, 0.45, 0.74];  % blue
    colorMapPlanes('z25') = [0.85, 0.33, 0.10];  % reddish
    colorMapPlanes('z75') = [0.47, 0.67, 0.19];  % greenish

    % Define line styles for thresholds (same for all planes)
    lineStyles = {'-', '--'};  % example if you add more thresholds

    for iNorm = 1:numel(avg_norm_cols)
        norm_col = avg_norm_cols{iNorm};
        nice_name = normalized_cols(norm_col);

        hfig = figure('Visible','off');
        hold on;
        has_data = false;

        for iLoc = 1:numel(LOCATIONS)
            loc = LOCATIONS{iLoc};

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

            if isKey(colorMapPlanes, loc)
                thisColor = colorMapPlanes(loc);
            else
                thisColor = [0 0 0];
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

                pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
                pct_text = strrep(pct_text, '%', '\%');
                label = sprintf('%s, %s $V_x/V_{x,\\infty}$', locLabel, pct_text);

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

        xlabel('$x/L$', 'Interpreter', 'latex');
        ylabel('$$\delta_{SL}/D$$', 'Interpreter', 'latex');

        % -------- TITLE (FIXED LATEX) --------
        % nice_name has $$...$$; strip and embed
        nice_core = regexprep(nice_name, '[$]', '');   % e.g. 'V_x/V_{x,\infty}'

        % Example: '$V_x/V_{x,\infty}$ Thickness, R/D = 0.17'
        title_str = sprintf('$%s$ Thickness, %s', nice_core, geoLabel);
        title(title_str, 'Interpreter', 'latex');

        grid on;
        legend('Location', 'best', 'Interpreter','latex');
        hold off;

        plot_path_png = fullfile(plots_dir,...
            sprintf('shearThick_%s_allPlanes_%s_Volcano.png', norm_col, geometryType));
        print(hfig, '-dpng', '-r300', plot_path_png);

        plot_path_fig = fullfile(plots_dir,...
            sprintf('shearThick_%s_allPlanes_%s_Volcano.fig', norm_col, geometryType));
        savefig(hfig, plot_path_fig);

        close(hfig);
    end

    % Store this geometry's results in global structure
    all_results.(geometryType) = results;

    fprintf('Processing complete for %s.\nFiles stored at: %s\n', geometryType, output_dir);
end

%% ============================================================
%  CROSS-GEOMETRY OVERLAYS
% ============================================================

% We overlay different geometries for the SAME:
%   - plane (loc)
%   - avg_norm_col (velocityxavg_norm, velocitymagavg_norm)
%   - threshold pair (upper/lower)

avg_norm_cols = {'velocityxavg_norm', 'velocitymagavg_norm'};

% Colors per geometry
colorMapGeom = containers.Map();
colorMapGeom('RD00') = [1.00, 0.80, 0.20];  % yellow
colorMapGeom('RD17') = [0.85, 0.33, 0.10];  % red
colorMapGeom('RD52') = [0.00, 0.45, 0.74];  % blue

% Line styles for different thresholds
lineStyles = {'-', '--', ':'};

% Use plots_dir of the first geometry for cross-geometry plots
firstGeom = all_geometryType{1};
plots_dir_global = fullfile(all_output_dirs.(firstGeom), 'Plots_Global');
if ~exist(plots_dir_global, 'dir')
    mkdir(plots_dir_global);
end

for iNorm = 1:numel(avg_norm_cols)
    norm_col = avg_norm_cols{iNorm};
    nice_name = normalized_cols(norm_col);

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};

        % Plane label
        switch loc
            case 'MP'
                locLabelLatex = '$$z/w = 0.50$$';
                locLabelPlain = 'z_w_0p50';
            case 'z25'
                locLabelLatex = '$$z/w = 0.25$$';
                locLabelPlain = 'z_w_0p25';
            case 'z75'
                locLabelLatex = '$$z/w = 0.75$$';
                locLabelPlain = 'z_w_0p75';
            otherwise
                locLabelLatex = loc;
                locLabelPlain = loc;
        end

        % For each threshold pair
        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            key   = make_key(norm_col, upper, lower);

            hfig = figure('Visible','off');
            hold on;
            has_data = false;

            for iFile = 1:numel(all_geometryType)
                geometryType = all_geometryType{iFile};
                if ~isfield(all_results, geometryType)
                    continue;
                end
                resultsGeom = all_results.(geometryType);

                if ~isfield(resultsGeom, loc)
                    continue;
                end
                if ~isfield(resultsGeom.(loc), key)
                    continue;
                end

                data = resultsGeom.(loc).(key);
                if isempty(data)
                    continue;
                end
                data = sortrows(data, 1);

                if isKey(colorMapGeom, geometryType)
                    thisColor = colorMapGeom(geometryType);
                else
                    thisColor = [0 0 0];
                end

                % geometry label
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

            xlabel('$x/L$', 'Interpreter', 'latex');
            ylabel('$$\delta_{SL}/D$$', 'Interpreter', 'latex');

            % -------- TITLE (FIXED LATEX) --------
            % nice_name & locLabelLatex: strip $$, embed core in $...$
            nice_core = regexprep(nice_name,     '[$]', '');
            loc_core  = regexprep(locLabelLatex, '[$]', '');

            % Example: '$V_x/V_{x,\infty}$ Thickness, z/w = 0.50'
            title_str = sprintf('$%s$ Thickness, %s', nice_core, loc_core);
            title(title_str, 'Interpreter', 'latex');

            grid on;
            legend('Location', 'best', 'Interpreter','latex');
            hold off;

            % Save cross-geometry plot
            plot_name_png = sprintf('shearThick_%s_%s_upper%d_lower%d_allGeometries_Volcano.png',...
                norm_col, locLabelPlain, round(upper*100), round(lower*100));
            plot_name_fig = strrep(plot_name_png, '.png', '.fig');
            plot_name_pdf = strrep(plot_name_png, '.png', '.pdf');

            print(hfig, '-dpng', '-r300', fullfile(plots_dir_global, plot_name_png));
            savefig(hfig, fullfile(plots_dir_global, plot_name_fig));
            exportgraphics(hfig, fullfile(plots_dir_global, plot_name_pdf), 'ContentType','vector');
            close(hfig);
        end
    end
end

fprintf('Cross-geometry overlays complete.\nGlobal plots stored at: %s\n', plots_dir_global);

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

    n = numel(vel);
    lower_vel_for_dat = NaN;

    above_upper = vel > upper;
    below_lower = vel < lower;

    idx_above = find(above_upper);

    if ~isempty(idx_above)
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
        upper_index_for_search = i_up;

    else
        can_extrap = false;
        if n >= 4 && vel(end) < upper
            v_last4 = vel(end-3:end);
            if all(diff(v_last4) > 0)
                can_extrap = true;
            end
        end

        if ~can_extrap
            thickness = NaN;
            return;
        end

        y_fit = y(end-2:end);
        v_fit = vel(end-2:end);

        p = polyfit(y_fit, v_fit, 1);
        a = p(1);
        b = p(2);

        if a <= 0
            thickness = NaN;
            return;
        end

        y_upper = (upper - b) / a;

        if y_upper <= y(end)
            thickness = NaN;
            return;
        end

        upper_index_for_search = n;
    end

    indices_below_upper_region = (1:n)' < upper_index_for_search;
    candidate_below = below_lower & indices_below_upper_region;

    idx_below = find(candidate_below);

    if isempty(idx_below)
        thickness = NaN;
        return;
    end

    i_low_below = idx_below(end);

    if i_low_below >= n
        thickness = NaN;
        return;
    end

    y1 = y(i_low_below);
    y2 = y(i_low_below + 1);
    v1 = vel(i_low_below);
    v2 = vel(i_low_below + 1);

    if v2 == v1
        thickness = NaN;
        return;
    end

    y_lower = y1 + (lower - v1) * (y2 - y1) / (v2 - v1);
    lower_vel_for_dat = lower;

    thickness = y_upper - y_lower;

    if thickness <= min_sep
        thickness = NaN;
        lower_vel_for_dat = NaN;
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