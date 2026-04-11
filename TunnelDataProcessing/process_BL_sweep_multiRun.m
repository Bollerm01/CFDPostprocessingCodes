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
    "BL Pstatic",...
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
    "psig",...      % BL Pstatic (gauge)
    "sec",...       % Time
    "in",...        % X
    "in"...         % Y
};

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
% BL line static pressure vs shifted Y-location
% figBLP   = figure; hold on; grid on; box on;
% xlabel('Shifted Y Location (in)');
% ylabel('Static Pressure (psia)');
% title('Static Pressure vs Shifted Y-location');

figBLP   = figure; hold on; grid on; box on;
ylabel('Shifted Y Location (in)');
xlabel('Static Pressure (psia)');
title('Shifted Y-location vs BL Static Pressure');

% Pressures vs normalized Time
figStagTime = figure; hold on; grid on; box on;
xlabel('Time (s)'); ylabel('Stagnation Pressure (psia)');
title('Stagnation Pressure vs Time');

figStaticTime = figure; hold on; grid on; box on;
xlabel('Time (s)'); ylabel('Static Pressure (psia)');
title('Static Pressure vs Time');

figManifTime = figure; hold on; grid on; box on;
xlabel('Time (s)'); ylabel('Manifold Pressure (psig)');
title('Manifold Pressure vs Time');

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
        blp_k_psia = T.("BL Pstatic")(idx) + Patm;

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
    end

    %% --------- Clean & Sort BL static pressure vs Y (unshifted) ---------
    validBL = ~isnan(avgY_raw) & ~isnan(avgBLP_psia);
    avgY_raw    = avgY_raw(validBL);
    avgBLP_psia = avgBLP_psia(validBL);

    [avgY_raw, sortIdxBL] = sort(avgY_raw);
    avgBLP_psia = avgBLP_psia(sortIdxBL);

    % --------- Apply Y-offset AFTER cutoff/trimming ---------
    avgY_shift = avgY_raw + yOffset;

    %% --------- Build time-series from kept rows ---------
    Tkeep = T(keepRow, :);

    allT       = Tkeep.("Time");
    y_keep     = Tkeep.("Y");            % unshifted Y
    stag_keep  = Tkeep.("Stagnation Pressure");
    static_keep= Tkeep.("Static Pressure");
    manif_keep = Tkeep.("Manifold Pressure");
    blp_psig_keep = Tkeep.("BL Pstatic");
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

    %% --------- Save data to Excel sheet ---------
    % Columns: Time_s, Y_shift_in, Stag, Static, Manifold, BL_psig, BL_psia
    RunData = table(...
        tNorm,...
        y_shift_keep,...
        stag_keep,...
        static_keep,...
        manif_keep,...
        blp_psig_keep,...
        blp_psia_keep,...
        'VariableNames', {...
            'Time_s',...
            'Y_shift_in',...
            'StagnationPressure_psia',...
            'StaticPressure_psia',...
            'ManifoldPressure_psig',...
            'BL_Pstatic_psig',...
            'BL_StaticPressure_psia'...
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

end

%% --------- Legends ---------
figure(figBLP);        legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figStagTime);   legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figStaticTime); legend('show', 'Interpreter', 'none', 'Location', 'best');
figure(figManifTime);  legend('show', 'Interpreter', 'none', 'Location', 'best');

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