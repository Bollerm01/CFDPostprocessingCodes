%% ============================================================
%  Volcano/VULCAN velocityxavg Shear Layer Thickness Script
%  - Local freestream normalization (top 5 max velocities)
%  - Volcano + VULCAN comparison
%  - Includes:
%       * Individual plots
%       * Global δ_SL overlays (NEW + enhanced)
%       * Global normalized overlays (RD00-based)
% ============================================================

clc;
clear all;
close all;

%% ============================================================
% USER SETTINGS
% ============================================================

THRESHOLD_UPPER = 0.95;
THRESHOLD_LOWER = 0.05;

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
    elseif strcmpi(geomToken,'RD17') || strcmpi(geomToken,'RD1')
        geometryBase = 'RD17';
    elseif strcmpi(geomToken,'RD52') || strcmpi(geomToken,'RD5')
        geometryBase = 'RD52';
    else
        error('Unsupported geometry token.');
    end

    %% --------------------------------------------------------
    % GEOMETRY KEY
    %% --------------------------------------------------------

    if isSlice
        geometryKey = sprintf('%s_%s_Slice', geometryBase, sourceType);
        legendLabel = sprintf('%s Slice', sourceType);
    else
        geometryKey = sprintf('%s_%s', geometryBase, sourceType);
        legendLabel = sourceType;
    end

    all_geometryKeys{end+1} = geometryKey;
    legendLabels(geometryKey) = legendLabel;
    sourceOfKey(geometryKey) = sourceType;
    geometryBaseOfKey(geometryKey) = geometryBase;

    %% --------------------------------------------------------
    % OUTPUT DIRECTORIES
    %% --------------------------------------------------------

    output_dir = fullfile(pathname,['UpdatedShearResults_' geometryKey]);
    plots_dir = fullfile(output_dir,'Plots');

    if ~exist(plots_dir,'dir')
        mkdir(plots_dir);
    end

    %% ========================================================
    % LOAD SHEETS
    %% ========================================================

    [~, sheets] = xlsfinfo(excel_file);

    %% ========================================================
    % RESULTS STORAGE
    %% ========================================================

    results = [];

    axial_sheets = sheets(startsWith(sheets,'xL'));

    %% ========================================================
    % PROCESS SHEETS
    %% ========================================================

    for iS = 1:numel(axial_sheets)

        sheet = axial_sheets{iS};

        if strcmpi(sourceType,'Volcano') && ~contains(sheet,'MP')
            continue;
        end

        xL = parse_xL_MATLAB(sheet);

        if xL < 0 || xL > 1.1
            continue;
        end

        df = readtable(excel_file,'Sheet',sheet);

        if ~ismember('Y_norm',df.Properties.VariableNames)
            continue;
        end

        if strcmpi(sourceType,'Volcano')
            velCol = 'velocityxavg';
        else
            velCol = 'Velocity_X';
        end

        if ~ismember(velCol,df.Properties.VariableNames)
            continue;
        end

        y = df.Y_norm;
        vel = df.(velCol);

        mask = ~(isnan(y) | isnan(vel));
        y = y(mask);
        vel = vel(mask);

        [y, idx] = sort(y);
        vel = vel(idx);

        [~, ia] = unique(vel,'first');
        y = y(ia);
        vel = vel(ia);

        %% ----------------------------------------------------
        % LOCAL FREESTREAM (TOP 5 MAX)
        %% ----------------------------------------------------

        Uinf_local = mean(maxk(vel,min(5,numel(vel))), 'omitnan');

        if ~isfinite(Uinf_local) || Uinf_local == 0
            continue;
        end

        vel_norm = vel ./ Uinf_local;

        %% ----------------------------------------------------
        % THICKNESS
        %% ----------------------------------------------------

        [thickness, ~] = find_thickness_robust_MATLAB( ...
            y, vel_norm, THRESHOLD_UPPER, THRESHOLD_LOWER);

        results = [results; xL, thickness];

    end

    results = sortrows(results,1);
    all_results.(geometryKey) = results;

    %% ========================================================
    % INDIVIDUAL PLOT
    %% ========================================================

    hfig = figure('Visible','off');
    hold on;

    if contains(geometryKey,'Slice')
        ls = ':';
        mk = '^';
    else
        if strcmpi(sourceType,'Volcano')
            ls = '--'; mk = 'o';
        else
            ls = '-'; mk = 's';
        end
    end

    plot(results(:,1), results(:,2), ...
        'LineStyle',ls,'Marker',mk,'LineWidth',1.5);

    xlabel('$$x/L$$','Interpreter','latex','FontSize',14);
    ylabel('$$\delta_{SL}/D$$','Interpreter','latex','FontSize',14);
    grid on;

    exportgraphics(hfig, fullfile(plots_dir,[geometryKey '.pdf']), ...
        'ContentType','vector');

    savefig(hfig, fullfile(plots_dir,[geometryKey '.fig']));
    close(hfig);

end

%% ============================================================
% GLOBAL PLOTS DIRECTORY
% ============================================================

plots_dir_global = fullfile(pathname,'Plots_Global');

if ~exist(plots_dir_global,'dir')
    mkdir(plots_dir_global);
end

%% ============================================================
% COLOR MAP
% ============================================================
colorOrder = [
    0.00 0.45 0.74;  % blue-ish
    0.85 0.33 0.10;  % red-ish
    0.93 0.69 0.13;  % yellow-ish
];
colorMap = containers.Map();
colorMap('RD00') = colorOrder(1, :);
colorMap('RD17') = colorOrder(2, :);
colorMap('RD52') = colorOrder(3, :);

%% ============================================================
% ============================================================
% 1. GLOBAL SHEAR THICKNESS OVERLAY (RAW)
% ============================================================
%% ============================================================

hfig = figure; hold on;

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};
    data = all_results.(k);

    if isempty(data), continue; end

    base = geometryBaseOfKey(k);
    source = sourceOfKey(k);

    color = colorMap(base);

    if contains(k,'Slice')
        ls = ':'; mk = '^';
    else
        if strcmpi(source,'Volcano')
            ls = '--'; mk = 'o';
        else
            ls = '-'; mk = 's';
        end
    end

    plot(data(:,1),data(:,2), ...
        'Color',color,'LineStyle',ls,'Marker',mk, ...
        'LineWidth',1.5);

end

xlabel('$$x/L$$','Interpreter','latex');
ylabel('$$\delta_{SL}/D$$','Interpreter','latex');
grid on;

exportgraphics(hfig, fullfile(plots_dir_global,'GlobalOverlay_deltaSL_RAW.pdf'));
savefig(hfig, fullfile(plots_dir_global,'GlobalOverlay_deltaSL_RAW.fig'));

%% ============================================================
% 2. GLOBAL RD00 NORMALIZED OVERLAY
% ============================================================

deltaMaxRD00 = containers.Map();

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};
    base = geometryBaseOfKey(k);

    if ~strcmpi(base,'RD00'), continue; end

    data = all_results.(k);

    if isempty(data), continue; end

    deltaMaxRD00(k) = max(data(:,2),[],'omitnan');

end

hfig = figure; hold on;

for iKey = 1:numel(all_geometryKeys)

    k = all_geometryKeys{iKey};
    data = all_results.(k);

    if isempty(data), continue; end

    base = geometryBaseOfKey(k);

    if contains(k,'Slice')
        refKey = 'RD00_Volcano';
    elseif strcmpi(sourceOfKey(k),'Volcano')
        refKey = 'RD00_Volcano';
    else
        refKey = 'RD00_VULCAN';
    end

    if ~isKey(deltaMaxRD00,refKey)
        continue;
    end

    norm = data(:,2) ./ deltaMaxRD00(refKey);

    color = colorMap(base);

    plot(data(:,1),norm,'Color',color,'LineWidth',1.5);

end

xlabel('$$x/L$$','Interpreter','latex');
ylabel('$$\delta_{SL}/\delta_{SL,max,RD00}$$','Interpreter','latex');
grid on;

exportgraphics(hfig, fullfile(plots_dir_global,'GlobalOverlay_deltaSL_RD00norm.pdf'));
savefig(hfig, fullfile(plots_dir_global,'GlobalOverlay_deltaSL_RD00norm.fig'));

%% ============================================================
% HELPER FUNCTIONS (UNCHANGED)
% ============================================================

function xL = parse_xL_MATLAB(sheet_name)

    base = regexprep(sheet_name,'_(MP|z25|z75)$','');

    tokens = regexp(base,'xL_?(-?\d+)p(\d+)$','tokens');

    if ~isempty(tokens)
        t = tokens{1};
        xL = str2double([t{1} '.' t{2}]);
        return;
    end

    tokens = regexp(base,'xL_?(-?\d+)$','tokens');

    if ~isempty(tokens)
        t = tokens{1};
        xL = str2double(t{1});
        return;
    end

    error('Could not parse x/L');
end

function [thickness, lower_vel] = find_thickness_robust_MATLAB( ...
    y, vel, upper, lower)

    thickness = NaN; lower_vel = NaN;

    mask = ~(isnan(y)|isnan(vel));
    y = y(mask); vel = vel(mask);

    [y,idx] = sort(y); vel = vel(idx);

    y_mono = y(1); vel_mono = vel(1);
    current_max = vel(1);

    for i=2:numel(vel)
        if vel(i) > current_max + 1e-4
            y_mono(end+1,1)=y(i);
            vel_mono(end+1,1)=vel(i);
            current_max=vel(i);
        end
    end

    if numel(vel_mono)<4, return; end

    idxU = find(vel_mono>=upper,1);
    if isempty(idxU)||idxU==1, return; end

    yU = interp1(vel_mono(idxU-1:idxU),y_mono(idxU-1:idxU),upper);

    idxL = find(vel_mono(1:idxU)<=lower,1,'last');
    if isempty(idxL)||idxL>=numel(vel_mono), return; end

    yL = interp1(vel_mono(idxL:idxL+1),y_mono(idxL:idxL+1),lower);

    thickness = yU - yL;

    if thickness<=0||~isfinite(thickness)
        thickness = NaN;
    end

end