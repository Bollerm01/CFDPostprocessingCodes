%% ============================================================
%  Volcano/VULCAN Shear Layer Thickness Processing Script
%  - Geometries: RD00, RD52
%  - Sources: Volcano (full + slice), VULCAN (full)
%  - Quantity: $$\delta_{SL}/D$$ vs $$x/L$$ using $$\text{velocityxavg\_norm}$$
%
%  Styles:
%    - Volcano Slice: triangles (^) with dotted lines (:)
%    - Volcano Full:  circles (o)  with dashed lines (--)
%    - VULCAN Full:   squares (s)  with solid lines (-)
%
%  Legends:
%    - 3 rows x 2 columns, below each plot (global and per-geometry)
%
%  Extra functionality:
%    - Additional global plots (for slice, full Volcano, and VULCAN sets)
%      where each $$\delta_{SL}$$ curve is divided by the maximum
%      $$\delta_{SL}$$ of the RD00 case of the same type:
%        * Volcano Slice   normalized by max $$\delta_{SL}$$ of RD00 Volcano Slice
%        * Volcano Full    normalized by max $$\delta_{SL}$$ of RD00 Volcano Full
%        * VULCAN          normalized by max $$\delta_{SL}$$ of RD00 VULCAN
% ============================================================

clc;

%% Excel GUI inputs (MULTI-FILE)
[filenames, pathname] = uigetfile('*.xlsx', ...
    'Select 6 Input Excel Workbooks (Volcano + VULCAN)', ...
    'MultiSelect', 'on');

if isequal(filenames,0)
    errordlg('No Excel files selected.', 'Error');
    return;
end

if ischar(filenames)
    filenames = {filenames};
end

if numel(filenames) ~= 6
    errordlg(['Please select exactly 6 Excel files:' newline ...
              '  - VolcanoCondensedProbeData_RD00.xlsx' newline ...
              '  - VolcanoCondensedProbeData_RD52.xlsx' newline ...
              '  - CondensedProbeData_RD0_Slice.xlsx (Volcano RD00 Slice)' newline ...
              '  - CondensedProbeData_RD5_Slice.xlsx (Volcano RD52 Slice, if used)' newline ...
              '  - VULCANCondensedProbeData_RD00.xlsx' newline ...
              '  - VULCANCondensedProbeData_RD52.xlsx'], ...
              'Error');
    return;
end

%% Parse geometry, slice, and source (Volcano vs VULCAN) from filenames
fileInfo = struct('filename', [], 'geometryBase', [], 'isSlice', [], ...
                  'sourceType', [], 'geometryKey', [], 'legendLabel', []);
allowedBases = {'RD00','RD52'};

for iFile = 1:numel(filenames)
    filename = filenames{iFile};

    [~, nameOnly, ~] = fileparts(filename);

    % --- 1) Source type: VULCAN vs Volcano (default: Volcano)
    if contains(nameOnly, 'VULCAN', 'IgnoreCase', true)
        sourceType  = 'VULCAN';
        sourceLabel = 'VULCAN';
    else
        sourceType  = 'Volcano';
        sourceLabel = 'Volcano';
    end

    % --- 2) Slice detection
    isSlice = contains(nameOnly, 'Slice', 'IgnoreCase', true);

    % --- 3) Extract RD token: RD + digits
    tok = regexp(nameOnly, '(RD\d+)', 'tokens', 'once');
    if isempty(tok)
        errordlg(sprintf('Could not find geometry token "RD..." in file "%s".', filename), 'Error');
        return;
    end
    geomToken = tok{1};

    % --- 4) Normalize to RD00 or RD52
    if strcmpi(geomToken, 'RD00') || strcmpi(geomToken, 'RD0')
        geometryBase = 'RD00';
    elseif strcmpi(geomToken, 'RD52') || strcmpi(geomToken, 'RD5')
        geometryBase = 'RD52';
    else
        errordlg(sprintf('Unrecognized geometry token "%s" in file "%s". Only RD00 and RD52 are allowed.', ...
            geomToken, filename), 'Error');
        return;
    end

    if ~ismember(geometryBase, allowedBases)
        errordlg(sprintf('File "%s" has unsupported geometry "%s". Only RD00 and RD52 are allowed.', ...
            filename, geometryBase), 'Error');
        return;
    end

    % --- 5) Build geometryKey and legendLabel
    if isSlice
        geometryKey = sprintf('%s_%s_Slice', geometryBase, sourceType);
        % legendLabel = sprintf('%s %s - Slice', sourceLabel, geometryBase);
        legendLabel = sprintf('%s - Slice', sourceLabel);
    else
        geometryKey = sprintf('%s_%s', geometryBase, sourceType);
        % legendLabel = sprintf('%s %s', sourceLabel, geometryBase);
        legendLabel = sprintf('%s', sourceLabel);
    end

    fileInfo(iFile).filename     = filename;
    fileInfo(iFile).geometryBase = geometryBase;
    fileInfo(iFile).isSlice      = isSlice;
    fileInfo(iFile).sourceType   = sourceType;
    fileInfo(iFile).geometryKey  = geometryKey;
    fileInfo(iFile).legendLabel  = legendLabel;
end

% Optional consistency check
bases   = {fileInfo.geometryBase};
sources = {fileInfo.sourceType};

if ~(any(strcmp(bases,'RD00') & strcmp(sources,'Volcano')) && ...
     any(strcmp(bases,'RD52') & strcmp(sources,'Volcano')) && ...
     any(strcmp(bases,'RD00') & strcmp(sources,'VULCAN'))  && ...
     any(strcmp(bases,'RD52') & strcmp(sources,'VULCAN')))
    warning('Expected at least one Volcano RD00, one Volcano RD52, one VULCAN RD00, and one VULCAN RD52 among the 6 files.');
end

% Global containers
all_results       = struct();  % all_results.(geometryKey).(loc).(key) = [xL thickness lower_vel]
all_output_dirs   = struct();
all_geometryKeys  = cell(1, numel(filenames));
legendLabels      = containers.Map();
geometryBaseOfKey = containers.Map();
sourceOfKey       = containers.Map();

%% COLUMN NAMES (defaults; overridden per file)
Y_COL_DEFAULT         = 'Y_norm';
VELX_COL_DEFAULT      = 'velocityx';
VELXAVG_COL_DEFAULT   = 'velocityxavg';
VELMAG_COL_DEFAULT    = 'velocitymag';
VELMAGAVG_COL_DEFAULT = 'velocitymagavg';

% Thresholds for shear layer thickness
THRESHOLDS = [0.95 0.05];

% Logical locations (only MP, but VULCAN has no sheet suffix)
LOCATIONS = {'MP'}; 

%% MAP OF NORMALIZED COLS (LABELS)
normalized_cols = containers.Map();
normalized_cols('velocityx_norm')      = '$$V_x/V_{x,\infty}$$';
normalized_cols('velocityxavg_norm')   = '$$\bar{V_x}/V_{x,\infty}$$';
normalized_cols('velocitymag_norm')    = '$$|V|/V_{\infty}$$';
normalized_cols('velocitymagavg_norm') = '$$|\bar{V}|/V_{\infty}$$';

norm_col_keys_all = keys(normalized_cols);

%% LOOP OVER FILES (GEOMETRY KEYS)
for iFile = 1:numel(fileInfo)

    filename     = fileInfo(iFile).filename;
    geometryBase = fileInfo(iFile).geometryBase;
    geometryKey  = fileInfo(iFile).geometryKey;
    legendLabel  = fileInfo(iFile).legendLabel;
    sourceType   = fileInfo(iFile).sourceType;

    all_geometryKeys{iFile}        = geometryKey;
    legendLabels(geometryKey)      = legendLabel;
    geometryBaseOfKey(geometryKey) = geometryBase;
    sourceOfKey(geometryKey)       = sourceType;

    excel_file = fullfile(pathname, filename);

    % --- File-specific column names ---
    Y_COL         = Y_COL_DEFAULT;
    VELMAG_COL    = VELMAG_COL_DEFAULT;
    VELMAGAVG_COL = VELMAGAVG_COL_DEFAULT;

    if strcmpi(sourceType, 'VULCAN')
        % VULCAN: only Velocity_X, no mag columns
        VELX_COL_file    = 'Velocity_X';
        VELXAVG_COL_file = 'Velocity_X';
        VELOCITY_COLS_file = {VELX_COL_file, VELXAVG_COL_file};
        norm_col_keys_file = {'velocityx_norm','velocityxavg_norm'};
    else
        % Volcano: full set
        VELX_COL_file    = VELX_COL_DEFAULT;
        VELXAVG_COL_file = VELXAVG_COL_DEFAULT;
        VELOCITY_COLS_file = {VELX_COL_file, VELXAVG_COL_file, VELMAG_COL, VELMAGAVG_COL};
        norm_col_keys_file = norm_col_keys_all;
    end

    % Base-geometry directory
    output_dir = fullfile(pathname, ['ShearResults_' geometryBase]);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    all_output_dirs.(geometryKey) = output_dir;

    % Subfolders
    dat_dir   = fullfile(output_dir, 'DAT_Files');
    plots_dir = fullfile(output_dir, 'Plots');
    if ~exist(dat_dir, 'dir'),   mkdir(dat_dir);   end
    if ~exist(plots_dir, 'dir'), mkdir(plots_dir); end

    %% LOAD WORKBOOK (sheet names)
    [status, sheets] = xlsfinfo(excel_file);
    if isempty(status)
        errordlg(['Unable to read Excel file or no sheets found: ' excel_file], 'Error');
        return;
    end

    %% FREESTREAM CALCULATION
    freestream_mag = containers.Map();
    freestream_x   = containers.Map();

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};

        if strcmpi(sourceType, 'Volcano')
            % Volcano: use US_loc
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
            nRows = height(df_fs);
            df_fs_tail = df_fs(max(1,nRows-5):nRows, :);

            if ~ismember(VELMAGAVG_COL, df_fs_tail.Properties.VariableNames)
                errordlg(['Column "' VELMAGAVG_COL '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
                return;
            end
            if ~ismember(VELX_COL_file, df_fs_tail.Properties.VariableNames)
                errordlg(['Column "' VELX_COL_file '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
                return;
            end

            freestream_mag(loc) = mean(df_fs_tail.(VELMAGAVG_COL), 'omitnan');
            freestream_x(loc)   = mean(df_fs_tail.(VELX_COL_file), 'omitnan');

        else
            % VULCAN: freestream from xL1, last 10 Velocity_X
            fs_sheet = 'xL1';
            if ~ismember(fs_sheet, sheets)
                errordlg(sprintf('For VULCAN file "%s", sheet "%s" not found for freestream.', ...
                    filename, fs_sheet), 'Error');
                return;
            end

            df_fs = readtable(excel_file, 'Sheet', fs_sheet);
            if ~ismember(Y_COL, df_fs.Properties.VariableNames)
                errordlg(['Column "' Y_COL '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
                return;
            end
            if ~ismember(VELX_COL_file, df_fs.Properties.VariableNames)
                errordlg(['Column "' VELX_COL_file '" not found in sheet "' fs_sheet '" in ' filename '.'], 'Error');
                return;
            end

            df_fs = sortrows(df_fs, Y_COL);
            nRows = height(df_fs);
            nTail = min(10, nRows);
            df_tail = df_fs(max(1, nRows - nTail + 1):nRows, :);

            Uinf_est = mean(df_tail.(VELX_COL_file), 'omitnan');

            freestream_mag(loc) = Uinf_est;
            freestream_x(loc)   = Uinf_est;
        end

        fprintf('========================================\n');
        fprintf('Freestream values for %s (%s / %s)\n', loc, geometryBase, legendLabel);
        fprintf('U_inf (mag) = %.6f\n', freestream_mag(loc));
        fprintf('U_inf (x)   = %.6f\n', freestream_x(loc));
        fprintf('========================================\n');
    end

    %% NORMALIZED XLSX OUTPUT (ONE WORKBOOK PER LOCATION)
    writers = containers.Map();

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};
        norm_xlsx = fullfile(output_dir, ...
            sprintf('normalized_velocity_profiles_%s_%s.xlsx', loc, geometryKey));
        writers(loc) = norm_xlsx;

        freestream_tbl = table(...
            {'velocitymagavg'; 'velocityxavg'},...
            [freestream_mag(loc); freestream_x(loc)],...
            'VariableNames', {'quantity', 'value'}...
        );
        writetable(freestream_tbl, norm_xlsx, 'Sheet', 'freestream', 'WriteMode', 'overwrite');
    end

    %% RESULTS STRUCT FOR THIS GEOMETRY KEY
    results = struct();
    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};
        results.(loc) = struct();
        for iNorm = 1:numel(norm_col_keys_file)
            norm_col = norm_col_keys_file{iNorm};
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

    if strcmpi(sourceType, 'Volcano')
        % Volcano: sheets use suffixes like xL0p5_MP
        for iS = 1:numel(all_axial_sheets)
            sname = all_axial_sheets{iS};
            loc = get_loc_from_sheet_MATLAB(sname, LOCATIONS);
            if ~isempty(loc)
                axial_sheets_by_loc.(loc){end+1} = sname; %#ok<AGROW>
            end
        end
    else
        % VULCAN: no suffix; all xL* -> MP
        axial_sheets_by_loc.MP = all_axial_sheets;
    end

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};
        sheet_list = axial_sheets_by_loc.(loc);
        for iS = 1:numel(sheet_list)
            sheet = sheet_list{iS};
            xL = parse_xL_MATLAB(sheet);
            if xL < 0 || xL > 1.1
                fprintf('Skipping sheet %s (x/L = %.3f) in %s (%s)\n', ...
                    sheet, xL, geometryBase, legendLabel);
                continue;
            end

            df = readtable(excel_file, 'Sheet', sheet);

            % Basic cleaning + pruning
            if strcmpi(sourceType, 'VULCAN')
                df_clean  = clean_velocity_dataframe_MATLAB(df, Y_COL, VELOCITY_COLS_file, VELXAVG_COL_file);
                df_pruned = prune_profile_keep_first_y_noMag_MATLAB(df_clean, Y_COL, VELOCITY_COLS_file, VELXAVG_COL_file);
            else
                df_clean  = clean_velocity_dataframe_MATLAB(df, Y_COL, VELOCITY_COLS_file, VELMAGAVG_COL);
                df_pruned = prune_profile_keep_first_y_MATLAB(df_clean, Y_COL, VELOCITY_COLS_file, VELMAGAVG_COL, VELXAVG_COL_file);
            end

            y = df_pruned.(Y_COL);

            % Normalize
            df_loc = df_pruned;
            df_loc.velocityx_norm    = df_loc.(VELX_COL_file)./ freestream_x(loc);
            df_loc.velocityxavg_norm = df_loc.(VELXAVG_COL_file)./ freestream_x(loc);

            if ~strcmpi(sourceType,'VULCAN')
                df_loc.velocitymag_norm    = df_loc.(VELMAG_COL)./ freestream_mag(loc);
                df_loc.velocitymagavg_norm = df_loc.(VELMAGAVG_COL)./ freestream_mag(loc);
            end

            % Write normalized data
            norm_xlsx = writers(loc);
            writetable(df_loc, norm_xlsx, 'Sheet', sheet, 'WriteMode', 'overwrite');

            % Thickness calculations
            for iNorm = 1:numel(norm_col_keys_file)
                norm_col = norm_col_keys_file{iNorm};
                vel_used = df_loc.(norm_col);
                for iThr = 1:size(THRESHOLDS,1)
                    upper = THRESHOLDS(iThr,1);
                    lower = THRESHOLDS(iThr,2);
                    [thickness, lower_vel_for_dat] = ...
                        find_thickness_robust_MATLAB(y, vel_used, upper, lower);

                    key = make_key(norm_col, upper, lower);
                    results.(loc).(key) = [...
                        results.(loc).(key);...
                        xL, thickness, lower_vel_for_dat...
                    ];
                end
            end
        end
    end

    %% OUTPUT DAT FILES + OVERLAID PLOTS (THIS GEOMETRY KEY ONLY)

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};

        % 1) DAT files
        for iNorm = 1:numel(norm_col_keys_file)
            norm_col = norm_col_keys_file{iNorm};
            for iThr = 1:size(THRESHOLDS,1)
                upper = THRESHOLDS(iThr,1);
                lower = THRESHOLDS(iThr,2);
                key = make_key(norm_col, upper, lower);
                data = results.(loc).(key);
                if isempty(data)
                    continue;
                end

                data = sortrows(data, 1);

                dat_path = fullfile(dat_dir,...
                    sprintf('thickness_%s_%d_%d_%s_%s_Volcano.dat', ...
                    norm_col, round(upper*100), round(lower*100), loc, geometryKey));
                writematrix(data, dat_path, 'Delimiter', ' ');
                add_header_to_dat(dat_path, 'xL thickness lower_vel_for_dat');
            end
        end

        % 2) Overlaid plots ONLY for velocityxavg_norm per location
        avg_norm_cols = {'velocityxavg_norm'};
        for iNorm = 1:numel(avg_norm_cols)
            norm_col = avg_norm_cols{iNorm};
            nice_name = normalized_cols(norm_col);

            hfig = figure('Visible','off');
            hold on;
            has_data = false;

            ax = gca;
            ax.FontSize    = 12;
            labelFontSize  = 14;
            titleFontSize  = 18;
            legendFontSize =  9;

            % Style mapping:
            % Volcano slice: triangles + dotted
            % Volcano full:  circles  + dashed
            % VULCAN full:   squares  + solid
            if contains(geometryKey, 'Slice')
                baseLineStyle = ':';
                baseMarker    = '^';
            else
                if strcmpi(sourceType,'Volcano')
                    baseLineStyle = '--';
                    baseMarker    = 'o';
                else
                    baseLineStyle = '-';
                    baseMarker    = 's';
                end
            end

            for iThr = 1:size(THRESHOLDS,1)
                upper = THRESHOLDS(iThr,1);
                lower = THRESHOLDS(iThr,2);
                key = make_key(norm_col, upper, lower);
                data = results.(loc).(key);
                if isempty(data)
                    continue;
                end
                data = sortrows(data, 1);

                pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
                pct_text = strrep(pct_text, '%', '\%');
                label = sprintf('%s, %s', legendLabel, pct_text);

                plot(data(:,1), data(:,2), ...
                     'LineStyle', baseLineStyle, ...
                     'Marker', baseMarker, ...
                     'DisplayName', label, ...
                     'LineWidth', 1.5);

                has_data = true;
            end

            if ~has_data
                close(hfig);
                continue;
            end

            switch loc
                case 'MP'
                    locLabel = '$$z/w = 0.50$$';
                otherwise
                    locLabel = loc;
            end

            xlabel('$$x/L$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);
            ylabel('$$\delta_{SL}/D$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);

            nice_core = regexprep(nice_name, '[$]', '');
            loc_core  = regexprep(locLabel,  '[$]', '');
            title_str = sprintf('$%s$ Thickness, %s', nice_core, loc_core);
            % title(title_str, 'Interpreter', 'latex', 'FontSize', titleFontSize);

            grid on;
            lgd = legend('Location', 'southoutside', 'Interpreter','latex');
            lgd.NumColumns = 2;  % 3 rows x 2 columns
            lgd.FontSize   = legendFontSize;
            hold off;

            plot_path_png = fullfile(plots_dir,...
                sprintf('shearThick_%s_overlaid_%s_%s_Volcano.png', ...
                norm_col, loc, geometryKey));
            print(hfig, '-dpng', '-r300', plot_path_png);

            plot_path_fig = fullfile(plots_dir,...
                sprintf('shearThick_%s_overlaid_%s_%s_Volcano.fig', ...
                norm_col, loc, geometryKey));
            savefig(hfig, plot_path_fig);

            plot_path_pdf = fullfile(plots_dir,...
                sprintf('shearThick_%s_overlaid_%s_%s_Volcano.pdf', ...
                norm_col, loc, geometryKey));
            exportgraphics(hfig, plot_path_pdf, 'ContentType','vector');

            close(hfig);
        end
    end

    %% OVERLAY ALL PLANES FOR velocityxavg_norm (WITHIN THIS GEOMETRY KEY)
    avg_norm_cols = {'velocityxavg_norm'};

    colorMapPlanes = containers.Map();
    colorMapPlanes('MP')  = [0.00, 0.45, 0.74];

    for iNorm = 1:numel(avg_norm_cols)
        norm_col = avg_norm_cols{iNorm};
        nice_name = normalized_cols(norm_col);

        hfig = figure('Visible','off');
        hold on;
        has_data = false;

        ax = gca;
        ax.FontSize    = 12;
        labelFontSize  = 14;
        titleFontSize  = 18;
        legendFontSize =  9;

        for iLoc = 1:numel(LOCATIONS)
            loc = LOCATIONS{iLoc};

            switch loc
                case 'MP'
                    locLabel = 'z/w = 0.50';
                otherwise
                    locLabel = loc;
            end

            if isKey(colorMapPlanes, loc)
                thisColor = colorMapPlanes(loc);
            else
                thisColor = [0 0 0];
            end

            % Style mapping
            if contains(geometryKey, 'Slice')
                lsPlane = ':';
                mkPlane = '^';
            else
                if strcmpi(sourceType,'Volcano')
                    lsPlane = '--';
                    mkPlane = 'o';
                else
                    lsPlane = '-';
                    mkPlane = 's';
                end
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
                label = sprintf('%s, %s, %s', locLabel, legendLabel, pct_text);

                plot(data(:,1), data(:,2),...
                     'LineStyle', lsPlane,...
                     'Marker', mkPlane,...
                     'Color', thisColor,...
                     'LineWidth', 1.5,...
                     'DisplayName', label);

                has_data = true;
            end
        end

        if ~has_data
            close(hfig);
            continue;
        end

        switch geometryBase
            case 'RD00'
                geoLabel = 'R/D = 0.0';
            case 'RD52'
                geoLabel = 'R/D = 0.52';
            otherwise
                geoLabel = geometryBase;
        end

        xlabel('$$x/L$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);
        ylabel('$$\delta_{SL}/D$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);

        nice_core = regexprep(nice_name, '[$]', '');
        title_str = sprintf('$%s$ Thickness, %s (%s)', nice_core, geoLabel, legendLabel);
        % title(title_str, 'Interpreter', 'latex', 'FontSize', titleFontSize);

        grid on;
        lgd = legend('Location', 'southoutside', 'Interpreter','latex');
        lgd.NumColumns = 2;
        lgd.FontSize   = legendFontSize;
        hold off;

        plot_path_png = fullfile(plots_dir,...
            sprintf('shearThick_%s_allPlanes_%s_Volcano.png', norm_col, geometryKey));
        print(hfig, '-dpng', '-r300', plot_path_png);

        plot_path_fig = fullfile(plots_dir,...
            sprintf('shearThick_%s_allPlanes_%s_Volcano.fig', norm_col, geometryKey));
        savefig(hfig, plot_path_fig);

        close(hfig);
    end

    all_results.(geometryKey) = results;

    fprintf('Processing complete for %s (%s, %s).\nFiles stored at: %s\n', ...
        geometryBase, sourceType, legendLabel, output_dir);
end

%% ============================================================
%  CROSS-GEOMETRY OVERLAYS (Volcano + VULCAN, full + slice)
% ============================================================

avg_norm_cols = {'velocityxavg_norm'};

colorMapGeomBase = containers.Map();
colorMapGeomBase('RD00') = [0.00, 0.45, 0.74];
colorMapGeomBase('RD52') = [1.00, 0.80, 0.20];

firstKey = all_geometryKeys{1};
plots_dir_global = fullfile(all_output_dirs.(firstKey), 'Plots_Global');
if ~exist(plots_dir_global, 'dir')
    mkdir(plots_dir_global);
end

for iNorm = 1:numel(avg_norm_cols)
    norm_col = avg_norm_cols{iNorm};
    nice_name = normalized_cols(norm_col);

    for iLoc = 1:numel(LOCATIONS)
        loc = LOCATIONS{iLoc};

        switch loc
            case 'MP'
                locLabelLatex = '$$z/w = 0.50$$';
                locLabelPlain = 'z_w_0p50';
            otherwise
                locLabelLatex = loc;
                locLabelPlain = loc;
        end

        for iThr = 1:size(THRESHOLDS,1)
            upper = THRESHOLDS(iThr,1);
            lower = THRESHOLDS(iThr,2);
            key   = make_key(norm_col, upper, lower);

            hfig = figure('Visible','off');
            hold on;
            has_data = false;

            ax = gca;
            ax.FontSize    = 12;
            labelFontSize  = 14;
            titleFontSize  = 18;
            legendFontSize =  9;

            for iFile = 1:numel(all_geometryKeys)
                geometryKey  = all_geometryKeys{iFile};

                if ~isfield(all_results, geometryKey)
                    continue;
                end
                resultsGeom = all_results.(geometryKey);

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

                baseGeom   = geometryBaseOfKey(geometryKey);
                thisLabel  = legendLabels(geometryKey);
                thisSource = sourceOfKey(geometryKey);

                if isKey(colorMapGeomBase, baseGeom)
                    thisColor = colorMapGeomBase(baseGeom);
                else
                    thisColor = [0 0 0];
                end

                switch baseGeom
                    case 'RD00'
                        geoLabel = 'R/D = 0.0';
                    case 'RD52'
                        geoLabel = 'R/D = 0.52';
                    otherwise
                        geoLabel = baseGeom;
                end

                pct_text = sprintf('%d%%/%d%%', round(upper*100), round(lower*100));
                pct_text = strrep(pct_text, '%', '\%');

                % Style mapping (global):
                if contains(geometryKey, 'Slice')
                    ls = ':';
                    mk = '^';
                else
                    if strcmpi(thisSource,'Volcano')
                        ls = '--';
                        mk = 'o';
                    else
                        ls = '-';
                        mk = 's';
                    end
                end

                label = sprintf('%s, %s, %s', geoLabel, thisLabel, pct_text);

                plot(data(:,1), data(:,2),...
                     'Color', thisColor,...
                     'LineStyle', ls,...
                     'Marker', mk,...
                     'LineWidth', 1.5,...
                     'DisplayName', label);

                has_data = true;
            end

            if ~has_data
                close(hfig);
                continue;
            end

            xlabel('$$x/L$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);
            ylabel('$$\delta_{SL}/D$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);

            nice_core = regexprep(nice_name,     '[$]', '');
            loc_core  = regexprep(locLabelLatex, '[$]', '');
            title_str = sprintf('$%s$ Thickness, %s', nice_core, loc_core);
            % title(title_str, 'Interpreter', 'latex', 'FontSize', titleFontSize);

            grid on;

            lgd = legend('Location', 'southoutside', 'Interpreter','latex');
            lgd.NumColumns = 2;  % 3 rows x 2 columns
            lgd.FontSize   = legendFontSize;

            hold off;

            plot_name_png = sprintf('shearThick_%s_%s_upper%d_lower%d_allCases_Volcano.png',...
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

fprintf('Cross-geometry overlays (Volcano + VULCAN, full + slice) complete.\nGlobal plots stored at: %s\n', plots_dir_global);

%% ============================================================
%  EXTRA GLOBAL PLOTS: NORMALIZED BY RD00 MAX delta_SL PER TYPE
%  Types:
%    - VolcanoFull   (source=Volcano, slice=false)
%    - VolcanoSlice  (source=Volcano, slice=true)
%    - VULCANFull    (source=VULCAN,  slice=false)
%  Also builds a combined global overlay of all normalized data.
% ============================================================

% Helper: typeName -> anonymous function that says if a geometryKey belongs
typeNames = {'VolcanoFull','VolcanoSlice','VULCANFull'};
isOfType  = containers.Map();

isOfType('VolcanoFull')  = @(k) strcmpi(sourceOfKey(k),'Volcano') && ~contains(k,'Slice');
isOfType('VolcanoSlice') = @(k) strcmpi(sourceOfKey(k),'Volcano') &&  contains(k,'Slice');
isOfType('VULCANFull')   = @(k) strcmpi(sourceOfKey(k),'VULCAN')  && ~contains(k,'Slice');

% Store RD00 max delta_SL per type: deltaMaxRD00(typeName) = value
deltaMaxRD00 = containers.Map();

for iType = 1:numel(typeNames)
    typeName = typeNames{iType};
    typeFunc = isOfType(typeName);   % function handle

    % Find RD00 geometryKey of this type
    rd00Key = '';
    for iKey = 1:numel(all_geometryKeys)
        k = all_geometryKeys{iKey};
        if strcmpi(geometryBaseOfKey(k),'RD00') && typeFunc(k)
            rd00Key = k;
            break;
        end
    end
    if isempty(rd00Key)
        fprintf('No RD00 case found for type %s. Skipping normalized global plot.\n', typeName);
        continue;
    end

    % Use MP, velocityxavg_norm, first threshold pair
    loc      = 'MP';
    norm_col = 'velocityxavg_norm';
    upper    = THRESHOLDS(1,1);
    lower    = THRESHOLDS(1,2);
    keyThick = make_key(norm_col, upper, lower);

    % Extract RD00 data and find max delta_SL (column 2)
    if ~isfield(all_results.(rd00Key), loc) || ...
       ~isfield(all_results.(rd00Key).(loc), keyThick)
        fprintf('No thickness data for RD00 (%s) type %s.\n', rd00Key, typeName);
        continue;
    end
    dataRD00 = all_results.(rd00Key).(loc).(keyThick);
    if isempty(dataRD00)
        fprintf('Empty thickness data for RD00 (%s) type %s.\n', rd00Key, typeName);
        continue;
    end
    dataRD00 = sortrows(dataRD00, 1);
    deltaRD00 = dataRD00(:,2);
    deltaMax = max(deltaRD00(~isnan(deltaRD00)));
    if isempty(deltaMax) || deltaMax <= 0
        fprintf('Invalid max delta_SL for RD00 (%s) type %s.\n', rd00Key, typeName);
        continue;
    end
    deltaMaxRD00(typeName) = deltaMax;  % store for later combined overlay

    % =========================
    % Per-type normalized plot
    % =========================
    hfig = figure('Visible','off');
    hold on;
    has_data = false;

    ax = gca;
    ax.FontSize    = 12;
    labelFontSize  = 14;
    titleFontSize  = 18;
    legendFontSize =  9;

    for iKey = 1:numel(all_geometryKeys)
        k = all_geometryKeys{iKey};
        if ~typeFunc(k)
            continue;
        end
        if ~isfield(all_results.(k), loc),      continue; end
        if ~isfield(all_results.(k).(loc), keyThick), continue; end

        data = all_results.(k).(loc).(keyThick);
        if isempty(data), continue; end
        data = sortrows(data, 1);

        baseGeom   = geometryBaseOfKey(k);
        thisLabel  = legendLabels(k);
        thisSource = sourceOfKey(k);

        if isKey(colorMapGeomBase, baseGeom)
            thisColor = colorMapGeomBase(baseGeom);
        else
            thisColor = [0 0 0];
        end

        % Style mapping (same as main plots):
        % VolcanoSlice: triangles + dotted
        % VolcanoFull:  circles  + dashed
        % VULCANFull:   squares  + solid
        if contains(k, 'Slice')
            ls = ':';
            mk = '^';
        else
            if strcmpi(thisSource,'Volcano')
                ls = '--';
                mk = 'o';
            else
                ls = '-';
                mk = 's';
            end
        end

        % Normalize by this type's RD00 max
        deltaNorm = data(:,2) ./ deltaMax;

        % Geometry label
        switch baseGeom
            case 'RD00'
                geoLabel = 'R/D = 0.0';
            case 'RD52'
                geoLabel = 'R/D = 0.52';
            otherwise
                geoLabel = baseGeom;
        end

        label = sprintf('%s, %s', geoLabel, thisLabel);

        plot(data(:,1), deltaNorm,...
             'Color', thisColor,...
             'LineStyle', ls,...
             'Marker', mk,...
             'LineWidth', 1.5,...
             'DisplayName', label);

        has_data = true;
    end

    if ~has_data
        close(hfig);
        continue;
    end

    xlabel('$$x/L$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);
    ylabel('$$\delta_{SL}/\delta_{SL,\max, RD00}$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);

    nice_name = normalized_cols('velocityxavg_norm');
    nice_core = regexprep(nice_name, '[$]', '');
    switch typeName
        case 'VolcanoFull'
            typeLabel = 'Volcano Full';
        case 'VolcanoSlice'
            typeLabel = 'Volcano Slice';
        case 'VULCANFull'
            typeLabel = 'VULCAN';
        otherwise
            typeLabel = typeName;
    end
    title_str = sprintf('$%s$ Thickness, %s, normalized by RD00 max', nice_core, typeLabel);
    % title(title_str, 'Interpreter','latex','FontSize',titleFontSize);

    grid on;
    lgd = legend('Location','southoutside','Interpreter','latex');
    lgd.NumColumns = 2;   % 3 rows x 2 columns
    lgd.FontSize   = legendFontSize;

    hold off;

    % Save per-type plot
    plot_name_png = sprintf('shearThick_%s_MP_upper%d_lower%d_%s_normByRD00max.png',...
        'velocityxavg_norm', round(upper*100), round(lower*100), typeName);
    plot_name_fig = strrep(plot_name_png, '.png', '.fig');
    plot_name_pdf = strrep(plot_name_png, '.png', '.pdf');

    print(hfig, '-dpng', '-r300', fullfile(plots_dir_global, plot_name_png));
    savefig(hfig, fullfile(plots_dir_global, plot_name_fig));
    exportgraphics(hfig, fullfile(plots_dir_global, plot_name_pdf), 'ContentType','vector');
    close(hfig);

    fprintf('Normalized per-type plot (type=%s) saved in %s\n', typeName, plots_dir_global);
end

%% ============================================================
%  COMBINED GLOBAL OVERLAY: ALL TYPES, EACH NORMALIZED BY ITS
%  OWN RD00 MAX delta_SL
% ============================================================

loc      = 'MP';
norm_col = 'velocityxavg_norm';
upper    = THRESHOLDS(1,1);
lower    = THRESHOLDS(1,2);
keyThick = make_key(norm_col, upper, lower);

hfig = figure('Visible','off');
hold on;
has_data = false;

ax = gca;
ax.FontSize    = 12;
labelFontSize  = 14;
titleFontSize  = 18;
legendFontSize =  9;

for iKey = 1:numel(all_geometryKeys)
    k = all_geometryKeys{iKey};

    if ~isfield(all_results, k),                continue; end
    if ~isfield(all_results.(k), loc),          continue; end
    if ~isfield(all_results.(k).(loc), keyThick), continue; end

    data = all_results.(k).(loc).(keyThick);
    if isempty(data), continue; end
    data = sortrows(data, 1);

    % Determine typeName for this key
    thisTypeName = '';
    for iType = 1:numel(typeNames)
        tn = typeNames{iType};
        tf = isOfType(tn);
        if tf(k)
            thisTypeName = tn;
            break;
        end
    end
    if isempty(thisTypeName)
        % not one of the three types; skip
        continue;
    end
    if ~isKey(deltaMaxRD00, thisTypeName)
        % no RD00 reference for this type
        continue;
    end
    deltaMax = deltaMaxRD00(thisTypeName);

    baseGeom   = geometryBaseOfKey(k);
    thisLabel  = legendLabels(k);
    thisSource = sourceOfKey(k);

    if isKey(colorMapGeomBase, baseGeom)
        thisColor = colorMapGeomBase(baseGeom);
    else
        thisColor = [0 0 0];
    end

    % Style mapping (same as before)
    if contains(k, 'Slice')
        ls = ':';
        mk = '^';
    else
        if strcmpi(thisSource,'Volcano')
            ls = '--';
            mk = 'o';
        else
            ls = '-';
            mk = 's';
        end
    end

    % Normalize by this type's RD00 max
    deltaNorm = data(:,2) ./ deltaMax;

    switch baseGeom
        case 'RD00'
            geoLabel = 'R/D = 0.0';
        case 'RD52'
            geoLabel = 'R/D = 0.52';
        otherwise
            geoLabel = baseGeom;
    end

    label = sprintf('%s, %s', geoLabel, thisLabel);

    plot(data(:,1), deltaNorm,...
         'Color', thisColor,...
         'LineStyle', ls,...
         'Marker', mk,...
         'LineWidth', 1.5,...
         'DisplayName', label);

    has_data = true;
end

if has_data
    xlabel('$$x/L$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);
    ylabel('$$\delta_{SL}/\delta_{SL,\max, RD00}$$', 'Interpreter', 'latex', 'FontSize', labelFontSize);

    nice_name = normalized_cols('velocityxavg_norm');
    nice_core = regexprep(nice_name, '[$]', '');
    title_str = sprintf('$%s$ Thickness, all cases, normalized by RD00 max (per type)', nice_core);
    % title(title_str, 'Interpreter','latex','FontSize',titleFontSize);

    grid on;
    lgd = legend('Location','southoutside','Interpreter','latex');
    lgd.NumColumns = 2;   % 3 rows x 2 columns
    lgd.FontSize   = legendFontSize;

    hold off;

    plot_name_png = sprintf('shearThick_%s_MP_upper%d_lower%d_allTypes_normByRD00max.png',...
        'velocityxavg_norm', round(upper*100), round(lower*100));
    plot_name_fig = strrep(plot_name_png, '.png', '.fig');
    plot_name_pdf = strrep(plot_name_png, '.png', '.pdf');

    print(hfig, '-dpng', '-r300', fullfile(plots_dir_global, plot_name_png));
    savefig(hfig, fullfile(plots_dir_global, plot_name_fig));
    exportgraphics(hfig, fullfile(plots_dir_global, plot_name_pdf), 'ContentType','vector');

    fprintf('Combined normalized global overlay (all types) saved in %s\n', plots_dir_global);
else
    close(hfig);
    fprintf('No data available for combined normalized global overlay.\n');
end

%% ============================================================
%  LOCAL HELPER FUNCTIONS
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

function df_pruned = prune_profile_keep_first_y_noMag_MATLAB(df, y_col, velocity_cols, VELXAVG_COL)
    df_sorted = sortrows(df, y_col);

    [~, ia] = unique(df_sorted.(VELXAVG_COL), 'first');
    df_pruned = df_sorted(ia, :);

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