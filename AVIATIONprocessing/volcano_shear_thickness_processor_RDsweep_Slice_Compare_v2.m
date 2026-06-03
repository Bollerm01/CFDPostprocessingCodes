%% ============================================================
%  Volcano/VULCAN velocityxavg Shear Layer Thickness Script
%  - ONLY velocityxavg_norm processed
%  - Volcano + VULCAN comparison
%  - Includes:
%       * Individual plots
%       * Global delta_SL overlays
%       * Global normalized overlays
% ============================================================

clc;
clear all;
close all;

%% ============================================================
% USER SETTINGS
% ============================================================

THRESHOLD_UPPER = 0.80;
THRESHOLD_LOWER = 0.20;

%% ============================================================
% FILE SELECTION
% ============================================================

[filenames, pathname] = uigetfile('*.xlsx', ...
    'Select Volcano and VULCAN Excel files', ...
    'MultiSelect', 'on');

if isequal(filenames,0)
    error('No files selected.');
end

if ischar(filenames)
    filenames = {filenames};
end

%% ============================================================
% GLOBAL STORAGE
% ============================================================

all_results = struct();

all_geometryKeys = {};

legendLabels = containers.Map();
sourceOfKey = containers.Map();
geometryBaseOfKey = containers.Map();

%% ============================================================
% LOOP OVER FILES
% ============================================================

for iFile = 1:numel(filenames)

    filename = filenames{iFile};

    excel_file = fullfile(pathname, filename);

    [~, nameOnly, ~] = fileparts(filename);

    %% --------------------------------------------------------
    % SOURCE TYPE
    %% --------------------------------------------------------

    if contains(nameOnly,'VULCAN','IgnoreCase',true)

        sourceType = 'VULCAN';

    else

        sourceType = 'Volcano';

    end

    %% --------------------------------------------------------
    % SLICE?
    %% --------------------------------------------------------

    isSlice = contains(nameOnly,'Slice','IgnoreCase',true);

    %% --------------------------------------------------------
    % GEOMETRY
    %% --------------------------------------------------------

    tok = regexp(nameOnly,'(RD\d+)','tokens','once');

    if isempty(tok)
        error('Could not determine geometry for %s', filename);
    end

    geomToken = tok{1};

    if strcmpi(geomToken,'RD00') || strcmpi(geomToken,'RD0')

        geometryBase = 'RD00';

    elseif strcmpi(geomToken,'RD52') || strcmpi(geomToken,'RD5')

        geometryBase = 'RD52';

    else

        error('Unsupported geometry token.');

    end

    %% --------------------------------------------------------
    % GEOMETRY KEY
    %% --------------------------------------------------------

    if isSlice

        geometryKey = sprintf('%s_%s_Slice', ...
            geometryBase, sourceType);

        legendLabel = sprintf('%s Slice', sourceType);

    else

        geometryKey = sprintf('%s_%s', ...
            geometryBase, sourceType);

        legendLabel = sourceType;

    end

    %% --------------------------------------------------------
    % STORE METADATA
    %% --------------------------------------------------------

    all_geometryKeys{end+1} = geometryKey;

    legendLabels(geometryKey) = legendLabel;
    sourceOfKey(geometryKey) = sourceType;
    geometryBaseOfKey(geometryKey) = geometryBase;

    %% --------------------------------------------------------
    % OUTPUT DIRECTORIES
    %% --------------------------------------------------------

    output_dir = fullfile(pathname, ...
        ['ShearResults_' geometryKey]);

    if ~exist(output_dir,'dir')
        mkdir(output_dir);
    end

    plots_dir = fullfile(output_dir,'Plots');

    if ~exist(plots_dir,'dir')
        mkdir(plots_dir);
    end

    %% ========================================================
    % LOAD SHEETS
    %% ========================================================

    [~, sheets] = xlsfinfo(excel_file);

    %% ========================================================
    % FREESTREAM
    %% ========================================================

    if strcmpi(sourceType,'Volcano')

        fs_sheet = 'US_MP';

        df_fs = readtable(excel_file,'Sheet',fs_sheet);

        df_fs = sortrows(df_fs,'Y_norm');

        tailRows = max(1,height(df_fs)-5):height(df_fs);

        Uinf = mean(df_fs.velocityxavg(tailRows), ...
            'omitnan');

        velCol = 'velocityxavg';

    else

        fs_sheet = 'xL1';

        df_fs = readtable(excel_file,'Sheet',fs_sheet);

        df_fs = sortrows(df_fs,'Y_norm');

        tailRows = max(1,height(df_fs)-10):height(df_fs);

        Uinf = mean(df_fs.Velocity_X(tailRows), ...
            'omitnan');

        velCol = 'Velocity_X';

    end

    fprintf('\n========================================\n');
    fprintf('%s\n', geometryKey);
    fprintf('Uinf = %.6f\n', Uinf);
    fprintf('========================================\n');

    %% ========================================================
    % RESULTS
    %% ========================================================

    results = [];

    %% ========================================================
    % AXIAL SHEETS
    %% ========================================================

    axial_sheets = sheets(startsWith(sheets,'xL'));

    %% ========================================================
    % PROCESS EACH SHEET
    %% ========================================================

    for iS = 1:numel(axial_sheets)

        sheet = axial_sheets{iS};

        %% ----------------------------------------------------
        % VOLCANO: ONLY MP
        %% ----------------------------------------------------

        if strcmpi(sourceType,'Volcano')

            if ~contains(sheet,'MP')
                continue;
            end

        end

        %% ----------------------------------------------------
        % x/L
        %% ----------------------------------------------------

        xL = parse_xL_MATLAB(sheet);

        if xL < 0 || xL > 1.1
            continue;
        end

        %% ----------------------------------------------------
        % READ DATA
        %% ----------------------------------------------------

        df = readtable(excel_file,'Sheet',sheet);

        if ~ismember('Y_norm', ...
                df.Properties.VariableNames)

            continue;

        end

        if ~ismember(velCol, ...
                df.Properties.VariableNames)

            continue;

        end

        y = df.Y_norm;

        vel = df.(velCol);

        %% ----------------------------------------------------
        % CLEAN NaNs
        %% ----------------------------------------------------

        mask = ~(isnan(y) | isnan(vel));

        y = y(mask);
        vel = vel(mask);

        %% ----------------------------------------------------
        % SORT
        %% ----------------------------------------------------

        [y, idx] = sort(y);

        vel = vel(idx);

        %% ----------------------------------------------------
        % REMOVE DUPLICATES
        %% ----------------------------------------------------

        [~, ia] = unique(vel,'first');

        y = y(ia);
        vel = vel(ia);

        %% ----------------------------------------------------
        % NORMALIZE
        %% ----------------------------------------------------

        vel_norm = vel ./ Uinf;

        %% ----------------------------------------------------
        % THICKNESS
        %% ----------------------------------------------------

        [thickness, ~] = ...
            find_thickness_robust_MATLAB( ...
            y, ...
            vel_norm, ...
            THRESHOLD_UPPER, ...
            THRESHOLD_LOWER);

        %% ----------------------------------------------------
        % STORE
        %% ----------------------------------------------------

        results = [results;
                   xL, thickness];

    end

    %% ========================================================
    % SORT RESULTS
    %% ========================================================

    results = sortrows(results,1);

    all_results.(geometryKey) = results;

    %% ========================================================
    % INDIVIDUAL PLOT
    %% ========================================================

    hfig = figure('Visible','off');

    hold on;

    %% --------------------------------------------------------
    % STYLE MAPPING
    %% --------------------------------------------------------

    if contains(geometryKey,'Slice')

        ls = ':';
        mk = '^';

    else

        if strcmpi(sourceType,'Volcano')

            ls = '--';
            mk = 'o';

        else

            ls = '-';
            mk = 's';

        end

    end

    %% --------------------------------------------------------
    % PLOT
    %% --------------------------------------------------------

    plot(results(:,1), results(:,2), ...
        'LineStyle', ls, ...
        'Marker', mk, ...
        'LineWidth', 1.5);

    xlabel('$$x/L$$', ...
        'Interpreter','latex', ...
        'FontSize',14);

    ylabel('$$\delta_{SL}/D$$', ...
        'Interpreter','latex', ...
        'FontSize',14);

    % xlim([0.2 1]);

    grid on;

    %% --------------------------------------------------------
    % SAVE
    %% --------------------------------------------------------

    exportgraphics(hfig, ...
        fullfile(plots_dir,...
        [geometryKey '.pdf']), ...
        'ContentType','vector');

    savefig(hfig, ...
        fullfile(plots_dir,...
        [geometryKey '.fig']));

    close(hfig);

end

%% ============================================================
% GLOBAL OVERLAY : delta_SL/D
% ============================================================

plots_dir_global = fullfile(pathname,'Plots_Global');

if ~exist(plots_dir_global,'dir')
    mkdir(plots_dir_global);
end

colorMap = containers.Map();

colorMap('Volcano')       = [0.00 0.45 0.74];   % blue
colorMap('Volcano_Slice') = [0.85 0.33 0.10];   % orange
colorMap('VULCAN')        = [0.47 0.67 0.19];   % green

hfig = figure;

hold on;

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};

    data = all_results.(k);

    if isempty(data)
        continue;
    end

    baseGeom = geometryBaseOfKey(k);
    
    geomType = getGeometryType(k);
    
    color = colorMap(geomType);
    
    % --------------------------------------------------------
    % RD determines line style
    % --------------------------------------------------------
    
    if strcmpi(baseGeom,'RD00')
    
        ls = '-';
        mk = 'sq';
    
    else
    
        ls = '--';
        mk = 'o';
    
    end
    
    % optional markers by geometry type
    % mk = 'none';
    % switch geomType
    % 
    %     case 'Volcano'
    %         mk = 'o';
    % 
    %     case 'Volcano_Slice'
    %         mk = '^';
    % 
    %     case 'VULCAN'
    %         mk = 's';
    % 
    %     otherwise
    %         mk = 'none';
    % 
    % end

    %% --------------------------------------------------------
    % LABELS
    %% --------------------------------------------------------

    switch baseGeom

        case 'RD00'
            geoLabel = 'R/D = 0.0';

        case 'RD52'
            geoLabel = 'R/D = 0.52';

        otherwise
            geoLabel = baseGeom;

    end

    label = sprintf('%s, %s', ...
        geoLabel, ...
        legendLabels(k));

    %% --------------------------------------------------------
    % PLOT
    %% --------------------------------------------------------

    plot(data(:,1), data(:,2), ...
        'Color', color, ...
        'LineStyle', ls, ...
        'Marker', mk, ...
        'LineWidth', 1.5, ...
        'DisplayName', label);

end

% xlim([0.2 1]);
xlabel('$$x/L$$', ...
    'Interpreter','latex', ...
    'FontSize',14);

ylabel('$$\delta_{SL}/D$$', ...
    'Interpreter','latex', ...
    'FontSize',14);

grid on;

lgd = legend('Location','southoutside');

lgd.NumColumns = 2;

exportgraphics(hfig, ...
    fullfile(plots_dir_global,...
    'GlobalOverlay_deltaSL.pdf'), ...
    'ContentType','vector');

savefig(hfig, ...
    fullfile(plots_dir_global,...
    'GlobalOverlay_deltaSL.fig'));

%% ============================================================
% GLOBAL OVERLAY : NORMALIZED BY RD00 MAX
% ============================================================

deltaMaxRD00 = containers.Map();

%% ------------------------------------------------------------
% FIND RD00 MAX VALUES
%% ------------------------------------------------------------

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};

    baseGeom = geometryBaseOfKey(k);

    if ~strcmpi(baseGeom,'RD00')
        continue;
    end

    data = all_results.(k);

    if isempty(data)
        continue;
    end

    deltaMaxRD00(k) = max(data(:,2),[],'omitnan');

end

%% ------------------------------------------------------------
% NORMALIZED PLOT
%% ------------------------------------------------------------

hfig = figure;

hold on;

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};

    data = all_results.(k);

    if isempty(data)
        continue;
    end

    sourceType = sourceOfKey(k);

    baseGeom = geometryBaseOfKey(k);

    %% --------------------------------------------------------
    % REFERENCE CASE
    %% --------------------------------------------------------

    if contains(k,'Slice')

        if strcmpi(sourceType,'Volcano')

            refKey = 'RD00_Volcano_Slice';

        else

            continue;

        end

    else

        if strcmpi(sourceType,'Volcano')

            refKey = 'RD00_Volcano';

        else

            refKey = 'RD00_VULCAN';

        end

    end

    if ~isKey(deltaMaxRD00, refKey)
        continue;
    end

    deltaMax = deltaMaxRD00(refKey);

    deltaNorm = data(:,2) ./ deltaMax;

    %% --------------------------------------------------------
    % STYLE
    %% --------------------------------------------------------

    geomType = getGeometryType(k);

    color = colorMap(geomType);
    
    if strcmpi(baseGeom,'RD00')
    
        ls = '-';
        mk = 'sq';
    
    else
    
        ls = '--';
        mk = 'o';
    
    end
    
    % mk = 'none';
    % switch geomType
    % 
    %     case 'Volcano'
    %         mk = 'o';
    % 
    %     case 'Volcano_Slice'
    %         mk = '^';
    % 
    %     case 'VULCAN'
    %         mk = 's';
    % 
    %     otherwise
    %         mk = 'none';
    % 
    % end

    %% --------------------------------------------------------
    % LABELS
    %% --------------------------------------------------------

    switch baseGeom

        case 'RD00'
            geoLabel = 'R/D = 0.0';

        case 'RD52'
            geoLabel = 'R/D = 0.52';

        otherwise
            geoLabel = baseGeom;

    end

    label = sprintf('%s, %s', ...
        geoLabel, ...
        legendLabels(k));

    %% --------------------------------------------------------
    % PLOT
    %% --------------------------------------------------------

    plot(data(:,1), deltaNorm, ...
        'Color', color, ...
        'LineStyle', ls, ...
        'Marker', mk, ...
        'LineWidth', 1.5, ...
        'DisplayName', label);

end

% xlim([0.2 1]);
xlabel('$$x/L$$', ...
    'Interpreter','latex', ...
    'FontSize',14);

ylabel('$$\delta_{SL}/\delta_{SL,max,RD00}$$', ...
    'Interpreter','latex', ...
    'FontSize',14);

grid on;

lgd = legend('Location','southoutside');

lgd.NumColumns = 2;

exportgraphics(hfig, ...
    fullfile(plots_dir_global,...
    'GlobalOverlay_deltaSL_Normalized.pdf'), ...
    'ContentType','vector');

savefig(hfig, ...
    fullfile(plots_dir_global,...
    'GlobalOverlay_deltaSL_Normalized.fig'));

fprintf('\n========================================\n');
fprintf('PROCESSING COMPLETE\n');
fprintf('Global plots saved in:\n%s\n', ...
    plots_dir_global);
fprintf('========================================\n');

%% ============================================================
% HELPER FUNCTIONS
% ============================================================

function geomType = getGeometryType(geometryKey)

    parts = split(geometryKey,'_');

    if numel(parts) < 2
        geomType = geometryKey;
        return;
    end

    geomType = strjoin(parts(2:end),'_');

end

function xL = parse_xL_MATLAB(sheet_name)

    base = regexprep(sheet_name, ...
        '_(MP|z25|z75)$','');

    %% --------------------------------------------------------
    % xL_0p5 format
    %% --------------------------------------------------------

    tokens = regexp(base, ...
        'xL_?(-?\d+)p(\d+)$', ...
        'tokens');

    if ~isempty(tokens)

        t = tokens{1};

        xL = str2double([t{1} '.' t{2}]);

        return;

    end

    %% --------------------------------------------------------
    % xL_1 format
    %% --------------------------------------------------------

    tokens = regexp(base, ...
        'xL_?(-?\d+)$', ...
        'tokens');

    if ~isempty(tokens)

        t = tokens{1};

        xL = str2double(t{1});

        return;

    end

    error('Could not parse x/L from sheet name.');

end

function [thickness, lower_vel] = ...
    find_thickness_robust_MATLAB( ...
    y, vel, upper, lower)

    %% ========================================================
    % Initialize
    %% ========================================================

    thickness = NaN;
    lower_vel = NaN;

    %% ========================================================
    % Column vectors
    %% ========================================================

    y   = y(:);
    vel = vel(:);

    %% ========================================================
    % Remove NaNs
    %% ========================================================

    mask = ~(isnan(y) | isnan(vel));

    y   = y(mask);
    vel = vel(mask);

    %% ========================================================
    % Restrict to y_norm > -0.5
    %% ========================================================

    maskY = y > -0.5;

    y   = y(maskY);
    vel = vel(maskY);

    if numel(y) < 4
        return;
    end

    %% ========================================================
    % Sort by y
    %% ========================================================

    [y, idx] = sort(y);

    vel = vel(idx);

    %% ========================================================
    % Enforce monotonic increasing envelope
    %
    % Removes:
    %   - oscillations
    %   - local dips
    %   - recirculation wiggles
    %   - noisy extrema
    %% ========================================================

    y_mono   = y(1);
    vel_mono = vel(1);

    current_max = vel(1);

    for i = 2:numel(vel)

        %% ----------------------------------------------------
        % Tolerance helps suppress numerical noise
        %% ----------------------------------------------------

        if vel(i) > current_max + 1e-4

            y_mono(end+1,1)   = y(i);
            vel_mono(end+1,1) = vel(i);

            current_max = vel(i);

        end

    end

    %% ========================================================
    % Need enough monotonic points
    %% ========================================================

    if numel(vel_mono) < 4
        return;
    end

    %% ========================================================
    % Ensure thresholds are bracketed
    %% ========================================================

    if max(vel_mono) < upper
        return;
    end

    if min(vel_mono) > lower
        return;
    end

    %% ========================================================
    % UPPER THRESHOLD
    %% ========================================================

    idxUpper = find(vel_mono >= upper,1,'first');

    if isempty(idxUpper)
        return;
    end

    if idxUpper == 1
        return;
    end

    %% --------------------------------------------------------
    % Interpolate upper crossing
    %% --------------------------------------------------------

    y_upper = interp1( ...
        vel_mono(idxUpper-1:idxUpper), ...
        y_mono(idxUpper-1:idxUpper), ...
        upper, ...
        'linear');

    %% ========================================================
    % LOWER THRESHOLD
    %% ========================================================

    idxLower = find( ...
        vel_mono(1:idxUpper) <= lower, ...
        1,'last');

    if isempty(idxLower)
        return;
    end

    if idxLower >= numel(vel_mono)
        return;
    end

    %% --------------------------------------------------------
    % Interpolate lower crossing
    %% --------------------------------------------------------

    y_lower = interp1( ...
        vel_mono(idxLower:idxLower+1), ...
        y_mono(idxLower:idxLower+1), ...
        lower, ...
        'linear');

    %% ========================================================
    % Compute thickness
    %% ========================================================

    thickness = y_upper - y_lower;

    %% ========================================================
    % Final validation
    %% ========================================================

    if ~isfinite(thickness)
        thickness = NaN;
        return;
    end

    if thickness <= 0
        thickness = NaN;
        return;
    end

    %% ========================================================
    % Return lower threshold value
    %% ========================================================

    lower_vel = lower;

end