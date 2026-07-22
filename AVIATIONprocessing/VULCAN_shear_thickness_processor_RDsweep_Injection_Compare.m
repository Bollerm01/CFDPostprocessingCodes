%% ============================================================
%  Volcano/VULCAN velocityxavg Shear Layer Thickness Script
%  - ONLY velocityxavg_norm processed
%  - Up to 12 files:
%       Injecting:      {Volcano, VULCAN} x {J=0.35, J=1.4} x {RD00, RD52}
%           naming: [VULCAN/Volcano]CondensedProbeData_[Injection]_[Geometry].xlsx
%       Non-injecting:  {Volcano, VULCAN} x {RD00, RD52}
%           naming: [VULCAN/Volcano]CondensedProbeData_[RD00s/RD52s].xlsx
%
%  Style mapping (per user request):
%       * Geometry (RD00 / RD52)                  -> COLOR   (blue / yellow)
%       * Injection (J=0.35 / J=1.4 / none)        -> MARKER  (o / ^ / d)
%       * Source (Volcano / VULCAN)                -> LINESTYLE ('-' / '--')
%
%  Figures generated:
%       1. Per-file individual plots
%       2. GlobalOverlay_deltaSL            - every case together
%       3. GlobalOverlay_deltaSL_Normalized - normalized by matching RD00 case
%       4. VolcanoOnly_AllInjections        - Volcano only, both geometries,
%                                             all injection conditions
%       5. InjectingOnly_VULCAN_vs_Volcano  - injecting cases only, comparing
%                                             VULCAN vs Volcano
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
    'Select Volcano and VULCAN Excel files (12 total)', ...
    'MultiSelect', 'on');

if isequal(filenames,0)
    error('No files selected.');
end

if ischar(filenames)
    filenames = {filenames};
end

%% ============================================================
% STYLE MAPS
% ============================================================

% --- Geometry -> Color ---
colorMap = containers.Map();
colorMap('RD00') = [0.00 0.45 0.74];   % blue
colorMap('RD52') = [0.93 0.69 0.13];   % yellow

% --- Injection -> Marker ---
markerMap = containers.Map();
markerMap('035')  = 'o';   % J = 0.35
markerMap('14')   = '^';   % J = 1.4
markerMap('000') = 'd';   % No injection

% --- Source -> LineStyle ---
lineStyleMap = containers.Map();
lineStyleMap('Volcano') = '-';
lineStyleMap('VULCAN')  = '--';

%% ============================================================
% GLOBAL STORAGE
% ============================================================

all_results = struct();

all_geometryKeys = {};

legendLabels        = containers.Map();
sourceOfKey          = containers.Map();
geometryBaseOfKey    = containers.Map();
injectionKeyOfKey    = containers.Map();
injectionValueOfKey  = containers.Map();

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
    % GEOMETRY (RD00 or RD52), with optional trailing 's' marking
    % the NON-INJECTING case, e.g. "RD00s" / "RD52s"
    %% --------------------------------------------------------

    tokGeom = regexp(nameOnly,'(RD\d+)(s)?','tokens','once');

    if isempty(tokGeom)
        error('Could not determine geometry for %s', filename);
    end

    geomToken       = tokGeom{1};
    % isNonInjecting  = ~isempty(tokGeom{2});   % true if trailing 's' present
    isNonInjecting = false;

    if strcmpi(geomToken,'RD00') || strcmpi(geomToken,'RD0')
        geometryBase = 'RD00';
    elseif strcmpi(geomToken,'RD52') || strcmpi(geomToken,'RD5')
        geometryBase = 'RD52';
    else
        error('Unsupported geometry token "%s" in %s. Expected RD00 or RD52.', ...
            geomToken, filename);
    end

    %% --------------------------------------------------------
    % INJECTION (J = 0.35, J = 1.4, or non-injecting "s" case)
    %% --------------------------------------------------------

    if isNonInjecting

        injectionKey   = '000';
        injectionValue = 0.0;

    else

        % Try "J0p35" / "J1p4" style first (underscore/decimal-as-p)
        tokInj = regexp(nameOnly, 'J[_]?(\d+)p(\d+)', 'tokens','once');

        if ~isempty(tokInj)
            injectionValue = str2double([tokInj{1} '.' tokInj{2}]);
        else
            % Fall back to "J0.35" / "J1.4" style with literal decimal point
            tokInj = regexp(nameOnly, 'J[_]?(\d+\.\d+)', 'tokens','once');

            if ~isempty(tokInj)
                injectionValue = str2double(tokInj{1});
            else
                injectionValue = 0.0;
                % error('Could not parse injection ratio (J) from %s', filename);
            end
        end

        if injectionValue == 0.0
            injectionKey = '000';
        elseif abs(injectionValue - 0.35) < 0.01
            injectionKey = '035';
        elseif abs(injectionValue - 1.4) < 0.01
            injectionKey = '14';
        else
            error('Unsupported injection value %.4f in %s. Expected J=0.35 or J=1.4.', ...
                injectionValue, filename);
        end

    end

    %% --------------------------------------------------------
    % GEOMETRY KEY (unique identifier per file)
    %% --------------------------------------------------------

    geometryKey = sprintf('%s_%s_J%s', ...
        geometryBase, sourceType, injectionKey);

    if isNonInjecting
        legendLabel = sprintf('%s, No Injection', sourceType);
    else
        legendLabel = sprintf('%s, J = %.2f', sourceType, injectionValue);
    end

    %% --------------------------------------------------------
    % STORE METADATA
    %% --------------------------------------------------------

    all_geometryKeys{end+1} = geometryKey;

    legendLabels(geometryKey)       = legendLabel;
    sourceOfKey(geometryKey)        = sourceType;
    geometryBaseOfKey(geometryKey)  = geometryBase;
    injectionKeyOfKey(geometryKey)  = injectionKey;
    injectionValueOfKey(geometryKey)= injectionValue;

    %% --------------------------------------------------------
    % OUTPUT DIRECTORIES
    %% --------------------------------------------------------

    output_dir = fullfile(pathname, ...
        ['InjectionUpdatedShearResults_' geometryKey]);

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
    % STYLE MAPPING (geometry=color, injection=marker, source=linestyle)
    %% --------------------------------------------------------

    color = colorMap(geometryBase);
    mk    = markerMap(injectionKey);
    ls    = lineStyleMap(sourceType);

    %% --------------------------------------------------------
    % PLOT
    %% --------------------------------------------------------

    plot(results(:,1), results(:,2), ...
        'Color', color, ...
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

plots_dir_global = fullfile(pathname,'InjectionPlots_Global');

if ~exist(plots_dir_global,'dir')
    mkdir(plots_dir_global);
end

hfig = figure;

hold on;

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};

    data = all_results.(k);

    if isempty(data)
        continue;
    end

    baseGeom     = geometryBaseOfKey(k);
    sourceType   = sourceOfKey(k);
    injectionKey = injectionKeyOfKey(k);

    color = colorMap(baseGeom);
    mk    = markerMap(injectionKey);
    ls    = lineStyleMap(sourceType);

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
% GLOBAL OVERLAY : NORMALIZED BY MATCHING RD00 MAX
%   (each Source/Injection combo normalized by its own RD00 case)
% ============================================================

deltaMaxRD00 = containers.Map();

%% ------------------------------------------------------------
% FIND RD00 MAX VALUES (per source/injection combo)
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

    sourceType   = sourceOfKey(k);
    baseGeom     = geometryBaseOfKey(k);
    injectionKey = injectionKeyOfKey(k);

    %% --------------------------------------------------------
    % REFERENCE CASE: same Source + Injection, RD00 geometry
    %% --------------------------------------------------------

    refKey = sprintf('RD00_%s_J%s', sourceType, injectionKey);

    if ~isKey(deltaMaxRD00, refKey)
        continue;
    end

    deltaMax = deltaMaxRD00(refKey);

    deltaNorm = data(:,2) ./ deltaMax;

    %% --------------------------------------------------------
    % STYLE
    %% --------------------------------------------------------

    color = colorMap(baseGeom);
    mk    = markerMap(injectionKey);
    ls    = lineStyleMap(sourceType);

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

    % maskY = y > -0.5;
    % 
    % y   = y(maskY);
    % vel = vel(maskY);
    % 
    % if numel(y) < 4
    %     return;
    % end

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