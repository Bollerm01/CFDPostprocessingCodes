function process_500kHz_folder()
    %% USER: Select folder containing the.dat files
    % dataFolder = uigetdir(pwd, 'Select folder containing 500kHz.dat files');
    dataFolder = 'E:\Boller CFD\AVIATION CFD\Paper Results\finalData\Volcano\RD00_500kHz_5CTUs';
    if isequal(dataFolder, 0)
        error('No folder selected.');
    end

    %% Settings
    allowedVars = {'density','pressure','temperature',...
                   'machnumber','velocityx','velocityy','velocityz'};
    coordVarName = 'coords';  % for "<location>_50kHz.coords.dat"

    % Pattern: "<location>_50kHz.<var>.dat"
    % Example: "xL0p59_z25_50kHz.density.dat"
    filePattern = fullfile(dataFolder, '*_50kHz.*.dat');
    files = dir(filePattern);

    if isempty(files)
        error('No matching *_50kHz.*.dat files found in %s', dataFolder);
    end

    %% Group files by location
    % Use a containers.Map: key = location, value = struct with fields:
    %.vars.(varName) = full path
    locations = containers.Map();

    for k = 1:numel(files)
        fname = files(k).name;

        % regex: <location>_50kHz.<var>.dat
        tokens = regexp(fname, '^(?<loc>.+)_50kHz\.(?<var>\w+)\.dat$', 'names');
        if isempty(tokens)
            % ignore non-conforming names
            continue;
        end

        loc = tokens.loc;
        var = lower(tokens.var);  % normalize to lower case

        % Only keep allowed variables and coords
        if ~ismember(var, allowedVars) && ~strcmp(var, coordVarName)
            continue;
        end

        fullpath = fullfile(files(k).folder, fname);

        if ~isKey(locations, loc)
            entry = struct();
            entry.vars = struct();
            locations(loc) = entry;
        else
            entry = locations(loc);
        end

        entry.vars.(var) = fullpath;
        locations(loc) = entry;
    end

    locKeys = locations.keys;
    if isempty(locKeys)
        error('No valid locations (with allowed variables/coords) found in %s', dataFolder);
    end

    %% Process each location
    for iLoc = 1:numel(locKeys)
        loc = locKeys{iLoc};
        entry = locations(loc);
        vars = entry.vars;

        fprintf('Processing location: %s\n', loc);

        % --- Require coords file ---
        if ~isfield(vars, coordVarName)
            warning('No coords file for location %s. Skipping.', loc);
            continue;
        end

        % --- Parse which variables we actually have at this location ---
        presentVars = intersect(fieldnames(vars), allowedVars);
        if isempty(presentVars)
            warning('No allowed variables present at location %s. Skipping.', loc);
            continue;
        end

        %% Read COORDS:
        coordFile  = vars.(coordVarName);
        coordTable = readCoordsDatWithHeader(coordFile);
        
        coordVarNames = lower(coordTable.Properties.VariableNames);
        
        % Header is "# number x y z"
        % Expected: 'number', 'x', 'y', 'z'
        if ~any(strcmp(coordVarNames, 'number'))
            error('Coords file %s must have a "number" column.', coordFile);
        end
        if ~any(strcmp(coordVarNames, 'x')) || ~any(strcmp(coordVarNames, 'y')) || ~any(strcmp(coordVarNames, 'z'))
            error('Coords file %s must have x, y, z columns.', coordFile);
        end
        
        % --- Probe number column ---
        probeRaw = coordTable{:, strcmp(coordVarNames, 'number')};
        if iscell(probeRaw) || isstring(probeRaw) || ischar(probeRaw)
            probeCol = str2double(string(probeRaw));
        else
            probeCol = double(probeRaw);
        end
        
        % --- x, y, z columns: force to double ---
        xRaw = coordTable{:, strcmp(coordVarNames, 'x')};
        yRaw = coordTable{:, strcmp(coordVarNames, 'y')};
        zRaw = coordTable{:, strcmp(coordVarNames, 'z')};
        
        if iscell(xRaw) || isstring(xRaw) || ischar(xRaw)
            xCol = str2double(string(xRaw));
        else
            xCol = double(xRaw);
        end
        
        if iscell(yRaw) || isstring(yRaw) || ischar(yRaw)
            yCol = str2double(string(yRaw));
        else
            yCol = double(yRaw);
        end
        
        if iscell(zRaw) || isstring(zRaw) || ischar(zRaw)
            zCol = str2double(string(zRaw));
        else
            zCol = double(zRaw);
        end
        
        % Basic consistency
        nProbes = numel(probeCol);
        if numel(xCol) ~= nProbes || numel(yCol) ~= nProbes || numel(zCol) ~= nProbes
            error('Mismatch in probe / coord lengths in coords file %s.', coordFile);
        end
        
        % Map: probeID -> row index in coords table
        probeIndexMap = containers.Map(probeCol(:).', 1:nProbes);

        %% Read DATA variables, check time consistency, store matrices
        % For each variable v: dataVar.(v).time [nTime x 1]
        %                      dataVar.(v).vals [nTime x nProbes]
        dataVar = struct();
        masterTime = [];

        for vIdx = 1:numel(presentVars)
            vname = presentVars{vIdx};
            vfile = vars.(vname);

            T = readProbeDatWithHeader(vfile);

            % Expect first column 'time', remaining 'probe000X'
            tVarNames = lower(T.Properties.VariableNames);
            timeColCandidates = find(strcmp(tVarNames,'time')...
                                  | contains(tVarNames,'time'));
            if isempty(timeColCandidates)
                error('No time column found in %s', vfile);
            end
            timeColIdx = timeColCandidates(1);
            timeVec = T{:, timeColIdx};

            % Probe columns:
            probeColsIdx = setdiff(1:width(T), timeColIdx);
            probeHeaders = T.Properties.VariableNames(probeColsIdx);

            % Expected names: 'probe0000', 'probe0001',..., 'probe0099'
            % Extract numeric index
            probeNumbers = zeros(numel(probeHeaders),1);
            for p = 1:numel(probeHeaders)
                ph = probeHeaders{p};
                tokProbe = regexp(ph, 'probe(\d+)$', 'tokens', 'once');
                if isempty(tokProbe)
                    error('Could not parse probe column name "%s" in file %s', ph, vfile);
                end
                probeNumbers(p) = str2double(tokProbe{1});
            end

            % Sort by probe number to have consistent ordering 0..N
            [probeNumbersSorted, sortIdx] = sort(probeNumbers);
            vals = T{:, probeColsIdx};
            vals = vals(:, sortIdx);  % sort columns

            % Check that coords file has all these probes
            for p = 1:numel(probeNumbersSorted)
                if ~isKey(probeIndexMap, probeNumbersSorted(p))
                    error('Probe %d in %s not found in coords file %s',...
                          probeNumbersSorted(p), vfile, coordFile);
                end
            end

            % Setup master time
            if isempty(masterTime)
                masterTime = timeVec;
            else
                if numel(timeVec) ~= numel(masterTime) || any(abs(timeVec - masterTime) > 1e-12)
                    error('Time vector mismatch for variable %s at location %s', vname, loc);
                end
            end

            dataVar.(vname).time = timeVec;
            dataVar.(vname).vals = vals;  % [nTime x nProbesUsed]

        end

        nTime = numel(masterTime);
        fprintf('  -> %d time steps, %d probes, %d variables for location %s\n',...
                 nTime, nProbes, numel(presentVars), loc);

        %% Reorder coords to match probe order used in dataVar
        % Use the probe numbers extracted from the first variable read
        % (all variables should share the same probe set)
        sampleV     = presentVars{1};
        sampleVals  = dataVar.(sampleV).vals;   % [nTime x nProbesUsed]
        nProbesUsed = size(sampleVals, 2);
        
        % Recompute probeNumbersSorted from that same file, using the robust reader
        Tsample = readProbeDatWithHeader(vars.(sampleV));   % <--- use the helper
        
        tVarNames = lower(Tsample.Properties.VariableNames);
        
        % Find the time column
        timeIdx = find(strcmp(tVarNames, 'time') | contains(tVarNames, 'time'), 1, 'first');
        if isempty(timeIdx)
            error('No time column found in sample variable file %s', vars.(sampleV));
        end
        
        % Candidate probe columns: everything except time
        allColsIdx   = 1:width(Tsample);
        nonTimeIdx   = setdiff(allColsIdx, timeIdx);
        allHeaders   = Tsample.Properties.VariableNames;
        
        % Filter non-time columns to only those matching 'probe<digits>'
        probeColsIdx = [];
        probeNumbers = [];
        for idx = nonTimeIdx
            name = allHeaders{idx};
            tok  = regexp(name, '^probe(\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                probeColsIdx(end+1) = idx;                %#ok<AGROW>
                probeNumbers(end+1) = str2double(tok{1}); %#ok<AGROW>
            end
        end
        
        if isempty(probeColsIdx)
            error('No probe columns of the form "probe00000" found in %s', vars.(sampleV));
        end
        
        % Sort by probe number so we have consistent ordering 0..N
        [probeNumbersSorted, sortIdxSample] = sort(probeNumbers);
        
        % Sanity check: number of probes from file vs from dataVar
        if numel(probeNumbersSorted) ~= nProbesUsed
            error('Mismatch between number of probes in %s (%d) and dataVar (%d).',...
                  vars.(sampleV), numel(probeNumbersSorted), nProbesUsed);
        end
        
        % coords for these probes:
        xData = zeros(nProbesUsed, 1);
        yData = zeros(nProbesUsed, 1);
        zData = zeros(nProbesUsed, 1);
        for p = 1:nProbesUsed
            probeID = probeNumbersSorted(p);  % e.g. 0,1,2,...
            if ~isKey(probeIndexMap, probeID)
                error('Probe %d from data file not found in coords file %s.', probeID, coordFile);
            end
            rowIdx = probeIndexMap(probeID);
            xData(p) = xCol(rowIdx);
            yData(p) = yCol(rowIdx);
            zData(p) = zCol(rowIdx);
        end

        %% BUILD 3D MATRIX AND RUNNING STATS
        %
        % Column layout:
        %
        %   col 1 : time
        %   col 2 : probe number
        %   col 3 : x
        %   col 4 : y
        %   col 5 : z
        %   col 6 : density (inst)          (if present)
        %   col 7 : density_mean            (running mean)
        %   col 8 : pressure (inst)        (if present)
        %   col 9 : pressure_mean
        %   col10 : pressure_rms_inst      (sqrt(<p^2>))
        %   col11 : pressure_rms_fluct     (sqrt(<(p - <p>)^2>))
        %   col12 : temperature (inst)     (if present)
        %   col13 : temperature_mean
        %   col14 : machnumber (inst)      (if present)
        %   col15 : mach_mean
        %   col16 : mach_rms_inst
        %   col17 : mach_rms_fluct
        %   col18 : velocityx (inst)       (if present)
        %   col19 : velocityx_mean
        %   col20 : velocityx_rms_inst
        %   col21 : velocityx_rms_fluct
        %   col22 : velocityy (inst)       (if present)
        %   col23 : velocityy_mean
        %   col24 : velocityy_rms_inst
        %   col25 : velocityy_rms_fluct
        %   col26 : velocityz (inst)       (if present)
        %   col27 : velocityz_mean
        %   col28 : velocityz_rms_inst
        %   col29 : velocityz_rms_fluct
        %   col30 : turbulence_intensity
        %
        % Columns corresponding to missing variables will remain zeros.

        nCols = 30;
        data3D = zeros(nTime, nProbesUsed, nCols);

        % Static columns
        for t = 1:nTime
            data3D(t,:,1) = masterTime(t);       % time
            data3D(t,:,2) = probeNumbersSorted;  % probe #
            data3D(t,:,3) = xData;
            data3D(t,:,4) = yData;
            data3D(t,:,5) = zData;
        end

        % Helper to get column indices:
        col = struct(...
            'density',       6,...
            'density_mean',  7,...
            'pressure',      8,...
            'pressure_mean', 9,...
            'pressure_rms_inst', 10,...
            'pressure_rms_fluct',11,...
            'temperature',   12,...
            'temperature_mean',13,...
            'mach',          14,...
            'mach_mean',     15,...
            'mach_rms_inst', 16,...
            'mach_rms_fluct',17,...
            'vx',            18,...
            'vx_mean',       19,...
            'vx_rms_inst',   20,...
            'vx_rms_fluct',  21,...
            'vy',            22,...
            'vy_mean',       23,...
            'vy_rms_inst',   24,...
            'vy_rms_fluct',  25,...
            'vz',            26,...
            'vz_mean',       27,...
            'vz_rms_inst',   28,...
            'vz_rms_fluct',  29,...
            'TI',            30 ...
            );

        % Stats containers for variables 
        stats = struct();

        statVars = {'density','pressure','temperature',...
                    'machnumber','velocityx','velocityy','velocityz'};

        for sv = 1:numel(statVars)
            v = statVars{sv};
            stats.(v).mean   = zeros(1, nProbesUsed);  % <x>
            stats.(v).M2     = zeros(1, nProbesUsed);  % sum of (x - <x>)^2
            stats.(v).meanSq = zeros(1, nProbesUsed);  % <x^2>
        end

        % Main time loop: update running stats and fill data3D
        for t = 1:nTime
            % For each variable present, update stats and record
            for vIdx = 1:numel(presentVars)
                vname = presentVars{vIdx};
                instVals = dataVar.(vname).vals(t,:);  % [1 x nProbesUsed]

                % Running mean / variance / <x^2> (Wolford's method of
                % delta means for reduced runtime)
                s = stats.(vname);
                n = t;  % count so far

                delta   = instVals - s.mean;
                newMean = s.mean + delta / n;
                delta2  = instVals - newMean;
                newM2   = s.M2 + delta.* delta2;
                newMeanSq = s.meanSq + (instVals.^2 - s.meanSq) / n;

                s.mean   = newMean;
                s.M2     = newM2;
                s.meanSq = newMeanSq;

                stats.(vname) = s;

                % Store instantaneous and mean / RMS in data3D
                switch vname
                    case 'density'
                        data3D(t,:,col.density)       = instVals;
                        data3D(t,:,col.density_mean)  = s.mean;

                    case 'pressure'
                        data3D(t,:,col.pressure)          = instVals;
                        data3D(t,:,col.pressure_mean)     = s.mean;
                        varInst = s.meanSq - s.mean.^2;   % variance of x
                        varInst(varInst < 0) = 0;         % numerical guard
                        rmsInst   = sqrt(varInst);
                        varFluct  = s.M2 / n;             % variance of fluctuations
                        varFluct(varFluct < 0) = 0;
                        rmsFluct  = sqrt(varFluct);
                        data3D(t,:,col.pressure_rms_inst)  = rmsInst;
                        data3D(t,:,col.pressure_rms_fluct) = rmsFluct;

                    case 'temperature'
                        data3D(t,:,col.temperature)      = instVals;
                        data3D(t,:,col.temperature_mean) = s.mean;

                    case 'machnumber'
                        data3D(t,:,col.mach)          = instVals;
                        data3D(t,:,col.mach_mean)     = s.mean;
                        varInst = s.meanSq - s.mean.^2;
                        varInst(varInst < 0) = 0;
                        rmsInst = sqrt(varInst);
                        varFluct = s.M2 / n;
                        varFluct(varFluct < 0) = 0;
                        rmsFluct = sqrt(varFluct);
                        data3D(t,:,col.mach_rms_inst)  = rmsInst;
                        data3D(t,:,col.mach_rms_fluct) = rmsFluct;

                    case 'velocityx'
                        data3D(t,:,col.vx)          = instVals;
                        data3D(t,:,col.vx_mean)     = s.mean;
                        varInst = s.meanSq - s.mean.^2;
                        varInst(varInst < 0) = 0;
                        rmsInst = sqrt(varInst);
                        varFluct = s.M2 / n;
                        varFluct(varFluct < 0) = 0;
                        rmsFluct = sqrt(varFluct);
                        data3D(t,:,col.vx_rms_inst)  = rmsInst;
                        data3D(t,:,col.vx_rms_fluct) = rmsFluct;

                    case 'velocityy'
                        data3D(t,:,col.vy)          = instVals;
                        data3D(t,:,col.vy_mean)     = s.mean;
                        varInst = s.meanSq - s.mean.^2;
                        varInst(varInst < 0) = 0;
                        rmsInst = sqrt(varInst);
                        varFluct = s.M2 / n;
                        varFluct(varFluct < 0) = 0;
                        rmsFluct = sqrt(varFluct);
                        data3D(t,:,col.vy_rms_inst)  = rmsInst;
                        data3D(t,:,col.vy_rms_fluct) = rmsFluct;

                    case 'velocityz'
                        data3D(t,:,col.vz)          = instVals;
                        data3D(t,:,col.vz_mean)     = s.mean;
                        varInst = s.meanSq - s.mean.^2;
                        varInst(varInst < 0) = 0;
                        rmsInst = sqrt(varInst);
                        varFluct = s.M2 / n;
                        varFluct(varFluct < 0) = 0;
                        rmsFluct = sqrt(varFluct);
                        data3D(t,:,col.vz_rms_inst)  = rmsInst;
                        data3D(t,:,col.vz_rms_fluct) = rmsFluct;
                end
            end

            % Turbulence intensity (requires velocity stats)
            if all(isfield(stats, {'velocityx','velocityy','velocityz'}))
                sx = stats.velocityx;
                sy = stats.velocityy;
                sz = stats.velocityz;
                n  = t;

                % RMS of fluctuating parts (using M2)
                ux_rms_fluct = sqrt(max(sx.M2 / n, 0));
                uy_rms_fluct = sqrt(max(sy.M2 / n, 0));
                uz_rms_fluct = sqrt(max(sz.M2 / n, 0));

                % Mean velocities
                ux_mean = sx.mean;
                uy_mean = sy.mean;
                uz_mean = sz.mean;

                % Turb. Intensity
                numTI = sqrt((ux_rms_fluct.^2 + uy_rms_fluct.^2 + uz_rms_fluct.^2) / 3);
                denTI = sqrt(ux_mean.^2 + uy_mean.^2 + uz_mean.^2);

                TI = zeros(1, nProbesUsed);
                nonzeroDen = denTI > 0;
                TI(nonzeroDen) = numTI(nonzeroDen)./ denTI(nonzeroDen);

                data3D(t,:,col.TI) = TI;
            end
        end

        %% Build final 2D matrix from last time step
        tLast = nTime;
        probeFinal = squeeze(data3D(tLast,:,2)).';
        xFinal     = squeeze(data3D(tLast,:,3)).';
        yFinal     = squeeze(data3D(tLast,:,4)).';
        zFinal     = squeeze(data3D(tLast,:,5)).';

        % Mean velocities at final time
        uMean = squeeze(data3D(tLast,:,col.vx_mean)).';
        vMean = squeeze(data3D(tLast,:,col.vy_mean)).';
        wMean = squeeze(data3D(tLast,:,col.vz_mean)).';

        % RMS of fluctuating velocities and Mach, pressure
        uRMS = squeeze(data3D(tLast,:,col.vx_rms_fluct)).';
        vRMS = squeeze(data3D(tLast,:,col.vy_rms_fluct)).';
        wRMS = squeeze(data3D(tLast,:,col.vz_rms_fluct)).';

        machRMS = zeros(size(uRMS));
        presRMS = zeros(size(uRMS));
        if ismember('machnumber', presentVars)
            machRMS = squeeze(data3D(tLast,:,col.mach_rms_fluct)).';
        end
        if ismember('pressure', presentVars)
            presRMS = squeeze(data3D(tLast,:,col.pressure_rms_fluct)).';
        end

        TI_final = squeeze(data3D(tLast,:,col.TI)).';

        % Assemble output matrix:
        % [probe, x, y, z, uMean, vMean, wMean, uRMS, vRMS, wRMS, machRMS, presRMS, TI]
        out2D = [probeFinal, xFinal, yFinal, zFinal,...
                 uMean, vMean, wMean,...
                 uRMS, vRMS, wRMS,...
                 machRMS, presRMS, TI_final];

        %% Write to XLSX workbook per plane
        % Determine plane from location string: last token after '_'
        parts = strsplit(loc, '_');
        plane = parts{end};          % e.g., 'z25', 'z75', 'MP'
        workbookName = fullfile(dataFolder, [plane '_results.xlsx']);

        % Header row
        header = {'probe', 'x', 'y', 'z',...
                  'u_mean', 'v_mean', 'w_mean',...
                  'u_rms_fluct', 'v_rms_fluct', 'w_rms_fluct',...
                  'mach_rms_fluct', 'pressure_rms_fluct',...
                  'turbulence_intensity'};

        % Write header + data as a sheet named by location
        sheetName = loc;
        Tout = array2table(out2D, 'VariableNames', header);

        if exist(workbookName, 'file')
            writetable(Tout, workbookName, 'Sheet', sheetName, 'WriteMode', 'overwritesheet');
        else
            writetable(Tout, workbookName, 'Sheet', sheetName);
        end

        fprintf('  -> Wrote sheet "%s" in %s\n', sheetName, workbookName);
    end

    fprintf('All locations processed.\n');

end

%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%% 

function T = readProbeDatWithHeader(fname)
    % READPROBEDATWITHHEADER  Read probe.dat files with '#' header

    fid = fopen(fname, 'r');
    if fid == -1
        error('Could not open file: %s', fname);
    end

    % Read the first line (the header)
    firstLine = fgetl(fid);
    fclose(fid);

    if ~ischar(firstLine)
        error('File %s appears to be empty or unreadable.', fname);
    end

    % Remove leading '#' and any leading/trailing whitespace
    firstLine = strtrim(regexprep(firstLine, '^#', ''));

    % Split by whitespace into tokens
    rawNames = regexp(firstLine, '\s+', 'split');

    % Sanitize for MATLAB variable names
    varNames = matlab.lang.makeValidName(rawNames);

    % Read the numeric data, skipping the first line
    T = readtable(fname,...
        'FileType', 'text',...
        'Delimiter', ' ',...
        'MultipleDelimsAsOne', true,...
        'HeaderLines', 1,...
        'ReadVariableNames', false);

    % Handle possible extra dummy column (e.g. Var1) before assigning names
    if width(T) ~= numel(varNames)
        % Common case: there is one extra leading column to drop
        if width(T) == numel(varNames) + 1
            T(:,1) = [];   % remove first column
        else
            error('Header / data column count mismatch in file %s.', fname);
        end
    end

    % Assign the intended variable names
    T.Properties.VariableNames = varNames;

    % If the first column is still named Var1 for any reason, drop it
    % (backup)
    if ~isempty(T.Properties.VariableNames) && strcmpi(T.Properties.VariableNames{1}, 'Var1')
        T.Var1 = [];
    end

    % --- Force all non-time columns to be numeric (double) ---
    vnames = T.Properties.VariableNames;
    timeIdx = find(strcmpi(vnames, 'time'), 1, 'first');

    if isempty(timeIdx)
        error('No "time" column found in %s.', fname);
    end

    for k = 1:numel(vnames)
        if k == timeIdx
            % time column: ensure numeric
            if ~isnumeric(T.(vnames{k}))
                T.(vnames{k}) = str2double(string(T.(vnames{k})));
            end
        else
            % probe columns: ensure numeric
            colData = T.(vnames{k});
            if iscell(colData) || isstring(colData) || ischar(colData)
                T.(vnames{k}) = str2double(string(colData));
            elseif ~isnumeric(colData)
                % Fallback: convert to string then numeric
                T.(vnames{k}) = str2double(string(colData));
            end
        end
    end
end

function coordTable = readCoordsDatWithHeader(fname)
    % READCOORDSDATWITHHEADER  Read coords.dat files with '#' header.

    fid = fopen(fname, 'r');
    if fid == -1
        error('Could not open coords file: %s', fname);
    end

    % Read the first line (header)
    firstLine = fgetl(fid);
    fclose(fid);

    if ~ischar(firstLine)
        error('Coords file %s appears to be empty or unreadable.', fname);
    end

    % Remove leading '#' and whitespace
    firstLine = strtrim(regexprep(firstLine, '^#', ''));

    % Split into tokens
    rawNames = regexp(firstLine, '\s+', 'split');

    % MATLAB variable names
    varNames = matlab.lang.makeValidName(rawNames);

    % Read numeric data, skipping the header line
    coordTable = readtable(fname,...
        'FileType', 'text',...
        'Delimiter', ' ',...
        'MultipleDelimsAsOne', true,...
        'HeaderLines', 1,...
        'ReadVariableNames', false);

    % If an extra dummy column (Var1) slipped in, remove it before assigning names
    if width(coordTable) ~= numel(varNames)
        % Common case: first column is an empty/dummy Var1 that we should drop
        if width(coordTable) == numel(varNames) + 1
            % Remove first column
            coordTable(:,1) = [];
        else
            error('Header / data column mismatch in coords file %s.', fname);
        end
    end

    % Assign the intended variable names
    coordTable.Properties.VariableNames = varNames;

    % Extra safety: if the first column is still named Var1 for any reason, drop it
    if ~isempty(coordTable.Properties.VariableNames) &&...
       strcmpi(coordTable.Properties.VariableNames{1}, 'Var1')
        coordTable.Var1 = [];
    end
end