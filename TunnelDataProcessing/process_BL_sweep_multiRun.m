%% Clear on runtime
clc; clear; close all;

%% Simple Data Visualization and BL Sweep Processing for SSWT (Multi-file)
% - BL line: Static Pressure (psia) vs shifted Y-location
% - Stagnation, Static (plenum), Manifold pressures vs normalized Time

headers1 = [...
    "Stagnation Pressure",...
    "Static Pressure",...
    "Stagnation Temperature",...
    "Manifold Pressure",...
    "Tank Pressure",...
    "Mach Number",...
    "Velocity",...
    "Static Temperature",...
    "Mass Flow",...
    "Static Density",...
    "Reynold's Number",...
    "BL Pressure",...
    "Time",...
    "X",...
    "Y"...
];

headers2 = {...
    "psia",...      % Stagnation Pressure
    "psia",...      % Static Pressure
    "degF",...      % Stagnation Temperature
    "psig",...      % Manifold Pressure
    "psig",...      % Tank Pressure
    "N/A",...       % Mach Number
    "m/s",...       % Velocity
    "degF",...      % Static Temperature
    "kg/s",...      % Mass Flow
    "kg/m^3",...    % Static Density
    "N/A",...       % Reynold's Number
    "psig",...      % BL pressure (gauge)
    "sec",...       % Time
    "in",...        % X
    "in"...         % Y
};

gamma = 1.4;
critRatio = 0.528; 

%% --------- File selection ---------
[txtFileNames, txtPath] = uigetfile('*.txt', 'Select one or more data files', 'MultiSelect', 'on');

if isequal(txtFileNames,0)
    error('No files selected. Script aborted.');
end

% Normalize to cell array of names
if ischar(txtFileNames)
    txtFileNames = {txtFileNames};
end

nFiles = numel(txtFileNames);

%% --------- Legend identifiers ---------
fileIDs = cell(nFiles,1);
fprintf('You selected %d files. Enter a legend identifier for each:\n', nFiles);
for f = 1:nFiles
    prompt = sprintf('Identifier for file %d (%s): ', f, txtFileNames{f});
    fileIDs{f} = input(prompt, 's');
    if isempty(fileIDs{f})
        fileIDs{f} = txtFileNames{f};
    end
end

%% --------- Y-offsets (inches) ---------
yOffsets = zeros(nFiles,1);
fprintf('\nEnter Y-offset (inches) for each file (positive shifts upward, same units as Y):\n');
for f = 1:nFiles
    prompt = sprintf('Y-offset for file %d (ID: %s): ', f, fileIDs{f});
    val = input(prompt);
    if isempty(val)
        val = 0;
    end
    yOffsets(f) = val;
end

%% --------- Atmospheric pressures (psia) ---------
atmPressures = zeros(nFiles,1);
fprintf('\nEnter atmospheric pressure (psia) for each file:\n');
for f = 1:nFiles
    prompt = sprintf('Atmospheric pressure (psia) for file %d (ID: %s): ', f, fileIDs{f});
    val = input(prompt);
    if isempty(val)
        error('Atmospheric pressure must be specified for each run.');
    end
    atmPressures(f) = val;
end

% Processing parameters
N0 = input('\nEnter number of latest samples at X=0, Y=0 to KEEP: ');
Ntrim = input(['Enter number of lines to trim at earliest and latest'...
               ' time at EACH location: ']);

%% --------- Prepare figures ---------
% BL pressure vs shifted Y-location
% figBLP   = figure; hold on; grid on; box on;
% xlabel('Shifted Y Location (in)');
% ylabel('Static Pressure (psia)');
% title('Static Pressure vs Shifted Y-location');

figBLP   = figure; hold on; grid on; box on;
ylabel('Shifted Y Location (in)');
xlabel('BL Pressure (psia)');
title('Shifted Y-location vs BL Pressure');

% Pressures vs normalized Time
figStagTime = figure; hold on; grid on; box on;
xlabel('Time (s)'); ylabel('Stagnation Pressure (psia)');
title('Stagnation Pressure vs Time');

figStaticTime = figure; hold on; grid on; box on;
xlabel('Time (s)'); ylabel('Static Pressure (psia)');
title('Upstream Static Pressure vs Time');

figManifTime = figure; hold on; grid on; box on;
xlabel('Time (s)'); ylabel('Manifold Pressure (psig)');
title('Manifold Pressure vs Time');

figMach   = figure; hold on; grid on; box on;
ylabel('Shifted Y Location (in)');
xlabel('Mach Number');
title('Shifted Y-location vs Mach');

colors = lines(nFiles);

%% --------- Loop over each selected file ---------
for f = 1:nFiles
    thisFile = fullfile(txtPath, txtFileNames{f});
    [~, baseName, ~] = fileparts(thisFile);
    yOffset = yOffsets(f);
    Patm = atmPressures(f);

    fprintf('\nProcessing file %d of %d: %s (ID: %s, Y-offset = %.4f in, Patm = %.3f psia)\n',...
        f, nFiles, thisFile, fileIDs{f}, yOffset, Patm);

    %% --------- Read Data for this file ---------
    fid = fopen(thisFile,'r');
    a = findFirstLineOfData(fid);
    fclose(fid);

    T = readtable(thisFile,"NumHeaderLines",a,"ReadVariableNames",false);
    T.Properties.VariableNames = headers1;

    % Raw arrays
    t = T.("Time");
    x = T.("X");
    y = T.("Y");

    %% --------- Sort by Time ---------
    [~, tOrder] = sort(t);
    T = T(tOrder, :);
    t = T.("Time");
    x = T.("X");
    y = T.("Y");

    %% --------- Truncate after home position (unshifted Y) ---------
    yCutoff = 1.00;
    lastIdx = find(T.("Y") == yCutoff, 1, 'last');

    if ~isempty(lastIdx)
        T = T(1:lastIdx, :);
        t = T.("Time");
        x = T.("X");
        y = T.("Y");
    else
        warning('No samples found with Y == %.2f; processing full file.', yCutoff);
    end

    %% --------- Identify Unique (X, Y) Locations (unshifted) ---------
    tol = 1e-6;
    xr = round(x / tol) * tol;
    yr = round(y / tol) * tol;

    XY = [xr, yr];
    [XYuniq, ~, locID] = unique(XY, 'rows');
    nLoc = size(XYuniq, 1);

    %% --------- Allocate Storage (averaged BL vs Y, unshifted) ---------
    avgY_raw   = nan(nLoc, 1);  % unshifted Y
    avgBLP_psia = nan(nLoc, 1); % BL static pressure in psia
    avgPstag_psia = nan(nLoc, 1); % Avg Pstag
    avgPstatic_psia = nan(nLoc, 1); % Avg Pstatic

    %% --------- Logical mask of rows to keep for time-series ---------
    keepRow = false(height(T),1);

    %% --------- Process Each Location ---------
    for k = 1:nLoc
        idx = find(locID == k);

        t_k      = t(idx);
        y_k      = y(idx);   % unshifted Y
        stag_k   = T.("Stagnation Pressure")(idx);
        static_k = T.("Static Pressure")(idx);
        manif_k  = T.("Manifold Pressure")(idx);
        % Convert BL Pstatic from psig to psia using per-run atmospheric pressure
        blp_k_psia = T.("BL Pressure")(idx) + Patm;

        % Sort by time within this location
        [t_k, sIdx] = sort(t_k);
        idx        = idx(        sIdx);
        y_k        = y_k(        sIdx);
        stag_k     = stag_k(     sIdx);
        static_k   = static_k(   sIdx);
        manif_k    = manif_k(    sIdx);
        blp_k_psia = blp_k_psia( sIdx);

        % Zero location test uses unshifted coordinates
        isZeroLoc = abs(XYuniq(k,1)) < tol && abs(XYuniq(k,2)) < tol;

        % Keep only last N0 at (0,0)
        if isZeroLoc
            if numel(t_k) > N0
                keepIdxZero = (numel(t_k)-N0+1):numel(t_k);
            else
                keepIdxZero = 1:numel(t_k);
            end
        else
            keepIdxZero = 1:numel(t_k);
        end

        idx        = idx(        keepIdxZero);
        t_k        = t_k(        keepIdxZero);
        y_k        = y_k(        keepIdxZero);
        stag_k     = stag_k(     keepIdxZero);
        static_k   = static_k(   keepIdxZero);
        manif_k    = manif_k(    keepIdxZero);
        blp_k_psia = blp_k_psia( keepIdxZero);

        % Trim Ntrim samples at start and end
        nSamples = numel(t_k);
        if nSamples <= 2*Ntrim
            continue;
        end

        keepIdxTrim = (Ntrim+1):(nSamples-Ntrim);

        idx        = idx(        keepIdxTrim);
        t_k        = t_k(        keepIdxTrim);
        y_k        = y_k(        keepIdxTrim);
        stag_k     = stag_k(     keepIdxTrim);
        static_k   = static_k(   keepIdxTrim);
        manif_k    = manif_k(    keepIdxTrim);
        blp_k_psia = blp_k_psia( keepIdxTrim);

        % Rows to keep for time-series
        keepRow(idx) = true;

        % Store averaged BL static pressure (psia) vs unshifted Y
        avgY_raw(k)    = mean(y_k,        'omitnan');
        avgBLP_psia(k) = mean(blp_k_psia, 'omitnan');
        avgPstag_psia(k) = mean(stag_k, 'omitnan');
        avgPstatic_psia(k) = mean(static_k, 'omitnan');
    end

    %% --------- Clean & Sort BL pressure and Pstatic vs Y (unshifted) ---------
    validBL = ~isnan(avgY_raw) & ~isnan(avgBLP_psia);
    avgY_raw    = avgY_raw(validBL);
    avgBLP_psia = avgBLP_psia(validBL);
    avgPstag_psia = avgPstag_psia(validBL);
    avgPstatic_psia = avgPstatic_psia(validBL);

    [avgY_raw, sortIdxBL] = sort(avgY_raw);
    avgBLP_psia = avgBLP_psia(sortIdxBL);
    avgPstag_psia = avgPstag_psia(sortIdxBL);
    avgPstatic_psia = avgPstatic_psia(sortIdxBL);

    % --------- Apply Y-offset AFTER cutoff/trimming ---------
    avgY_shift = avgY_raw + yOffset;

    %% --------- Build time-series from kept rows ---------
    Tkeep = T(keepRow, :);

    allT       = Tkeep.("Time");
    y_keep     = Tkeep.("Y");            % unshifted Y
    stag_keep  = Tkeep.("Stagnation Pressure");
    static_keep= Tkeep.("Static Pressure");
    manif_keep = Tkeep.("Manifold Pressure");
    blp_psig_keep = Tkeep.("BL Pressure"); % actually stagnation pressure
    blp_psia_keep = blp_psig_keep + Patm;  % convert to psia for each sample

    % Sort by absolute time
    [allT, sortIdxT] = sort(allT);
    y_keep        = y_keep(sortIdxT);
    stag_keep     = stag_keep(sortIdxT);
    static_keep   = static_keep(sortIdxT);
    manif_keep    = manif_keep(sortIdxT);
    blp_psig_keep = blp_psig_keep(sortIdxT);
    blp_psia_keep = blp_psia_keep(sortIdxT);

    % Normalize time so earliest kept time is zero
    if ~isempty(allT)
        t0 = allT(1);
        tNorm = allT - t0;
    else
        tNorm = allT;
    end
    
    % Apply Y-offset per-sample (for export and for any Y-based analysis)
    y_shift_keep = y_keep + yOffset;

    %% --------- Compute P_BL/P0 and Mach ---------
    ratio_PBL_Pstag_avg = avgBLP_psia./ avgPstag_psia;   % P_Static / P_BL (Avg for plotting)
    ratio_PBL_Pstag_raw = blp_psia_keep./ stag_keep; % Same for table

    ratio_PBL_Pstatic_raw = blp_psia_keep ./ static_keep;
    ratio_PBL_Pstatic_avg = avgBLP_psia./ avgPstatic_psia;


    Mach_Avg = nan(size(ratio_PBL_Pstatic_avg));
    Mach_Raw = nan(size(ratio_PBL_Pstatic_raw));
    % My_Raw = nan(size(ratio_PBL_Pstag_raw));

    % Average Mach Loop
    for i = 1:numel(ratio_PBL_Pstatic_avg)
        r = ratio_PBL_Pstatic_avg(i);
        if ~isfinite(r) || r <= 0
            Mach_Avg(i) = NaN;
            continue;
        end

        if r < 1/critRatio
            % For P_static/P_BL > 0.528, use isentropic inversion for subsonic
            % cases
            Mach_Avg(i) = mach_from_isentropic_ratio(r, gamma);
             
        else
            % For P_static/P_BL <= 0.528, use Rayleigh Pitot relation + bisection
            Mach_Avg(i) = mach_from_rayleigh_ratio_bisect(r, gamma);
        end
    end

    % Table Mach Loop
    for i = 1:numel(ratio_PBL_Pstatic_raw)
        r = ratio_PBL_Pstatic_raw(i);
        if ~isfinite(r) || r <= 0
            Mach_Raw(i) = NaN;
            continue;
        end

        if r < 1/critRatio
            % For P_static/P_BL > 0.528, use isentropic inversion for subsonic
            % cases
            Mach_Raw(i) = mach_from_isentropic_ratio(r, gamma);
             
        else
            % For P_static/P_BL <= 0.528, use Rayleigh Pitot relation + bisection
            Mach_Raw(i) = mach_from_rayleigh_ratio_bisect(r, gamma);
        end
    end

    % Freestream Mach Calc
    ratio_Pstatic_Pstag_Raw = static_keep./ stag_keep;
    Mach_FS = nan(size(ratio_Pstatic_Pstag_Raw));

    for i = 1:numel(ratio_Pstatic_Pstag_Raw)
        r = ratio_Pstatic_Pstag_Raw(i);
        if ~isfinite(r) || r <= 0
            Mach_FS(i) = NaN;
            continue;
        end

        if r > critRatio
            % For P_static/P_BL > 0.528, use isentropic inversion for subsonic
            % cases
            Mach_FS(i) = mach_from_isentropic_ratio(r, gamma);
             
        else
            % For P_static/P_BL <= 0.528, use Rayleigh Pitot relation + bisection
            Mach_FS(i) = mach_from_rayleigh_ratio_bisect(r, gamma);
        end
    end

    %% --------- Save ALL per-sample data to ONE Excel sheet ---------
    RunData = table(...
        tNorm,...
        y_shift_keep,...
        stag_keep,...
        static_keep,...
        manif_keep,...
        blp_psig_keep,...
        blp_psia_keep,...
        ratio_PBL_Pstatic_raw,...
        Mach_Raw,...
        Mach_FS,...
        'VariableNames', {...
            'Time_s',...
            'Y_shift_in',...
            'StagnationPressure_psia',...
            'StaticPressure_psia',...
            'ManifoldPressure_psig',...
            'BL_Pressure_psig',...
            'BL_Pressure_psia',...
            'PBL_over_Pstatic',...
            'Mach BL',...
            'Mach FS'...
        }...
    );

    excelName = sprintf('%s_processed_%s.xlsx', baseName, fileIDs{f});
    excelPath = fullfile(txtPath, excelName);

    fprintf('  Writing processed run data to %s\n', excelPath);

    % Single sheet per run with all fields
    writetable(RunData, excelPath, 'Sheet', 'RunData', 'WriteMode','overwrite');

    %% --------- Plots ---------
    % BL static pressure (psia) vs shifted Y-location
    % figure(figBLP);
    % plot(avgY_shift, avgBLP_psia, '-o', 'LineWidth', 1.5, 'Color', colors(f,:),...
    %     'DisplayName', fileIDs{f});

    % Y-loc vs BL Static (psia)
    figure(figBLP);
    plot(avgBLP_psia, avgY_shift, '-o', 'LineWidth', 1.5, 'Color', colors(f,:),...
        'DisplayName', fileIDs{f});

    % Stagnation vs normalized Time
    figure(figStagTime);
    plot(tNorm, stag_keep, '-', 'LineWidth', 1.5, 'Color', colors(f,:),...
        'DisplayName', fileIDs{f});

    % Static (plenum) vs normalized Time
    figure(figStaticTime);
    plot(tNorm, static_keep, '-', 'LineWidth', 1.5, 'Color', colors(f,:),...
        'DisplayName', fileIDs{f});

    % Manifold vs normalized Time
    figure(figManifTime);
    plot(tNorm, manif_keep, '-', 'LineWidth', 1.5, 'Color', colors(f,:),...
        'DisplayName', fileIDs{f});

    % y-loc v Mach
    figure(figMach);
    plot(Mach_Avg, avgY_shift, '-', 'LineWidth', 1.5, 'Color', colors(f,:),...
        'DisplayName', fileIDs{f});

end

%% --------- Legends ---------
figure(figBLP);        legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figStagTime);   legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figStaticTime); legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figManifTime);  legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figMach);        legend('show', 'Interpreter', 'none', 'Location', 'best');

fprintf('\nProcessing complete. Y-offsets and atmospheric-pressure offsets applied; time normalized per run.\n');

%% --------- Helper Function ---------
function firstDataLine = findFirstLineOfData(fileID)
    count = 0;
    while 1
        count = count + 1;
        tline = fgetl(fileID);
        if ~ischar(tline)
            break
        end
        celldata = textscan(tline,'%f %f %f %f %f');
        cellCount = 0;
        for i = 1:length(celldata)
            if isempty(celldata{i})
                break
            end
            cellCount = cellCount + 1;
        end
        if cellCount == 5
            break
        end
    end
    firstDataLine = count;
end

% Invert isentropic total-to-static pressure relation:
% r = P/P0, gamma = 1.4
% M = sqrt( 2/(gamma-1) * ( r^(-(gamma-1)/gamma) - 1 ) )
function M = mach_from_isentropic_ratio(r, gamma)
    if r <= 0 || r >= 1
        M = NaN;
        return;
    end
    M = sqrt( (2/(gamma-1)) * ( r.^(-(gamma-1)/gamma) - 1 ) );
end

%% Rayleigh Pitot tube relation inversion via bisection.
% r = P_static / P0 (P_BL / P0), gamma = 1.4
% Uses standard Rayleigh Pitot expression for P0/P.
function M = mach_from_rayleigh_ratio_bisect(r_target, gamma)
    % If r is out of physical range, return NaN
    if r_target <= 0
        M = NaN;
        return;
    end

    % Define Rayleigh Pitot static-to-total ratio function r(M) = P/P0
    rayleigh_r = @(M) rayleigh_total_static_ratio(M, gamma);

    % Bisection bounds (supersonic range; adjust if needed)
    M_lo = 1.0 + 1e-6;
    M_hi = 10.0;

    % Check monotonicity and bracket
    f_lo = rayleigh_r(M_lo) - r_target;
    f_hi = rayleigh_r(M_hi) - r_target;

    % If we failed to bracket, return NaN
    if f_lo * f_hi > 0
        M = NaN;
        return;
    end

    % Bisection iterations
    maxIter = 60;
    tolM = 1e-6;

    for it = 1:maxIter
        M_mid = 0.5*(M_lo + M_hi);
        f_mid = rayleigh_r(M_mid) - r_target;

        if abs(f_mid) < 1e-8 || (M_hi - M_lo) < tolM
            M = M_mid;
            return;
        end

        if f_lo * f_mid < 0
            M_hi = M_mid;
            f_hi = f_mid;
        else
            M_lo = M_mid;
            f_lo = f_mid;
        end
    end

    M = 0.5*(M_lo + M_hi);
end

%% Normal shock inversion via bisection.
% Given downstream Mach M2_target and gamma,
% solve for upstream Mach M1 (supersonic) satisfying the normal shock relation:
%
%   M2^2 = [M1^2 + 2/gamma-1] / [2*gamma/gamma-1*M1^2 - 1]
%
% Uses bisection over M1 in a supersonic range.
function M1 = mach_from_normal_shock_M2_bisect(M2_target, gamma)

    % Basic validity check
    if ~isfinite(M2_target) || M2_target <= 0
        M1 = NaN;
        return;
    end

    % Define function of M1: f(M1) = M2(M1) - M2_target
    normal_shock_M2 = @(M1) normal_shock_downstream_Mach(M1, gamma);
    f = @(M1) normal_shock_M2(M1) - M2_target;

    % Bisection bounds for upstream supersonic Mach number
    M1_lo = 1.0 + 1e-6;
    M1_hi = 10.0;

    f_lo = f(M1_lo);
    f_hi = f(M1_hi);

    % If we failed to bracket a root, return NaN
    if f_lo * f_hi > 0
        M1 = NaN;
        return;
    end

    maxIter = 60;
    tolM = 1e-6;

    for it = 1:maxIter
        M1_mid = 0.5*(M1_lo + M1_hi);
        f_mid = f(M1_mid);

        if abs(f_mid) < 1e-8 || (M1_hi - M1_lo) < tolM
            M1 = M1_mid;
            return;
        end

        if f_lo * f_mid < 0
            M1_hi = M1_mid;
            f_hi = f_mid;
        else
            M1_lo = M1_mid;
            f_lo = f_mid;
        end
    end

    M1 = 0.5*(M1_lo + M1_hi);
end

%% Helper: normal shock downstream Mach as function of upstream Mach
function M2 = normal_shock_downstream_Mach(M1, gamma)
    % Guard against non-physical M1
    if any(M1 <= 0)
        M2 = NaN;
        return;
    end

    % Normal shock relation:
    % M2^2 = [M1^2 + 2/gamma-1] / [2*gamma/gamma-1*M1^2 - 1]
    num = M1.^2 + (2/(gamma-1));
    den = ((2*gamma)/(gamma-1)).*M1.^2 - 1;
    M2sq = num./ den;

    % For invalid (negative) M2^2, return NaN
    M2sq(M2sq <= 0) = NaN;
    M2 = sqrt(M2sq);
end

% Rayleigh Pitot: P0/P1 relation for supersonic flow with a normal shock ahead of Pitot
% Returns r = P_static / P0 for given M.
function r = rayleigh_total_total_ratio(M, gamma)
    % Guard against invalid M
    if any(M <= 0)
        r = NaN;
        return;
    end

    % P0,2/P1 (Rayleigh Pitot total-to-static ratio)
    term1 = ((((gamma+1).^2).*(M.^2)) / (4.*gamma.*M.^2 - (2.*(gamma-1)))).^(gamma / (gamma - 1));
    term2 = (1 - gamma + (2.*gamma.*M.^2)) / (gamma +1);
    term3 = (1 + ((gamma-1)/2).*M.^2).^(-(gamma/ (gamma-1)));
    P02_over_P01 = term1.* term2 .* term3;

    % r = P02/P01
    r = P02_over_P01;
end

% Rayleigh Pitot: P0/P1 relation for supersonic flow with a normal shock ahead of Pitot
% Returns r = P_static / P0 for given M.
function r = rayleigh_total_static_ratio(M, gamma)
    % Guard against invalid M
    if any(M <= 0)
        r = NaN;
        return;
    end

    % P0,2/P1 (Rayleigh Pitot total-to-static ratio)
    term1 = ((((gamma+1).^2).*(M.^2)) / (4.*gamma.*M.^2 - (2.*(gamma-1)))).^(gamma / (gamma - 1));
    term2 = (1 - gamma + (2.*gamma.*M.^2)) / (gamma +1);
    % term3 = (1 + ((gamma-1)/2).*M.^2).^(-(gamma/ (gamma-1)));
    P02_over_P = term1.* term2;

    % r = P02/P01
    r = P02_over_P;
end